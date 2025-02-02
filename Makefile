.PHONY: build clean

VERSION ?= $(shell git rev-parse HEAD)

build:
	mkdir -p build
	docker build . --output=build

clean:
	rm -rf build/*

release: firedancer-$(VERSION).tar.xz sha256sum.txt sha256sum.txt.sig

sha256sum.txt: firedancer-$(VERSION).tar.xz
	sha256sum firedancer-$(VERSION).tar.xz > sha256sum.txt

sha256sum.txt.sig: sha256sum.txt
	gpg --detach-sign $^

firedancer-$(VERSION).tar.xz:
	tar cvJf $@ -C build .
