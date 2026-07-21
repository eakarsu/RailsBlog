FROM ruby:3.4.4-slim AS build
WORKDIR /app
ENV BUNDLE_WITHOUT=development:test BUNDLE_PATH=/usr/local/bundle
RUN apt-get update && apt-get install -y --no-install-recommends build-essential libpq-dev && rm -rf /var/lib/apt/lists/*
COPY Gemfile Gemfile.lock ./
RUN bundle install
COPY . .
RUN SECRET_KEY_BASE=build-only-placeholder-not-used-at-runtime-0000000000000000000000000000 DATABASE_URL=postgresql://unused/unused RAILS_ENV=production bundle exec rails assets:precompile

FROM ruby:3.4.4-slim
WORKDIR /app
ENV RAILS_ENV=production BUNDLE_WITHOUT=development:test BUNDLE_PATH=/usr/local/bundle
RUN apt-get update && apt-get install -y --no-install-recommends libpq5 postgresql-client && rm -rf /var/lib/apt/lists/* \
    && groupadd --system rails && useradd --system --gid rails --create-home rails
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=rails:rails /app /app
USER rails
EXPOSE 3000
ENTRYPOINT ["./bin/start"]
