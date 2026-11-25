.PHONY: build run test icons

build:
	bash ./scripts/build-app.sh

run:
	bash ./scripts/run-app.sh

test:
	swift test

icons:
	bash ./scripts/generate-icons.sh
