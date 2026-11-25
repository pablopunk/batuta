.PHONY: build run icons

build:
	bash ./scripts/build-app.sh

run:
	bash ./scripts/run-app.sh

icons:
	bash ./scripts/generate-icons.sh
