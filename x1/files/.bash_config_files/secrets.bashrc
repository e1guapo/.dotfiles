# Load machine-local secrets (OAuth tokens, API keys) into the environment.
#
# The sourced file lives OUTSIDE this repo on purpose. Anything under files/
# is git-tracked and gets copied into /gnu/store by
# home-dotfiles-service-type, and store paths are world-readable (chmod 444).
# Same reason secrets never go in (environment-variables ...) in the manifest.
#
# Format is plain KEY=value lines; `set -a` auto-exports them, so no `export`
# keyword is needed and the same file works as a systemd `EnvironmentFile=`.
_secrets_env="${XDG_CONFIG_HOME:-$HOME/.config}/secrets/env"
if [ -r "$_secrets_env" ]; then
    set -a
    . "$_secrets_env"
    set +a
fi
unset _secrets_env
