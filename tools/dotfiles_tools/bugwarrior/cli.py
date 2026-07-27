#!/usr/bin/env python3
"""Bugwarrior config render and helper commands."""

import argparse
import os
import subprocess
import sys

from dotfiles_tools.bugwarrior.render import RenderError, write_bugwarriorrc
from dotfiles_tools.config import (
    bugwarrior_output_path,
    dotfiles_dir,
    ensure_bugwarrior_env,
)
from dotfiles_tools.secrets_store import export_to_environ


def _bin(name):
    tools = os.path.join(dotfiles_dir(), 'var', 'tools', 'bin', name)
    if os.path.isfile(tools):
        return tools
    return name


def cmd_render(args):
    try:
        if args.dry_run or args.stdout:
            content = write_bugwarriorrc(path=args.output, dry_run=True)
            sys.stdout.write(content)
            return 0
        path = write_bugwarriorrc(path=args.output, dry_run=False)
    except RenderError as exc:
        print('render failed: {}'.format(exc), file=sys.stderr)
        return 1
    print('Wrote {}'.format(path))
    print('Tokens:  dotfiles secrets set jira_api_token | gitlab_token')
    print('BUGWARRIORRC auto-set when this file exists (no local.sh needed).')
    return 0


def cmd_pull(args):
    rc = bugwarrior_output_path()
    if not os.path.isfile(rc):
        print('{} not found — run: dotfiles bugwarrior render'.format(rc), file=sys.stderr)
        return 1
    export_to_environ()
    ensure_bugwarrior_env()
    env = os.environ.copy()
    env['BUGWARRIORRC'] = rc
    cmd = [_bin('bugwarrior-pull')]
    if args.verbose:
        cmd.append('-v')
    if args.dry_run:
        cmd.append('--dry-run')
    return subprocess.call(cmd, env=env)


def cmd_uda(_args):
    return subprocess.call([_bin('bugwarrior-uda')])


def build_parser():
    parser = argparse.ArgumentParser(description='Bugwarrior sync configuration.')
    sub = parser.add_subparsers(dest='command')

    render = sub.add_parser('render', help='Generate bugwarriorrc from config.toml')
    render.add_argument('--output', help='Output path (default: local/tools/bugwarriorrc)')
    render.add_argument('--dry-run', action='store_true', help='Print to stdout only')
    render.add_argument('--stdout', action='store_true', help='Alias for --dry-run')

    pull = sub.add_parser('pull', help='Run bugwarrior-pull using generated config')
    pull.add_argument('-v', '--verbose', action='store_true')
    pull.add_argument('--dry-run', action='store_true')

    sub.add_parser('uda', help='Print taskrc UDA definitions for bugwarrior')

    return parser


def main(argv=None):
    args = build_parser().parse_args(argv)
    if not args.command:
        build_parser().print_help()
        return 2
    if args.command == 'render':
        return cmd_render(args)
    if args.command == 'pull':
        return cmd_pull(args)
    if args.command == 'uda':
        return cmd_uda(args)
    return 1


if __name__ == '__main__':
    raise SystemExit(main())
