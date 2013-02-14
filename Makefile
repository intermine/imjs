# Makefile for the imjs project
#
# Version 1.0
# Alex Kalderimis
# Thu Feb 14 16:29:54 GMT 2013

TASK = default
REPORTER = spec

export PATH := $(find node_modules -name 'bin' -printf %p:)node_modules/.bin:${PATH}

test:
	grunt test

run:
	grunt $(TASK)

test-cov: instrument
	IMJS_COV=1 mocha --reporter html-cov test/mocha/*.coffee > coverage.html; exit 0
	@echo Coverage report generated in coverage.html

xunit: build
	mkdir -p test/results
	mocha --reporter xunit test/mocha/*.coffee > test/results/node.xml
	mocha-phantomjs test/browser/index.html -R xunit > test/results/browser.xml
	@echo Generated test reports in test/results

build:
	grunt build

instrument: build
	@echo Instrumenting source code.
	@jscoverage --no-highlight build build-cov

docs:
	codo -n imjs src

clean:
	rm -rf test/results
	rm -rf build-cov
	rm -rf build
	rm -rf doc
	rm -f coverage.html


.PHONY: test
