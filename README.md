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

### AMD Ryzen 7 5700G

Machine specs:

* CPU: AMD Ryzen 7 5700G
* OS: Arch Linux (Kernel 6.10.9-arch1-2, amd_pstate=passive)
* Storage: ext4 in cryptlvm (LUKS) @ NVMe

Results:

| Tool | Script | Total Seconds (stddev) | System Seconds (stddev) | User Seconds (stddev) | RSS Memory (stddev) |
| --- | --- | --- | --- | --- | --- |
| python | python/orjson-stdout.py | 1.89 (0.05) | 0.26 (0.02) | 1.62 (0.05) | 12.3 MiB (100 KiB) |
| bun | node/node-console.js | 1.96 (0.03) | 1.08 (0.06) | 0.88 (0.07) | 116.9 MiB (1261 KiB) |
| python | python/orjson-print.py | 2.02 (0.07) | 0.20 (0.03) | 1.82 (0.08) | 12.3 MiB (82 KiB) |
| bun | node/node-stream.js | 2.47 (0.02) | 1.10 (0.05) | 1.39 (0.05) | 119 MiB (1721 KiB) |
| bun | node/pino-log.js | 3.27 (0.05) | 1.14 (0.04) | 2.23 (0.07) | 139.3 MiB (1163 KiB) |
| pypy | python/json-print.py | 3.36 (0.03) | 0.25 (0.03) | 3.09 (0.03) | 99.4 MiB (276 KiB) |
| node | node/node-stream.js | 3.38 (0.05) | 1.09 (0.07) | 2.33 (0.06) | 72.7 MiB (193 KiB) |
| deno | deno-stdout.ts | 3.64 (0.06) | 1.22 (0.06) | 2.59 (0.03) | 61.2 MiB (1024 KiB) |
| deno | deno-log-stdout.ts | 3.73 (0.06) | 1.11 (0.06) | 2.77 (0.05) | 64.1 MiB (1189 KiB) |
| deno | deno-stream.ts | 4.14 (0.07) | 1.17 (0.04) | 3.14 (0.08) | 64.9 MiB (888 KiB) |
| node | node/pino-log.js | 4.45 (0.09) | 1.16 (0.05) | 3.33 (0.07) | 76.2 MiB (284 KiB) |
| node | node/node-console.js | 4.69 (0.12) | 1.18 (0.04) | 3.60 (0.16) | 75 MiB (359 KiB) |
| deno | deno-console.ts | 5.81 (0.15) | 1.14 (0.05) | 4.67 (0.14) | 59.7 MiB (1441 KiB) |
| python | python/json-print.py | 6.31 (0.11) | 0.20 (0.02) | 6.07 (0.12) | 9.4 MiB (83 KiB) |
| deno | deno-log.ts | 7.07 (0.14) | 1.15 (0.06) | 5.96 (0.14) | 62.3 MiB (1149 KiB) |
| python | python/orjson-log-opt.py | 14.36 (0.28) | 1.22 (0.04) | 13.08 (0.3) | 13.7 MiB (53 KiB) |
| pypy | python/json-log.py | 16.96 (0.14) | 3.36 (0.14) | 13.57 (0.19) | 102.3 MiB (291 KiB) |
| python | python/orjson-log.py | 17.69 (0.47) | 1.41 (0.07) | 16.28 (0.43) | 13.6 MiB (169 KiB) |
| python | python/json-log.py | 23.10 (0.29) | 1.53 (0.06) | 21.52 (0.28) | 13.5 MiB (179 KiB) |
