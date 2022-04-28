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

lint:
	$(MAKE) console CMD="mix do credo"

lint-root:
	$(MAKE) console MIX_ENV=test USER=root CMD="mix do local.hex --force, local.rebar --force, deps.get, credo"
