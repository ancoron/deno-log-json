# Deno Logging Tests

Some basic code to compare performance for logging JSON messages using different
approaches with Deno and other runtimes (Node, Bun) and even languages (Python).

The following flavors are included:

* Deno:
  * using builtin [`console.log`](https://docs.deno.com/api/node/console/)
  * using builtin [`process.stdout`](https://docs.deno.com/api/node/process/~/Process.stdout)
    stream
  * using builtin [`Deno.stdout`](https://docs.deno.com/api/deno/~/Deno.stdout)
    stream
  * using the [`@std/log`](https://jsr.io/@std/log) library
  * using the [`@std/log`](https://jsr.io/@std/log) library but with
    `Deno.stdout` instead of `console.log`
* NodeJS:
  * using builtin [`console.log`](https://nodejs.org/api/console.html)
  * using builtin [`process.stdout`](https://nodejs.org/api/process.html#processstdout)
    stream
  * using the [Pino](https://github.com/pinojs/pino/) library
* Bun: just executing the NodeJS scripts as they are
* CPython:
  * using defaults of [`python-json-logger`](https://github.com/nhairs/python-json-logger)
  * using [`orjson`](https://github.com/ijl/orjson) with
    [`python-json-logger`](https://github.com/nhairs/python-json-logger)
  * using [`orjson`](https://github.com/ijl/orjson) with
    [`python-json-logger`](https://github.com/nhairs/python-json-logger) + some
    optimizations for standard Python logging
  * using standard [`json`](https://docs.python.org/3/library/json.html) with
    builtin [`print`](https://docs.python.org/3/library/functions.html#print)
  * using [`orjson`](https://github.com/ijl/orjson) with builtin
    [`print`](https://docs.python.org/3/library/functions.html#print)
  * using [`orjson`](https://github.com/ijl/orjson) with builtin
    [`sys.stdout`](https://docs.python.org/3/library/sys.html#sys.stdout) and
    its binary buffer
* PyPy: just executing the Python scripts except OrJson (since it is
  incompatible)

## Running Tests

Make sure you have the following CLI tools/commands installed:

* `make` (the GNU version)
* `time` (the GNU version)
* `deno`
* `node`
* `bun`
* `python` (Python 3)
* `pypy3`
* `virtualenv`
* `mlr`: [Miller](https://miller.readthedocs.io/en/latest/)

Now execute the following command:

```bash
make run-bench-x
```

By default, all scripts are run 7 times, which you can adjust by setting the
`RUNS` variable, e.g. to get results for only 3 runs:

```bash
make run-bench-x RUNS=3
```

## Test Results

Here are some results of running with the default number of runs on different
hardware (all on Linux, though).

### Versions

The benchmark was executed using the following tool versions:

* Deno: 1.46.2
* Node: v22.9.0
* Bun: 1.1.29
* CPython: 3.12.6
* PyPy: 7.3.17

Library versions where as follows at the time of the test:

* `@std/log`: 0.224.7
* `pino`: 9.4.0
* `orjson`: 3.10.7
* `python-json-logger`: 3.1.0

### AMD Ryzen 7 5700G

Machine specs:

* CPU: AMD Ryzen 7 5700G (capped to 35W TDP)
* OS: Arch Linux (Kernel 6.10.9-arch1-2, amd_pstate=passive)
* Storage: ext4 in cryptlvm (LUKS) @ NVMe

#### Load Situations

Please note that the system under test has been used as the tests where running,
so the numbers here are more what you see in real situations. Please also note
that while this system acts as a desktop, even on servers the application will
never be the only one running. Agents are most likely present to provide one the
following aspects and will take their share of CPU, memory and I/O:

* management
* logging
* system metrics
* ...

3 test profiles have been defined to see how certain system load types influence
the various runtimes and implementations, since those can give you an idea about
how it probably will behave under your specific workload:

* idle:
  * KDE 6 Plasma session
  * Firefox with many tabs (some CPU/memory load depending on the web page)
  * Thunderbird with multiple IMAP accounts
  * multiple Dolphin instances
  * multiple Kate sessions
  * Vector log aggregation agent capturing journald logs
  * Scaphandre power consumption metrics
* CPU:
  * based on "idle" situation
  * additional `ffmpeg` HEVC encode running using half the CPU threads:

    ```bash
    ffmpeg -v warning -i input.mkv -c:v libx265 -crf 23 -preset veryslow -tune grain -x265-params 'frame-threads=8:pools=8' -an -sn -y output.mkv
    ```

* I/O:
  * based on "idle" situation
  * additional `fio` mixed I/O test running (note this does involve quite some
    CPU load due to Linux kernel kcryptd I/O workers):

    ```bash
    fio --name=randrw --rw=randrw --direct=1 --ioengine=libaio --iodepth=64 --bs=8k --numjobs=1 --rwmixread=70 --size=1G --runtime=1h --time_based --group_reporting --filename=fio.dat
    ```

#### Idle

| Tool | Script | Total Seconds (stddev) | System Seconds (stddev) | User Seconds (stddev) | RSS Memory (stddev) |
| --- | --- | --- | --- | --- | --- |
| bun | node/node-stdout-worker.js | 0.88 (0.06) | 0.38 (0.04) | 1.05 (0.08) | 165.3 MiB (6770 KiB) |
| bun | node/node-stdout-buffer.js | 1.06 (0.09) | 0.30 (0.04) | 0.79 (0.06) | 120.2 MiB (2287 KiB) |
| node | node/node-stdout-worker.js | 1.64 (0.1) | 0.25 (0.03) | 2.08 (0.11) | 362.5 MiB (319 KiB) |
| deno | deno-stdout-worker.ts | 1.92 (0.18) | 0.36 (0.03) | 2.31 (0.25) | 97.4 MiB (772 KiB) |
| python | python/orjson-stdout.py | 1.97 (0.07) | 0.24 (0.02) | 1.72 (0.07) | 12.2 MiB (155 KiB) |
| bun | node/node-console.js | 1.99 (0.08) | 1.06 (0.04) | 0.95 (0.06) | 116.3 MiB (1134 KiB) |
| python | python/orjson-print.py | 2.03 (0.04) | 0.19 (0.02) | 1.83 (0.04) | 12.2 MiB (139 KiB) |
| node | node/node-stdout-buffer.js | 2.58 (0.14) | 0.33 (0.03) | 2.43 (0.12) | 82.3 MiB (161 KiB) |
| deno | deno-stdout-buffer.ts | 2.59 (0.18) | 0.38 (0.04) | 2.40 (0.14) | 70.3 MiB (709 KiB) |
| bun | node/node-stream.js | 2.59 (0.06) | 1.16 (0.03) | 1.44 (0.05) | 118.9 MiB (1212 KiB) |
| bun | node/node-pino.js | 3.35 (0.12) | 1.20 (0.04) | 2.19 (0.11) | 137.7 MiB (721 KiB) |
| pypy | python/json-print.py | 3.47 (0.09) | 0.26 (0.02) | 3.20 (0.08) | 99.1 MiB (216 KiB) |
| node | node/node-stream.js | 3.52 (0.15) | 1.13 (0.05) | 2.46 (0.14) | 80.3 MiB (98 KiB) |
| deno | deno-stdout.ts | 3.76 (0.21) | 1.20 (0.1) | 2.70 (0.14) | 67.8 MiB (781 KiB) |
| deno | deno-log-stdout.ts | 4.17 (0.13) | 1.27 (0.05) | 3.08 (0.12) | 70.3 MiB (929 KiB) |
| deno | deno-log.ts | 4.20 (0.04) | 1.09 (0.05) | 3.16 (0.06) | 71.7 MiB (824 KiB) |
| deno | deno-stream.ts | 4.26 (0.12) | 1.27 (0.07) | 3.17 (0.12) | 71.2 MiB (1224 KiB) |
| deno | deno-console.ts | 4.69 (0.16) | 1.15 (0.06) | 3.61 (0.11) | 69.5 MiB (1334 KiB) |
| node | node/node-pino.js | 4.71 (0.21) | 1.15 (0.05) | 3.62 (0.18) | 83.9 MiB (235 KiB) |
| node | node/node-console.js | 4.85 (0.14) | 1.22 (0.05) | 3.66 (0.17) | 81.1 MiB (272 KiB) |
| deno | deno-pino.ts | 5.23 (0.17) | 1.26 (0.07) | 4.17 (0.13) | 75.3 MiB (1350 KiB) |
| python | python/json-print.py | 6.31 (0.24) | 0.23 (0.02) | 6.05 (0.22) | 9.4 MiB (112 KiB) |
| python | python/orjson-log-opt.py | 14.58 (0.16) | 1.31 (0.08) | 13.23 (0.18) | 13.5 MiB (158 KiB) |
| pypy | python/json-log.py | 17.25 (0.49) | 3.39 (0.14) | 13.90 (0.4) | 101.7 MiB (395 KiB) |
| python | python/orjson-log.py | 18.07 (0.55) | 1.46 (0.11) | 16.49 (0.46) | 13.6 MiB (188 KiB) |
| python | python/json-log.py | 23.85 (0.51) | 1.58 (0.06) | 22.12 (0.49) | 13.5 MiB (94 KiB) |

#### CPU

| Tool | Script | Total Seconds (stddev) | System Seconds (stddev) | User Seconds (stddev) | RSS Memory (stddev) |
| --- | --- | --- | --- | --- | --- |
| bun | node/node-stdout-worker.js | 1.43 (0.2) | 0.49 (0.04) | 1.66 (0.2) | 149.6 MiB (9998 KiB) |
| bun | node/node-stdout-buffer.js | 1.69 (0.35) | 0.38 (0.05) | 1.34 (0.3) | 119.9 MiB (826 KiB) |
| node | node/node-stdout-worker.js | 1.90 (0.34) | 0.32 (0.03) | 2.42 (0.35) | 362.5 MiB (813 KiB) |
| python | python/orjson-stdout.py | 2.21 (0.63) | 0.26 (0.06) | 1.94 (0.57) | 12.4 MiB (6 KiB) |
| bun | node/node-console.js | 2.33 (0.58) | 1.17 (0.19) | 1.23 (0.4) | 116.2 MiB (1665 KiB) |
| python | python/orjson-print.py | 2.41 (0.71) | 0.23 (0.04) | 2.16 (0.67) | 12.4 MiB (71 KiB) |
| deno | deno-stdout-worker.ts | 2.63 (0.51) | 0.41 (0.04) | 3.16 (0.51) | 97.8 MiB (724 KiB) |
| pypy | python/json-print.py | 3.66 (1.04) | 0.30 (0.06) | 3.44 (0.99) | 99.4 MiB (83 KiB) |
| deno | deno-stdout-buffer.ts | 3.76 (0.72) | 0.43 (0.06) | 3.44 (0.69) | 70.8 MiB (427 KiB) |
| node | node/node-stdout-buffer.js | 3.90 (0.71) | 0.40 (0.07) | 3.68 (0.66) | 82.4 MiB (114 KiB) |
| bun | node/node-stream.js | 4.25 (0.38) | 1.58 (0.1) | 2.70 (0.29) | 120 MiB (172 KiB) |
| bun | node/node-pino.js | 4.48 (0.8) | 1.56 (0.17) | 3.17 (0.66) | 138.1 MiB (923 KiB) |
| deno | deno-log.ts | 4.68 (0.98) | 1.22 (0.13) | 3.56 (0.85) | 72.6 MiB (345 KiB) |
| node | node/node-stream.js | 5.13 (0.63) | 1.36 (0.1) | 3.83 (0.54) | 80.6 MiB (70 KiB) |
| node | node/node-console.js | 5.43 (1.22) | 1.31 (0.14) | 4.26 (1.09) | 81.7 MiB (250 KiB) |
| deno | deno-stdout.ts | 5.74 (0.55) | 1.47 (0.12) | 4.45 (0.46) | 68.4 MiB (742 KiB) |
| node | node/node-pino.js | 5.77 (1.33) | 1.34 (0.16) | 4.50 (1.17) | 84.3 MiB (88 KiB) |
| deno | deno-console.ts | 5.89 (1.26) | 1.31 (0.15) | 4.57 (1.11) | 69.6 MiB (329 KiB) |
| deno | deno-log-stdout.ts | 5.98 (0.45) | 1.39 (0.11) | 4.77 (0.36) | 70.2 MiB (537 KiB) |
| deno | deno-stream.ts | 6.35 (0.92) | 1.53 (0.2) | 5.02 (0.74) | 71.6 MiB (932 KiB) |
| python | python/json-print.py | 7.32 (0.61) | 0.26 (0.02) | 7.04 (0.58) | 9.6 MiB (100 KiB) |
| deno | deno-pino.ts | 7.99 (0.74) | 1.57 (0.12) | 6.57 (0.7) | 75.3 MiB (1257 KiB) |
| python | python/orjson-log-opt.py | 16.00 (1.93) | 1.37 (0.11) | 14.51 (1.82) | 13.7 MiB (28 KiB) |
| pypy | python/json-log.py | 20.26 (1.6) | 3.66 (0.3) | 16.39 (1.31) | 101.5 MiB (349 KiB) |
| python | python/orjson-log.py | 21.76 (2.43) | 1.68 (0.12) | 20.03 (2.29) | 13.7 MiB (60 KiB) |
| python | python/json-log.py | 28.08 (2.47) | 1.84 (0.17) | 26.13 (2.32) | 13.7 MiB (32 KiB) |

#### I/O

| Tool | Script | Total Seconds (stddev) | System Seconds (stddev) | User Seconds (stddev) | RSS Memory (stddev) |
| --- | --- | --- | --- | --- | --- |
| bun | node/node-stdout-worker.js | 0.82 (0.02) | 0.39 (0.03) | 0.99 (0.03) | 168.9 MiB (6217 KiB) |
| bun | node/node-stdout-buffer.js | 1.07 (0.05) | 0.31 (0.04) | 0.82 (0.04) | 119.7 MiB (992 KiB) |
| node | node/node-stdout-worker.js | 1.64 (0.09) | 0.28 (0.04) | 2.16 (0.08) | 362.6 MiB (432 KiB) |
| deno | deno-stdout-worker.ts | 1.72 (0.16) | 0.40 (0.02) | 2.04 (0.18) | 98.4 MiB (1268 KiB) |
| python | python/orjson-stdout.py | 1.99 (0.1) | 0.28 (0.03) | 1.69 (0.1) | 11.9 MiB (275 KiB) |
| bun | node/node-console.js | 2.01 (0.05) | 1.14 (0.04) | 0.90 (0.05) | 115.9 MiB (1224 KiB) |
| python | python/orjson-print.py | 2.10 (0.08) | 0.21 (0.02) | 1.92 (0.08) | 12.3 MiB (140 KiB) |
| bun | node/node-stream.js | 2.63 (0.08) | 1.17 (0.04) | 1.48 (0.07) | 117.8 MiB (1728 KiB) |
| node | node/node-stdout-buffer.js | 2.65 (0.16) | 0.36 (0.05) | 2.48 (0.13) | 82.1 MiB (211 KiB) |
| deno | deno-stdout-buffer.ts | 2.67 (0.24) | 0.39 (0.04) | 2.41 (0.18) | 70.4 MiB (886 KiB) |
| bun | node/node-pino.js | 3.50 (0.21) | 1.26 (0.09) | 2.38 (0.14) | 137.7 MiB (954 KiB) |
| pypy | python/json-print.py | 3.54 (0.11) | 0.28 (0.02) | 3.20 (0.12) | 98.8 MiB (374 KiB) |
| node | node/node-stream.js | 3.65 (0.13) | 1.13 (0.06) | 2.57 (0.11) | 80.1 MiB (282 KiB) |
| deno | deno-stdout.ts | 3.75 (0.41) | 1.27 (0.11) | 2.64 (0.32) | 69.2 MiB (809 KiB) |
| deno | deno-log-stdout.ts | 4.00 (1.98) | 1.23 (0.09) | 2.91 (0.11) | 70.9 MiB (1294 KiB) |
| deno | deno-stream.ts | 4.27 (0.13) | 1.22 (0.08) | 3.19 (0.13) | 70.9 MiB (864 KiB) |
| deno | deno-log.ts | 4.43 (0.19) | 1.16 (0.08) | 3.21 (0.17) | 71.5 MiB (877 KiB) |
| node | node/node-pino.js | 4.66 (0.11) | 1.12 (0.02) | 3.58 (0.09) | 83.8 MiB (143 KiB) |
| deno | deno-console.ts | 4.74 (0.25) | 1.16 (0.03) | 3.56 (0.16) | 69.7 MiB (825 KiB) |
| node | node/node-console.js | 4.93 (0.13) | 1.21 (0.07) | 3.80 (0.09) | 81.2 MiB (377 KiB) |
| deno | deno-pino.ts | 5.50 (0.54) | 1.27 (0.07) | 4.41 (0.2) | 74.5 MiB (675 KiB) |
| python | python/json-print.py | 6.62 (0.34) | 0.23 (0.03) | 6.36 (0.33) | 9.5 MiB (136 KiB) |
| python | python/orjson-log-opt.py | 15.38 (0.51) | 1.34 (0.07) | 14.00 (0.5) | 13.5 MiB (350 KiB) |
| pypy | python/json-log.py | 18.37 (0.88) | 3.62 (0.15) | 14.72 (0.71) | 101.7 MiB (340 KiB) |
| python | python/orjson-log.py | 19.73 (0.91) | 1.54 (0.12) | 18.09 (0.8) | 13.3 MiB (258 KiB) |
| python | python/json-log.py | 25.31 (0.66) | 1.60 (0.08) | 23.48 (0.61) | 13.5 MiB (122 KiB) |

#### Comparison

**Performance**:

| Tool | Script | Idle | CPU (slowdown) | I/O (slowdown) |
| --- | --- | --- | --- | --- |
| bun | node/node-stdout-worker.js | 0.88 | 1.43 (1.63) | 0.82 (0.93) |
| bun | node/node-stdout-buffer.js | 1.06 | 1.69 (1.59) | 1.07 (1.01) |
| bun | node/node-console.js | 1.99 | 2.33 (1.17) | 2.01 (1.01) |
| bun | node/node-stream.js | 2.59 | 4.25 (1.64) | 2.63 (1.02) |
| bun | node/node-pino.js | 3.35 | 4.48 (1.34) | 3.50 (1.04) |
| deno | deno-stdout-worker.ts | 1.92 | 2.63 (1.37) | 1.72 (0.9) |
| deno | deno-stdout-buffer.ts | 2.59 | 3.76 (1.45) | 2.67 (1.03) |
| deno | deno-stdout.ts | 3.76 | 5.74 (1.53) | 3.75 (1) |
| deno | deno-log-stdout.ts | 4.17 | 5.98 (1.43) | 4.00 (0.96) |
| deno | deno-stream.ts | 4.26 | 6.35 (1.49) | 4.27 (1) |
| deno | deno-log.ts | 4.20 | 4.68 (1.11) | 4.43 (1.05) |
| deno | deno-console.ts | 4.69 | 5.89 (1.26) | 4.74 (1.01) |
| deno | deno-pino.ts | 5.23 | 7.99 (1.53) | 5.50 (1.05) |
| node | node/node-stdout-worker.js | 1.64 | 1.90 (1.16) | 1.64 (1) |
| node | node/node-stdout-buffer.js | 2.58 | 3.90 (1.51) | 2.65 (1.03) |
| node | node/node-stream.js | 3.52 | 5.13 (1.46) | 3.65 (1.04) |
| node | node/node-pino.js | 4.71 | 5.77 (1.23) | 4.66 (0.99) |
| node | node/node-console.js | 4.85 | 5.43 (1.12) | 4.93 (1.02) |
| pypy | python/json-print.py | 3.47 | 3.66 (1.05) | 3.54 (1.02) |
| pypy | python/json-log.py | 17.25 | 20.26 (1.17) | 18.37 (1.06) |
| python | python/orjson-stdout.py | 1.97 | 2.21 (1.12) | 1.99 (1.01) |
| python | python/orjson-print.py | 2.03 | 2.41 (1.19) | 2.10 (1.03) |
| python | python/json-print.py | 6.31 | 7.32 (1.16) | 6.62 (1.05) |
| python | python/orjson-log-opt.py | 14.58 | 16.00 (1.1) | 15.38 (1.05) |
| python | python/orjson-log.py | 18.07 | 21.76 (1.2) | 19.73 (1.09) |
| python | python/json-log.py | 23.85 | 28.08 (1.18) | 25.31 (1.06) |

**Slowdown aggregation**:

| Tool | Slowdown (CPU) | Slowdown (I/O) | Slowdown (average) |
| --- | --- | --- | --- |
| pypy | 1.15 | 1.06 | 1.11 |
| python | 1.16 | 1.06 | 1.11 |
| node | 1.28 | 1.01 | 1.15 |
| deno | 1.4 | 1.01 | 1.21 |
| bun | 1.44 | 1.02 | 1.23 |

**Memory usage**:

| Tool | Idle (median) | Idle (max) | CPU (median) | CPU (max) | I/O (median) | I/O (max) |
| --- | --- | --- | --- | --- | --- | --- |
| python | 13.5 | 13.6 | 13.7 | 13.7 | 13.3 | 13.5 |
| deno | 71.2 | 97.4 | 71.6 | 97.8 | 70.9 | 98.4 |
| node | 82.3 | 362.5 | 82.4 | 362.5 | 82.1 | 362.6 |
| pypy | 101.7 | 101.7 | 101.5 | 101.5 | 101.7 | 101.7 |
| bun | 120.2 | 165.3 | 120 | 149.6 | 119.7 | 168.9 |

### Key Takeaways

1. CPython + orjson (directly writing binary data into `sys.stdout.buffer`) is
   really hard to beat (only possible by using some tricks for any JavaScript
   runtime - worker thread or relatively big output buffering)
2. CPython uses the least amount of memory in any situation
3. CPython and PyPy are the most resilient when the system is under CPU pressure
4. pino doesn't work as well under Deno as it does for Node or Bun
5. `console.log` is highly optimized in Bun
6. Deno uses the least amount of memory across all JavaScript runtime
   environments and also less than PyPy
7. Bun consistently outperforms Node and Deno by a factor of 2 (+/- depending on
   the case) which seems to come at the expense of higher memory usage
8. the Python logging subsystem is really slow, even when various features are
   turned off and orjson is used for fast JSON serialization
9. Node really seems to have an issue with memory management in the worker
   thread scenario (script `node/node-stdout-worker.js`)

