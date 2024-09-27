from datetime import datetime, timezone
import json
import sys
import time


class LogEncoder(json.JSONEncoder):
    def default(self, obj):
        if isinstance(obj, datetime):
            return obj.isoformat()

        # Let the base class default method raise the TypeError
        return super().default(obj)


def log(message: str, data: dict):
    print(
        json.dumps(
            (data or {}) |
            {
                "asctime": datetime.now(timezone.utc),
                "level": "INFO",
                "message": message,
            },
            cls=LogEncoder,
        )
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
