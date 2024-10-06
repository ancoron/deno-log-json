STATS_LOG = stats.log
STATS_CMD = /usr/bin/time -f '%C,,%e,%P,%U,%S,%M,%O' -a -o "$(STATS_LOG)"
SCRIPTS = deno-*.ts deno-*.js

SUB_DIRS = node python

LOG_FILE ?= .local/deno-test.log

LC_ALL = C
export LC_ALL

DENO_DIR = .deno
export DENO_DIR

.PHONY: install clean-install clean clean-stats stats_compare.md $(SCRIPTS) $(SUB_DIRS)

.DEFAULT_GOAL := all

BENCH_CASE ?=

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

$(LOG_FILE):
	mkdir -p "$$(dirname "$(LOG_FILE)")"
	touch "$(LOG_FILE)"

*.[jt]s: install $(LOG_FILE)
	$(STATS_CMD) deno run --allow-read --allow-env --allow-sys "$@" > "$(LOG_FILE)"

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
	[ -z "$(BENCH_CASE)" ] || cp stats_agg.json "stats_agg.$(BENCH_CASE).json"

stats_compare.md: stats_agg.idle.json stats_agg.cpu.json stats_agg.io.json
	mlr --ijson --omd \
		join -j command --lp "cpu_" -f stats_agg.cpu.json \
		then join -j command --lp "io_" -f stats_agg.io.json \
		then cut -o -f 'tool,script,wall_seconds_p50,cpu_wall_seconds_p50,io_wall_seconds_p50,max_rss_mb_p50,cpu_max_rss_mb_p50,io_max_rss_mb_p50' \
		then rename 'tool,Tool,script,Script,wall_seconds_p50,idle,cpu_wall_seconds_p50,cpu,io_wall_seconds_p50,io,max_rss_mb_p50,mem,cpu_max_rss_mb_p50,cpu_mem,io_max_rss_mb_p50,io_mem' \
		then sort -nf 'Tool,io' stats_agg.idle.json > "$@"

stats-compare: stats_compare.md
	mlr --imd --omd \
		put '$$cpu = $$cpu . " (" . (round($$cpu / $$idle * 100) / 100) . ")"; $$io = $$io . " (" . (round($$io / $$idle * 100) / 100) . ")"' \
		then cut -f 'Tool,Script,idle,cpu,io' \
		then rename 'idle,Idle,cpu,CPU (slowdown),io,I/O (slowdown)' \
		stats_compare.md
	echo
	mlr --imd --omd \
		stats1 -g 'Tool' -a 'sum' -f 'idle,cpu,io' \
		then put '$$cpu_sum = round($$cpu_sum / $$idle_sum * 100) / 100; $$io_sum = round($$io_sum / $$idle_sum * 100) / 100; $$avg = round(($$cpu_sum + $$io_sum) / 2 * 100) / 100' \
		then cut -f 'Tool,cpu_sum,io_sum,avg' \
		then sort -nf 'avg' \
		then rename 'cpu_sum,Slowdown (CPU),io_sum,Slowdown (I/O),avg,Slowdown (average)' \
		stats_compare.md
	echo
	mlr --imd --omd \
		stats1 -g 'Tool' -a 'p50,max' -f 'mem,cpu_mem,io_mem' \
		then cut -o -f 'Tool,mem_p50,mem_max,cpu_mem_p50,cpu_mem_max,io_mem_p50,io_mem_max' \
		then sort -nf 'io_mem_p50' \
		then rename 'mem_p50,Idle (median),mem_max,Idle (max),cpu_mem_p50,CPU (median),cpu_mem_max,CPU (max),io_mem_p50,I/O (median),io_mem_max,I/O (max)' \
		stats_compare.md

RUNS = 7
run-bench-x: clean-stats clean-logs
	echo "command,path,wall_seconds,cpu_percent,user_seconds,system_seconds,max_rss_kb,fs_out_num" > "$(STATS_LOG)"
	for i in $$(seq 1 $(RUNS)); do \
		sleep 6; \
		$(MAKE) run-bench; \
	done

	# generate statistics
	$(MAKE) stats-agg
