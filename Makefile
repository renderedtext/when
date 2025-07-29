.PHONY: console test test.matrix

APP_NAME=when

export MIX_ENV?=dev

BRANCH := $(shell branch=$$(git rev-parse --abbrev-ref HEAD); \
                if [ "$$branch" = "HEAD" ]; then \
                    echo "master"; \
                else \
                    echo "$$branch" | sed 's/[^a-z]//g'; \
                fi)
SECURITY_TOOLBOX_BRANCH?=master
SECURITY_TOOLBOX_TMP_DIR?=/tmp/security-toolbox
REGISTRY_HOST?=local
IMAGE?=$(REGISTRY_HOST)/$(APP_NAME)/$(BRANCH)
MASTER_IMAGE?=$(REGISTRY_HOST)/$(APP_NAME)/master
IMAGE_TAG?=$(MIX_ENV)

DOCKER_BUILD_TARGET?=dev

CONTAINER_ENV_VARS= \
  -e CI=$(CI) \
  -e MIX_ENV=$(MIX_ENV) \

export DOCKER_BUILDKIT=1
BUILDKIT_INLINE_CACHE=1

# Localy we want to bind volumes we're working on. On CI environment this is not necessary and would only slow us down. The data is already on the host.
ifeq ($(CI),)
	VOLUME_BIND?=--volume $(PWD):/app
	export BUILDKIT_INLINE_CACHE=0
endif

ifneq ($(CI),)
	DRY_RUN?=--dry-run --check-formatted
endif

build:
	docker build --target $(DOCKER_BUILD_TARGET) --ssh default --build-arg BUILDKIT_INLINE_CACHE=$(BUILDKIT_INLINE_CACHE) \
	             --build-arg MIX_ENV=$(MIX_ENV) --build-arg ERLANG_VERSION=$(ERLANG_VERSION) --build-arg ELIXIR_VERSION=$(ELIXIR_VERSION) \
				 --cache-from=$(IMAGE):$(IMAGE_TAG) -t $(IMAGE):$(IMAGE_TAG) .

format: ERLANG_VERSION=26
format: ELIXIR_VERSION=1.16.3
format: build
	docker run --rm $(VOLUME_BIND) $(CONTAINER_ENV_VARS) $(IMAGE):$(IMAGE_TAG) mix do format $(DRY_RUN), app.config --warnings-as-errors

credo: ERLANG_VERSION=26
credo: ELIXIR_VERSION=1.16.3
credo: build
	docker run --rm $(VOLUME_BIND) $(CONTAINER_ENV_VARS)  $(IMAGE):$(IMAGE_TAG) mix credo --all

test.setup: export MIX_ENV=test
test.setup: build
	$(MAKE) cmd CMD="mix do deps.get, deps.compile"

test: export MIX_ENV=test
test:
	docker run --rm $(VOLUME_BIND) -v $(PWD)/out:/app/out $(CONTAINER_ENV_VARS) $(IMAGE):$(IMAGE_TAG) mix test $(FILE) $(FLAGS)

# Run tests on all combinations of Erlang and Elixir versions
test.matrix: export MIX_ENV=test
test.matrix:
	@echo "Running tests on all Erlang/Elixir combinations"
	@for erlang_version in 24 25 26 27; do \
		for elixir_version in 1.14.5 1.15.7 1.16.3 1.17.3; do \
			echo "\n\n=== Testing with Erlang $$erlang_version and Elixir $$elixir_version ==="; \
			ERLANG_VERSION=$$erlang_version ELIXIR_VERSION=$$elixir_version $(MAKE) build && \
			ERLANG_VERSION=$$erlang_version ELIXIR_VERSION=$$elixir_version $(MAKE) test || exit 1; \
		done; \
	done

escript.build:
	docker run --rm --volume $(PWD):/app $(CONTAINER_ENV_VARS) $(IMAGE):$(IMAGE_TAG) mix escript.build

prod.setup: export MIX_ENV=prod
prod.setup: build
	docker run --rm --volume $(PWD):/app $(CONTAINER_ENV_VARS) $(IMAGE):$(IMAGE_TAG) mix do deps.get, deps.compile

cmd: build
	docker run --rm $(VOLUME_BIND) $(CONTAINER_ENV_VARS) $(IMAGE):$(IMAGE_TAG) $(CMD)

dev.setup:
	$(MAKE) cmd CMD="mix do deps.get, deps.compile"

# Security checks. On CI environment - we're using sem-version to provide a ruby version.
check.prepare:
	rm -rf $(SECURITY_TOOLBOX_TMP_DIR)
	git clone git@github.com:renderedtext/security-toolbox.git $(SECURITY_TOOLBOX_TMP_DIR) && (cd $(SECURITY_TOOLBOX_TMP_DIR) && git checkout $(SECURITY_TOOLBOX_BRANCH) && cd -)

# A few things we're ignoring here:
# - TLS doesn't happen on the pod level, so we ignore the HTTPS warning
check.static: check.prepare
ifeq ($(CI),)
# We're running on local machine
	docker run -it -v $$(pwd):/app \
		-v $(SECURITY_TOOLBOX_TMP_DIR):$(SECURITY_TOOLBOX_TMP_DIR) \
		registry.semaphoreci.com/ruby:2.7 \
		bash -c 'cd /app && $(SECURITY_TOOLBOX_TMP_DIR)/code --language elixir -d'
else
# We're running on Semaphore
	$(SECURITY_TOOLBOX_TMP_DIR)/code --language elixir -d
endif

check.deps: check.prepare
ifeq ($(CI),)
# We're running on local machine
	docker run -it -v $$(pwd):/app \
		-v $(SECURITY_TOOLBOX_TMP_DIR):$(SECURITY_TOOLBOX_TMP_DIR) \
		registry.semaphoreci.com/ruby:2.7 \
		bash -c 'cd /app && $(SECURITY_TOOLBOX_TMP_DIR)/dependencies -d --language elixir'
else
# We're running on Semaphore
	$(SECURITY_TOOLBOX_TMP_DIR)/dependencies -d --language elixir
endif


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
