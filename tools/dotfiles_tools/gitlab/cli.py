#!/usr/bin/env python3
"""GitLab productivity commands (invite, list, test)."""

import argparse
import json
import sys

from dotfiles_tools.config import gitlab_connection
from dotfiles_tools.gitlab import invite as glinvite


def _split(value):
    if not value:
        return []
    return [x.strip() for x in value.split(',') if x.strip()]


def _root_group_id(args, cfg):
    # type: (Any, dict) -> int
    root_id = getattr(args, 'root_group_id', None)
    if root_id is not None:
        return int(root_id)
    cfg_id = cfg.get('root_group_id')
    if cfg_id is not None:
        return int(cfg_id)
    raise SystemExit(
        'root group id required. Set gitlab.root_group_id in local/tools/config.toml '
        'or pass --root-group-id (or export GITLAB_ROOT_GROUP_ID).'
    )


def _access_level(args, cfg):
    # type: (Any, dict) -> int
    if getattr(args, 'access_level', None) is not None:
        return int(args.access_level)
    cfg_level = cfg.get('access_level')
    if cfg_level is not None:
        return int(cfg_level)
    return glinvite.DEVELOPER


def _client(args):
    cfg = gitlab_connection({
        'url': getattr(args, 'url', None),
        'token': getattr(args, 'token', None),
        'email_domain': getattr(args, 'email_domain', None),
    })
    if getattr(args, 'insecure', False):
        cfg['verify_ssl'] = False
    url = cfg.get('url')
    token = cfg.get('token')
    if not url:
        raise SystemExit('GitLab URL required (gitlab.url in config.toml or GITLAB_URL).')
    if not token:
        raise SystemExit(
            'GitLab token required — run: dotfiles secrets set gitlab_token'
        )
    verify = bool(cfg.get('verify_ssl', True))
    return glinvite.gl(url, token, verify_ssl=verify), cfg


def print_test_report(report):
    # type: (dict) -> None
    user = report.get('user') or {}
    print('GitLab API test: OK')
    print('  url:      {}'.format(report.get('url')))
    print('  user:     {} ({})'.format(
        user.get('username') or user.get('name'),
        user.get('id'),
    ))
    if user.get('name'):
        print('  name:     {}'.format(user.get('name')))
    if user.get('email'):
        print('  email:    {}'.format(user.get('email')))
    if user.get('state'):
        print('  state:    {}'.format(user.get('state')))

    group = report.get('root_group')
    if group:
        print('  group:    {} ({})'.format(group.get('full_path'), group.get('id')))


def build_parser():
    parser = argparse.ArgumentParser(
        description='GitLab group/project invite and listing.',
    )
    sub = parser.add_subparsers(dest='command')

    test_p = sub.add_parser('test', help='Verify GitLab URL and token')
    test_p.add_argument(
        '--root-group-id', type=int, metavar='ID',
        help='also verify access to this group (default: gitlab.root_group_id in config)',
    )
    test_p.add_argument('--url', help='GitLab base URL')
    test_p.add_argument('--token', help='GitLab personal access token')
    test_p.add_argument('--insecure', action='store_true')
    test_p.add_argument('--json', action='store_true')

    list_p = sub.add_parser('list', help='List groups and repos under a root group')
    list_p.add_argument(
        '--root-group-id', type=int, metavar='ID',
        help='root group numeric ID (default: gitlab.root_group_id in config)',
    )
    list_p.add_argument('--groups-only', action='store_true')
    list_p.add_argument('--debug', action='store_true')
    list_p.add_argument('--url', help='GitLab base URL')
    list_p.add_argument('--token', help='GitLab personal access token')
    list_p.add_argument('--insecure', action='store_true')

    inv = sub.add_parser('invite', help='Invite users to groups or projects')
    target = inv.add_argument_group('targets')
    target.add_argument('--group-id', dest='group_ids', default='', metavar='ID[,ID...]')
    target.add_argument('--project-id', dest='project_ids', default='', metavar='ID[,ID...]')
    target.add_argument(
        '--root-group-id', type=int, metavar='ID',
        help='root group for --path resolution (default: gitlab.root_group_id in config)',
    )
    target.add_argument('--path', dest='paths', default='', metavar='PATH[,PATH...]')
    inv.add_argument('--users', metavar='USER[,USER...]', required=True)
    inv.add_argument('--url', help='GitLab base URL')
    inv.add_argument('--token', help='GitLab personal access token')
    inv.add_argument('--email-domain', metavar='DOMAIN')
    inv.add_argument(
        '--access-level', type=int, metavar='N',
        help='GitLab access level (default: 30 Developer, or gitlab.access_level in config)',
    )
    inv.add_argument('--dry-run', action='store_true')
    inv.add_argument('--insecure', action='store_true')

    return parser


def main(argv=None):
    args = build_parser().parse_args(argv)
    if not args.command:
        build_parser().print_help()
        return 2
    client, cfg = _client(args)

    if args.command == 'test':
        root_id = getattr(args, 'root_group_id', None)
        if root_id is None:
            root_id = cfg.get('root_group_id')
        try:
            report = glinvite.test_connection(client, root_group_id=root_id)
        except ValueError as exc:
            print('GitLab API test: FAILED', file=sys.stderr)
            print('  {}'.format(exc), file=sys.stderr)
            return 1

        if args.json:
            print(json.dumps(report, indent=2))
        else:
            print_test_report(report)
        return 0

    if args.command == 'list':
        glinvite.list_tree(
            client,
            _root_group_id(args, cfg),
            groups_only=args.groups_only,
            debug=args.debug,
        )
        return 0

    domain = args.email_domain or cfg.get('email_domain')
    root_id = args.root_group_id if args.root_group_id is not None else cfg.get('root_group_id')
    if _split(args.paths) and root_id is None:
        raise SystemExit(
            '--root-group-id required with --path (or set gitlab.root_group_id in config).'
        )
    glinvite.invite(
        client,
        _split(args.users),
        group_ids=_split(args.group_ids),
        project_ids=_split(args.project_ids),
        root_id=root_id,
        paths=_split(args.paths),
        level=_access_level(args, cfg),
        dry_run=args.dry_run,
        domain=domain,
    )
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
