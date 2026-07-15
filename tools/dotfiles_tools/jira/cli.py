#!/usr/bin/env python3
"""Create or update JIRA issues from YAML via the public REST API."""

import argparse
import json
import sys
from typing import Any, Optional

from dotfiles_tools.config import jira_connection
from dotfiles_tools.jira.client import JiraError, client_from_mapping
from dotfiles_tools.jira.yaml_lib import (
    YamlError,
    execute_yaml,
    expand_issues,
    expand_updates,
    load_yaml,
    validate_config,
)


def build_parser():
    # type: () -> argparse.ArgumentParser
    parser = argparse.ArgumentParser(
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
        description='Create or update JIRA issues from YAML via REST API.',
    )
    parser.add_argument(
        'command',
        choices=['test', 'create', 'update', 'sync', 'validate'],
        help='What to do',
    )
    parser.add_argument(
        'yaml_file',
        nargs='?',
        help='YAML definition file (not needed for test)',
    )
    parser.add_argument('--url', help='JIRA base URL (overrides config / JIRA_URL)')
    parser.add_argument('--email', help='JIRA account email (Cloud)')
    parser.add_argument('--token', help='JIRA API token')
    parser.add_argument('--user', help='JIRA username (Server/Data Center)')
    parser.add_argument('--password', help='JIRA password (Server/Data Center)')
    parser.add_argument('--api-version', type=int, choices=[2, 3], help='Force REST API version')
    parser.add_argument('--insecure', action='store_true', help='Disable TLS certificate verification')
    parser.add_argument('--project', help='For test: verify project access and create metadata')
    parser.add_argument('--issue', help='For test: verify read access to an existing issue key')
    parser.add_argument('--issuetype', help='For test: limit create-metadata lookup to one issue type')
    parser.add_argument('--dry-run', action='store_true', help='Validate and print actions only')
    parser.add_argument('--continue-on-error', action='store_true', help='Keep going after a failure')
    parser.add_argument('--json', action='store_true', help='Print results as JSON')
    return parser


def build_client(args, config=None):
    # type: (argparse.Namespace, Optional[dict]) -> Any
    connection = dict(jira_connection())
    connection.update((config or {}).get('connection') or {})
    if args.url:
        connection['url'] = args.url
    if args.email:
        connection['email'] = args.email
    if args.token:
        connection['token'] = args.token
    if args.user:
        connection['username'] = args.user
    if args.password:
        connection['password'] = args.password
    if args.api_version:
        connection['api_version'] = args.api_version
    if args.insecure:
        connection['verify_ssl'] = False
    return client_from_mapping(connection)


def print_test_report(report):
    # type: (dict) -> None
    user = report.get('user') or {}
    print('JIRA API test: OK')
    print('  url:         {}'.format(report.get('url')))
    print('  api_version: {}'.format(report.get('api_version')))
    print('  user:        {}'.format(user.get('name') or user.get('email') or user.get('accountId')))
    if user.get('email'):
        print('  email:       {}'.format(user.get('email')))

    project = report.get('project')
    if project:
        print('  project:     {} ({})'.format(project.get('key'), project.get('name')))
        print('  can_create:  {}'.format(report.get('can_create')))
        meta = report.get('create_meta') or []
        if isinstance(meta, list):
            for item in meta:
                req = ', '.join(item.get('required_fields') or []) or '-'
                print('    issuetype: {}  required_fields: {}'.format(item.get('name'), req))

    issue = report.get('issue')
    if issue:
        print('  issue:       {} [{}] {}'.format(
            issue.get('key'), issue.get('status'), issue.get('summary')
        ))


def print_results(results):
    # type: (dict) -> None
    for item in results.get('created', []):
        if item.get('error'):
            print('CREATE FAILED: {} ({})'.format(item.get('summary'), item['error']))
        elif item.get('dry_run'):
            print('DRY-RUN CREATE: project={} summary={} fields={}'.format(
                item.get('project'), item.get('summary'), ','.join(item.get('fields', []))
            ))
        else:
            print('Created: {}  {}'.format(item.get('url'), item.get('summary')))

    for item in results.get('updated', []):
        if item.get('error'):
            print('UPDATE FAILED: {} ({})'.format(item.get('key'), item['error']))
        elif item.get('dry_run'):
            print('DRY-RUN UPDATE: {} changed=[{}]'.format(
                item.get('key'), ','.join(item.get('changed', []))
            ))
        else:
            print('Updated: {} changed=[{}]'.format(
                item.get('url'), ','.join(item.get('changed', []))
            ))


def main(argv=None):
    # type: (Optional[list]) -> int
    args = build_parser().parse_args(argv)

    if args.command == 'test':
        try:
            client = build_client(args)
            project = args.project or jira_connection().get('default_project')
            report = client.test_connection(
                project=project,
                issue_key=args.issue,
                issuetype=args.issuetype,
            )
        except JiraError as exc:
            print('JIRA API test: FAILED', file=sys.stderr)
            print('  {}'.format(exc), file=sys.stderr)
            return 1

        if args.json:
            print(json.dumps(report, indent=2))
        else:
            print_test_report(report)
        return 0

    if not args.yaml_file:
        print('Error: yaml_file is required for command {}'.format(args.command), file=sys.stderr)
        return 1

    try:
        config = load_yaml(args.yaml_file)
    except YamlError as exc:
        print('Error: {}'.format(exc), file=sys.stderr)
        return 1

    errors = validate_config(config, args.yaml_file)
    if errors:
        print('Validation failed:', file=sys.stderr)
        for error in errors:
            print('  - {}'.format(error), file=sys.stderr)
        return 1

    if args.command == 'validate':
        issues = expand_issues(config, args.yaml_file)
        updates = expand_updates(config, args.yaml_file)
        print('OK: {} create(s), {} update(s)'.format(len(issues), len(updates)))
        return 0

    try:
        client = build_client(args, config)
    except JiraError as exc:
        print('Error: {}'.format(exc), file=sys.stderr)
        return 1

    try:
        results = execute_yaml(
            args.yaml_file,
            client,
            mode=args.command,
            dry_run=args.dry_run,
            stop_on_error=not args.continue_on_error,
        )
    except (YamlError, JiraError) as exc:
        print('Error: {}'.format(exc), file=sys.stderr)
        return 1

    if args.json:
        print(json.dumps(results, indent=2))
    else:
        print_results(results)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
