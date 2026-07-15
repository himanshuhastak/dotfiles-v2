"""Parse and validate YAML files for JIRA create/update operations."""

import os
from copy import deepcopy
from typing import Any, Dict, List

import yaml

from dotfiles_tools.jira.client import (
    as_list,
    build_create_fields,
    build_update_payload,
)

CREATE_KEYS = {
    'summary', 'description', 'description_file', 'project', 'issuetype', 'type',
    'priority', 'assignee', 'labels', 'components', 'fields',
}
UPDATE_KEYS = CREATE_KEYS | {
    'key', 'jira_id', 'add_labels', 'remove_labels', 'comment', 'add_watchers',
}


class YamlError(Exception):
    """Raised when YAML input is invalid."""


def load_yaml(path):
    # type: (str) -> Dict[str, Any]
    if not os.path.isfile(path):
        raise YamlError('YAML file not found: {}'.format(path))
    with open(path, encoding='utf-8') as handle:
        data = yaml.safe_load(handle)
    if not isinstance(data, dict):
        raise YamlError('YAML root must be a mapping')
    return data


def yaml_dir(path):
    # type: (str) -> str
    return os.path.dirname(os.path.abspath(path))


def merge_dicts(base, override):
    # type: (Dict[str, Any], Dict[str, Any]) -> Dict[str, Any]
    merged = deepcopy(base)
    for key, value in override.items():
        if key == 'fields' and isinstance(value, dict):
            merged.setdefault('fields', {})
            if not isinstance(merged['fields'], dict):
                raise YamlError('fields must be a mapping')
            merged['fields'].update(value)
        else:
            merged[key] = value
    return merged


def resolve_description(entry, base_dir):
    # type: (Dict[str, Any], str) -> str
    if 'description_file' in entry:
        path = entry['description_file']
        if not os.path.isabs(path):
            path = os.path.join(base_dir, path)
        if not os.path.isfile(path):
            raise YamlError('description_file not found: {}'.format(path))
        with open(path, encoding='utf-8') as handle:
            return handle.read()
    if 'description' in entry and entry['description'] is not None:
        return str(entry['description'])
    return None


def prepare_entry(defaults, raw, base_dir, index, section):
    # type: (Dict[str, Any], Dict[str, Any], str, int, str) -> Dict[str, Any]
    if not isinstance(raw, dict):
        raise YamlError('{}[{}] must be a mapping'.format(section, index))

    entry = merge_dicts(defaults, raw)
    entry['_index'] = index
    entry['_section'] = section

    if 'description_file' in entry or 'description' in entry:
        entry['description'] = resolve_description(entry, base_dir)
    entry.pop('description_file', None)

    return entry


def expand_issues(config, path):
    # type: (Dict[str, Any], str) -> List[Dict[str, Any]]
    defaults = config.get('defaults') or {}
    if not isinstance(defaults, dict):
        raise YamlError('defaults must be a mapping')

    raw_issues = config.get('issues') or []
    if not isinstance(raw_issues, list):
        raise YamlError('issues must be a list')

    base_dir = yaml_dir(path)
    out = []  # type: List[Dict[str, Any]]
    for index, raw in enumerate(raw_issues, start=1):
        issue = prepare_entry(defaults, raw, base_dir, index, 'issues')
        if not issue.get('summary'):
            raise YamlError('issues[{}] missing summary'.format(index))
        if not issue.get('project'):
            raise YamlError('issues[{}] missing project (set in entry or defaults)'.format(index))
        issuetype = issue.get('issuetype') or issue.get('type')
        if not issuetype:
            raise YamlError('issues[{}] missing issuetype/type'.format(index))
        out.append(issue)
    return out


def expand_updates(config, path):
    # type: (Dict[str, Any], str) -> List[Dict[str, Any]]
    defaults = config.get('update_defaults') or config.get('defaults') or {}
    if not isinstance(defaults, dict):
        raise YamlError('update_defaults must be a mapping')

    raw_updates = config.get('updates') or []
    if not isinstance(raw_updates, list):
        raise YamlError('updates must be a list')

    base_dir = yaml_dir(path)
    out = []  # type: List[Dict[str, Any]]
    for index, raw in enumerate(raw_updates, start=1):
        update = prepare_entry(defaults, raw, base_dir, index, 'updates')
        key = update.get('key') or update.get('jira_id')
        if not key:
            raise YamlError('updates[{}] missing key'.format(index))
        update['key'] = str(key).strip()

        mutable = [
            name for name in UPDATE_KEYS
            if name in update and name not in {'key', 'jira_id'}
        ]
        if not mutable:
            raise YamlError('updates[{}] has no fields to change'.format(index))
        out.append(update)
    return out


def validate_config(config, path):
    # type: (Dict[str, Any], str) -> List[str]
    errors = []  # type: List[str]
    try:
        issues = expand_issues(config, path)
        updates = expand_updates(config, path)
    except YamlError as exc:
        return [str(exc)]

    if not issues and not updates:
        errors.append('YAML must contain issues and/or updates')
    return errors


def run_create(client, issue, dry_run=False):
    # type: (Any, Dict[str, Any], bool) -> Dict[str, Any]
    fields = build_create_fields(client, issue)
    if dry_run:
        return {
            'action': 'create',
            'dry_run': True,
            'summary': issue.get('summary'),
            'project': issue.get('project'),
            'fields': sorted(fields.keys()),
        }

    result = client.create_issue(fields)
    key = result['key']
    return {
        'action': 'create',
        'dry_run': False,
        'key': key,
        'url': client.browse_url(key),
        'summary': issue.get('summary'),
    }


def run_update(client, update, dry_run=False):
    # type: (Any, Dict[str, Any], bool) -> Dict[str, Any]
    fields, ops = build_update_payload(client, update)
    changed = sorted(set(list(fields.keys()) + list(ops.keys())))
    if update.get('comment'):
        changed.append('comment')

    if dry_run:
        return {
            'action': 'update',
            'dry_run': True,
            'key': update['key'],
            'changed': changed,
        }

    if not client.get_issue(update['key']):
        raise YamlError('updates[{}]: issue {} not found'.format(
            update['_index'], update['key']
        ))

    client.update_issue(
        update['key'],
        fields=fields or None,
        update=ops or None,
        comment=update.get('comment'),
    )
    return {
        'action': 'update',
        'dry_run': False,
        'key': update['key'],
        'url': client.browse_url(update['key']),
        'changed': changed,
    }


def execute_yaml(path, client, mode='sync', dry_run=False, stop_on_error=True):
    # type: (str, Any, str, bool, bool) -> Dict[str, List[Dict[str, Any]]]
    config = load_yaml(path)
    errors = validate_config(config, path)
    if errors:
        raise YamlError('\n'.join(errors))

    created = []  # type: List[Dict[str, Any]]
    updated = []  # type: List[Dict[str, Any]]

    if mode in ('create', 'sync'):
        for issue in expand_issues(config, path):
            try:
                created.append(run_create(client, issue, dry_run=dry_run))
            except Exception as exc:
                if stop_on_error:
                    raise
                created.append({
                    'action': 'create',
                    'error': str(exc),
                    'summary': issue.get('summary'),
                })

    if mode in ('update', 'sync'):
        for update in expand_updates(config, path):
            try:
                updated.append(run_update(client, update, dry_run=dry_run))
            except Exception as exc:
                if stop_on_error:
                    raise
                updated.append({
                    'action': 'update',
                    'error': str(exc),
                    'key': update.get('key'),
                })

    return {'created': created, 'updated': updated}
