{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    wgsl-analyzer = {
      url = "github:wgsl-analyzer/wgsl-analyzer";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = { self, nixpkgs, fenix, flake-utils, wgsl-analyzer }:
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
        rustDefaults = with pkgs; [
          rustToolchain
          rust-analyzer
          bacon
        ];
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
            buildInputs = with pkgs; [] ++ rustDefaults;
          };
          bevy = pkgs.mkShell rec {
            buildInputs = with pkgs; [
              wgsl-analyzer.packages.${system}.default
              mold-wrapped # faster linker
              fontconfig
              udev alsa-lib vulkan-loader
              libxkbcommon wayland # wayland feature
              xorg.libX11 xorg.libXcursor xorg.libXi xorg.libXrandr # x11 feature
            ] ++ rustDefaults;
            nativeBuildInputs = with pkgs; [
              pkg-config
            ];
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
          };
          ev3dev = pkgs.mkShell {
            packages = with pkgs; [
              (python3.withPackages (ps: [
                ps.ev3dev2
                ps.python-lsp-black
              ]))
            ];
          };
          python = pkgs.mkShell {
            packages = with pkgs; [
              (python3.withPackages (ps: [
                ps.python-lsp-black
              ]))
            ];
          };
          pyautogui = pkgs.mkShell {
            packages = with pkgs; [
              (python3.withPackages (ps: [
                ps.python-lsp-black
                ps.pyautogui
              ]))
            ];
          };
          comfyui = pkgs.mkShell rec {
            buildInputs = with pkgs; [
              git
              python310
              stdenv.cc.cc.lib
              stdenv.cc
              ncurses5
              binutils
              gitRepo gnupg autoconf curl
              procps gnumake util-linux m4 gperf unzip
              libGLU libGL
              glib
              # rocm packages for amd gpu
              rocmPackages.rocm-runtime
              pciutils
            ];
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath buildInputs;
          };
        };
      }
    );
}
