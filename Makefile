GEM = raygatherer-$(shell ruby -e "require_relative 'lib/raygatherer/version'; puts Raygatherer::VERSION").gem

build: $(GEM)

$(GEM): raygatherer.gemspec lib/**/*.rb exe/*
	gem build raygatherer.gemspec

install: $(GEM)
	gem install $(GEM)

uninstall:
	gem uninstall raygatherer

clean:
	rm -f raygatherer-*.gem

lint:
	bundle exec standardrb

test:
	bundle exec rspec

.PHONY: install uninstall clean test
