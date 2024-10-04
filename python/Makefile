STATS_LOG = ../stats.log
GNU_TIME = /usr/bin/time
STATS_CMD = $(GNU_TIME) -f '%C,python,%e,%P,%U,%S,%M,%O' -a -o "$(STATS_LOG)"
SCRIPTS = *.py

BIN_PYTHON = $(shell which python3)
BIN_PYPY = $(shell which pypy3)

LOG_FILE ?= .local/python-test.log

LC_ALL = C
export LC_ALL

.PHONY: install clean-install clean $(SCRIPTS)

.DEFAULT_GOAL := all

.venv:
	$(BIN_PYTHON) -m venv $@
	$@/bin/pip install -r requirements.txt

.venv-pypy:
	virtualenv -p $(BIN_PYPY) $@
	$@/bin/pip install -r requirements-pypy.txt

install: .venv .venv-pypy

clean-install:
	-rm -rf .venv .venv-pypy

clean:
	-rm -f *.log *.out

$(LOG_FILE):
	mkdir -p "$$(dirname "$(LOG_FILE)")"
	touch "$(LOG_FILE)"

*.py: install $(LOG_FILE)
	$(STATS_CMD) .venv/bin/python "$@" > "$(LOG_FILE)"
	[[ "$@" =~ ^orjson.* ]] || $(STATS_CMD) .venv-pypy/bin/pypy "$@" > "$(LOG_FILE)"

all: $(SCRIPTS)
