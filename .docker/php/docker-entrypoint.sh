#!/bin/sh
set -e

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi

if [ "$1" = 'php-fpm' ] || [ "$1" = 'php' ] || [ "$1" = 'bin/console' ]; then
# The first time volumes are mounted, the vendors needs to be reinstalled
  if [ ! -d vendor/ ]; then
      composer install --prefer-dist --no-dev --no-progress --no-interaction
  fi
fi

#setfacl -R -m u:www-data:rwX -m u:"$(whoami)":rwX var
#setfacl -dR -m u:www-data:rwX -m u:"$(whoami)":rwX var

chmod -R 775 var/cache var/log
exec docker-php-entrypoint "$@"
