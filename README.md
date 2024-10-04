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
| deno | deno-stdout-worker.ts | 1.65 (0.14) | 0.31 (0.03) | 2.06 (0.17) | 93.9 MiB (581 KiB) |
| bun | node/node-console.js | 1.97 (0.12) | 1.06 (0.09) | 0.93 (0.05) | 115.9 MiB (1610 KiB) |
| python | python/orjson-stdout.py | 2.01 (0.08) | 0.26 (0.03) | 1.74 (0.08) | 12.2 MiB (150 KiB) |
| python | python/orjson-print.py | 2.05 (0.13) | 0.20 (0.02) | 1.81 (0.13) | 12.2 MiB (81 KiB) |
| deno | deno-stdout-buffer.ts | 2.54 (0.08) | 0.33 (0.04) | 2.31 (0.1) | 66.4 MiB (548 KiB) |
| bun | node/node-stream.js | 2.61 (0.1) | 1.21 (0.07) | 1.48 (0.09) | 118.1 MiB (1184 KiB) |
| bun | node/pino-log.js | 3.38 (0.16) | 1.18 (0.09) | 2.28 (0.09) | 137.8 MiB (813 KiB) |
| pypy | python/json-print.py | 3.45 (0.09) | 0.29 (0.03) | 3.14 (0.08) | 98.7 MiB (225 KiB) |
| node | node/node-stream.js | 3.51 (0.12) | 1.07 (0.03) | 2.48 (0.1) | 80.3 MiB (149 KiB) |
| deno | deno-stdout.ts | 3.65 (0.15) | 1.22 (0.09) | 2.57 (0.08) | 64.5 MiB (1062 KiB) |
| deno | deno-log-stdout.ts | 3.99 (0.13) | 1.20 (0.09) | 2.96 (0.1) | 66.5 MiB (1347 KiB) |
| deno | deno-log.ts | 4.12 (0.07) | 1.12 (0.07) | 3.07 (0.03) | 68.1 MiB (700 KiB) |
| deno | deno-stream.ts | 4.41 (0.18) | 1.21 (0.05) | 3.32 (0.15) | 67.4 MiB (748 KiB) |
| node | node/pino-log.js | 4.51 (0.12) | 1.15 (0.04) | 3.48 (0.09) | 84 MiB (144 KiB) |
| deno | deno-console.ts | 4.71 (0.16) | 1.14 (0.05) | 3.48 (0.17) | 66.1 MiB (185 KiB) |
| node | node/node-console.js | 5.01 (0.19) | 1.18 (0.06) | 3.81 (0.14) | 81.4 MiB (155 KiB) |
| python | python/json-print.py | 6.37 (0.13) | 0.21 (0.03) | 6.11 (0.13) | 9.5 MiB (181 KiB) |
| python | python/orjson-log-opt.py | 14.29 (0.44) | 1.23 (0.11) | 13.06 (0.37) | 13.6 MiB (243 KiB) |
| pypy | python/json-log.py | 17.15 (0.53) | 3.38 (0.15) | 13.70 (0.37) | 101.6 MiB (258 KiB) |
| python | python/orjson-log.py | 18.11 (0.6) | 1.38 (0.1) | 16.71 (0.53) | 13.7 MiB (182 KiB) |
| python | python/json-log.py | 23.35 (0.42) | 1.52 (0.12) | 21.70 (0.3) | 13.5 MiB (105 KiB) |

#### CPU

