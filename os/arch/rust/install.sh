#!/usr/bin/env bash
set -e

# Source helpers
source "${ROOT_DIR}/lib/helpers.sh"

# --- Configuration Variables ---
# Packages required for building code and running the rustup installer
CORE_TOOLS=(
    "curl"          # For downloading rustup installer
    "gcc"           # Required for building some Rust dependencies (Arch's base-devel might cover this, but explicit is safer)
    "base-devel"    # Provides make, gcc, pkg-config, etc., essential for Rust/Cargo
)

# The default path where the rustup installer places the binaries
RUST_BIN_PATH="$HOME/.cargo/bin"

LOG_INFO "Setting up Rust toolchain using 'rustup' for Arch Linux..."

# 1. INSTALL CORE DEPENDENCIES
LOG_INFO "Ensuring build tools are installed via Pacman..."
run sudo pacman -S --needed --noconfirm "${CORE_TOOLS[@]}"

# 2. INSTALL RUSTUP ITSELF
LOG_INFO "Installing rustup via official script..."

if [[ ! -f "$RUST_BIN_PATH/rustup" ]]; then
    if [[ "${DRY_RUN}" == true ]]; then
        LOG_INFO "[dry-run] curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y"
    else
        # The '-y' argument tells rustup to proceed with default installation options (stable toolchain)
        # without prompting the user.
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    fi
    LOG_SUCCESS "Rustup and the stable toolchain installed successfully."
else
    LOG_SUCCESS "Rustup is already installed."
fi

# 3. ADD RUST BINARY PATH TO CURRENT SESSION
# This is CRITICAL for the next commands to work, and for other packages
# that might need cargo/rustc in the same bootstrap run.
export PATH="$RUST_BIN_PATH:$PATH"
LOG_INFO "Added $RUST_BIN_PATH to PATH for this script execution."

# 4. (Optional) INSTALL COMMON RUST TOOLS
# You can uncomment this section to install common binaries like 'cargo-watch'
# LOG_INFO "Installing common Rust cargo tools..."
# RUST_TOOLS=(
#     "cargo-watch"
#     "cargo-edit"
# )
# for tool in "${RUST_TOOLS[@]}"; do
#     LOG_INFO "  -> Installing $tool..."
#     # Using run cargo install ensures the command is executed safely
#     run cargo install "$tool"
# done

# 5. Final Verification and Reminder
LOG_INFO "Verification and reminders:"
LOG_INFO "  Rust toolchain is installed in $RUST_BIN_PATH."
LOG_INFO "  Default toolchain is 'stable'."
LOG_WARN "  Ensure $RUST_BIN_PATH is permanently added to your shell's PATH."

LOG_SUCCESS "Rust setup complete! 🦀"