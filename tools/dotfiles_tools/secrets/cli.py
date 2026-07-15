#!/usr/bin/env python3
"""Manage dotfiles keyring secrets: dotfiles secrets set|list|clear|export."""

from __future__ import print_function

import argparse
import getpass
import sys

from dotfiles_tools.secrets_store import (
    SECRET_ENV,
    SECRET_HIDDEN,
    SECRET_LABELS,
    backend_info,
    clear_secret,
    export_env_shell,
    list_secrets,
    set_secret,
)


def cmd_list(_args):
    names = list_secrets()
    print('Backend: {}'.format(backend_info()))
    if not names:
        print('No secrets stored yet.')
        print('Set with:  dotfiles secrets set jira_url')
        print('           dotfiles secrets set jira_email')
        print('           dotfiles secrets set jira_api_token')
        print('           dotfiles secrets set gitlab_url')
        print('           dotfiles secrets set gitlab_token')
        return 0
    for name in sorted(names):
        label = SECRET_LABELS.get(name, name)
        kind = 'hidden' if name in SECRET_HIDDEN else 'identity'
        print('  {}  ({}) [{}]'.format(name, label, kind))
    return 0


def _prompt(name):
    label = SECRET_LABELS.get(name, name)
    if name in SECRET_HIDDEN:
        value = getpass.getpass('Enter {}: '.format(label))
        confirm = getpass.getpass('Confirm: ')
        if value != confirm:
            raise ValueError('mismatch')
        return value
    # URLs / emails: visible input (still stored in keyring)
    try:
        value = raw_input('{}: '.format(label))  # noqa: F821  # py2
    except NameError:
        value = input('{}: '.format(label))
    return value


def cmd_set(args):
    name = args.name
    if name not in SECRET_ENV:
        print('Unknown secret: {}'.format(name), file=sys.stderr)
        print('Valid: {}'.format(', '.join(sorted(SECRET_ENV))), file=sys.stderr)
        return 1
    try:
        value = args.value if args.value else _prompt(name)
    except ValueError:
        print('Mismatch — not stored.', file=sys.stderr)
        return 1
    set_secret(name, value)
    print('Stored: {}'.format(name))
    return 0


def cmd_clear(args):
    name = args.name
    if name not in SECRET_ENV:
        print('Unknown secret: {}'.format(name), file=sys.stderr)
        return 1
    clear_secret(name)
    print('Cleared: {}'.format(name))
    return 0


def cmd_export(args):
    text = export_env_shell()
    if args.check:
        return 0 if text else 1
    if text:
        sys.stdout.write(text + '\n')
    return 0


def build_parser():
    parser = argparse.ArgumentParser(
        description=(
            'Keyring for URLs, emails/usernames, and tokens '
            '(not stored in config.toml).'
        ),
    )
    sub = parser.add_subparsers(dest='command')

    sub.add_parser('list', help='List stored secret names (not values)')

    set_p = sub.add_parser('set', help='Store a secret in OS keyring')
    set_p.add_argument(
        'name',
        choices=sorted(SECRET_ENV.keys()),
        help='Secret name',
    )
    set_p.add_argument('--value', help='Value (else prompt)')

    clear_p = sub.add_parser('clear', help='Remove a secret from keyring')
    clear_p.add_argument('name', choices=sorted(SECRET_ENV.keys()))

    export_p = sub.add_parser(
        'export',
        help='Print export lines for shell eval (cron/CI only; dotfiles loads keyring itself)',
    )
    export_p.add_argument(
        '--check', action='store_true',
        help='Exit 0 if any secret exists',
    )

    return parser


def main(argv=None):
    args = build_parser().parse_args(argv)
    if not args.command:
        build_parser().print_help()
        return 2
    if args.command == 'list':
        return cmd_list(args)
    if args.command == 'set':
        return cmd_set(args)
    if args.command == 'clear':
        return cmd_clear(args)
    if args.command == 'export':
        return cmd_export(args)
    return 1


if __name__ == '__main__':
    raise SystemExit(main())
