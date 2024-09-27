import logging
from pythonjsonlogger.orjson import OrjsonFormatter
import sys
import time

# see: https://docs.python.org/3/howto/logging.html#optimization
logging._srcfile = None
logging.logThreads = False
logging.logProcesses = False
logging.logAsyncioTasks = False
logging.logMultiprocessing = False

logger = logging.getLogger()
logger.setLevel(logging.INFO)

handler = logging.StreamHandler(sys.stdout)
formatter = OrjsonFormatter("{asctime}{message}{exc_info}", style="{")
handler.setFormatter(formatter)

logger.addHandler(handler)

ts_start = time.time()

for _ in range(0, 1000000):
    logger.info(
        "This is a log message",
        extra={
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
