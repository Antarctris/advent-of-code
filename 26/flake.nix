{
  description = "Flake providing zig and zls";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zls-repository.url = "github:zigtools/zls/0.17.0";
  };

  outputs = {
    self,
    nixpkgs,
    zig-overlay,
    zls-repository,
    ...
  }:
    builtins.foldl' nixpkgs.lib.recursiveUpdate {} (
      builtins.map (
        system: let
          pkgs = nixpkgs.legacyPackages.${system};
          zig = zig-overlay.packages.${system}."0.17.1";
          zls = zls-repository.packages.${system}.zls;
        in {
          devShells.${system}.default = pkgs.mkShell {
            packages = with pkgs; [
              zig
              zls
            ];
          };
        }
      ) (builtins.attrNames zig-overlay.packages)
    );
}
