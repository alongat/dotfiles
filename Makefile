PACKAGE_GROUPS ?= core

.PHONY: all help install packages packages-all dotfiles test verify clean

all: install

help:
	@echo "Available targets:"
	@echo "  install      - Install core packages and link managed configuration"
	@echo "  packages     - Install PACKAGE_GROUPS (default: core)"
	@echo "  packages-all - Install core, development, and devops groups"
	@echo "  dotfiles     - Back up conflicts and link managed configuration"
	@echo "  test         - Preview package and configuration changes"
	@echo "  verify       - Validate scripts, links, and shell startup"
	@echo "  clean        - Remove broken managed symlinks"

install: packages dotfiles
	@echo "› Omarchy dotfiles installation completed"

packages:
	@./scripts/install-packages.sh $(PACKAGE_GROUPS)

packages-all:
	@./scripts/install-packages.sh core development devops

dotfiles:
	@./scripts/link-configs.sh

test:
	@./scripts/verify.sh --scripts-only
	@echo "› Previewing package installation"
	@./scripts/install-packages.sh --dry-run $(PACKAGE_GROUPS)
	@echo "› Previewing configuration links"
	@./scripts/link-configs.sh --dry-run

verify:
	@./scripts/verify.sh

clean:
	@./scripts/link-configs.sh --clean
