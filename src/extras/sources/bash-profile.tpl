if [ -n "$BASH_VERSION" ]; then
    [ -f "$HOME/.bashrc" ] && . "$HOME/.bashrc"
fi

# Set PATH so it includes user's private bin if it exists.
[ -d "$HOME/bin" ] && PATH="$HOME/bin:$PATH"

# Add additional environment setup below this line if needed.

export PATH
