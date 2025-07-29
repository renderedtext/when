# Define an ARG to parameterize the Erlang version, with an empty default value
ARG ELIXIR_VERSION=1.17.3
ARG ERLANG_VERSION=27

# Conditionally set the base image using the ARG value, or default to "elixir:1.16.3"
FROM elixir:${ELIXIR_VERSION}-otp-${ERLANG_VERSION} as base

ARG MIX_ENV=prod
ENV MIX_ENV=$MIX_ENV

RUN echo "Build for $MIX_ENV environment on elixir:${ELIXIR_VERSION}-otp-${ERLANG_VERSION} started"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git

RUN mix local.hex --force --if-missing && \
    mix local.rebar --force --if-missing

WORKDIR /app

COPY mix.* ./
COPY config config
RUN --mount=type=ssh mix do deps.get, deps.compile

COPY lib lib
COPY src src

FROM base AS dev

RUN apt-get install -y --no-install-recommends \
    bash make gnupg openssh-client

COPY .formatter.exs .formatter.exs
COPY .credo.exs .credo.exs

COPY test test

RUN mix compile

CMD [ "/bin/ash",  "-c \"while sleep 1000; do :; done\"" ]
