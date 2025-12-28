# Lazy-load rbenv for faster shell startup
# Only initializes when ruby/gem/bundle commands are used

if command -v rbenv &> /dev/null; then
  # Set up PATH to rbenv shims immediately (fast)
  export PATH="$HOME/.rbenv/shims:$PATH"
  
  # Lazy-load full rbenv initialization
  _rbenv_lazy_init() {
    unset -f rbenv ruby gem bundle rake irb
    eval "$(command rbenv init - zsh)"
  }
  
  rbenv() {
    _rbenv_lazy_init
    rbenv "$@"
  }
  
  ruby() {
    _rbenv_lazy_init
    ruby "$@"
  }
  
  gem() {
    _rbenv_lazy_init
    gem "$@"
  }
  
  bundle() {
    _rbenv_lazy_init
    bundle "$@"
  }
  
  rake() {
    _rbenv_lazy_init
    rake "$@"
  }
  
  irb() {
    _rbenv_lazy_init
    irb "$@"
  }
fi
