#!/bin/bash

[ ! "$#" -eq 0 ] || exit 2

SOCKET="$(lsof -U | awk '/tmux/ && $9 != "type=STREAM" { print $9; exit }')"

RUNIN_VIM="ps -o state= -o comm= -t '#{pane_tty}' | \
grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?(view|l?n?vim?x?|fzf)(diff)?$'"

VIMKEY=$1
TMUXDIR=$2
TMUXKEY=$3

tmux -S $SOCKET \
if-shell "$RUNIN_VIM" \
    "send-keys M-$VIMKEY" \
    "if -F '#{pane_at_$TMUXDIR}' '' 'select-pane -$TMUXKEY'"
