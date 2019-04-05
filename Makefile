# Makefile Usage:
# make DEPLOYMENT COMMAND
# - where DEPLOYMENT is a folder with a config.nix and state.nixops
# - where COMMAND is passed on to nixops
# - NIXPKGS is built as below
#
# Special:
# make doc - shows html form of options available in config.nix
# make update - updates nixpkgs used for all deployments

DEPLOYMENT := $(word 1,$(MAKECMDGOALS))
COMMAND := $(word 2, $(MAKECMDGOALS))
DEPS := $(shell find ./src ./${DEPLOYMENT} -iname "*.nix" -o -iname "*.nixops" -type f)
RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))

# Hide all targets on CMDLINE
$(eval $(RUN_ARGS):;@:)

$(eval NIXDRV := $(shell nix-instantiate ${CURDIR}/src/nixpkgs.nix --quiet))
$(eval NIXPKGS := nixpkgs=$(shell nix-store -r --quiet $(NIXDRV)))
$(eval OVERLAYS := nixpkgs-overlays=${CURDIR}/src/overlays)
$(eval export NIXOPS_DEPLOYMENT = ${DEPLOYMENT})
$(eval export NIXOPS_STATE = ${DEPLOYMENT}/state.nixops)
$(eval SRC := ${CURDIR}/src)
$(eval DEP := ${CURDIR}/${DEPLOYMENT})
$(eval export NIX_PATH = ${OVERLAYS}:${NIXPKGS}:${SRC}:${DEP})
$(eval export BOTO_USE_ENDPOINT_HEURISTICS = True)

# Build CMD

CMD := exec nix-shell -p nixopsUnstable3
ifeq (,$(COMMAND))
CMD += --run "nixops deploy "
else ifeq (deploy,$(COMMAND))
CMD += --run "nixops ${RUN_ARGS}"
else 
.PHONY: ${DEPLOYMENT}
ifeq (.shell,$(COMMAND))
CMD += --command return
else ifeq (create,$(COMMAND))
CMD += --run "nixops ${RUN_ARGS} '<top-level.nix>'"
else
CMD += --run "nixops ${RUN_ARGS}"
endif
endif

# Allow a touch on DEPLOYMENT to trigger a rebuild
OUT := $(shell test ${DEPLOYMENT} -nt ${DEPLOYMENT}/state.nixops && touch ${DEPLOYMENT}/state.nixops)

# Execute
$(DEPLOYMENT) : ${DEPS}
	@mkdir -p ${DEPLOYMENT}
	${CMD}

doc:
	NIX_PATH=${NIX_PATH} xdg-open $$(nix-build src/options-doc.nix --no-out-link)

options.html:
	cp $$(nix-build -I ${NIX_PATH} src/options-doc.nix --no-out-link) options.html
	sed -i.bak 's#${CURDIR}#.#g' options.html
	rm options.html.bak

update:
	nix-prefetch-git https://github.com/NixOS/nixpkgs.git refs/head/nixos-19.03 > nixpkgs-version.json

help:
	@echo -e "\033[35;1m[*]Usage: make DEPLOYMENT COMMAND"
	@echo -e "    Will run 'nixops COMMAND' with proper environment"
	@echo -e "    Example: 'make local ssh office' will SSH into the office machine of the 'local' deployment"
	@echo -e "    Example: 'make local deploy' will deploy the 'local' environment\033[0m"
	@echo ""
	@exec nix-shell -p nixopsUnstable3 --run "nixops --help"

osx:
	[ -x "`which nix 2>/dev/null`" ] && source <(curl -fsSL https://nixos.org/nix/install)
	source <(curl -fsSL https://raw.githubusercontent.com/LnL7/nix-docker/master/start-docker-nix-build-slave)

.PRECIOUS : ${DEPLOYMENT}/state.nixops
