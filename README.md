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
| bun | node/node-stdout-worker.js | 0.92 (0.14) | 0.39 (0.09) | 1.12 (0.16) | 155.2 MiB (5886 KiB) |
| bun | node/node-stdout-buffer.js | 1.07 (0.07) | 0.29 (0.02) | 0.80 (0.08) | 121.4 MiB (945 KiB) |
| node | node/node-stdout-worker.js | 1.65 (0.09) | 0.28 (0.03) | 2.11 (0.09) | 362.5 MiB (434 KiB) |
| deno | deno-stdout-worker.ts | 1.76 (0.12) | 0.36 (0.05) | 2.09 (0.13) | 98.3 MiB (639 KiB) |
| python | python/orjson-stdout.py | 1.88 (0.04) | 0.21 (0.02) | 1.63 (0.04) | 12.3 MiB (125 KiB) |
| bun | node/node-console.js | 1.94 (0.09) | 1.04 (0.04) | 0.91 (0.08) | 116.1 MiB (1019 KiB) |
| python | python/orjson-print.py | 2.04 (0.06) | 0.21 (0.02) | 1.83 (0.04) | 12.3 MiB (101 KiB) |
| bun | node/node-stream.js | 2.55 (0.09) | 1.16 (0.05) | 1.44 (0.06) | 117.8 MiB (798 KiB) |
| node | node/node-stdout-buffer.js | 2.63 (0.1) | 0.38 (0.06) | 2.45 (0.1) | 82.4 MiB (161 KiB) |
| deno | deno-stdout-buffer.ts | 2.65 (0.07) | 0.38 (0.04) | 2.45 (0.07) | 70.6 MiB (548 KiB) |
| pypy | python/json-print.py | 3.45 (0.08) | 0.25 (0.02) | 3.18 (0.07) | 98.7 MiB (205 KiB) |
| bun | node/node-pino.js | 3.49 (0.13) | 1.19 (0.07) | 2.29 (0.1) | 137.9 MiB (789 KiB) |
| node | node/node-stream.js | 3.55 (0.19) | 1.16 (0.04) | 2.45 (0.17) | 80.3 MiB (271 KiB) |
| deno | deno-stdout.ts | 3.68 (0.19) | 1.20 (0.08) | 2.61 (0.15) | 67.8 MiB (911 KiB) |
| deno | deno-log-stdout.ts | 4.07 (0.11) | 1.25 (0.1) | 2.96 (0.08) | 70.2 MiB (722 KiB) |
| deno | deno-stream.ts | 4.15 (0.1) | 1.16 (0.05) | 3.16 (0.1) | 71.8 MiB (1448 KiB) |
| deno | deno-log.ts | 4.22 (0.19) | 1.15 (0.08) | 3.10 (0.2) | 71.4 MiB (442 KiB) |
| deno | deno-console.ts | 4.59 (0.16) | 1.17 (0.06) | 3.49 (0.11) | 69.7 MiB (264 KiB) |
| node | node/node-pino.js | 4.60 (0.1) | 1.19 (0.05) | 3.50 (0.08) | 83.8 MiB (265 KiB) |
| node | node/node-console.js | 4.76 (0.11) | 1.13 (0.06) | 3.70 (0.08) | 81.3 MiB (128 KiB) |
| deno | deno-pino.ts | 5.25 (0.09) | 1.27 (0.05) | 4.18 (0.09) | 75.4 MiB (1008 KiB) |
| python | python/json-print.py | 6.34 (0.12) | 0.21 (0.03) | 6.10 (0.1) | 9.6 MiB (61 KiB) |
| python | python/orjson-log-opt.py | 14.64 (0.42) | 1.29 (0.09) | 13.46 (0.38) | 13.6 MiB (157 KiB) |
| pypy | python/json-log.py | 17.22 (0.49) | 3.45 (0.08) | 13.79 (0.46) | 101.4 MiB (221 KiB) |
| python | python/orjson-log.py | 17.64 (0.23) | 1.47 (0.09) | 16.10 (0.19) | 13.5 MiB (145 KiB) |
| python | python/json-log.py | 23.53 (0.6) | 1.55 (0.07) | 21.86 (0.55) | 13.6 MiB (117 KiB) |

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
| bun | node/node-stdout-worker.js | 0.92 | 1.43 (1.55) | 0.82 (0.89) |
| bun | node/node-stdout-buffer.js | 1.07 | 1.69 (1.58) | 1.07 (1) |
| bun | node/node-console.js | 1.94 | 2.33 (1.2) | 2.01 (1.04) |
| bun | node/node-stream.js | 2.55 | 4.25 (1.67) | 2.63 (1.03) |
| bun | node/node-pino.js | 3.49 | 4.48 (1.28) | 3.50 (1) |
| deno | deno-stdout-worker.ts | 1.76 | 2.63 (1.49) | 1.72 (0.98) |
| deno | deno-stdout-buffer.ts | 2.65 | 3.76 (1.42) | 2.67 (1.01) |
| deno | deno-stdout.ts | 3.68 | 5.74 (1.56) | 3.75 (1.02) |
| deno | deno-log-stdout.ts | 4.07 | 5.98 (1.47) | 4.00 (0.98) |
| deno | deno-stream.ts | 4.15 | 6.35 (1.53) | 4.27 (1.03) |
| deno | deno-log.ts | 4.22 | 4.68 (1.11) | 4.43 (1.05) |
| deno | deno-console.ts | 4.59 | 5.89 (1.28) | 4.74 (1.03) |
| deno | deno-pino.ts | 5.25 | 7.99 (1.52) | 5.50 (1.05) |
| node | node/node-stdout-worker.js | 1.65 | 1.90 (1.15) | 1.64 (0.99) |
| node | node/node-stdout-buffer.js | 2.63 | 3.90 (1.48) | 2.65 (1.01) |
| node | node/node-stream.js | 3.55 | 5.13 (1.45) | 3.65 (1.03) |
| node | node/node-pino.js | 4.60 | 5.77 (1.25) | 4.66 (1.01) |
| node | node/node-console.js | 4.76 | 5.43 (1.14) | 4.93 (1.04) |
| pypy | python/json-print.py | 3.45 | 3.66 (1.06) | 3.54 (1.03) |
| pypy | python/json-log.py | 17.22 | 20.26 (1.18) | 18.37 (1.07) |
| python | python/orjson-stdout.py | 1.88 | 2.21 (1.18) | 1.99 (1.06) |
| python | python/orjson-print.py | 2.04 | 2.41 (1.18) | 2.10 (1.03) |
| python | python/json-print.py | 6.34 | 7.32 (1.15) | 6.62 (1.04) |
| python | python/orjson-log-opt.py | 14.64 | 16.00 (1.09) | 15.38 (1.05) |
| python | python/orjson-log.py | 17.64 | 21.76 (1.23) | 19.73 (1.12) |
| python | python/json-log.py | 23.53 | 28.08 (1.19) | 25.31 (1.08) |

**Slowdown aggregation**:

| Tool | Slowdown (CPU) | Slowdown (I/O) | Slowdown (average) |
| --- | --- | --- | --- |
| pypy | 1.16 | 1.06 | 1.11 |
| python | 1.18 | 1.08 | 1.13 |
| node | 1.29 | 1.02 | 1.16 |
| bun | 1.42 | 1.01 | 1.21 |
| deno | 1.42 | 1.02 | 1.22 |

**Memory usage**:

| Tool | Idle (MiB) | CPU (MiB) | I/O (MiB) |
| --- | --- | --- | --- |
| python | 12.5 | 12.6 | 12.3 |
| deno | 74.4 | 74.5 | 74.4 |
| pypy | 100.1 | 100.5 | 100.3 |
| bun | 129.7 | 128.8 | 132 |
| node | 138.1 | 138.3 | 138 |

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
