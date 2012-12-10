test:
	./node_modules/.bin/grunt test-node

TASK=default
run:
	./node_modules/.bin/grunt $(TASK)

.PHONY: test
