DOTFILES = $(shell find -H $(CURDIR) -maxdepth 2 -name '*.symlink' -not -path "*.git*")
BACKUP_DIR = $(HOME)/.dotfiles-backup/$(shell date +%Y%m%d-%H%M%S)

.PHONY: all dotfiles install backup clean test help
all: dotfiles install

help:
	@echo "Available targets:"
	@echo "  all      - Install dotfiles and run all installers"
	@echo "  dotfiles - Create symlinks for dotfiles"
	@echo "  install  - Run all install.sh scripts"
	@echo "  backup   - Backup existing dotfiles"
	@echo "  clean    - Remove broken symlinks"
	@echo "  test     - Test installation without making changes"
	@echo "  help     - Show this help message"

backup:
	@echo "› Creating backup directory: $(BACKUP_DIR)"
	@mkdir -p $(BACKUP_DIR)
	@$(foreach src,$(DOTFILES), \
		if [ -f $(HOME)/.$(shell basename $(subst .symlink,,$(src))) ] && [ ! -L $(HOME)/.$(shell basename $(subst .symlink,,$(src))) ]; then \
			echo "  Backing up ~/.$(shell basename $(subst .symlink,,$(src)))"; \
			cp $(HOME)/.$(shell basename $(subst .symlink,,$(src))) $(BACKUP_DIR)/; \
		fi;)
	@echo "› Backup completed in $(BACKUP_DIR)"

dotfiles: backup
	@echo "› Installing dotfiles"
	@$(foreach src,$(DOTFILES), \
		echo "  Linking $(src) -> $(HOME)/.$(shell basename $(subst .symlink,,$(src)))"; \
		ln -sfn $(src) $(HOME)/.$(shell basename $(subst .symlink,,$(src))) || { echo "ERROR: Failed to link $(src)"; exit 1; };)
	@echo "› Dotfiles installation completed"

install:
	@echo "› Installing Homebrew"
	@if [ -f ./brew/install.sh ]; then \
		echo "  Running brew/install.sh"; \
		sh -c "./brew/install.sh" || { echo "ERROR: Homebrew installation failed"; exit 1; }; \
	else \
		echo "WARNING: brew/install.sh not found, skipping Homebrew installation"; \
	fi
	@echo "› Running brew bundle"
	@if command -v brew >/dev/null 2>&1; then \
		brew bundle || { echo "ERROR: Brew bundle failed"; exit 1; }; \
	else \
		echo "ERROR: Homebrew not available for brew bundle"; exit 1; \
	fi
	@echo "› Running remaining install scripts"
	@if [ ! -d ~/.config ]; then \
		echo "  Creating ~/.config directory"; \
		mkdir -p ~/.config || { echo "ERROR: Failed to create ~/.config"; exit 1; }; \
	fi
	@install_count=0; \
	failed_count=0; \
	for script in $$(find . -name install.sh | grep -v './brew/install.sh'); do \
		echo "  Running $$script"; \
		if sh -c "$$script"; then \
			install_count=$$((install_count + 1)); \
		else \
			echo "ERROR: $$script failed"; \
			failed_count=$$((failed_count + 1)); \
		fi; \
	done; \
	echo "› Install scripts completed: $$install_count succeeded, $$failed_count failed"; \
	if [ $$failed_count -gt 0 ]; then exit 1; fi
	@echo "› Installation completed successfully"

clean:
	@echo "› Cleaning broken symlinks"
	@$(foreach src,$(DOTFILES), \
		if [ -L $(HOME)/.$(shell basename $(subst .symlink,,$(src))) ] && [ ! -e $(HOME)/.$(shell basename $(subst .symlink,,$(src))) ]; then \
			echo "  Removing broken symlink: ~/.$(shell basename $(subst .symlink,,$(src)))"; \
			rm $(HOME)/.$(shell basename $(subst .symlink,,$(src))); \
		fi;)

test:
	@echo "› Testing dotfiles installation (dry run)"
	@echo "Files that would be symlinked:"
	@$(foreach src,$(DOTFILES), \
		echo "  $(src) -> $(HOME)/.$(shell basename $(subst .symlink,,$(src)))";)
	@echo "Install scripts that would be executed:"
	@find . -name install.sh | sort
	@echo "› Test completed"
