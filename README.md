# nitropad-measure-scripts

Two small scripts to measure what Qubes OS actually costs on a machine: memory,
CPU, and how long a qube takes to start. Written while testing Qubes 4.3.1 on a
NitroPad T480 (i5-8350U, 32 GB), but nothing in them is specific to that
hardware.

Both run in **dom0**. Read them before you run them.

## qubes-session-recorder.sh

Samples every running domain into a CSV: memory, CPU percentage, the number of
running qubes, and uptime. One row per qube per sample, plus a `_TOTAL_` row.

```bash
./qubes-session-recorder.sh          # 5 s interval, auto-named file
./qubes-session-recorder.sh 10 ~/session.csv
```

Stop with Ctrl-C. Read-only: it calls `xentop` and `xl uptime`, writes one file,
needs no network.

Analyse the CSV outside dom0. Copy it to an AppVM with `qvm-copy-to-vm` and use
`analyze-session.py`, or whatever you prefer.

## qube-starttime.sh

Starts a qube, launches a GUI application in it, and times both phases over
several runs.

```bash
./qube-starttime.sh personal firefox 3
./qube-starttime.sh HTB xterm 5
./qube-starttime.sh personal firefox 3 --no-shutdown
```

Output:

```
run      start_s      gui_s    total_s
------------------------------------------
1            6.9        3.1        9.9
2            7.3        3.2       10.6
3            7.4        3.0       10.4
------------------------------------------
avg          7.2        3.1       10.3
```

- `start_s` — `qvm-start` returns, the domain is up at Xen level
- `gui_s` — the GUI process appears in the qube, a second or two before the
  window is fully rendered
- `total_s` — the two combined

By default each run shuts the qube down first, so you measure a cold start.
`--no-shutdown` leaves it running between runs.

This one does start and stop the named qube, so don't point it at a qube with
unsaved work.

## Notes

`gui_s` marks when the process exists, not when the window is clickable. Report
it as "until the window appears", not "until usable".

The GUI detection uses `pgrep` on the command name. That works for `xterm` and
`firefox`. Electron apps often run under a different process name, so the poll
may time out on those.

Neither script logs the vCPU count. If you change a qube's vCPUs mid-session,
the CPU percentages before and after are not directly comparable.

## Results

I used these for [a write-up on running Qubes on the NitroPad T480](https://mickhat.xyz/blog/).

## License

MIT