{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, fenix, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        overlays = [ fenix.overlays.default ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        toolchain = fenix.packages.${system}.stable;
        rustToolchain =
          (toolchain.withComponents [
            "cargo"
            "clippy"
            "rust-src"
            "rustc"
            "rustfmt"
          ]);
      in
      {
        devShells = {
          cpp = pkgs.mkShell {
            packages = with pkgs; [
              cmake
              clang-tools
            ];
          };
          rust = pkgs.mkShell {
            buildInputs = with pkgs; [
              rustToolchain
              rust-analyzer
            ];
          };
          bevy = pkgs.mkShell rec {
            buildInputs = with pkgs; [
              rustToolchain
              rust-analyzer
              udev alsa-lib vulkan-loader
              libxkbcommon wayland # wayland feature
              # xorg.libX11 xorg.libXcursor xorg.libXi xorg.libXrandr # x11 feature
            ];
            nativeBuildInputs = with pkgs; [
              pkg-config
            ];
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
          };
        };
      }
    );
}
