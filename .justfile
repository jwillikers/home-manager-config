default: build

alias b := build

build:
    home-manager --flake . build

alias c := check

check: && format
    yamllint .
    asciidoctor **/*.adoc
    lychee --cache **/*.html

alias f := format
alias fmt := format

format:
    treefmt

alias s := switch

switch:
    home-manager --flake . switch

alias u := update
alias up := update

update:
    nix flake update
    nix run '.#update-packages'
