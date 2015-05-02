
VERSION=$(shell cat VERSION)
GEMFILE=ezdraw-$(VERSION).gem
INSTALL_TIMESTAMP=.install.timestamp

default: build

COMMANDS="help version build install test clean"

.PHONY: help version build install test clean

help:
	@echo $(COMMANDS)

version:
	@echo $(VERSION)

build: $(GEMFILE)

install: $(INSTALL_TIMESTAMP)

test: $(INSTALL_TIMESTAMP)
#	ruby examples/test.rb
	ruby examples/test_dsl.rb

clean:
	rm -rf $(INSTALL_TIMESTAMP) $(GEMFILE)

$(GEMFILE): $(wildcard lib/* res/* examples/*)
	gem build ezdraw.gemspec

$(INSTALL_TIMESTAMP): $(GEMFILE)
	sudo gem install $(GEMFILE)
	touch $(INSTALL_TIMESTAMP)

