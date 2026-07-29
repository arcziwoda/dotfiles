#!/bin/sh
# Prints the active Docker context, but only when it is one worth noticing.
#
# Used by starship for both `when` and `command` of the custom.docker_context
# module: exit 1 means "nothing to show", which is how starship hides it.
#
# Reads the context out of Docker's config instead of running `docker context
# show`, which costs ~10ms and would be paid on every single prompt.

# Everyday contexts. Seeing these in the prompt tells you nothing, since they
# are what you are on almost all the time.
SKIP="default desktop-linux orbstack"

ctx="${DOCKER_CONTEXT:-}"
if [ -z "$ctx" ]; then
	ctx=$(sed -n 's/.*"currentContext"[^"]*"\([^"]*\)".*/\1/p' \
		"${DOCKER_CONFIG:-$HOME/.docker}/config.json" 2>/dev/null)
fi

[ -n "$ctx" ] || exit 1

for skip in $SKIP; do
	if [ "$ctx" = "$skip" ]; then
		exit 1
	fi
done

printf '%s' "$ctx"
