FROM nginx/unit:1.26.1-php8.1

ENV APP_ENV=prod
ARG TZ=Europe/Paris

RUN apt update && apt upgrade -y \
    && apt-get install -y acl git zip unzip libzip-dev \
    && apt autoremove --purge -y \
    && rm -rf /var/lib/apt/lists/* /etc/apt/sources.list.d/*.list
\
RUN mkdir -p /srv/app log config state && touch log/unit.log
\
RUN set -eux; \
    docker-php-ext-install -j$(nproc) \
        opcache \
        zip \
 	; \
	docker-php-ext-enable \
	    opcache \
        zip \
    ;


# App files
COPY bin /srv/app/bin
COPY config /srv/app/config
COPY public /srv/app/public
COPY src /srv/app/src
COPY .env /srv/app/.env
COPY composer.json /srv/app
COPY composer.lock /srv/app
COPY symfony.lock /srv/app

WORKDIR /srv/app

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER=1

RUN set -eux; \
	mkdir -p var/cache var/log; \
	composer install --prefer-dist --no-progress --no-dev --no-scripts --no-interaction; \
    composer clear-cache; \
	composer dump-autoload --classmap-authoritative; \
	composer run-script post-install-cmd; \
sync


# Config script
COPY --chown=unit:unit ./.docker/unit/config.json /docker-entrypoint.d/


RUN chown -R unit:unit /srv/app

EXPOSE 8080 80