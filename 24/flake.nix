{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    
    zig-overlay = {
      url = "github:mitchellh/zig-overlay";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    zls-overlay.url = "github:omega-800/zls-overlay";
  };

  outputs = {
    self,
    nixpkgs,
    zig-overlay,
    zls-overlay,
    ...
  }:
    builtins.foldl' nixpkgs.lib.recursiveUpdate {} (
      builtins.map (
        system: let
          pkgs = nixpkgs.legacyPackages.${system};
          zig = zig-overlay.packages.${system}."0.14.1";
          zls = zls-overlay.packages.${system}."0.14.0";
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
