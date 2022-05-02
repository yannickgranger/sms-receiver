ARG PHP_VERSION=8.1.4

FROM php:${PHP_VERSION}-fpm-alpine

ARG TZ=Europe/Stockholm
ARG APP_DIR
ARG APP_ENV=dev

ENV TZ=$TZ
ENV APP_ENV=dev

# non-persistent / build deps
RUN apk add --no-cache --virtual .build-deps \
            autoconf \
    		file \
    		gettext \
    		git \
            g++ \
            gcc \
  ;
 \

# persistent / runtime deps
RUN apk add --no-cache \
		acl \
		fcgi \
		file \
		gettext \
		git \
        gnu-libiconv \
        tzdata \
        unzip \
;
RUN set -eux; \
	apk add --no-cache --virtual .build-deps \
		$PHPIZE_DEPS \
        oniguruma-dev \
		libzip-dev \
		zlib-dev \
	; \
	\
	docker-php-ext-configure zip; \
	docker-php-ext-install -j$(nproc) \
        mbstring \
        opcache \
        zip \
	; \
	docker-php-ext-enable \
		opcache \
        mbstring \
        zip \
	; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --no-cache --virtual .phpexts-rundeps $runDeps; \
	\
	apk del .build-deps

HEALTHCHECK --interval=10s --timeout=3s --retries=3 CMD ["docker-healthcheck"]

WORKDIR /srv/app

# Copy only what we need
COPY ${APP_DIR}/bin bin/
COPY ${APP_DIR}/config config/
COPY ${APP_DIR}/public public/
COPY ${APP_DIR}/src src/
COPY ${APP_DIR}/composer.json ${APP_DIR}/composer.lock ${APP_DIR}/.env ./

# App conf
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
COPY ./.docker/php/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf
COPY ./.docker/php/docker-healthcheck.sh /usr/local/bin/docker-healthcheck
COPY ./.docker/php/conf.d/symfony.prod.ini $PHP_INI_DIR/conf.d/symfony.ini
COPY ./.docker/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh


# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER=1

RUN ln -s $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini ; \
set -eux; \
	mkdir -p var/cache var/log; \
	composer install --prefer-dist --no-progress --no-dev --no-scripts --no-interaction; \
    composer clear-cache; \
	composer dump-autoload --classmap-authoritative; \
	composer run-script post-install-cmd; \
chmod +x /usr/local/bin/docker-healthcheck /usr/local/bin/docker-entrypoint.sh; \
cp /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone \
sync

# Socket
VOLUME /var/run/php

ENTRYPOINT ["docker-entrypoint.sh"]

CMD ["php-fpm"]
