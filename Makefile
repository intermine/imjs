TASK = default
REPORTER = spec

-init:
	./bin/activate

test: -init
	grunt test

run: -init
	grunt $(TASK)

test-cov: -init prep-coverage
	@IMJS_COV=1 mocha --reporter html-cov test/mocha/*.coffee > coverage.html
	@echo Coverage report generated in coverage.html

prep-coverage: build instrument

build: -init
	grunt build

instrument:
	@if [ -d build-cov ]; then rm -rf build-cov; fi
	@jscoverage --no-highlight build build-cov
	@echo Generated instrumented source code.

docs: -init
	codo -n imjs src

.PHONY: test
