PREFIX?=/usr/local
INSTALL_NAME = createTOC

install: build install_bin

build:
	swift package update
	s

install_bin:
	mkdir -p $(PREFIX)/bin
	mv .build/Release/CreateTOC .build/Release/$(INSTALL_NAME)
	install .build/Release/$(INSTALL_NAME) $(PREFIX)/bin

uninstall:
	rm -f $(PREFIX)/bin/$(INSTALL_NAME)
