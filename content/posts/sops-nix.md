---
title: "sops-nix: simple secrets management for Nix"
date: 2023-02-13T22:57:50+01:00
draft: false
toc: false
images:
tags:
    - dotfiles
    - nix
---

## Secrets in git

There are many ways to manage secrets in git repositories. Some examples in no particular order:

-   [git-crypt](https://github.com/AGWA/git-crypt)
-   [sops](https://github.com/mozilla/sops)
-   a separate private repo added as a submodule to the main one

Each with its advantages and disadvantages, but all get the job done.

When I transitioned my [dotfiles](https://github.com/konradmalik/dotfiles) to Nix flakes, I looked for a way to not only manage secrets in git
but for something that would also allow me to treat secrets as a part of my Nix config, including the declarative part. But let's start from the beginning.

## Secrets in NixOS

Initially, I had three specific secrets I wanted to somehow integrate into my Nix setup:

-   `wpa_supplicant` config (with my WiFi passwords)
-   my Linux login password (for fully declarative setup via NixOS)
-   company's ssh config (contains IP addresses so it's better to not make them public)

So I explored options.

### Private flake

I decided I'd create a private GitHub repo with a private flake which I added as input to my main flake.
If the private flake was not available because I was on an untrusted machine, or because it was a CI/CD pipeline,
or because someone just used my public code, then the input could just be replaced with a dummy, empty package which I happened to host in a subfolder.

This worked somehow but was not great as you can probably imagine. Seemed hacky (and it was).

### Private repo + GNU Stow

I was not happy with my private flake configuration, so I decided to not use private flake inputs, and just handle all the public-safe stuff in Nix,
while using my private repository as a source for [GNU Stow](https://www.gnu.org/software/stow/manual/stow.html).

This worked much better, but I still needed to manually link the appropriate files, remember to pull the repository locally on each
machine after an important change, etc. It still was not great and seamless, and I wanted great and seamless.

### The Nix way

I thought that there must be some "nixy" way to solve this problem and indeed, I've found a couple of projects but I settled
on [sops-nix](https://github.com/Mic92/sops-nix) (another good choice would be [agenix](https://github.com/ryantm/agenix)).

I've been using `sops-nix` for some time already to manage my secrets on my NixOS machines
and I love it. It's simple, allows to use [age](https://github.com/FiloSottile/age) as an encryption tool (a modern GnuPG
alternative, although targeting specific use-cases like file encryption), allows reusing your ssh keys or host ssh keys
as encryption keys, and uses `sops` under the hood which I like a lot. I use `sops` at work in our GitOps flow to keep
Kubernetes secrets directly in the git repository and automatically synchronize them to the cluster via [fluxCD](https://github.com/fluxcd/flux2).

Firstly, I only used `sops-nix` for my NixOS stuff (it wasn't possible to use it on [home-manager](https://github.com/nix-community/home-manager)-only machine
or on [nix-darwin](https://github.com/LnL7/nix-darwin). That meant I used it only for `wpa_supplicant` and my Linux login password. My company ssh config was
still lined via `stow` from my dotfiles-private repository. However, thanks to a recent [PR](https://github.com/Mic92/sops-nix/pull/268),
`sops-nix` now includes a `home-manager` module, so it can be used on practically any machine with Nix installed.
For me, it effectively means that now I can have all configurations and secrets in a single repository,
regardless of whether it's system-wide stuff on NixOS, user-specific stuff on NixOS, or user-specific stuff on MacOS.

With a working `home-manager` module, I could finally move the last bit (ssh config) into my main, public repository, encrypt it with `sops`, and automatically decrypt
and link with `sops-nix`.

An example from my [dotfiles](https://github.com/konradmalik/dotfiles):

The secret itself. I placed it in my `common` subfolder of `home-manager` nix configs:

```yaml
# dotfiles/nix/home/konrad/common/secrets.yaml
ssh_configd:
    cerebre: ENC[AES256_GCM,data:u+cagDh97y8wdVAEk5R0vofy3WVRDbMojQqFjmMHPYehqPlq1ql6PITf+9RdGhl+PwpYZ5OhSdzTIHzfK+iTF7tFEOLsGgJDU/GLAkbdPiJVjAdZqbrM/ApHn1ppqNvZ7wfDjc8PJ8gQCy+svCAHKLQU0TclzgjTYg3zD805aMFdJZAtDQYkY+H8cAoycK8uOUo+kPaacPhqJGc8R/X5ITEDRpSUyG3kD/2jFjyl1/PUc0BB0KfHLADndHia9WLZND9k4hh4Q4X1nr/XFXPtWvNlhAf/6LwCPjakxcNNCnzp+UQ4yso+H66y5IZjdiKo7pzIyLutU3WuscFg3SDT4DDP6KHtF6Wvx7w9AAue6+/iPJDmEVwO8r9+PrYLN1rFy2qXAqN7seI1nMPL14AHrE4Zf0v09xdpaRubfZmEsiPMYGcvPjIIUkq9/2KfCvbubZG1Hk6vu7Sqsn3JSPGoVcBRTj0=,iv:qoLDRsx/Xy437mNk7nPnez0f7toe0nJCcYnI2khnM1M=,tag:JZeWO7nt0avc6RlfzvNl4A==,type:str]
sops:
```

Next, in my global, shared `home-manager` config, I set up the `sops-nix` module:

```nix
# dotfiles/nix/home/konrad/common/global/default.nix
{ config, pkgs, lib, inputs, outputs, ... }:
let
  inherit (inputs.nix-colors) colorSchemes;
  inherit (inputs.nix-colors.lib-contrib { inherit pkgs; }) nixWallpaperFromScheme;
in
{
  imports = [
    inputs.nix-colors.homeManagerModule
    inputs.sops-nix.homeManagerModules.sops
.
.
.
  # shared sops config
  sops = {
    defaultSopsFile = ./../secrets.yaml;
    age.keyFile = "${config.xdg.configHome}/sops/age/personal.txt";
  };
.
.
.
```

Then in my `ssh-egress` module I defined the secret while also providing the path, where the `sops-nix` should link it.

```nix
# dotfiles/nix/home/konrad/common/modules/ssh-egress.nix
{ config, pkgs, lib, osConfig, ... }:
with lib;
let cfg = config.konrad.programs.ssh-egress;
in {
  options.konrad.programs.ssh-egress = {
    enable = mkEnableOption "Enables ssh-egress configuration through home-manager";
    enableSecret = mkOption {
      type = types.bool;
      default = true;
      description = "whether to enable secret ssh config.d (requires sops-nix and age key)";
    };
  };

  config = mkIf cfg.enable (mkMerge [
.
.
.
    (mkIf cfg.enableSecret {
      sops.secrets."ssh_configd/cerebre" = {
        path = "${config.home.homeDirectory}/.ssh/config.d/cerebre";
      };
    })
  ]);
}
```

And that's it! It works, because my main ssh config says to `include config.d/*` by default.

## Conclusion

I'm happy with this setup for now. Feel free to explore my [repository](https://github.com/konradmalik/dotfiles) for the bigger
picture, and for the comments in README.

The specific commit that introduced the changes is described here:
[99ca739](https://github.com/konradmalik/dotfiles/commit/99ca739a65f9cc96da26b63d18307e2760d1b75a).
