#!/bin/sh
set -e
setfacl -R -m u:www-data:rwX -m u:"$(whoami)":rwX /srv/app/var
setfacl -dR -m u:www-data:rwX -m u:"$(whoami)":rwX /srv/app/var
exec docker-php-entrypoint "$@"
