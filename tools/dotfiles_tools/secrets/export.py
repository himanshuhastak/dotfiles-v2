#!/usr/bin/env python3
"""Export keyring secrets as shell exports (used by bin/dotfiles-run)."""

from dotfiles_tools.secrets_store import export_env_shell


def main():
    text = export_env_shell()
    if text:
        print(text)


if __name__ == '__main__':
    main()
