STATS_LOG = stats.log
STATS_CMD = /usr/bin/time -f '%C,,%e,%P,%U,%S,%M,%O' -a -o "$(STATS_LOG)"
SCRIPTS = *.ts *.js

SUB_DIRS = node python

LOG_FILE ?= deno-test.log

LC_ALL = C
export LC_ALL

DENO_DIR = .deno
export DENO_DIR

.PHONY: install clean-install clean clean-stats $(SCRIPTS) $(SUB_DIRS)

.DEFAULT_GOAL := all

install:
	deno cache --check $(SCRIPTS)

clean-install:
	-rm -rf "$(DENO_DIR)"

clean:
	-rm -f deno*.log deno*.out

clean-stats:
	-rm -f "$(STATS_LOG)"

clean-logs: clean
	for d in $(SUB_DIRS); do \
		$(MAKE) -C "$$d" clean; \
	done

*.[jt]s: install
	$(STATS_CMD) deno run "$@" > "$(LOG_FILE)"

all: $(SCRIPTS)

$(SUB_DIRS):
	$(MAKE) -C "$@" all

run-bench: all $(SUB_DIRS)

stats-agg:
	# aggregate stats...
	mlr --icsv --ojson \
		stats1 -a 'p50,stddev' -g 'command,path' -f 'wall_seconds,user_seconds,system_seconds,max_rss_kb' \
		then sort -n 'wall_seconds_p50' \
		then put '$$tool = splitax(splitax($$command, " ")[1], "/")[-1]; $$script = $$path . ($$path == "" ? "" : "/") . splitax($$command, " ")[-1]; $$wall_seconds_stddev = round($$wall_seconds_stddev * 100) / 100; $$user_seconds_stddev = round($$user_seconds_stddev * 100) / 100; $$system_seconds_stddev = round($$system_seconds_stddev * 100) / 100; $$max_rss_mb_p50 = round($$max_rss_kb_p50 / 1024 * 10) / 10; $$max_rss_kb_stddev = round($$max_rss_kb_stddev)' \
		"$(STATS_LOG)" > stats_agg.json

	# generate Markdown table for docs
	mlr --ijson --omd \
		put '$$time_mean = $$wall_seconds_p50 . " (" . $$wall_seconds_stddev . ")"; $$system_mean = $$system_seconds_p50 . " (" . $$system_seconds_stddev . ")"; $$user_mean = $$user_seconds_p50 . " (" . $$user_seconds_stddev . ")"; $$mem = $$max_rss_mb_p50 . " MiB (" . $$max_rss_kb_stddev . " KiB)"' \
		then cut -o -f 'tool,script,time_mean,system_mean,user_mean,mem' \
		then rename 'tool,Tool,script,Script,time_mean,Total Seconds (stddev),system_mean,System Seconds (stddev),user_mean,User Seconds (stddev),mem,RSS Memory (stddev)' \
		stats_agg.json > stats_table.md

	# just print out the data nicely formatted
	mlr --m2p cat stats_table.md

RUNS = 7
run-bench-x: clean-stats clean-logs
	echo "command,path,wall_seconds,cpu_percent,user_seconds,system_seconds,max_rss_kb,fs_out_num" > "$(STATS_LOG)"
	for i in $$(seq 1 $(RUNS)); do \
		sleep 6; \
		$(MAKE) run-bench; \
	done

	# generate statistics
	$(MAKE) stats-agg
