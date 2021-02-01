.PHONY: console test

USER=dev
MIX_ENV=dev
HOME_DIR=/home/dev
WORKDIR=$(HOME_DIR)/when
INTERACTIVE_SESSION=\
          -v $$PWD/home_dir:$(HOME_DIR) \
          -v $$PWD/:$(WORKDIR) \
          -e HOME=$(HOME_DIR) \
          -e MIX_ENV=test \
          --workdir=$(WORKDIR) \
          -it renderedtext/elixir-dev:1.6.5-v2 \

CONTAINER_ENV_VARS= \
	-e MIX_ENV=$(MIX_ENV)\
  --user=$(USER)

CMD?=/bin/bash

setup:
	$(MAKE) console USER=root CMD="mix local.hex --force"
	$(MAKE) console USER=root CMD="mix deps.get"
	$(MAKE) console USER=root CMD="mix deps.compile"

console:
	docker run --network=host $(CONTAINER_ENV_VARS) $(INTERACTIVE_SESSION) $(CMD)

test:
	$(MAKE) console USER=root MIX_ENV=test CMD="mix do local.hex --force, local.rebar --force, deps.get, test $(FILE)"

escript.build:
	$(MAKE) console USER=root CMD="mix escript.build"

lint:
	$(MAKE) console CMD="mix do credo"

lint-root:
	$(MAKE) console MIX_ENV=test USER=root CMD="mix do local.hex --force, local.rebar --force, deps.get, credo"

#
# Release process
#
# 1. Checkout the git commit that you want to release. Usually this is the latest head on master.
# 2. Run `make release.minor`. This will create a new tag on Github.
# 3. Semaphore will pick up this tag and release a new binary, and attach it to the release.
#

release.major:
	git fetch --tags
	latest=$$(git tag | sort --version-sort | tail -n 1); new=$$(echo $$latest | cut -c 2- | awk -F '.' '{ print "v" $$1+1 ".0.0" }');          echo $$new; git tag $$new; git push origin $$new

release.minor:
	git fetch --tags
	latest=$$(git tag | sort --version-sort | tail -n 1); new=$$(echo $$latest | cut -c 2- | awk -F '.' '{ print "v" $$1 "." $$2 + 1 ".0" }');  echo $$new; git tag $$new; git push origin $$new

release.patch:
	git fetch --tags
	latest=$$(git tag | sort --version-sort | tail -n 1); new=$$(echo $$latest | cut -c 2- | awk -F '.' '{ print "v" $$1 "." $$2 "." $$3+1 }'); echo $$new; git tag $$new; git push origin $$new
