{ pkgs }:

pkgs.vimUtils.buildVimPlugin {
  name = "elin";
  version = "2024-11-21";
  src = pkgs.fetchFromGitHub {
    owner = "liquidz";
    repo = "elin";
    rev = "4a9e3908e76f3015a37c620a09472dc0a146320a";
    hash = "sha256-Do5/u+WVCnaCIA55u4jlQq+UHVS2AEA5qEsF13BFIu8=";
  };
}
