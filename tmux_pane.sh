#!/bin/bash

SOCKET="$(lsof -U | awk '/tmux/ && $9 != "type=STREAM" { print $9; exit }')"

tmux -S $SOCKET display-message -p "#{pane_id}" | cut -d '%' -f 2
