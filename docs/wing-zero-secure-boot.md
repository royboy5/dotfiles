[Home](/README.md) > wing-zero Secure Boot

# EndeavourOS Secure Boot Guide for Surface Pro 3

*Restoring Microsoft Factory Keys and Fixing the Red Screen with Shim + systemd-boot*

## Overview & Key Generation Mechanics

On the **Microsoft Surface Pro 3**, the UEFI firmware enforces a visual hardware check:

* **Red Screen at Boot:** Displayed when **Secure Boot is disabled** OR when a **Custom Platform Key (PK)** is enrolled into the UEFI firmware via `sbctl enroll-keys`.
* **Black Screen at Boot:** Displayed ONLY when **Microsoft Factory Keys (Windows & 3rd-Party UEFI CA)** remain in the firmware and TPM is enabled.

To achieve Secure Boot **with the black boot screen**:

1. You **do** generate local keys on disk (`sbctl create-keys`) to sign `grubx64.efi` and Linux kernels.
2. You **do not** put UEFI into Setup Mode or run `sbctl enroll-keys` (which would overwrite the factory Platform Key and cause the red screen).
3. You chain-load `systemd-boot` through Fedora's Microsoft-signed `shim` and enroll your local `sbctl` certificate into **MokManager**.

---

## Certificate Enrollment vs. Hash Enrollment

Understanding the distinction in MokManager is critical for system updates:

* **Hash Enrollment (`grubx64.efi` hash):** Only authorizes the exact binary existing at that moment. Whenever a `systemd` update occurs, the hash changes, triggering a `Security Violation` on reboot until you manually enroll the new hash.
* **Certificate Enrollment (`MOK.cer`):** Authorizes your private signing key. As long as future `systemd-boot` updates are signed with your `sbctl` key via the Pacman hook, `shim` trusts them automatically—enabling hands-free updates.

---

## Step-by-Step Configuration Guide

### Step 1: Install Required Tools and Extract Fedora Shim

1. Install `sbctl` and `mokutil` from the official EndeavourOS repositories:

   ```bash
   sudo pacman -S --needed sbctl mokutil
   ```

2. Download and extract the Microsoft-signed Fedora `shim` binary:

   ```bash
   mkdir -p /tmp/shim && cd /tmp/shim
   curl -fLO https://kojipkgs.fedoraproject.org/packages/shim/16.1/10/x86_64/shim-x64-16.1-10.x86_64.rpm
   bsdtar -xf shim-x64-16.1-10.x86_64.rpm
   sudo mkdir -p /usr/local/share/shim
   sudo cp usr/lib/efi/shim/16.1-10/EFI/fedora/shimx64.efi usr/lib/efi/shim/16.1-10/EFI/fedora/mmx64.efi /usr/local/share/shim/
   ```

3. Verify both files exist in `/usr/local/share/shim/`:

   ```bash
   ls -l /usr/local/share/shim/
   ```

   *(Expected output: `mmx64.efi` and `shimx64.efi`)*

### Step 2: Generate `sbctl` Keys and Export MOK Certificate

1. Generate your local signing keys on disk (skip `sbctl enroll-keys`):

   ```bash
   sudo sbctl create-keys
   ```

2. Convert your public database certificate (`db.pem`) into DER format and save it onto the EFI System Partition (`/efi`):

   ```bash
   # Standard sbctl path:
   sudo openssl x509 -in /var/lib/sbctl/keys/db/db.pem -outform DER -out /efi/MOK.cer

   # Legacy sbctl path (if using older secureboot folder):
   # sudo openssl x509 -in /usr/share/secureboot/keys/db/db.pem -outform DER -out /efi/MOK.cer
   ```

3. Queue the certificate with `mokutil`:

   ```bash
   sudo mokutil --import /efi/MOK.cer
   ```

   *Enter a temporary password (8–16 characters) when prompted.*
   
   *(Note: If `mokutil` outputs `skip: /efi/MOK.cer is already in db`, it means your key is already active in MokManager. You can verify enrollment in Step 5).*

### Step 3: Configure `shim` to Chain-Load `systemd-boot`

`shimx64.efi` acts as the primary bootloader and automatically executes a binary named `grubx64.efi` in its directory. You will copy `systemd-bootx64.efi` as `grubx64.efi` and sign it with `sbctl`.

1. Remove fallback `BOOTX64.EFI` from `sbctl` tracking so it doesn't attempt to sign or overwrite `shim`:

   ```bash
   sudo sbctl remove-file /efi/EFI/BOOT/BOOTX64.EFI 2>/dev/null || true
   ```

