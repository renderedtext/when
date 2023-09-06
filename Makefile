.PHONY: console test

APP_NAME=when

export MIX_ENV?=dev

BRANCH=$(shell git rev-parse --abbrev-ref HEAD | sed 's/[^a-z]//g')
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
	docker build --target $(DOCKER_BUILD_TARGET) --ssh default --build-arg BUILDKIT_INLINE_CACHE=$(BUILDKIT_INLINE_CACHE) --build-arg MIX_ENV=$(MIX_ENV) --cache-from=$(IMAGE):$(IMAGE_TAG) -t $(IMAGE):$(IMAGE_TAG) .

format: build
	docker run --rm $(VOLUME_BIND) $(CONTAINER_ENV_VARS) $(IMAGE):$(IMAGE_TAG) mix do format $(DRY_RUN), app.config --warnings-as-errors

credo: build
	docker run --rm $(VOLUME_BIND) $(CONTAINER_ENV_VARS)  $(IMAGE):$(IMAGE_TAG) mix credo --all

test: export MIX_ENV=test
test: build
	docker run --rm $(VOLUME_BIND) -v $(PWD)/out:/app/out $(CONTAINER_ENV_VARS)  $(IMAGE):$(IMAGE_TAG) mix test $(FILE) $(FLAGS)

escript.build: build
	docker run --rm --volume $(PWD):/app $(CONTAINER_ENV_VARS)  $(IMAGE):$(IMAGE_TAG) mix escript.build

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
