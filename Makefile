TASK = default
REPORTER = spec

-init:
	. ./bin/activate

test: -init
	grunt test

run: -init
	grunt $(TASK)

test-cov: -init instrument
	IMJS_COV=1 mocha --reporter html-cov test/mocha/*.coffee > coverage.html
	@echo Coverage report generated in coverage.html

build: -init
	grunt build

instrument: build
	@if [ -d build-cov ]; then rm -rf build-cov; fi
	@jscoverage --no-highlight build build-cov
	@echo Generated instrumented source code.

docs: -init
	codo -n imjs src

.PHONY: test
