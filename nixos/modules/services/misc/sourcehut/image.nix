{ pkgs ? import <nixpkgs> {} }:

let
  #makeDiskImage = import (pkgs.path +"/nixos/lib/make-disk-image.nix");
  makeDiskImage = import ../../../../lib/make-disk-image.nix;
  evalConfig = import ../../../../lib/eval-config.nix;
  config = (evalConfig {
    modules = [ (import ./qemu-system-configuration.nix) ];
    system = "x86_64-linux";
  }).config;
in
  makeDiskImage {
    inherit pkgs config;
    lib = pkgs.lib;
    diskSize = 16000;
    format = "qcow2-compressed";
    contents = [{
      source = pkgs.writeText "gitconfig" ''
        [user]
          name = builds.sr.ht
          email = builds@sr.ht
      '';
      target = "/home/build/.gitconfig";
      user = "build";
      group = "users";
      mode = "644";
    }];
  }

