---
title: "sops-nix: simple secrets management for Nix"
date: 2023-02-12T20:03:50+01:00
draft: true
toc: false
images:
tags:
  - nix
---

Secrets:

- wpa_supplicant config (with my WiFi passwords)
- my linux login password (for fully declarative setup via NixOS)
- company's ssh config (contains IP addresses so it's better to not make them public)

I used to use a private GitHub repo, which I added to my flake inputs. If repo was not available because I was on an untrusted
machine or because it was a CI/CD pipeline, then I just replaced that input with a dummy, empty package.

This worked somehow, but was definitely not great as you can probably imagine. Seemed hacky (and it was).

I then decided to not use private flake inputs, and just handle all the public-safe stuff in Nix, while using my private repo
as a source for [GNU Stow](https://www.gnu.org/software/stow/manual/stow.html).

This worked much better, but I still needed to manually link the appropriate files, remember to pull the repo locally on each
machine after an important change etc. It still wasn't great.

I thought that there must be some "nixy" way to solve this problem and indeed, I've found a couple of projects but I settled
on [sops-nix](https://github.com/Mic92/sops-nix) (another good choice would be [agenix](https://github.com/ryantm/agenix) I think).

I've been using sops-nix for some time already to manage my secrets on my NixOS machines
and I've loved it. It's simple, allows to use [age](https://github.com/FiloSottile/age) as a encryption tool (a modern GnuPG
alternative, although targeting specific use-cases like file encryption), allow reusing your ssh keys or host ssh keys
as encryption keys, and uses sops under the hood which I like a lot. I use sops at work in our GitOps flow to keep
kubernetes secrets directly in the git repository and automatically synchronize them to the cluster via [fluxCD](https://github.com/fluxcd/flux2).

Thanks to a recent [Pull Request](https://github.com/Mic92/sops-nix/pull/268) on sops-nix.
one can now use sops-nix on any machine that is either a NixOS or has Nix [home-manager](https://github.com/nix-community/home-manager)
installed. The mentioned PR introduced a new home-manager module to sops-nix.
For me it effectively means that now I can have all configurations and secrets in a single repository,
regardless if it's system-wide stuff on NixOS, user-specific stuff on NixOS, or user-specific stuff on MacOS.

As a first use-case for home-manager, I converted my company's ssh config file to sops format and added it to my secrets ...

```nix
sops = {
  some = config;
  here = "and there";
};
```
