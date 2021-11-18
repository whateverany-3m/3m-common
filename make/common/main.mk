DOCKER_COMPOSE_YML := $(3M_ROOT)/3m-common/docker/docker-compose.yml
DOCKER_COMPOSE_SHELLS ?= 3m-root-/bin/sh lint-root-/bin/bash source-root-/bin/sh target-root-/bin/sh
ENVFILE ?= .env
ENVFILE_DEFAULTS ?= .env.template
TARGET_REGISTRY ?= ghcr.io
TARGET_SEMANTIC_VERSION ?= $(TARGET_VERSION)
TARGET_SEMANTIC_RC ?= $(TARGET_SEMANTIC_VERSION)-rc.$(TARGET_BUILD)
CI_ENVS ?= CI_DEBUG DOCKER_ARGS SOURCE_GROUP SOURCE_IMAGE SOURCE_REGISTRY SOURCE_VERSION TARGET_GROUP TARGET_IMAGE TARGET_REGISTRY TARGET_SEMANTIC_RC TARGET_SEMANTIC_VERSION
#
DOCKER_ARGS := $(foreach _t,${CI_ENVS},-e $(_t)="$${$(_t)}")
DOCKER_COMPOSE_RUN := docker-compose --file $(DOCKER_COMPOSE_YML) --project-directory $(3M_ROOT) run --rm
TARGET_DEPS := .env $(foreach _t,${CI_ENVS},_env-$(_t) )

export DOCKER_ARGS
export TARGET_SEMANTIC_VERSION
export TARGET_SEMANTIC_RC

###############################################################################
# setup .env file
###############################################################################
ci_auth:
	echo "$(TARGET_REGISTRY_TOKEN)" | docker login --username "$(TARGET_REGISTRY_USER)" --password-stdin "$(TARGET_REGISTRY)"
.PHONY: ci_auth

ci_env: ci_auth .env
	$(DOCKER_COMPOSE_RUN) $(DOCKER_ARGS) make ./3m-common/scripts/make.sh ci_env
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
$(1): ci_auth $(TARGET_DEPS)
	$(eval CI_JOB = $(word 1,$(subst -, ,$(1))))
	$(eval DOCKER_COMPOSE_SERVICE = $(word 2,$(subst -, ,$(1))))
	$(DOCKER_COMPOSE_RUN) $(DOCKER_ARGS) $(DOCKER_COMPOSE_SERVICE) ./3m-common/scripts/make.sh $(CI_JOB)
.PHONY: $(1)
endef
$(foreach _t,$(CI_JOBS),$(eval $(call RULE,$(_t))))

###############################################################################
# Macro to run shells in docker-compose services
###############################################################################
define RULE
shell_$(1): $(TARGET_DEPS)
	$(eval DOCKER_COMPOSE_SERVICE = $(word 1,$(subst -, ,$(1))))
	$(eval SHELL_USER = $(word 2,$(subst -, ,$(1))))
	$(eval SERVICE_SHELL = $(word 3,$(subst -, ,$(1))))
	$(DOCKER_COMPOSE_RUN) $(DOCKER_ARGS) --user $(SHELL_USER) --entrypoint "" $(DOCKER_COMPOSE_SERVICE) $(SERVICE_SHELL)
.PHONY: $(1)
endef
$(foreach _t,$(DOCKER_COMPOSE_SHELLS),$(eval $(call RULE,$(_t))))

_env-%: ci_auth
	$(DOCKER_COMPOSE_RUN) -e $(*)="$(subst $\",,$($(*)))" make /bin/sh -c 'echo "INFO: Checking for $(*)";\
		if [[ -z "$${$(*)+set}" ]]; then \
      echo "ERROR: Environment variable $(*) not set"; \
      exit 1; \
    else \
      echo "INFO: $(*) is set" ;\
    fi'
.PHONY: _env-%

.env: ci_auth
	$(DOCKER_COMPOSE_RUN) -e "GITHUB_ENV=${GITHUB_ENV}" make /bin/sh -c 'set -x ;\
		echo "INFO: Checking for .env";\
		if [[ $\! -e "$(ENVFILE)" ]]; then \
		  if [[ -e "${GITHUB_ENV}" ]]; then \
		    echo "INFO: Using ${GITHUB_ENV} for $(ENVFILE)" ;\
			  cp ${GITHUB_ENV} $(ENVFILE) ;\
			else \
		    echo "INFO: .env doesn$'t exist, copying .env.template to $(ENVFILE)" ;\
			  cp .env.template $(ENVFILE) ;\
			fi \
    fi'
.PHONY: .env

