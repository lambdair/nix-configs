//! Serialization wrapper around the real `jj` binary.
//!
//! jj workspaces isolate the working copy but share one operation log, so two
//! jj processes that rewrite the same change at overlapping times fork the op
//! log into a divergent change — which then refuses `jj edit`/`describe`/
//! `squash` by change id. This happens in practice between the main session
//! and a background worktree agent (both drive jj concurrently). Holding one
//! repo-shared lock (flock(2)) for the whole invocation serializes those calls
//! so the op log never forks. The lock fd is left open across exec, so the
//! kernel holds the lock for jj's entire run and releases it on exit.
//!
//! The lock mode depends on the subcommand. Rewrites take LOCK_EX. Inspections
//! take LOCK_SH: they are not read-only — each still snapshots its own
//! workspace's working copy — but they never rewrite someone else's change, so
//! they only need to exclude rewrites, not each other. That matters because
//! the lock is held for the whole run: `jj log` waits on its pager, so an
//! exclusive lock there holds up every other jj call in the repo, the
//! per-render `jj log` behind the statusline included. Anything not
//! recognized as an inspection falls back to LOCK_EX, so an unknown or
//! aliased subcommand is never under-locked.
//!
//! Every workspace of a repo resolves to the same shared store, so they share
//! one lock file. Outside a jj repo the lock is skipped and jj runs unwrapped.
//!
//! zig 0.16's std has no cross-platform posix flock/execv/realpath wrappers, so
//! the syscalls go through libc; only the path logic is Zig.
const std = @import("std");
const c = @cImport({
    @cInclude("unistd.h"); // getcwd, execv, read, close
    @cInclude("sys/file.h"); // flock, LOCK_EX
    @cInclude("sys/stat.h"); // stat, S_IFMT, S_IFDIR
    @cInclude("fcntl.h"); // open, O_RDONLY, O_RDWR, O_CREAT
    @cInclude("stdlib.h"); // realpath
});

// Replaced by nix at build time with the absolute path to the real jj binary.
const real_jj = "@REAL_JJ@";

const max_path = 4096;

/// Global flags that take a separate value, so the token after them is not the
/// subcommand.
const value_flags = [_][]const u8{
    "-R",
    "--repository",
    "--at-op",
    "--at-operation",
    "--config",
    "--config-file",
    "--color",
};

/// Inspection subcommands as (command, subcommand) pairs; an empty subcommand
/// matches any. Names that cover both reads and rewrites (`file`, `op`,
/// `config`, `workspace`, `bookmark`) are listed only for their reading forms,
/// so e.g. `file show` is shared but `file track` is exclusive.
const inspections = [_][2][]const u8{
    .{ "log", "" },
    .{ "show", "" },
    .{ "diff", "" },
    .{ "status", "" },
    .{ "st", "" },
    .{ "evolog", "" },
    .{ "interdiff", "" },
    .{ "root", "" },
    .{ "version", "" },
    .{ "help", "" },
    .{ "file", "show" },
    .{ "file", "list" },
    .{ "op", "log" },
    .{ "op", "show" },
    .{ "op", "diff" },
    .{ "config", "get" },
    .{ "config", "list" },
    .{ "config", "path" },
    .{ "workspace", "list" },
    .{ "workspace", "root" },
    .{ "bookmark", "list" },
};

fn takesValue(flag: []const u8) bool {
    for (value_flags) |f| {
        if (std.mem.eql(u8, flag, f)) return true;
    }
    return false;
}

/// flock mode for this invocation: LOCK_SH for an inspection, LOCK_EX for
/// anything else — including subcommands not listed above, so an unrecognized
/// or user-aliased name errs toward full serialization.
fn lockMode(args: []const [*:0]const u8) c_int {
    var words: [2][]const u8 = .{ "", "" };
    var n: usize = 0;
    var i: usize = 1;
    while (i < args.len and n < words.len) : (i += 1) {
        const a = std.mem.sliceTo(args[i], 0);
        if (a.len == 0) continue;
        if (a[0] == '-') {
            // `--flag=value` carries its value inline; `--flag value` does not.
            if (std.mem.indexOfScalar(u8, a, '=') == null and takesValue(a)) i += 1;
            continue;
        }
        words[n] = a;
        n += 1;
    }
    if (n == 0) return c.LOCK_SH; // bare `jj` only prints help
    for (inspections) |pair| {
        if (!std.mem.eql(u8, words[0], pair[0])) continue;
        if (pair[1].len == 0 or std.mem.eql(u8, words[1], pair[1])) return c.LOCK_SH;
    }
    return c.LOCK_EX;
}

