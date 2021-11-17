DOCKER_COMPOSE_RUN ?= docker-compose run --rm
DOCKER_COMPOSE_SHELLS ?= 3m-root-/bin/sh lint-root-/bin/bash source-root-/bin/sh target-root-/bin/sh
ENVFILE ?= .env
TARGET_SEMANTIC_VERSION ?= $(TARGET_VERSION)
TARGET_SEMANTIC_RC ?= $(TARGET_SEMANTIC_VERSION)-rc.$(TARGET_BUILD)
TARGET_ENVS ?= TARGET_ENVS=SOURCE_GROUP SOURCE_IMAGE SOURCE_REGISTRY SOURCE_VERSION TARGET_GROUP TARGET_IMAGE TARGET_REGISTRY TARGET_SEMANTIC_RC TARGET_SEMANTIC_VERSION
#
DOCKER_COMPOSE_ARGS ?= $(foreach _t,${TARGET_ENVS},-e "$(_t)=$${$(_t)}")
TARGET_ARGS ?= $(foreach _t,${TARGET_ENVS},--build-arg "$(_t)=$${$(_t)}")
TARGET_DEPS ?= .env $(foreach _t,${TARGET_ENVS},_env-$(_t) )

preaction: $(TARGET_DEPS)
	echo "$(TARGET_REGISTRY_TOKEN)" | docker login --username $(TARGET_REGISTRY_USER) --password-stdin "$(TARGET_REGISTRY)"
	$(DOCKER_COMPOSE_RUN) 3m make _login
.PHONY: preaction

runaction: $(TARGET_DEPS)
	$(DOCKER_COMPOSE_RUN) 3m make _login
	$(DOCKER_COMPOSE_RUN) 3m make _build
	$(DOCKER_COMPOSE_RUN) lint make _lint
	$(DOCKER_COMPOSE_RUN) 3m make _publish
.PHONY: .runaction

postaction: $(TARGET_DEPS)
	$(DOCKER_COMPOSE_RUN) 3m make _logout
.PHONY: postaction

_login:
	echo "INFO: docker login"
	echo "$(TARGET_REGISTRY_TOKEN)" | docker login --username $(TARGET_REGISTRY_USER) --password-stdin "$(TARGET_REGISTRY)"
.PHONY: _login

_build:
	echo "INFO: docker build"
	echo "INFO: TARGET_ARGS=$(TARGET_ARGS)"
	echo "INFO: TARGET_DEPS=$(TARGET_DEPS)"
	docker build \
	  $(TARGET_ARGS) \
		--no-cache \
	  --tag $(TARGET_REGISTRY)$(TARGET_GROUP)$(TARGET_IMAGE):$(TARGET_SEMANTIC_RC) \
	  --tag $(TARGET_REGISTRY)$(TARGET_GROUP)$(TARGET_IMAGE):$(TARGET_SEMANTIC_VERSION) \
	  --file Dockerfile \
	  .
.PHONY: _build

_lint:
	echo "INFO: _lint"
.PHONY: _lint

	
_publish:
	echo "INFO: docker images"
	docker images
	echo "INFO: docker push"
	docker push $(TARGET_REGISTRY)$(TARGET_GROUP)$(TARGET_IMAGE):$(TARGET_SEMANTIC_RC)
	echo "INFO: docker push"
	docker push $(TARGET_REGISTRY)$(TARGET_GROUP)$(TARGET_IMAGE):$(TARGET_SEMANTIC_VERSION)
.PHONY: _publish

_logout:
	echo "INFO: docker logout"
	docker logout "$(TARGET_REGISTRY)"
.PHONY: _logout

###############################################################################
# Macro to run shells from docker-compose services
###############################################################################
define RULE
shell_$(1): $(TARGET_DEPS)
	@echo "INFO: TARGET_DEPS=$(TARGET_DEPS)"
	$(eval DOCKER_COMPOSE_SERVICE = $(word 1,$(subst -, ,$(1)))) \
	$(eval SHELL_USER = $(word 2,$(subst -, ,$(1)))) \
	$(eval SERVICE_SHELL = $(word 3,$(subst -, ,$(1)))) \
	$(DOCKER_COMPOSE_RUN) $(DOCKER_COMPOSE_ARGS) --user $(SHELL_USER) --entrypoint "" $(DOCKER_COMPOSE_SERVICE) $(SERVICE_SHELL)
.PHONY: $(1)
endef
$(foreach _t,$(DOCKER_COMPOSE_SERVICES),$(eval $(call RULE,$(_t))))

_env-%:
	if [ "${${*}}" = "" ]; then \
			echo "Environment variable $* not set"; \
			echo "Please check README.md for variables required"; \
			exit 1; \
	fi
	@echo "INFO: ${*}='${${*}}'";
.PHONY: _env-%

.env:
	@echo "INFO: Checking for .env";
	@ if [ \! -e .env ]; then \
	  echo "INFO: .env doesn't exist, copying $(ENVFILE)"; \
	  cp $(ENVFILE) .env; \
	fi
.PHONY: .env

