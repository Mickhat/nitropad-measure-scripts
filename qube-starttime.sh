#!/bin/bash
#
# SPDX-License-Identifier: MIT
# Copyright (c) 2026 mickhat  (https://mickhat.xyz)
# Measure qube start timings from dom0.
#
# Per run it records:
#   start_s : qvm-start returns (domain up at Xen level)
#   gui_s   : the GUI process appears in the qube
#   total_s : start_s + gui_s
#
# gui_s marks when the process exists, a second or two before the window is
# fully rendered. Report it as "until the window appears", not "until usable".
#
# Runs in dom0. It starts and stops the named qube, so don't point it at a
# qube with unsaved work. Reads nothing else, installs nothing, no network.
#
# Usage:  ./qube-starttime.sh <qube> [gui-cmd] [runs] [--no-shutdown]
#   ./qube-starttime.sh personal firefox 3
#   ./qube-starttime.sh HTB xterm 5
#   ./qube-starttime.sh discord discord 3 --no-shutdown

set -u

QUBE="${1:?usage: $0 <qube> [gui-cmd] [runs] [--no-shutdown]}"
GUICMD="${2:-xterm}"
RUNS="${3:-3}"
NOSHUT=0
[ "${4:-}" = "--no-shutdown" ] && NOSHUT=1

ms() { date +%s%3N; }

printf "%-4s %10s %10s %10s\n" "run" "start_s" "gui_s" "total_s"
echo "------------------------------------------"

sum_start=0; sum_gui=0; sum_total=0
for i in $(seq 1 "$RUNS"); do
  qvm-shutdown --wait "$QUBE" >/dev/null 2>&1
  sleep 2

  t0=$(ms)
  qvm-start "$QUBE" >/dev/null 2>&1
  t1=$(ms)

  # Launch the GUI app detached, then poll until its process exists in the
  # qube. Waiting on qvm-run itself would block until the window is closed.
  qvm-run -q "$QUBE" "$GUICMD" >/dev/null 2>&1 &
  runpid=$!
  for _ in $(seq 1 300); do
    if qvm-run -q --no-gui "$QUBE" "pgrep -x $(basename "$GUICMD") >/dev/null" 2>/dev/null; then
      break
    fi
    sleep 0.2
  done
  t2=$(ms)

  d_start=$(awk "BEGIN{printf \"%.1f\", ($t1-$t0)/1000}")
  d_gui=$(awk "BEGIN{printf \"%.1f\", ($t2-$t1)/1000}")
  d_total=$(awk "BEGIN{printf \"%.1f\", ($t2-$t0)/1000}")
  printf "%-4s %10s %10s %10s\n" "$i" "$d_start" "$d_gui" "$d_total"

  sum_start=$(awk "BEGIN{print $sum_start+$d_start}")
  sum_gui=$(awk "BEGIN{print $sum_gui+$d_gui}")
  sum_total=$(awk "BEGIN{print $sum_total+$d_total}")

  [ "$NOSHUT" -eq 0 ] && qvm-shutdown --wait "$QUBE" >/dev/null 2>&1
done

echo "------------------------------------------"
printf "%-4s %10s %10s %10s\n" "avg" \
  "$(awk "BEGIN{printf \"%.1f\", $sum_start/$RUNS}")" \
  "$(awk "BEGIN{printf \"%.1f\", $sum_gui/$RUNS}")" \
  "$(awk "BEGIN{printf \"%.1f\", $sum_total/$RUNS}")"