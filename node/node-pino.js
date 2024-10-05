const pino = require('pino');

const log = pino({ timestamp: pino.stdTimeFunctions.isoTime }, process.stdout);

const ts_start = performance.now();

for (let i = 0; i < 1000000; i++) {
  log.info(
    {
      msg: "This is a log message",
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
  );
}

const ts_end = performance.now();
console.error({"millis": ts_end - ts_start});
