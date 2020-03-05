.PHONY: test
test:
	scripts/test
	PRELOAD_GEMS=faraday scripts/test

release:
	rake release