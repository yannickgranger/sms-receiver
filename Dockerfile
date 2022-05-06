FROM php:8.1-apache
WORKDIR /srv/app/
# https://getcomposer.org/doc/03-cli.md#composer-allow-superuser
ENV COMPOSER_ALLOW_SUPERUSER=1

COPY public public
COPY src src
COPY bin bin
COPY config config
COPY composer.json composer.lock symfony.lock .env ./
RUN mkdir -p var/log var/cache

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer
COPY ./.docker/php/docker-healthcheck.sh /usr/local/bin/docker-healthcheck
COPY ./.docker/php/docker-entrypoint.sh /usr/local/bin/docker-entrypoint

COPY .docker/apache/site.conf /etc/apache2/sites-available/site.conf

RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -qq install zip unzip acl

RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf && \
    a2enmod rewrite && \
    a2dissite 000-default && \
    a2ensite site && \
    service apache2 restart

RUN ln -s $PHP_INI_DIR/php.ini-production $PHP_INI_DIR/php.ini ; \
set -eux; \
	mkdir -p var/cache var/log; \
	composer install --prefer-dist --no-progress --no-dev --no-scripts --no-interaction; \
    composer clear-cache; \
	composer dump-autoload --classmap-authoritative; \
	composer run-script post-install-cmd; \
chmod +x /usr/local/bin/docker-healthcheck /usr/local/bin/docker-entrypoint; \
sync

ENTRYPOINT ["docker-entrypoint"]

EXPOSE 8080

CMD ["apache2-foreground"]