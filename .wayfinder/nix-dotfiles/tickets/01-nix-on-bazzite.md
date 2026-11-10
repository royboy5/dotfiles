---
title: Nix on Bazzite
type: research
status: closed
assignee: research-agent
blocked_by: []
---

## Question

Can Nix plus standalone home-manager be installed on Bazzite (Fedora Atomic / rpm-ostree, read-only `/`) and survive image updates and rebases? Which installer works (Determinate Systems vs official multi-user vs others), what has to be done about `/nix`, SELinux and the composefs root, and what are the known failure modes? Prefer primary sources: Bazzite/Universal Blue docs, the installer docs, and the relevant issues.

## Resolution

Findings: `research/nix-on-bazzite.md` on local branch `research/nix-on-bazzite` (commit `1ebb31b`, not pushed).

- **Works, but needs a one-time host change, and Bazzite/Universal Blue don't support it.** Since Fedora 42 the composefs root is fully read-only, so every installer fails to create `/nix` (DetSys #1445, #1682; NixOS/nix-installer #248 still open). Layering Fedora's `nix` RPM is rejected (rpm-ostree #5554).
- **Fix:** provide an empty `/nix` mount point, then the installer's ostree mode bind-mounts a store from `/var`. That store survives updates.
  - **Option A (recommended):** `root.transient = true` in `/etc/ostree/prepare-root.conf`, then `rpm-ostree initramfs-etc --track`, reboot, then `nix-installer install ostree --persistence=/var/lib/nix`.
  - **Option B:** a custom derived image that adds `/nix`. Rebasing back to a stock image loses it.
- **Installer:** the NixOS community installer (upstream Nix). Determinate now defaults to Determinate Nix.
- **SELinux:** caused the 2024 ujust removals. The installer now ships its own policy, and no recent failures blame SELinux.
- **Recommendation for the bootstrap:** treat Bazzite as an explicit Nix-enablement host (detect ostree, apply Option A, reboot, install). Keep Homebrew as the fallback.
- **Unverified:** whether `initramfs-etc` tracking carries over across rebases; whether Bazzite updates through `bootc` (the heavier initramfs variant breaks it).
