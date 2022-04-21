#!Make
OS=$(shell uname)

ifeq ($(OS),Darwin)
	export UID = 1000
	export GID = 1000
else
	export UID = $(shell id -u)
	export GID = $(shell id -g)
endif

APP_IMAGE_NAME=sms_receiver
DOCKER_COMPOSE_FILE?=docker-compose.yml
DOCKER_COMPOSE=docker-compose --file ${DOCKER_COMPOSE_FILE}
RUN_IN_CONTAINER := docker exec -i ${APP_IMAGE_NAME}
CONTAINER_SHELL := docker exec  -ti ${APP_IMAGE_NAME} sh
DOCKER_ENV := cat /etc/*-release | grep -q "https://alpinelinux.org" && echo true

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | cut -d: -f2- | sort -t: -k 2,2 | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: consume
consume: ## (messenger) consume : consume info channel (strategy)
	@if $(DOCKER_ENV); then \
		bin/console messenger:consume scraper_registration owner_added owner_persisted scrap_errors scrap_stats owner_privacy -vv; \
	else \
		$(RUN_IN_CONTAINER) $(MAKE) $@ ; \
	fi

.PHONY: build
build: ## (docker) build: build service image
	${DOCKER_COMPOSE} pull ${APP_IMAGE_NAME} --include-deps
	${DOCKER_COMPOSE} build ${APP_IMAGE_NAME} --force-rm

.PHONY: down
down: ## (docker) down: stops container
	${DOCKER_COMPOSE} stop ${APP_IMAGE_NAME}

.PHONY: up
up: ## (docker) up: starts container
	${DOCKER_COMPOSE} up -d

.PHONY: app
app: ## (docker) app : container cli
	@${CONTAINER_SHELL}

.PHONY: cc
cc: ## (symfony) cc : clear-cache
	@${CONTAINER_SHELL} -c "php bin/console cache:clear"

.PHONY: ddc
ddc: ## (doctrine) ddc : doctrine-database-create
	@${CONTAINER_SHELL} -c "php bin/console doctrine:database:create"

.PHONY: ddd
ddd: ## (doctrine) ddd : doctrine-drop-database
	@${CONTAINER_SHELL} -c "php bin/console doctrine:database:drop --force"

.PHONY: dsv
dsv: ## (doctrine) dsv : doctrine-schema-validate
	@${CONTAINER_SHELL} -c "php bin/console doctrine:database:drop --force"

.PHONY: dmd
dmd: ## (doctrine) dmd : doctrine-migrations-diff
	@${CONTAINER_SHELL} -c "php bin/console doctrine:migrations:diff"

.PHONY: dmm
dmm: ## (doctrine) dmm : doctrine-migrations-migrate
	@${CONTAINER_SHELL} -c "php bin/console doctrine:migrations:migrate -n"

.PHONY: stan
stan: ## (code) stan : run phpstan
	@if $(DOCKER_ENV); then \
		php -d memory_limit=-1 ./vendor/bin/phpstan analyse -l 5 public src tests; \
	else \
		$(RUN_IN_CONTAINER) $(MAKE) $@ ; \
	fi

.PHONY: cs-fixer
cs-fixer:  ## (code) cs : run php-cs-fixer
	@if $(DOCKER_ENV); then \
		./vendor/bin/php-cs-fixer fix src -v --using-cache=no; \
		./vendor/bin/php-cs-fixer fix tests -v --using-cache=no; \
	else \
		$(RUN_IN_CONTAINER) $(MAKE) $@ ; \
	fi


.PHONY: fixtures
fixtures:
	make db
	APP_ENV=test php bin/console d:f:l -n

.PHONY: unit
unit: ## (code) unit : run phpunit
	@if $(DOCKER_ENV); then \
		make fixtures; \
		./vendor/bin/phpunit; \
	else \
		$(RUN_IN_CONTAINER) $(MAKE) $@ ; \
	fi

.PHONY: unit-watcher
unit-watcher: ## (code) unit : run phpunit
		phpunit-watcher watch

.PHONY: behat
behat:
	@if $(DOCKER_ENV); then \
  		make fixtures ; \
		APP_ENV=test ./vendor/bin/behat --colors; \
	else \
		$(RUN_IN_CONTAINER) $(MAKE) $@ ; \
	fi

.PHONY: db-test
db-test:
	@if $(DOCKER_ENV); then \
		APP_ENV=test php bin/console c:c ;\
		APP_ENV=test php bin/console d:d:d --force ;\
		APP_ENV=test php bin/console d:d:c ;\
		APP_ENV=test php bin/console d:m:m -n ;\
	else \
		$(RUN_IN_CONTAINER) $(MAKE) $@ ; \
	fi

.PHONY: db
db:
	@if $(DOCKER_ENV); then \
		php bin/console c:c ;\
		php bin/console d:d:d --force ;\
		php bin/console d:d:c ;\
		php bin/console d:m:m -n ;\
	else \
		$(RUN_IN_CONTAINER) $(MAKE) $@ ; \
	fi

.PHONY: deploy
deploy:
	gcloud app deploy