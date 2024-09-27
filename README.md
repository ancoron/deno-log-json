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

### AMD Ryzen 7 5700G

Machine specs:

* CPU: AMD Ryzen 7 5700G
* Disk  Type: NVMe
* OS: Arch Linux (Kernel 6.10.9-arch1-2, amd_pstate=passive)
* Storage: ext4 in cryptlvm (LUKS) @ NVMe

Results:

| Tool | Script | Total Seconds (stddev) | System Seconds (stddev) | User Seconds (stddev) | RSS Memory (stddev) |
| --- | --- | --- | --- | --- | --- |
| python | python/orjson-print.py | 2.07 (0.14) | 0.20 (0.04) | 1.86 (0.1) | 12.1 MiB (268 KiB) |
| bun | node/node-console.js | 2.13 (0.08) | 1.13 (0.06) | 1.03 (0.05) | 115.2 MiB (1909 KiB) |
| bun | node/node-stream.js | 2.66 (0.23) | 1.19 (0.13) | 1.51 (0.15) | 120.2 MiB (1595 KiB) |
| node | node/node-stream.js | 3.46 (0.24) | 1.14 (0.07) | 2.35 (0.18) | 72.6 MiB (230 KiB) |
| pypy | python/json-print.py | 3.50 (0.27) | 0.29 (0.02) | 3.20 (0.27) | 99.2 MiB (448 KiB) |
| bun | node/pino-log.js | 3.70 (0.18) | 1.29 (0.12) | 2.46 (0.1) | 139.2 MiB (1143 KiB) |
| node | node/pino-log.js | 4.62 (0.27) | 1.18 (0.1) | 3.51 (0.21) | 76.1 MiB (263 KiB) |
| deno | deno-stdout.ts | 4.65 (0.23) | 2.17 (0.06) | 2.68 (0.22) | 60.3 MiB (1250 KiB) |
| deno | deno-log-stdout.ts | 4.81 (0.66) | 2.09 (0.24) | 2.90 (0.44) | 63.7 MiB (863 KiB) |
| node | node/node-console.js | 4.91 (0.28) | 1.22 (0.07) | 3.63 (0.31) | 75.4 MiB (268 KiB) |
| deno | deno-stream.ts | 5.21 (0.37) | 2.03 (0.12) | 3.37 (0.26) | 63.9 MiB (863 KiB) |
| python | python/json-print.py | 6.64 (0.43) | 0.25 (0.03) | 6.38 (0.4) | 9.4 MiB (200 KiB) |
| deno | deno-console.ts | 7.25 (2.91) | 2.23 (0.75) | 5.00 (2.12) | 59.6 MiB (286 KiB) |
| deno | deno-log.ts | 8.43 (1.12) | 2.31 (0.19) | 6.20 (0.91) | 62.5 MiB (1578 KiB) |
| python | python/orjson-log-opt.py | 15.16 (1.28) | 1.27 (0.08) | 13.86 (1.18) | 13.3 MiB (235 KiB) |
| pypy | python/json-log.py | 18.71 (1.25) | 3.54 (0.22) | 14.91 (1.01) | 101.8 MiB (343 KiB) |
| python | python/orjson-log.py | 19.40 (1.64) | 1.48 (0.15) | 17.83 (1.49) | 13.3 MiB (163 KiB) |
| python | python/json-log.py | 24.73 (2.14) | 1.65 (0.12) | 23.11 (2.01) | 13.3 MiB (302 KiB) |
