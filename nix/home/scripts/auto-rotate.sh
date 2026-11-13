# auto-rotate: turn the built-in screen to follow the accelerometer, as
# reported by iio-sensor-proxy's monitor-sensor (system layer, pacman).
# Packaged by nix/home/auto-rotate.nix (writeShellApplication adds the shebang
# and `set -euo pipefail`; shellcheck runs at build time). Started by Hyprland
# (configs/hypr/hyprland.lua) and by COSMIC (an autostart entry).
#
# COSMIC turns touch and pen input with the screen by itself; Hyprland has to
# be told. hyprctl and cosmic-randr come with the desktops, not from Nix.

output="${AUTO_ROTATE_OUTPUT:-eDP-1}"
# cosmic-randr sets a transform as part of a mode, so it needs the panel's
# native mode too (the Surface Pro 3's is 2160x1440).
mode="${AUTO_ROTATE_MODE:-2160x1440}"

if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    desktop=hyprland
elif [[ "${XDG_CURRENT_DESKTOP:-}" == *COSMIC* ]]; then
    desktop=cosmic
else
    echo "auto-rotate: only works in Hyprland or COSMIC (XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-unset})" >&2
    exit 1
fi

# Counter-clockwise quarter turns for each orientation (wl_output's transform
# numbering, which both Hyprland and cosmic-randr use).
quarter_turns() {
    case "$1" in
        normal) echo 0 ;;
        left-up) echo 1 ;;
        bottom-up) echo 2 ;;
        right-up) echo 3 ;;
        *) return 1 ;;
    esac
}

rotate() {
    local turns="$1"
    if [[ "$desktop" == hyprland ]]; then
        # mode/position/scale match the monitor rule in hyprland.lua.
        hyprctl eval "hl.monitor({ output = \"$output\", mode = \"preferred\", position = \"auto\", scale = \"auto\", transform = $turns }) hl.config({ input = { touchdevice = { transform = $turns }, tablet = { transform = $turns } } })"
    else
        local names=(normal rotate90 rotate180 rotate270)
        cosmic-randr mode "$output" "${mode%x*}" "${mode#*x}" --transform "${names[$turns]}"
    fi
}

last=""
while IFS= read -r line; do
    case "$line" in
        *"orientation changed: "*)
            orientation="${line##*: }"
            ;;
        "=== Has accelerometer (orientation: "*)
            orientation="${line#*orientation: }"
            orientation="${orientation%%,*}"
            ;;
        *) continue ;;
    esac
    turns=$(quarter_turns "$orientation") || continue
    [[ "$turns" == "$last" ]] && continue
    if ! rotate "$turns"; then
        echo "auto-rotate: rotating to $orientation failed" >&2
    fi
    last="$turns"
done < <(monitor-sensor --accel)
