# Js dependencies
FROM oven/bun:1 AS bun
WORKDIR /app
COPY package.json bun.lock* ./
COPY patches ./patches/
RUN bun install --frozen-lockfile

# Ruby dependencies
FROM ruby:3.4.5-slim-bookworm AS builder
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential git libpq-dev libicu-dev zlib1g-dev libyaml-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local build.sassc '--disable-march-tune-native' \
    && bundle config set --local deployment true \
    && bundle config set --local without 'development test' \
    && bundle install --jobs 4

# Image
FROM ruby:3.4.5-slim-bookworm

ENV APP_PATH=/app \
    RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=true \
    RAILS_SERVE_STATIC_FILES=true \
    RUBY_YJIT_ENABLE=true \
    # We use delayed_job (DB-backed) instead of Sidekiq — no Redis needed for jobs.
    RAILS_QUEUE_ADAPTER=delayed_job \
    # GPP identity — override via env if needed.
    APPLICATION_NAME="Gestionnaire des Processus Projets" \
    APPLICATION_BASE_URL="https://demarche.numerique.gouv.fr" \
    # Default to local filesystem storage; set ACTIVE_STORAGE_SERVICE=amazon for S3.
    ACTIVE_STORAGE_SERVICE=local \
    # Disabled by default; enable only if you have the services configured.
    CLAMAV_ENABLED=disabled \
    SENTRY_ENABLED=disabled \
    LOGRAGE_ENABLED=disabled \
    # Public government API defaults (safe to leave as-is).
    API_ADRESSE_URL="https://data.geopf.fr/geocodage" \
    API_GEO_URL="https://geo.api.gouv.fr" \
    API_EDUCATION_URL="https://data.education.gouv.fr/api/records/1.0" \
    # Placeholder values required for Rails to boot during assets:precompile.
    # All of these are overridden at runtime by docker-compose / .env.
    APP_HOST="localhost:3000" \
    DB_HOST="localhost" \
    DB_DATABASE="gpp_production" \
    DB_USERNAME="gpp" \
    DB_PASSWORD="placeholder" \
    DB_POOL="5" \
    DB_PORT="5432" \
    SECRET_KEY_BASE="placeholder_secret_key_base_replaced_at_runtime_do_not_use" \
    AR_ENCRYPTION_PRIMARY_KEY="placeholder_ar_encryption_primary_key_replaced_at_runtime" \
    AR_ENCRYPTION_KEY_DERIVATION_SALT="placeholder_ar_encryption_salt_replaced_at_runtime_x" \
    OTP_SECRET_KEY="placeholder_otp_secret_key_replaced_at_runtime" \
    INVISIBLE_CAPTCHA_SECRET="placeholder_invisible_captcha_secret_replaced_at_runtime"

# Runtime system packages only
RUN apt-get update && apt-get install -y --no-install-recommends \
      postgresql-client libpq5 \
      libicu72 \
      nodejs \
      poppler-utils imagemagick ghostscript \
      git zip unzip curl \
    && rm -rf /var/lib/apt/lists/*

COPY config/image_magick_policy.xml /etc/ImageMagick-6/policy.xml

# Non-root user; home is the app directory so Bun installs there.
RUN useradd --no-log-init --create-home --home-dir $APP_PATH --shell /bin/bash appuser
USER appuser
WORKDIR $APP_PATH
RUN curl -fsSL https://bun.sh/install | bash
ENV PATH="$APP_PATH/.bun/bin:$PATH"

# Gems
COPY --chown=appuser:appuser --from=builder /app $APP_PATH/
RUN bundle config set --local build.sassc '--disable-march-tune-native' \
    && bundle config set --local deployment true \
    && bundle config set --local without 'development test' \
    && bundle install

COPY --chown=appuser:appuser --from=bun /app/node_modules $APP_PATH/node_modules

COPY --chown=appuser:appuser . $APP_PATH/

RUN NODE_OPTIONS=--max-old-space-size=4000 bundle exec rake assets:precompile

RUN chmod +x bin/docker-entrypoint.sh

EXPOSE 3000
ENTRYPOINT ["bin/docker-entrypoint.sh"]
CMD ["bin/rails", "server", "-b", "0.0.0.0"]