| Tool | Script | Total Seconds (stddev) | System Seconds (stddev) | User Seconds (stddev) | RSS Memory (stddev) |
| --- | --- | --- | --- | --- | --- |
| python | python/orjson-stdout.py | 1.93 (0.4) | 0.26 (0.06) | 1.65 (0.36) | 12.4 MiB (2 KiB) |
| python | python/orjson-print.py | 2.32 (0.22) | 0.25 (0.04) | 2.06 (0.2) | 12.4 MiB (43 KiB) |
| deno | deno-stdout-worker.ts | 2.84 (0.54) | 0.40 (0.03) | 3.38 (0.57) | 94.3 MiB (869 KiB) |
| bun | node/node-console.js | 3.35 (0.67) | 1.57 (0.46) | 1.77 (0.31) | 114.1 MiB (880 KiB) |
| pypy | python/json-print.py | 4.12 (0.58) | 0.31 (0.05) | 3.80 (0.54) | 99.3 MiB (220 KiB) |
| bun | node/node-stream.js | 4.26 (0.43) | 1.54 (0.32) | 2.59 (0.3) | 119.3 MiB (1636 KiB) |
| deno | deno-stdout-buffer.ts | 4.51 (0.69) | 0.48 (0.1) | 4.21 (0.63) | 66.9 MiB (746 KiB) |
| deno | deno-log.ts | 4.67 (1.15) | 1.19 (0.45) | 3.54 (0.74) | 69 MiB (943 KiB) |
| bun | node/pino-log.js | 4.82 (0.58) | 1.50 (0.35) | 3.37 (0.42) | 137.8 MiB (1190 KiB) |
| node | node/node-stream.js | 5.27 (0.85) | 1.62 (0.25) | 3.87 (0.82) | 80.5 MiB (173 KiB) |
| deno | deno-stdout.ts | 6.11 (0.75) | 1.62 (0.49) | 4.65 (0.38) | 65.1 MiB (1312 KiB) |
| deno | deno-console.ts | 6.26 (1.03) | 1.27 (0.46) | 5.01 (0.79) | 66.1 MiB (755 KiB) |
| deno | deno-log-stdout.ts | 6.49 (0.64) | 1.67 (0.43) | 4.68 (0.35) | 66.9 MiB (711 KiB) |
| node | node/pino-log.js | 6.49 (0.63) | 1.41 (0.21) | 5.22 (0.64) | 84.2 MiB (110 KiB) |
| node | node/node-console.js | 6.75 (0.92) | 1.48 (0.4) | 4.73 (0.73) | 81.6 MiB (177 KiB) |
| deno | deno-stream.ts | 6.95 (0.94) | 1.58 (0.43) | 5.59 (0.78) | 69.6 MiB (1208 KiB) |
| python | python/json-print.py | 7.73 (1.14) | 0.27 (0.08) | 7.42 (1.11) | 9.6 MiB (79 KiB) |
| python | python/orjson-log-opt.py | 16.16 (2.49) | 1.43 (0.45) | 14.63 (2.18) | 13.7 MiB (64 KiB) |
| python | python/orjson-log.py | 19.69 (3.02) | 1.58 (0.46) | 18.06 (2.8) | 13.7 MiB (59 KiB) |
| pypy | python/json-log.py | 21.07 (2.57) | 3.94 (0.47) | 17.02 (2.24) | 101.5 MiB (274 KiB) |
| python | python/json-log.py | 27.15 (3.22) | 1.70 (0.51) | 25.40 (2.88) | 13.7 MiB (67 KiB) |

#### I/O

| Tool | Script | Total Seconds (stddev) | System Seconds (stddev) | User Seconds (stddev) | RSS Memory (stddev) |
| --- | --- | --- | --- | --- | --- |
| deno | deno-stdout-worker.ts | 1.66 (0.15) | 0.34 (0.03) | 2.08 (0.21) | 93.9 MiB (459 KiB) |
| python | python/orjson-stdout.py | 1.96 (0.12) | 0.22 (0.02) | 1.74 (0.11) | 12 MiB (210 KiB) |
| bun | node/node-console.js | 2.02 (0.12) | 1.12 (0.03) | 0.92 (0.1) | 115.9 MiB (1555 KiB) |
| python | python/orjson-print.py | 2.11 (0.12) | 0.23 (0.03) | 1.89 (0.1) | 12.2 MiB (276 KiB) |
| bun | node/node-stream.js | 2.52 (0.17) | 1.16 (0.05) | 1.43 (0.13) | 119 MiB (766 KiB) |
| deno | deno-stdout-buffer.ts | 2.62 (0.06) | 0.35 (0.01) | 2.39 (0.07) | 66.6 MiB (389 KiB) |
| bun | node/pino-log.js | 3.47 (0.5) | 1.30 (0.17) | 2.33 (0.35) | 137.7 MiB (688 KiB) |
| pypy | python/json-print.py | 3.48 (0.23) | 0.27 (0.04) | 3.18 (0.21) | 98.8 MiB (435 KiB) |
| node | node/node-stream.js | 3.55 (0.27) | 1.12 (0.06) | 2.42 (0.21) | 80.2 MiB (332 KiB) |
| deno | deno-stdout.ts | 3.62 (0.27) | 1.21 (0.1) | 2.61 (0.19) | 63.9 MiB (920 KiB) |
| deno | deno-log-stdout.ts | 3.89 (0.32) | 1.19 (0.09) | 2.88 (0.21) | 66.7 MiB (1170 KiB) |
| deno | deno-log.ts | 4.24 (0.09) | 1.16 (0.06) | 3.09 (0.11) | 68.8 MiB (557 KiB) |
| deno | deno-stream.ts | 4.30 (0.27) | 1.26 (0.09) | 3.26 (0.22) | 66.9 MiB (788 KiB) |
| node | node/pino-log.js | 4.60 (0.32) | 1.15 (0.07) | 3.54 (0.24) | 83.8 MiB (323 KiB) |
| deno | deno-console.ts | 4.69 (0.24) | 1.13 (0.04) | 3.53 (0.2) | 65.9 MiB (357 KiB) |
| node | node/node-console.js | 4.88 (0.37) | 1.18 (0.07) | 3.72 (0.3) | 80.9 MiB (266 KiB) |
| python | python/json-print.py | 6.65 (0.46) | 0.25 (0.04) | 6.40 (0.41) | 9.3 MiB (239 KiB) |
| python | python/orjson-log-opt.py | 15.18 (1.48) | 1.38 (0.18) | 13.81 (1.29) | 13.6 MiB (232 KiB) |
| pypy | python/json-log.py | 17.63 (1.7) | 3.51 (0.22) | 14.22 (1.43) | 101.4 MiB (373 KiB) |
| python | python/orjson-log.py | 19.51 (2.01) | 1.60 (0.12) | 17.86 (1.86) | 13.5 MiB (234 KiB) |
| python | python/json-log.py | 24.82 (3.5) | 1.72 (0.21) | 23.01 (3.22) | 13.3 MiB (342 KiB) |

