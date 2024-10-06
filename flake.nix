{
  description = "Personal page";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }:
    let
      forAllSystems =
        function:
        nixpkgs.lib.genAttrs
          [
            "x86_64-linux"
            "aarch64-linux"
            "x86_64-darwin"
            "aarch64-darwin"
          ]
          (
            system:
            function (
              import nixpkgs {
                inherit system;
                config.allowUnfree = true;
              }
            )
          );
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          name = "page";

          packages = with pkgs; [
            hugo
            vale
          ];
        };
      });
      formatter = forAllSystems (pkgs: pkgs.nixpkgs-fmt);
    };
}
