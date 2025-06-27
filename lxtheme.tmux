#!/usr/bin/env bash
PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

get_tmux_option() {
    local option value default
    option="$1"
    default="$2"
    value="$(tmux show-option -gqv "$option")"

    if [ -n "$value" ]; then
        echo "$value"
    else
        echo "$default"
    fi
}

set() {
    local option=$1
    local value=$2
    tmux_commands+=(set-option -gq "$option" "$value" ";")
}

setw() {
    local option=$1
    local value=$2
    tmux_commands+=(set-window-option -gq "$option" "$value" ";")
}

pill() {
    local fg=$1
    local bg=$2
    local txt=$3
    if [ -n "$4" ]; then
        echo "#[fg=$bg bg=$thmBg]$right_separator#[fg=$fg bg=$bg]$4 #[fg=$fg]$txt#[fg=$bg bg=$thmBg]$left_separator"
    else
        echo "#[fg=$bg bg=$thmBg]$right_separator#[fg=$fg bg=$bg]$txt#[fg=$bg bg=$thmBg]$left_separator"
    fi
}

main() {
    local theme="$(get_tmux_option "@lxtheme.theme" "blue")"
    local tmux_commands=()
    source /dev/stdin <<<"$(sed -e "/^[^#].*=/s/^/local /" "${PLUGIN_DIR}/lx-${theme}.tmuxtheme")"

    set status "on"
    set status-bg "${thmBg}"
    set status-justify "left"
    set status-left-length "100"
    set status-right-length "100"

    set pane-active-border-style "fg=${thmPaneBorderActive}"
    set pane-border-style "fg=${thmPaneBorderInactive}"
    setw pane-border-lines "single"
    setw pane-border-indicators "colour"

    setw window-status-activity-style "none"
    setw window-status-separator ""
    setw window-status-style "none"

    local right_separator="$(get_tmux_option "@lxtheme.rSep" "")"
    local left_separator="$(get_tmux_option "@lxtheme.lSep" "")"
    local date_fmt="$(get_tmux_option "@lxtheme.date" "off")"

    local directory_icon="$(get_tmux_option "@lxtheme.icon.dir" "")"
    local session_icon="$(get_tmux_option "@lxtheme.icon.sesh" "")"
    local host_icon="$(get_tmux_option "@lxtheme.icon.host" "󰒋")"
    thmHostFg="$(get_tmux_option "@lxtheme.theme.hostFg" "$thmHostFg")"
    thmHostBg="$(get_tmux_option "@lxtheme.theme.hostBg" "$thmHostBg")"

    local directory="$(pill "${thmDirFg}" "${thmDirBg}" "#{b:pane_current_path}" "$directory_icon")"
    local session="$(pill "${thmSeshFg}" "${thmSeshBg}" "#S" "$session_icon")"
    local window_status_current="$(pill "${thmActiveWindowFg}" "${thmActiveWindowBg}" "#I")"
    local window_status="$(pill "${thmInactiveWindowFg}" "${thmInactiveWindowBg}" "#I")"
    local host="$(pill "${thmHostFg}" "${thmHostBg}" "#H" "$host_icon")"
    local date_time="$(pill "${thmDateFg}" "${thmDateBg}" "$date_fmt")"

    local right="$session"

    if [[ "$(get_tmux_option "@lxtheme.enable.dir" "off")" == "on" ]]; then
        right="$directory$right"
    fi

    if [[ "$(get_tmux_option "@lxtheme.enable.host" "off")" == "on" ]]; then
        right="$right$host"
    fi

    if [[ "$date_fmt" != "off" ]]; then
        right="$right$date_time"
    fi

    set status-left ""

    set status-right "${right}"

    setw window-status-format "${window_status}"
    setw window-status-current-format "${window_status_current}"

    setw status-position "top"

    # --------=== Modes
    #
    setw clock-mode-colour "${thmClock}"
    setw mode-style "fg=${thmCopyModeFg} bg=${thmCopyModeBg}"
    setw copy-mode-match-style "fg=${thmCopyModeMatchFg} bg=${thmCopyModeMatchBg}"
    setw copy-mode-current-match-style "fg=${thmCopyModeCurrentMatchFg} bg=${thmCopyModeCurrentMatchBg}"

    tmux "${tmux_commands[@]}"
}

main "$@"
