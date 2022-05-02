#!/bin/sh
set -e

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
    set -- php-fpm "$@"
fi

mkdir -p /srv/app/var/cache /srv/app/var/log
setfacl -R -m u:www-data:rwX -m u:"$(whoami)":rwX /srv/app/var
setfacl -dR -m u:www-data:rwX -m u:"$(whoami)":rwX /srv/app/var

if [ "$1" = 'php-fpm' ] || [ "$1" = 'php' ] || [ "$1" = 'bin/console' ]; then

    # The first time volumes are mounted, the vendors needs to be reinstalled
    if [ ! -d vendor/ ]; then
        composer install --prefer-dist --no-dev --no-progress --no-interaction
    fi

    if [ "$APP_ENV" = 'dev']; then
        mkdir -p /composer
        chown -R "${UID}":"${GID}" /srv
        setfacl -R -m u:www-data:rwX,u:"${UID}":rwX /tmp
        setfacl -dR -m u:www-data:rwX,u:"${UID}":rwX /tmp
        setfacl -R -m u:www-data:rwX,u:"${UID}":rwX /srv/app/var
        setfacl -dR -m u:www-data:rwX,u:"${UID}":rwX /srv/app/var
        mkdir -p /srv/app/var/cache /srv/app/var/log
        setfacl -R -m u:www-data:rwX,u:"$(whoami)":rwX /composer
        setfacl -dR -m u:www-data:rwX,u:"$(whoami)":rwX /composer
        composer install --prefer-dist --no-progress --no-interaction
    fi
fi


setfacl -R -m u:www-data:rwX -m u:"$(whoami)":rwX var
setfacl -dR -m u:www-data:rwX -m u:"$(whoami)":rwX var

exec docker-php-entrypoint "$@"