2. Copy `shim` and MokManager (`mmx64.efi`) into both systemd and fallback boot locations:

   ```bash
   sudo cp /usr/local/share/shim/shimx64.efi /efi/EFI/systemd/shimx64.efi
   sudo cp /usr/local/share/shim/mmx64.efi /efi/EFI/systemd/mmx64.efi
   sudo cp /usr/local/share/shim/shimx64.efi /efi/EFI/BOOT/BOOTX64.EFI
   sudo cp /usr/local/share/shim/mmx64.efi /efi/EFI/BOOT/mmx64.efi
   ```

3. Copy `systemd-bootx64.efi` to `grubx64.efi` and sign all boot binaries:

   ```bash
   sudo cp /efi/EFI/systemd/systemd-bootx64.efi /efi/EFI/systemd/grubx64.efi
   sudo cp /efi/EFI/systemd/systemd-bootx64.efi /efi/EFI/BOOT/grubx64.efi
   sudo sbctl sign -s /efi/EFI/systemd/systemd-bootx64.efi
   sudo sbctl sign -s /efi/EFI/systemd/grubx64.efi
   sudo sbctl sign -s /efi/EFI/BOOT/grubx64.efi
   ```

4. Sign all kernel images across `/efi`:

   ```bash
   sudo reinstall-kernels
   ```

5. Create a UEFI boot menu entry pointing to `shim` (check drive partition with `findmnt /efi`, typically `/dev/sda1`):

   ```bash
   sudo efibootmgr --create --disk /dev/sda --part 1 --label "EndeavourOS (Shim)" --loader '\EFI\systemd\shimx64.efi'
   ```

### Step 4: Restore Microsoft Factory Keys in Surface UEFI

1. Reboot into the Surface Pro 3 UEFI:

   ```bash
   systemctl reboot --firmware-setup
   ```

2. Confirm **Trusted Platform Module (TPM)** is set to **Enabled**.
3. Reset Secure Boot keys:
   * Select **Delete All Secure Boot Keys** -> Select **Yes**.
   * The menu option will change to **Install All Factory Default Keys**.
   * Select **Install All Factory Default Keys** -> Choose **Windows & 3rd-party UEFI CA (Default)**.
4. Confirm **Secure Boot Control** is set to **Enabled**.
5. Select **Exit Setup** -> Choose **Yes** to save and reboot.

### Step 5: Enroll MOK Key in MokManager

Upon rebooting, the Surface Pro 3 will display the **Black Screen**. If `MOK.cer` was queued in Step 2:

1. A blue box stating `Verification failed: (0x1A) Security Violation` or the MokManager countdown will appear. Press **Enter** on **OK** / press any key.
2. Select **Enroll MOK** (or **Enroll key from disk** -> browse to `/efi/MOK.cer`).
3. Select **Continue** -> **Yes**.
4. Enter the temporary password set in Step 2 (if prompted).
5. Select **Reboot**.

---

### Step 6: Automate Updates via Pacman Hook

Create a hook so future `systemd` package upgrades automatically copy the updated `systemd-boot` to `grubx64.efi` and re-sign all files:

```bash
sudo mkdir -p /etc/pacman.d/hooks
sudo tee /etc/pacman.d/hooks/99-shim-systemd-boot.hook > /dev/null << 'EOF'
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Updating and signing systemd-boot for shim...
When = PostTransaction
Exec = /bin/sh -c 'cp /usr/lib/systemd/boot/efi/systemd-bootx64.efi /efi/EFI/systemd/grubx64.efi && cp /usr/lib/systemd/boot/efi/systemd-bootx64.efi /efi/EFI/BOOT/grubx64.efi && cp /usr/local/share/shim/shimx64.efi /efi/EFI/BOOT/BOOTX64.EFI && /usr/bin/sbctl sign-all'
EOF
```

---

## Verification & Maintenance Checklist

To verify that your configuration is robust and update-proof:

1. **Verify Signed Files:**
   ```bash
   sudo sbctl verify
   ```
   Ensure `/efi/EFI/systemd/grubx64.efi`, `/efi/EFI/BOOT/grubx64.efi`, and your kernel binaries show green checkmarks (`✓`).

2. **Verify Certificate Enrollment:**
   ```bash
   sudo mokutil --import /efi/MOK.cer
   ```
   If it outputs `skip: /efi/MOK.cer is already in db`, your certificate is successfully enrolled and updates will not break boot.

3. **Verify Pacman Hook:**
   ```bash
   cat /etc/pacman.d/hooks/99-shim-systemd-boot.hook
   ```
   Confirm the hook exists to automate copying and re-signing upon system update.
