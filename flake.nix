{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    fenix = {
      url = "github:nix-community/fenix/monthly";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      fenix,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [ fenix.overlays.default ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        fenixSystem = fenix.packages.${system};
        rustToolchain = (
          fenixSystem.complete.withComponents [
            "cargo"
            "clippy"
            "rust-src"
            "rustc"
            "rustfmt"
          ]
        );
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
              bacon
              pkg-config
              dbus
              openssl
              udev
              jack2
            ];
          };
          rust-windows =
            let
              target = "x86_64-pc-windows-gnu";
            in
            pkgs.mkShell {
              buildInputs = with pkgs; [
                (fenixSystem.combine [
                  rustToolchain
                  fenixSystem.targets.${target}.latest.rust-std
                ])
                rust-analyzer
                bacon
                pkgsCross.mingwW64.stdenv.cc
                pkgsCross.mingwW64.windows.mingw_w64_pthreads
              ];
            };
          bevy = pkgs.mkShell rec {
            buildInputs = with pkgs; [
              wgsl-analyzer
              mold-wrapped # faster linker
              fontconfig
              udev
              alsa-lib
              vulkan-loader
              libxkbcommon
              wayland # wayland feature
              xorg.libX11
              xorg.libXcursor
              xorg.libXi
              xorg.libXrandr # x11 feature
              rustToolchain
              rust-analyzer
            ];
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
              gitRepo
              gnupg
              autoconf
              curl
              procps
              gnumake
              util-linux
              m4
              gperf
              unzip
              libGLU
              libGL
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
