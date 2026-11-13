#!/usr/bin/env bats
# Unit tests for nix/home/scripts/auto-rotate.sh. monitor-sensor is a stub that
# prints canned accelerometer output; hyprctl and cosmic-randr record their
# arguments in $CALLS.
#
# Run: nix shell nixpkgs#bats -c bats tests/

setup() {
    ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
    SCRIPT="$ROOT/nix/home/scripts/auto-rotate.sh"
    TMP="$(mktemp -d)"
    STUBS="$TMP/stubs"
    CALLS="$TMP/calls"
    mkdir -p "$STUBS"
    : > "$CALLS"
    export CALLS
    for cmd in hyprctl cosmic-randr; do
        printf '#!/usr/bin/env bash\necho "%s $*" >> "$CALLS"\n' "$cmd" > "$STUBS/$cmd"
        chmod +x "$STUBS/$cmd"
    done
    export PATH="$STUBS:$PATH"
    unset HYPRLAND_INSTANCE_SIGNATURE XDG_CURRENT_DESKTOP AUTO_ROTATE_OUTPUT AUTO_ROTATE_MODE
}

teardown() {
    rm -rf "$TMP"
}

# sensor <line>...: monitor-sensor prints these lines, then exits.
sensor() {
    {
        echo '#!/usr/bin/env bash'
        echo 'echo "monitor-sensor $*" >> "$CALLS"'
        for line in "$@"; do printf 'echo %q\n' "$line"; done
    } > "$STUBS/monitor-sensor"
    chmod +x "$STUBS/monitor-sensor"
}

run_script() {
    run bash -c 'set -euo pipefail; source "$1"' _ "$SCRIPT"
}

@test "in Hyprland, rotates the screen, touch and pen to the starting and new orientations" {
    export HYPRLAND_INSTANCE_SIGNATURE=abc
    sensor "    Waiting for iio-sensor-proxy to appear" \
        "=== Has accelerometer (orientation: normal, tilt: vertical)" \
        "    Accelerometer orientation changed: left-up"
    run_script
    [ "$status" -eq 0 ]
    grep -q "^monitor-sensor --accel" "$CALLS"
    [ "$(grep -c '^hyprctl eval' "$CALLS")" -eq 2 ]
    grep '^hyprctl eval' "$CALLS" | head -1 | grep -q 'output = "eDP-1".*transform = 0 })'
    grep '^hyprctl eval' "$CALLS" | tail -1 | grep -q 'transform = 1 })'
    grep '^hyprctl eval' "$CALLS" | tail -1 | grep -q 'touchdevice = { transform = 1 }, tablet = { transform = 1 }'
}

@test "in COSMIC, sets the panel's mode with the matching transform" {
    export XDG_CURRENT_DESKTOP=COSMIC
    sensor "    Accelerometer orientation changed: left-up" \
        "    Accelerometer orientation changed: bottom-up" \
        "    Accelerometer orientation changed: right-up" \
        "    Accelerometer orientation changed: normal"
    run_script
    [ "$status" -eq 0 ]
    diff <(grep '^cosmic-randr' "$CALLS") - <<'EOF'
cosmic-randr mode eDP-1 2160 1440 --transform rotate90
cosmic-randr mode eDP-1 2160 1440 --transform rotate180
cosmic-randr mode eDP-1 2160 1440 --transform rotate270
cosmic-randr mode eDP-1 2160 1440 --transform normal
EOF
}

@test "skips repeated and unknown orientations" {
    export XDG_CURRENT_DESKTOP=COSMIC
    sensor "=== Has accelerometer (orientation: undefined, tilt: vertical)" \
        "    Accelerometer orientation changed: left-up" \
        "    Accelerometer orientation changed: left-up" \
        "=== Has ambient light sensor (value: 5, unit: lux)"
    run_script
    [ "$status" -eq 0 ]
    [ "$(grep -c '^cosmic-randr' "$CALLS")" -eq 1 ]
}

@test "the output and mode can be overridden" {
    export XDG_CURRENT_DESKTOP=COSMIC AUTO_ROTATE_OUTPUT=eDP-2 AUTO_ROTATE_MODE=1920x1080
    sensor "    Accelerometer orientation changed: right-up"
    run_script
    grep -qx "cosmic-randr mode eDP-2 1920 1080 --transform rotate270" "$CALLS"
}

@test "keeps going when a rotation fails" {
    export XDG_CURRENT_DESKTOP=COSMIC
    printf '#!/usr/bin/env bash\necho "cosmic-randr $*" >> "$CALLS"\nexit 1\n' > "$STUBS/cosmic-randr"
    sensor "    Accelerometer orientation changed: left-up" \
        "    Accelerometer orientation changed: normal"
    run_script
    [ "$status" -eq 0 ]
    [ "$(grep -c '^cosmic-randr' "$CALLS")" -eq 2 ]
}

@test "refuses to run outside Hyprland and COSMIC" {
    export XDG_CURRENT_DESKTOP=KDE
    sensor "    Accelerometer orientation changed: left-up"
    run_script
    [ "$status" -ne 0 ]
    [[ "$output" == *"Hyprland"*"COSMIC"* ]]
    [ ! -s "$CALLS" ]
}
