#!/usr/bin/env python3
"""dotfiles productivity tools — single entry: python -m dotfiles_tools <cmd>."""

from __future__ import print_function

import sys


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    if not argv or argv[0] in ('-h', '--help', 'help'):
        print(
            'usage: dotfiles <command> …\n'
            '  jira …          create/update/sync/test/validate issues\n'
            '  gitlab …        list / invite / test\n'
            '  secrets …       set|list|clear|export (OS keyring)\n'
            '  bugwarrior …    render|pull|uda\n'
            '  invite …        run local/tools/invite_policy.py\n'
        )
        return 0 if argv and argv[0] in ('-h', '--help', 'help') else 2

    cmd = argv[0]
    rest = argv[1:]

    if cmd == 'jira':
        from dotfiles_tools.jira.cli import main as jira_main
        return jira_main(rest)
    if cmd == 'gitlab':
        from dotfiles_tools.gitlab.cli import main as gitlab_main
        return gitlab_main(rest)
    if cmd == 'secrets':
        from dotfiles_tools.secrets.cli import main as secrets_main
        return secrets_main(rest)
    if cmd in ('bugwarrior', 'bw'):
        from dotfiles_tools.bugwarrior.cli import main as bw_main
        return bw_main(rest)
    if cmd == 'invite':
        from dotfiles_tools.invite import main as invite_main
        return invite_main(rest)

    print('unknown command: {}'.format(cmd), file=sys.stderr)
    print('try: jira | gitlab | secrets | bugwarrior | invite', file=sys.stderr)
    return 2


if __name__ == '__main__':
    raise SystemExit(main())
