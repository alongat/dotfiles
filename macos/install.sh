if [ "$(uname)" == "Darwin" ]; then
  echo "› macos softwareupdate"
  sudo softwareupdate -i -a
  $(dirname $0)/defaults.sh
fi

if [ ! -d /etc/pam.d/sudo_local ]; then
  sudo cp $(dirname $0)/sudo_local.template /etc/pam.d/sudo_local
fi

