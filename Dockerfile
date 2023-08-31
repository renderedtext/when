FROM elixir:1.14.5 as base

ARG MIX_ENV=prod
ENV MIX_ENV=$MIX_ENV

RUN echo "Build for $MIX_ENV environment started"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git

RUN mix local.hex --force --if-missing && \
    mix local.rebar --force --if-missing

RUN mkdir -p ~/.ssh
RUN touch ~/.ssh/known_hosts
RUN ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

WORKDIR /app

COPY mix.* ./
COPY config config
RUN --mount=type=ssh mix do deps.get, deps.compile

COPY lib lib

FROM base as dev

RUN apt-get install -y --no-install-recommends \
    bash make gnupg openssh-client

COPY .formatter.exs .formatter.exs
COPY .credo.exs .credo.exs
COPY test test

RUN mix compile

CMD [ "/bin/ash",  "-c \"while sleep 1000; do :; done\"" ]
