default: build

alias i := init

init:
    # if Steam Deck
    mkdir ~/Projects
    git -C ~/Projects clone https://github.com/tailscale-dev/deck-tailscale.git
    cd ~/Projects/deck-tailscale
    sudo bash tailscale.sh
    source /etc/profile.d/tailscale.sh
    sudo tailscale up --qr --operator=deck --ssh
    # Else Fedora Atomic


alias b := build

build:
    home-manager --flake . build

alias c := check

check: && format
    yamllint .
    asciidoctor **/*.adoc
    lychee --cache **/*.html
    nix flake check

alias f := format
alias fmt := format

format:
    treefmt

alias s := switch

switch:
    home-manager --flake ".#"$(id --name --user)@$(hostname --short) switch

alias u := update
alias up := update

update:
    nix run ".#update-nix-direnv"
    nix run ".#update-nixos-release"
    nix flake update
    nix run ".#update-packages"
