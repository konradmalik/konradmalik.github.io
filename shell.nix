let
  flakeLock = builtins.fromJSON (builtins.readFile ./flake.lock);
  nixpkgsRev = flakeLock.nodes.nixpkgs.locked.rev;
  lockedNixpkgs = import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/${nixpkgsRev}.tar.gz") { };
in
{ pkgs ? lockedNixpkgs }:
pkgs.mkShell {
  name = "page-shell";

  nativeBuildInputs = with pkgs; [
    # nix
    nil
    nixpkgs-fmt
    #
    hugo
    vale
  ];
}
