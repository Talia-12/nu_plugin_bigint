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

      filterSrc = src: regexes:
        pkgs.lib.cleanSourceWith {
          inherit src;
          filter = path: type:
            let
              relPath = pkgs.lib.removePrefix (toString src + "/") (toString path);
            in
            pkgs.lib.all (re: builtins.match re relPath == null) regexes;
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
        nu_plugin_bigint = { lib, ... }: ourRustPlatform.buildRustPackage {
          pname = "nu_plugin_bigint";
          version = "unstable-${self.shortRev or "dirty"}";

          buildFeatures = [ ];
          # cargoBuildFlags = [ ]; # don't build and install the fake editors
          useNextest = true;
          src = filterSrc ./. [
            ".*\\.nix$"
            "^.jj/"
            "^flake\\.lock$"
            "^target/"
          ];

          cargoLock.lockFile = ./Cargo.lock;
          nativeBuildInputs = with pkgs; [
            gmp gmp.dev m4
            # gzip
            # installShellFiles
            # makeWrapper
            # pkg-config

            # # for signing tests
            # gnupg 
            # openssh
          ] ++ linuxNativeDeps;
          buildInputs = with pkgs; [
            gmp gmp.dev m4
            # openssl zstd libgit2 libssh2
          ] ++ darwinDeps;

          ZSTD_SYS_USE_PKG_CONFIG = "1";
          LIBSSH2_SYS_USE_PKG_CONFIG = "1";
          RUSTFLAGS = pkgs.lib.optionalString pkgs.stdenv.isLinux "-C link-arg=-fuse-ld=mold";
          NIX_JJ_GIT_HASH = self.rev or "";
          CARGO_INCREMENTAL = "0";

          preCheck = ''
            export RUST_BACKTRACE=1
          '';

          # postInstall = ''
          #   $out/bin/jj util mangen > ./jj.1
          #   installManPage ./jj.1

          #   installShellCompletion --cmd jj \
          #     --bash <($out/bin/jj util completion bash) \
          #     --fish <($out/bin/jj util completion fish) \
          #     --zsh <($out/bin/jj util completion zsh)
          # '';

          meta = {
            description = "A nushell plugin to add BigInteger and Fractional types.";
            mainProgram = "nu_plugin_bigint";
            homepage = "https://github.com/Talia-12/nu_plugin_bigint";
            license = lib.licenses.mit;
            # maintainers = [];
          };
          
        };
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