/// Walk up from cwd to find `.jj/repo`, resolve the shared store, and write
/// `<store>/.claude-jj.lock` into `out`. Returns null if not in a jj repo.
fn findLock(out: []u8) ?[]const u8 {
    var dir_buf: [max_path]u8 = undefined;
    if (c.getcwd(&dir_buf, dir_buf.len) == null) return null;
    var dir_len = std.mem.indexOfScalar(u8, &dir_buf, 0) orelse return null;

    while (true) {
        const dir = dir_buf[0..dir_len];

        var repo_buf: [max_path]u8 = undefined;
        const repo = std.fmt.bufPrintZ(&repo_buf, "{s}/.jj/repo", .{dir}) catch return null;

        var st: c.struct_stat = undefined;
        if (c.stat(repo.ptr, &st) == 0) {
            var store_buf: [max_path]u8 = undefined;
            const store = if (st.st_mode & c.S_IFMT == c.S_IFDIR)
                // Main workspace: .jj/repo is the store directory.
                resolveReal(repo.ptr, &store_buf) orelse return null
            else
                // Added workspace: .jj/repo is a file whose contents are the
                // store path, relative to the .jj directory.
                resolveWorkspace(repo.ptr, dir, &store_buf) orelse return null;

            return std.fmt.bufPrint(out, "{s}/.claude-jj.lock", .{store}) catch return null;
        }

        // Not a repo boundary here; walk up one level.
        const idx = std.mem.lastIndexOfScalar(u8, dir, '/') orelse return null;
        if (idx == 0) return null; // reached filesystem root
        dir_len = idx;
    }
}

fn resolveReal(path_z: [*:0]const u8, buf: *[max_path]u8) ?[]const u8 {
    if (c.realpath(path_z, buf) == null) return null;
    return std.mem.sliceTo(buf, 0);
}

fn resolveWorkspace(repo_z: [*:0]const u8, dir: []const u8, buf: *[max_path]u8) ?[]const u8 {
    const fd = c.open(repo_z, c.O_RDONLY);
    if (fd < 0) return null;
    defer _ = c.close(fd);

    var rel_buf: [max_path]u8 = undefined;
    const n = c.read(fd, &rel_buf, rel_buf.len - 1);
    if (n <= 0) return null;
    const rel = std.mem.trimEnd(u8, rel_buf[0..@intCast(n)], " \r\n");

    var joined_buf: [max_path]u8 = undefined;
    const joined = std.fmt.bufPrintZ(&joined_buf, "{s}/.jj/{s}", .{ dir, rel }) catch return null;
    return resolveReal(joined, buf);
}

pub fn main(init: std.process.Init.Minimal) void {
    // Acquire the repo-shared lock (best effort). The fd is intentionally left
    // open across exec so the kernel holds the lock for jj's entire run.
    const mode = lockMode(init.args.vector);
    var lock_buf: [max_path]u8 = undefined;
    if (findLock(&lock_buf)) |lock| {
        var lock_z: [max_path]u8 = undefined;
        if (std.fmt.bufPrintZ(&lock_z, "{s}", .{lock})) |lz| {
            const fd = c.open(lz.ptr, c.O_RDWR | c.O_CREAT, @as(c_uint, 0o644));
            if (fd >= 0) _ = c.flock(fd, mode);
        } else |_| {}
    }

    // Build argv: [real_jj, original argv[1..], null] and exec. The incoming
    // vector is already an array of NUL-terminated C strings, ideal for execv.
    // Sized to the real argument count so nothing is ever silently dropped; the
    // allocation is freed by the exec (or process exit).
    const in = init.args.vector; // []const [*:0]const u8
    const argc = @max(in.len, 1); // keep argv[0] even if exec'd with empty argv
    const argv = std.heap.page_allocator.alloc(?[*:0]const u8, argc + 1) catch
        std.process.exit(127);
    argv[0] = real_jj;
    if (in.len > 1) {
        for (in[1..], 1..) |arg, i| argv[i] = arg;
    }
    argv[argc] = null;

    _ = c.execv(real_jj, @ptrCast(argv.ptr));
    std.process.exit(127); // only reached if execv failed
}