#### Comparison

| Tool | Script | Idle | CPU (slowdown) | I/O (slowdown) |
| --- | --- | --- | --- | --- |
| deno | deno-stdout-worker.ts | 1.65 | 2.84 (1.72) | 1.66 (1.01) |
| bun | node/node-console.js | 1.97 | 3.35 (1.7) | 2.02 (1.03) |
| python | python/orjson-stdout.py | 2.01 | 1.93 (0.96) | 1.96 (0.98) |
| python | python/orjson-print.py | 2.05 | 2.32 (1.13) | 2.11 (1.03) |
| deno | deno-stdout-buffer.ts | 2.54 | 4.51 (1.78) | 2.62 (1.03) |
| bun | node/node-stream.js | 2.61 | 4.26 (1.63) | 2.52 (0.97) |
| bun | node/pino-log.js | 3.38 | 4.82 (1.43) | 3.47 (1.03) |
| pypy | python/json-print.py | 3.45 | 4.12 (1.19) | 3.48 (1.01) |
| node | node/node-stream.js | 3.51 | 5.27 (1.5) | 3.55 (1.01) |
| deno | deno-stdout.ts | 3.65 | 6.11 (1.67) | 3.62 (0.99) |
| deno | deno-log-stdout.ts | 3.99 | 6.49 (1.63) | 3.89 (0.97) |
| deno | deno-log.ts | 4.12 | 4.67 (1.13) | 4.24 (1.03) |
| deno | deno-stream.ts | 4.41 | 6.95 (1.58) | 4.30 (0.98) |
| node | node/pino-log.js | 4.51 | 6.49 (1.44) | 4.60 (1.02) |
| deno | deno-console.ts | 4.71 | 6.26 (1.33) | 4.69 (1) |
| node | node/node-console.js | 5.01 | 6.75 (1.35) | 4.88 (0.97) |
| python | python/json-print.py | 6.37 | 7.73 (1.21) | 6.65 (1.04) |
| python | python/orjson-log-opt.py | 14.29 | 16.16 (1.13) | 15.18 (1.06) |
| pypy | python/json-log.py | 17.15 | 21.07 (1.23) | 17.63 (1.03) |
| python | python/orjson-log.py | 18.11 | 19.69 (1.09) | 19.51 (1.08) |
| python | python/json-log.py | 23.35 | 27.15 (1.16) | 24.82 (1.06) |

Aggregating the data, we see a trend for each of the tools:

| Tool | Slowdown (CPU) | Slowdown (I/O) | Slowdown (average) |
| --- | --- | --- | --- |
| python | 1.13 | 1.06 | 1.1 |
| pypy | 1.22 | 1.02 | 1.12 |
| node | 1.42 | 1 | 1.21 |
| deno | 1.51 | 1 | 1.25 |
| bun | 1.56 | 1.01 | 1.29 |
