const log_enc = new TextEncoder();

// maximum buffer size in KiB
const max_log_buffer = 4096;

let last_flush = Date.now();
const max_delay = 250;

let count_flush = 0;
let buffer_pos = 0;
const buf_backend = new ArrayBuffer(max_log_buffer * 1024);
const buffer = new Uint8Array(buf_backend, 0, buf_backend.byteLength);

function flush_log() {
  if (buffer_pos === 0) {
    return;
  }

  count_flush++;
  Deno.stdout.writeSync(new Uint8Array(buf_backend, 0, buffer_pos));
  buffer_pos = 0;
}

globalThis.onbeforeunload = (_: Event): void => {
  flush_log();
};

function log(record: any) {
  // pay the stringify price immediately...
  const data = log_enc.encode(JSON.stringify(record) + "\n");
  const len = data.byteLength;

  // ensure we don't write past the buffer...
  const now = Date.now();
  if ((buffer_pos + len) > max_log_buffer || (last_flush + max_delay) < now) {
    last_flush = now;
    flush_log();
  }

  // add the log line to the buffer...
  buffer.set(data, buffer_pos);
  buffer_pos += len;
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

const ts_end = performance.now();
console.error({millis: ts_end - ts_start, flushed: count_flush});
