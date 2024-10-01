{
  description = "Jujutsu VCS, a Git-compatible DVCS that is both simple and powerful";

  inputs = {
    # For listing and iterating nix systems
    flake-utils.url = "github:numtide/flake-utils";

    # For installing non-standard rustc versions
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay }: {
    overlays.default = (final: prev: {
      # jujutsu = self.packages.${final.system}.jujutsu;
    });
  } //
  (flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          rust-overlay.overlays.default
        ];
      };

      ourRustVersion = pkgs.rust-bin.selectLatestNightlyWith (toolchain: toolchain.complete);

      ourRustPlatform = pkgs.makeRustPlatform {
        rustc = ourRustVersion;
        cargo = ourRustVersion;
      };

      # these are needed in both devShell and buildInputs
      darwinDeps = with pkgs; lib.optionals stdenv.isDarwin [
        darwin.apple_sdk.frameworks.Security
        darwin.apple_sdk.frameworks.SystemConfiguration
        libiconv
      ];

      # these are needed in both devShell and buildInputs
      linuxNativeDeps = with pkgs; lib.optionals stdenv.isLinux [
        mold-wrapped
      ];

      # on macOS and Linux, use faster parallel linkers that are much more
      # efficient than the defaults. these noticeably improve link time even for
      # medium sized rust projects like jj
      rustLinkerFlags =
        if pkgs.stdenv.isLinux then
          [ "-fuse-ld=mold" "-Wl,--compress-debug-sections=zstd" ]
        else if pkgs.stdenv.isDarwin then
          [ "-fuse-ld=/usr/bin/ld" "-ld_new" ]
        else
          [ ];

      rustLinkFlagsString = pkgs.lib.concatStringsSep " " (pkgs.lib.concatMap (x:
        [ "-C" "link-arg=${x}" ]
      ) rustLinkerFlags);
    in
    {
      packages = {
        nu_plugin_bigint = pkgs.callPackage ./. { inherit ourRustPlatform self darwinDeps linuxNativeDeps; };
        default = self.packages.${system}.nu_plugin_bigint;
      };
      
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          ourRustVersion

          # Foreign dependencies
          # openssl zstd libgit2 libssh2
          # pkg-config
          gmp m4
          gmp.dev

          # Additional tools recommended by contributing.md
          cargo-deny
          cargo-insta
          cargo-nextest
          cargo-watch

        ] ++ darwinDeps ++ linuxNativeDeps;

        shellHook = ''
          export RUST_BACKTRACE=1
          export ZSTD_SYS_USE_PKG_CONFIG=1
          export LIBSSH2_SYS_USE_PKG_CONFIG=1

          export RUSTFLAGS="-Zthreads=0 ${rustLinkFlagsString}"
        '';
      };
    }));
}
