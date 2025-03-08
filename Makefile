.PHONY: build clean release

# renovate: datasource=github-releases depName=firedancer-io/firedancer
FIREDANCER_VERSION ?= v0.406.20113
JOBS_NUM ?= $(shell nproc)

CACHE_IMAGE_NAME = ghcr.io/rocket-sol/firedancer-builder

ENABLE_CACHE ?= 1
ifeq "$(ENABLE_CACHE)" "1"
	DOCKER_BUILD_CACHE_ARGS := --cache-to=type=registry,ref=$(CACHE_IMAGE_NAME):cache,mode=max --cache-from=type=registry,ref=$(CACHE_IMAGE_NAME):cache --cache-from=type=registry,ref=$(CACHE_IMAGE_NAME):latest
endif

build:
	mkdir -p build
	# Useful debug options: --progress=plain --load --target source --no-cache
	docker buildx build . --build-arg JOBS_NUM=$(JOBS_NUM) --build-arg FIREDANCER_VERSION=$(FIREDANCER_VERSION) $(DOCKER_BUILD_CACHE_ARGS) --pull --output=build

clean:
	rm -rf build/*
	rm -f firedancer-*.tar.xz sha256sum.txt sha256sum.txt.sig

release: firedancer-$(FIREDANCER_VERSION).tar.xz sha256sum.txt

sign: sha256sum.txt.sig
	gh release upload $(FIREDANCER_VERSION) sha256sum.txt.sig

publish: release
	gh release create --generate-notes $(FIREDANCER_VERSION) firedancer-$(FIREDANCER_VERSION).tar.xz sha256sum.txt sha256sum.txt.sig

sha256sum.txt: firedancer-$(FIREDANCER_VERSION).tar.xz
	sha256sum firedancer-$(FIREDANCER_VERSION).tar.xz > sha256sum.txt

sha256sum.txt.sig: sha256sum.txt
	gpg --detach-sign $^

firedancer-$(FIREDANCER_VERSION).tar.xz:
	tar cvJf $@ -C build .
