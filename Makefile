.PHONY: build run icons build-release release appcast generate-keys

build:
	bash ./scripts/build-app.sh

run:
	bash ./scripts/run-app.sh

icons:
	bash ./scripts/generate-icons.sh

build-release:
	CONFIGURATION=release INSTALL_APP=0 bash ./scripts/build-release.sh

release:
	bash ./scripts/release.sh $(VERSION)

appcast:
	bash ./scripts/generate-appcast.sh

generate-keys:
	bash ./scripts/generate-keys.sh
