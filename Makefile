.PHONY: build clean release

FIREDANCER_VERSION ?= v0.403.20113

build:
	mkdir -p build
	docker build . --build-arg FIREDANCER_VERSION=$(FIREDANCER_VERSION) --output=build --pull

clean:
	rm -rf build/*

release: firedancer-$(FIREDANCER_VERSION).tar.xz sha256sum.txt sha256sum.txt.sig

publish: release
	gh release create --generate-notes $(FIREDANCER_VERSION) firedancer-$(FIREDANCER_VERSION).tar.xz sha256sum.txt sha256sum.txt.sig

sha256sum.txt: firedancer-$(FIREDANCER_VERSION).tar.xz
	sha256sum firedancer-$(FIREDANCER_VERSION).tar.xz > sha256sum.txt

sha256sum.txt.sig: sha256sum.txt
	gpg --detach-sign $^

firedancer-$(FIREDANCER_VERSION).tar.xz:
	tar cvJf $@ -C build .
