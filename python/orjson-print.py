from datetime import datetime, timezone
import orjson
import sys
import time


def log(message: str, data: dict):
    print(
        orjson.dumps(
            (data or {}) |
            {
                "asctime": datetime.now(timezone.utc),
                "level": "INFO",
                "message": message,
            },
        ).decode("utf-8")
    )


ts_start = time.time()

for _ in range(0, 1000000):
    log(
        "This is a log message",
        {
            "trace": {
                "trace_id": "925c4bb6ec837bc0",
                "span_id": "057704dfa1fb090e",
            },
            "user_id": "123",
            "roles": [
                "user:write",
                "sales:write",
            ],
            "x-request-id": "458868fc6e4bbd30fd6dd6da5f8828f7",
        },
    )

ts_end = time.time()
print({"millis": (ts_end - ts_start) * 1000}, file=sys.stderr)
