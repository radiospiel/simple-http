.PHONY: test
test:
	scripts/test
	PRELOAD_GEMS=faraday scripts/test