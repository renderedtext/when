FROM elixir:1.12.3 as base

ARG MIX_ENV=prod
ENV MIX_ENV=$MIX_ENV

RUN echo "Build for $MIX_ENV environment started"

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

FROM base as dev

RUN apt-get install -y --no-install-recommends \
    bash make gnupg openssh-client

COPY .formatter.exs .formatter.exs
COPY .credo.exs .credo.exs

COPY test test

RUN mix compile

CMD [ "/bin/ash",  "-c \"while sleep 1000; do :; done\"" ]
