const worker = new Worker(
  import.meta.resolve("./worker-stdout.js"),
  {
    name: "logging",
    type: "module",
  }
);

// posting messages is slow, so we better reduce the calls
// see: https://github.com/denoland/deno/issues/11561
let last_flush = Date.now();
const max_delay = 50;

const max_buffer = 100;
const log_buffer: string[] = [];
let count_flush = 0;

function log(record: any) {
  const now = Date.now();
  log_buffer.push(JSON.stringify(record));

  if (log_buffer.length === max_buffer || (last_flush + max_delay) < now) {
    last_flush = now;
    count_flush++;
    worker.postMessage(log_buffer);
    log_buffer.length = 0;
  }
}

const ts_start = performance.now();

for (let i = 0; i < 1000000; i++) {
  log({
    level: "INFO",
    datetime: new Date().toISOString(),
    message: "This is a log message",
    args: {
      trace: {
        trace_id: "925c4bb6ec837bc0",
        span_id: "057704dfa1fb090e",
      },
      user_id: "123",
      roles: [
        "user:write",
        "sales:write",
      ],
      "x-request-id": "458868fc6e4bbd30fd6dd6da5f8828f7",
    },
  });
}

// HACK: gracefully terminate the worker
worker.postMessage(null);

const ts_end = performance.now();
console.error({millis: ts_end - ts_start, flushed: count_flush});
