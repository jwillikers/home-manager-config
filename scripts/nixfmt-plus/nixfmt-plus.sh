#!/usr/bin/env bash

if [ $# -eq 0 ]; then
  deadnix --edit
  statix fix
  nixfmt --verify .
else
  deadnix --edit "$1"
  statix fix "$1"
  nixfmt --verify "$1"
fi
