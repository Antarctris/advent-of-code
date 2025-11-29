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
    zls-overlay.url = "github:zigtools/zls/ce6c8f02c78e622421cfc2405c67c5222819ec03";
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
          zig = zig-overlay.packages.${system}."0.15.2";
          zls = zls-overlay.packages.x86_64-linux.zls.overrideAttrs (old: {
            nativeBuildInputs = [ zig ];
          });
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
