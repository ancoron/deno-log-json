STATS_LOG = ../stats.log
STATS_CMD = /usr/bin/time -f '%C,node,%e,%P,%U,%S,%M,%O' -a -o "$(STATS_LOG)"
SCRIPTS = node-*.js

BIN_NODE = $(shell which node)
BIN_BUN = $(shell which bun)

LOG_FILE ?= .local/node-test.log

LC_ALL = C
export LC_ALL

.PHONY: install clean-install clean $(SCRIPTS)

.DEFAULT_GOAL := all

node_modules:
	npm install

install: node_modules

clean-install:
	-rm -rf node_modules

clean:
	-rm -f *.log *.out

$(LOG_FILE):
	mkdir -p "$$(dirname "$(LOG_FILE)")"
	touch "$(LOG_FILE)"

*.js: install $(LOG_FILE)
	$(STATS_CMD) $(BIN_NODE) "$@" > "$(LOG_FILE)"
	$(STATS_CMD) $(BIN_BUN) run "$@" > "$(LOG_FILE)"

all: $(SCRIPTS)
