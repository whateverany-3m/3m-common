DOCKER_COMPOSE_YML := $(3M_ROOT)/3m-common/docker/docker-compose.yml
DOCKER_COMPOSE_SHELLS ?= 3m-root-/bin/sh lint-root-/bin/bash source-root-/bin/sh target-root-/bin/sh
ENVFILE ?= .env
TARGET_SEMANTIC_VERSION ?= $(TARGET_VERSION)
TARGET_SEMANTIC_RC ?= $(TARGET_SEMANTIC_VERSION)-rc.$(TARGET_BUILD)
TARGET_ENVS ?= TARGET_ENVS=SOURCE_GROUP SOURCE_IMAGE SOURCE_REGISTRY SOURCE_VERSION TARGET_GROUP TARGET_IMAGE TARGET_REGISTRY TARGET_SEMANTIC_RC TARGET_SEMANTIC_VERSION
#
DOCKER_COMPOSE_ARGS ?= $(foreach _t,${TARGET_ENVS},-e "$(_t)=$${$(_t)}")
DOCKER_COMPOSE_RUN := docker-compose --file $(DOCKER_COMPOSE_YML) --project-directory $(3M_ROOT) run --rm
TARGET_ARGS := $(foreach _t,${TARGET_ENVS},--build-arg "$(_t)=$${$(_t)}")
TARGET_DEPS := .env $(foreach _t,${TARGET_ENVS},_env-$(_t) )

export TARGET_SEMANTIC_VERSION
export TARGET_SEMANTIC_RC

###############################################################################
# setup .env file
###############################################################################
ci_env: $(TARGET_DEPS)
	echo "${TARGET_REGISTRY_TOKEN}" | docker login --username "${TARGET_REGISTRY_USER}" --password-stdin "${TARGET_REGISTRY}"
	$(DOCKER_COMPOSE_RUN) $(DOCKER_COMPOSE_ARGS) 3m ./3m-common/scripts/make.sh ci_env
.PHONY: ci_env

###############################################################################
# run everything in CI_JOBS var
###############################################################################
ci_jobs: $(CI_JOBS)
.PHONY: ci_jobs

###############################################################################
# Macro to run targets defined in CI_JOBS in docker-compose services
###############################################################################
define RULE
$(1): $(TARGET_DEPS)
	$(eval CI_JOB = $(word 1,$(subst -, ,$(1)))) \
	$(eval DOCKER_COMPOSE_SERVICE = $(word 2,$(subst -, ,$(1)))) \
	echo "${TARGET_REGISTRY_TOKEN}" | docker login --username "${TARGET_REGISTRY_USER}" --password-stdin "${TARGET_REGISTRY}"
	$(DOCKER_COMPOSE_RUN) $(DOCKER_COMPOSE_ARGS) $(DOCKER_COMPOSE_SERVICE) ./3m-common/scripts/make.sh $(CI_JOB)
.PHONY: $(1)
endef
$(foreach _t,$(CI_JOBS),$(eval $(call RULE,$(_t))))

###############################################################################
# Macro to run shells in docker-compose services
###############################################################################
define RULE
shell_$(1): $(TARGET_DEPS)
	$(eval DOCKER_COMPOSE_SERVICE = $(word 1,$(subst -, ,$(1)))) \
	$(eval SHELL_USER = $(word 2,$(subst -, ,$(1)))) \
	$(eval SERVICE_SHELL = $(word 3,$(subst -, ,$(1)))) \
	$(DOCKER_COMPOSE_RUN) $(DOCKER_COMPOSE_ARGS) --user $(SHELL_USER) --entrypoint "" $(DOCKER_COMPOSE_SERVICE) $(SERVICE_SHELL)
.PHONY: $(1)
endef
$(foreach _t,$(DOCKER_COMPOSE_SHELLS),$(eval $(call RULE,$(_t))))

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

