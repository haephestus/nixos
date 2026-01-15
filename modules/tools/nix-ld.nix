{ pkgs, ... }:

{
  programs.nix-ld = {
    enable = true;

    libraries = with pkgs; [
      # --- Core C/C++ runtime libraries ---
      glibc
      gcc
      libc
      zlib
      libffi
      zstd

      # --- Rust toolchain libraries ---
      rustc
      cargo

      # --- Java and Gradle native dependencies ---
      openjdk17
      openjdk21
      fontconfig
      freetype
      xorg.libX11
      xorg.libXext
      xorg.libXrender
      xorg.libxcb
      xorg.libXrandr
      xorg.libXinerama
      xorg.libXcursor
      libGL
      mesa
      openssl

      # --- Flutter / Dart native dependencies ---
      cairo
      pango
      libpng
      libjpeg_turbo
      harfbuzz

      # --- Network-related libraries ---
      curl
      libssh2
      nghttp2
      openssl

      # --- Compression and archiving support ---
      xz
      unzip
      gzip

      # --- Filesystem and fuse ---
      fuse

      # --- Neovim and Lua ecosystems ---
      luajit
      libuv
      ncurses
      gperf
 
      # LazyVim Runtime Utilities
      ripgrep
      nodejs
      fd
 
      # --- Fonts ----
      #fontconfig
      #freetype

      # --- Miscellaneous libraries ----
      xorg.libxcb
      libxkbcommon
    ];
  };
}
