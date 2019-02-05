{ config, pkgs, ... }:

let
    /* Adapted from https://alpmestan.com/posts/2017-09-06-quick-haskell-hacking-with-nix.html
     * Use 'nix-haskell' to try a haskell package in nix-shell. E.g.:
     * 'nix-haskell ghc822 protolude' to try protolude package
     */
    nix-haskell = pkgs.writeScriptBin "nix-haskell" ''
      #!/usr/bin/env bash
      if [[ $# -lt 2 ]];
      then
        echo "Must provide a ghc version (e.g ghc822) and at least one package"
        return 1;
      else
        ghcver=$1
        # get the rest of the arguments
        shift
        pkgs=$@
        echo "Starting haskell shell, ghc = $ghcver, pkgs = $pkgs"
        nix-shell -p "haskell.packages.$ghcver.ghcWithPackages (pkgs: with pkgs; [$pkgs])"
      fi
    '';

    /* Adapted from http://nicknovitski.com/nix-npm-install
     * Use 'nix-npm-install' to install a npm package. E.g.:
     * 'nix-npm-install tern' to install tern
     * 'nix-env -e node-tern' to uninstall tern
     */
    nix-npm-install = pkgs.writeScriptBin "nix-npm-install" ''
      #!/usr/bin/env bash
      tempdir="/tmp/nix-npm-install/$1"
      mkdir -p $tempdir
      pushd $tempdir
      # '-8' switch instructs node2nix to use nodejs 8
      ${pkgs.nodePackages.node2nix}/bin/node2nix -8 --input <( echo "[\"$1\"]")
      nix-env --install --file .
      popd
    '';
in
{
  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  # To rebuild run:
  # $ darwin-rebuild changelog
  environment.systemPackages =
    (with pkgs; [
      # zsh
      zsh
      zsh-completions
      oh-my-zsh
      nix-zsh-completions
      zsh-syntax-highlighting
      zsh-autosuggestions
      # TODO powerlevel9k doesn't work - install using instructions from https://github.com/bhilburn/powerlevel9k/wiki/Install-Instructions#option-2-install-for-oh-my-zsh
      zsh-powerlevel9k

      # nix utils
      nix-prefetch-scripts
      nixops
      nixpkgs-lint

      # shell utils
      exa
      fd
      fzf
      git
      jq
      pandoc
      silver-searcher # ag
      ripgrep
      # TODO error
      # tokei
      vim
      curl
      tree
      htop
      rsync

      # emacs and it's layers' dependencies
      emacsMacport
      # spell-checking
      aspell
      aspellDicts.cs
      aspellDicts.en
      aspellDicts.en-computers
      aspellDicts.en-science
      aspellDicts.fr

      # TODO clone gtd layer
      # cd ~/.emacs.d/private
      # git clone https://github.com/et2010/org-gtd.git gtd

      # Elm
      elmPackages.elm
      elmPackages.elm-format
      elm2nix
      nodePackages.elm-live
      nodePackages.elm-oracle

      # Haskell
      ghc
      cabal2nix
      cabal-install

      # Rust
      rustup

      # Scala
      sbt
      scala

      # Node
      nodejs-10_x
      nodePackages.node2nix

      # JS
      # nodePackages.brunch
      nodePackages.prettier
      nodePackages.uglify-js

      # fonts
      powerline-fonts # used in zsh
    ] ++

    [ # my nix utils
      nix-haskell
      nix-npm-install
    ]);

  # powerlevel9k - https://github.com/bhilburn/powerlevel9k
  programs.zsh.promptInit = "source ${pkgs.zsh-powerlevel9k}/share/zsh-powerlevel9k/powerlevel9k.zsh-theme";

  # zsh-autosuggestions - https://github.com/NixOS/nixpkgs/blob/92a047a6c4d46a222e9c323ea85882d0a7a13af8/pkgs/shells/zsh/zsh-autosuggestions/default.nix#L3
  # TODO > error: The option `programs.zsh.enableAutoSuggestions' defined in `/Users/tzemanovic/.nixpkgs/darwin-configuration.nix' does not exist.
  # programs.zsh.enableAutoSuggestions = true;

  # Use a custom configuration.nix location.
  # $ darwin-rebuild switch -I darwin-config=$HOME/.config/nixpkgs/darwin/configuration.nix
  # environment.darwinConfig = "$HOME/.config/nixpkgs/darwin/configuration.nix";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.bash.enable = true;
  programs.zsh.enable = true;
  # programs.fish.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 3;

  # You should generally set this to the total number of logical cores in your system.
  # $ sysctl -n hw.ncpu
  nix.maxJobs = 8;
  nix.buildCores = 8;

  # obelisk caches
  nix.binaryCaches = [ "https://cache.nixos.org/" "https://nixcache.reflex-frp.org" ];
  nix.binaryCachePublicKeys = [ "ryantrinkle.com-1:JJiAKaRv9mWgpVAz8dwewnZe0AzzEAzPkagE9SP5NWI=" ];
}
