import * as log from "jsr:@std/log@0.224.7";

const log_enc = new TextEncoder();

class StdoutHandler extends log.BaseHandler {
  constructor(levelName: log.LevelName, options: log.BaseHandlerOptions = {}) {
    super(levelName, options);
  }

  log(msg: string) {
    Deno.stdout.writeSync(log_enc.encode(msg + "\n"));
  }
}


function json_fmt(logRecord: log.LogRecord): string {
  return JSON.stringify({
    level: logRecord.levelName,
    datetime: logRecord.datetime.toISOString(),
    message: logRecord.msg,
    args: flattenArgs(logRecord.args),
  });
}

function flattenArgs(args: unknown[]): unknown {
  if (args.length === 1) {
    return args[0];
  } else if (args.length > 1) {
    return args;
  }
}

log.setup({
  handlers: {
    default: new StdoutHandler("DEBUG", {
      formatter: json_fmt,
    }),
  },
});

const ts_start = performance.now();

for (let i = 0; i < 1000000; i++) {
  log.info(
    "This is a log message",
    {
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
