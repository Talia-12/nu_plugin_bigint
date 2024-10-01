{
  lib,
  pkgs,
  ourRustPlatform,
  self,
  darwinDeps,
  linuxNativeDeps
}: let
  filterSrc = src: regexes:
    pkgs.lib.cleanSourceWith {
      inherit src;
      filter = path: type:
        let
          relPath = pkgs.lib.removePrefix (toString src + "/") (toString path);
        in
        pkgs.lib.all (re: builtins.match re relPath == null) regexes;
    };
in ourRustPlatform.buildRustPackage {
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
  
}
