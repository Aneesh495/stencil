.PHONY: all test bench verify build serve demo clean help

PYTHON ?= python3

all: test bench

help:
	@echo "Stencil Build & Test Automation Suite"
	@echo "======================================"
	@echo "make test     : Run complete 80-test AS3 verification suite"
	@echo "make bench    : Execute high-throughput computational geometry benchmarks"
	@echo "make verify   : Run full AST parsing and runtime test execution"
	@echo "make build    : Parse and typecheck all ActionScript 3 modules"
	@echo "make demo     : Generate sample vector SVG and binary PDF documents"
	@echo "make serve    : Launch local HTTP server for interactive Web Studio"
	@echo "make clean    : Remove generated test artifacts and scratch files"

test:
	$(PYTHON) tooling/run_tests.py

bench:
	$(PYTHON) bench/benchmark_suite.py

verify:
	$(PYTHON) tooling/as3_parser.py src/ test/
	$(PYTHON) tooling/run_tests.py

build:
	@bash scripts/build.sh

demo:
	@bash scripts/demo.sh

serve:
	$(PYTHON) scripts/serve.py

clean:
	rm -rf dist/ *.pyc __pycache__ .pytest_cache
