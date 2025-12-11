#!/usr/bin/env bash

#############################################
# LOGGING
#############################################
LOG_INFO()    { printf "\033[0;34m[INFO]\033[0m    %s\n" "$*"; }
LOG_WARN()    { printf "\033[0;33m[WARN]\033[0m    %s\n" "$*"; }
LOG_ERROR()   { printf "\033[0;31m[ERROR]\033[0m   %s\n" "$*"; }
LOG_SUCCESS() { printf "\033[0;32m[SUCCESS]\033[0m %s\n" "$*"; }

#############################################
# run: executes safely
#############################################
run() {
    # Use "$@" to safely execute commands passed as arguments
    if [[ "${DRY_RUN}" == true ]]; then
        LOG_INFO "[dry-run] $*"
    else
        "$@"
    fi
}

#############################################
# ensure_executable
#############################################
ensure_executable() {
    local f="$1"
    if [[ ! -x "$f" ]]; then
        if [[ "${DRY_RUN}" == true ]]; then
             LOG_INFO "[dry-run] chmod +x $f"
        else
             chmod +x "$f"
        fi
    fi
}

#############################################
# link <src_rel_to_package> <target_rel_to_HOME>
#############################################
link_file() {
    local src="$1"
    local target="$2"

    if [[ ! -e "$src" ]]; then
        LOG_WARN "Source file not found: $src"
        return 1
    fi

    # Create parent dir
    local target_dir=$(dirname "$target")
    if [[ ! -d "$target_dir" ]]; then
        run mkdir -p "$target_dir"
    fi

    # Check existing
    if [[ -L "$target" ]]; then
        local current_link
        current_link=$(command readlink "$target")
        if [[ "$current_link" == "$src" ]]; then
            LOG_INFO "Already linked: $target"
            return 0
        fi
        LOG_INFO "Updating link: $target"
        run rm "$target"
    elif [[ -e "$target" ]]; then
        LOG_WARN "File exists. Backing up to $target.bak"
        run mv "$target" "$target.bak"
    fi

    run ln -sf "$src" "$target"
    LOG_SUCCESS "Linked: $src -> $target"
}

#############################################
# unlink <target_rel_to_HOME>
#############################################
unlink() {
    local target_rel="$1"
    local target="$HOME/${target_rel}"

    if [[ -L "$target" ]]; then
        LOG_INFO "Removing symlink: $target_rel"
        run rm "$target"
        LOG_SUCCESS "Unlinked: ~/${target_rel}"
    elif [[ -e "$target" ]]; then
        LOG_WARN "Existing file/dir found at target: $target_rel. Not removing."
    else
        LOG_INFO "Target does not exist: $target_rel. Skipping unlink."
    fi
}

#############################################
# detect_os
#############################################
detect_os() {
    local explicit="$1"

    if [[ -n "$explicit" ]]; then
        OS="$explicit"
        return
    fi

    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    elif [[ -f /etc/arch-release ]]; then
        OS="arch"
    elif grep -qi "fedora" /etc/os-release; then
        OS="fedora"
    elif grep -qi "ubuntu\|debian\|pop" /etc/os-release; then
        OS="debian"
    else
        LOG_ERROR "Unable to detect OS. Use --os to override."
        exit 1
    fi
}

#############################################
# get_package_manager
#############################################
get_package_manager() {
    case "$OS" in
        arch)
            echo "pacman"
            ;;
        debian)
            echo "apt"
            ;;
        macos)
            echo "brew"
            ;;
        fedora)
            echo "dnf"
            ;;
        *)
            LOG_ERROR "Unsupported OS for package management: $OS" >&2
            return 1
            ;;
    esac
}

#############################################
# package_supported_on_os
#############################################
package_supported_on_os() {
    local pkg="$1"
    local os="$2"

    if [[ -z "${SUPPORTED_OS+x}" || ${#SUPPORTED_OS[@]} -eq 0 ]]; then
        return 0
    fi

    for allowed in "${SUPPORTED_OS[@]}"; do
        [[ "$allowed" == "$os" ]] && return 0
    done

    return 1
}

#############################################
# get_os_package_name
#############################################
get_os_package_name() {
    local os_upper
    os_upper="$(echo "$OS" | tr '[:lower:]' '[:upper:]')"
    
    local var="PACKAGE_NAME_${os_upper}"
    
    local val="${!var:-}"

    echo "$val"
}

#############################################
# check_installed
#############################################
check_installed() {
    command -v "$1" >/dev/null 2>&1
}