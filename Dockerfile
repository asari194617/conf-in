FROM ruby:4.0.9-slim-trixie AS base
WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends libmariadb3 \
    && rm -rf /var/lib/apt/lists/*

FROM base AS build
RUN apt-get update \
    && apt-get install -y --no-install-recommends build-essential pkg-config default-libmysqlclient-dev libyaml-dev \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock .ruby-version ./
RUN --mount=type=cache,id=conf-in-gems,target=/app/vendor/cache,sharing=locked \
    gem install bundler -v "$(awk '/^BUNDLED WITH$/{getline; print $1}' Gemfile.lock)" --no-document \
    && BUNDLE_FROZEN=true bundle install --prefer-local

COPY . .
RUN SECRET_KEY_BASE_DUMMY=1 RAILS_ENV=production bin/rails assets:precompile && rm -f tmp/local_secret.txt

FROM base
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app
EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
