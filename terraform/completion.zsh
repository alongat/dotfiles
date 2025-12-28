# Lazy-load terraform completion for faster shell startup
if command -v terraform &> /dev/null; then
  terraform() {
    unfunction terraform
    complete -o nospace -C terraform terraform
    terraform "$@"
  }
fi
