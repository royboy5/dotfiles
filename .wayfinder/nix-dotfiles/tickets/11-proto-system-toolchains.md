---
title: Can proto/moon use toolchains already on PATH
type: research
status: closed
assignee: Roy Eng
blocked_by: []
---

## Question

Split from [Language toolchains and dev shells](08-toolchains-devshells.md). Can proto (and moon, which drives proto) use a toolchain that is already on PATH (e.g. Node, Go, Python, Rust installed by Nix) instead of downloading its own, including when a repo pins versions in `.prototools` / moon's `toolchain.yml`? Cover: proto's "system" / `*` version handling and `auto-install` settings, moon v2's toolchain config (can a toolchain be disabled or marked as system-provided), and what happens when the pinned version doesn't match the one on PATH. The answer decides whether proto downloads unpatched binaries on NixOS, and therefore whether `wing-zero` needs nix-ld.

## Resolution

Findings: `.wayfinder/nix-dotfiles/research/proto-system-toolchains.md` on branch `research/proto-system-toolchains`. The branch is local only because the push failed with no HTTPS credentials (`git push -u origin research/proto-system-toolchains`).

- **proto has no "system" version.** Its shims fall through to the PATH binary only when no version is pinned anywhere: not as an arg, in `PROTO_<TOOL>_VERSION`, in `.prototools`, in ecosystem files or in the global config. A pin that isn't installed errors (`auto-install=false`) or downloads (`true`), and never falls back to PATH.
- **moon v2 can use PATH tools and skip proto entirely.** Leave out a toolchain's `version` (it becomes "global") and set `versionFromPrototools: false`, or set `MOON_TOOLCHAIN_FORCE_GLOBALS=true`, which also skips installing proto. There is no version check, so repo pins are silently ignored.
- **On NixOS:** proto's Node and Python downloads, and the proto binary itself, are glibc-dynamic and would need nix-ld. Go's tarball is static. proto doesn't download Rust; it calls rustup. The NixOS part is untested general knowledge.
- **Implication:** if Nix provides the toolchains and moon runs on force-globals, nix-ld isn't needed. It's needed only if proto actually downloads toolchains on `wing-zero`.
