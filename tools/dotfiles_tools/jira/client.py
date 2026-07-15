#!/usr/bin/env python3
"""Minimal JIRA REST API client using the Python standard library."""

import base64
import json
import os
import ssl
from typing import Any, Dict, List, Optional, Tuple
from urllib.error import HTTPError, URLError
from urllib.parse import urljoin
from urllib.request import Request, urlopen

DEFAULT_TIMEOUT = 120


class JiraError(Exception):
    """Raised when a JIRA API call fails."""


class JiraClient(object):
    """Small wrapper around JIRA REST API v2/v3."""

    def __init__(
        self,
        url,
        email=None,
        token=None,
        username=None,
        password=None,
        api_version=None,
        verify_ssl=True,
        timeout=DEFAULT_TIMEOUT,
    ):
        # type: (str, Optional[str], Optional[str], Optional[str], Optional[str], Optional[int], bool, int) -> None
        self.base_url = url.rstrip('/')
        self.timeout = timeout
        self.verify_ssl = verify_ssl

        if api_version is None:
            api_version = 3 if '.atlassian.net' in self.base_url else 2
        self.api_version = int(api_version)

        self.email = email or os.environ.get('JIRA_EMAIL')
        self.token = token or os.environ.get('JIRA_API_TOKEN') or os.environ.get('JIRA_TOKEN')
        self.username = username or os.environ.get('JIRA_USER') or os.environ.get('JIRA_USERNAME')
        self.password = password or os.environ.get('JIRA_PASSWORD')

        auth = self._auth_header()
        if not auth:
            raise JiraError(
                'Missing credentials. Set JIRA_EMAIL + JIRA_API_TOKEN for Cloud, '
                'or JIRA_USER + JIRA_TOKEN/JIRA_PASSWORD for Server/Data Center.'
            )

        self._auth_header = auth
        self._ctx = None  # type: Optional[ssl.SSLContext]
        if not verify_ssl:
            self._ctx = ssl.create_default_context()
            self._ctx.check_hostname = False
            self._ctx.verify_mode = ssl.CERT_NONE

    def _auth_header(self):
        # type: () -> Optional[str]
        if self.email and self.token:
            raw = '{}:{}'.format(self.email, self.token)
        elif self.username and self.token:
            raw = '{}:{}'.format(self.username, self.token)
        elif self.username and self.password:
            raw = '{}:{}'.format(self.username, self.password)
        else:
            return None
        encoded = base64.b64encode(raw.encode('utf-8')).decode('ascii')
        return 'Basic {}'.format(encoded)

    @property
    def api_base(self):
        # type: () -> str
        return '{}/rest/api/{}'.format(self.base_url, self.api_version)

    def _request(self, method, path, payload=None):
        # type: (str, str, Optional[Dict[str, Any]]) -> Any
        url = urljoin(self.api_base + '/', path.lstrip('/'))
        data = None
        headers = {
            'Authorization': self._auth_header,
            'Accept': 'application/json',
        }
        if payload is not None:
            data = json.dumps(payload).encode('utf-8')
            headers['Content-Type'] = 'application/json'

        req = Request(url, data=data, headers=headers, method=method)
        try:
            with urlopen(req, timeout=self.timeout, context=self._ctx) as resp:
                body = resp.read().decode('utf-8')
                if not body:
                    return None
                return json.loads(body)
        except HTTPError as exc:
            detail = exc.read().decode('utf-8', errors='replace')
            raise JiraError('HTTP {} {}: {}'.format(exc.code, path, detail)) from exc
        except URLError as exc:
            raise JiraError('Request failed for {}: {}'.format(url, exc)) from exc

    def get_issue(self, key):
        # type: (str) -> Optional[Dict[str, Any]]
        try:
            return self._request('GET', 'issue/{}'.format(key))
        except JiraError as exc:
            if 'HTTP 404' in str(exc):
                return None
            raise

    def create_issue(self, fields):
        # type: (Dict[str, Any]) -> Dict[str, Any]
        return self._request('POST', 'issue', {'fields': fields})

    def update_issue(self, key, fields=None, update=None, comment=None):
        # type: (str, Optional[Dict[str, Any]], Optional[Dict[str, Any]], Optional[str]) -> None
        payload = {}  # type: Dict[str, Any]
        if fields:
            payload['fields'] = fields
        if update:
            payload['update'] = update
        if comment:
            payload['update'] = payload.get('update', {})
            payload['update']['comment'] = [self._comment_body(comment)]
        if not payload:
            raise JiraError('No update fields provided for {}'.format(key))
        self._request('PUT', 'issue/{}'.format(key), payload)

    def _comment_body(self, text):
        # type: (str) -> Dict[str, Any]
        if self.api_version >= 3:
            return {'add': {'body': text_to_adf(text)}}
        return {'add': {'body': text}}

    def browse_url(self, key):
        # type: (str) -> str
        return '{}/browse/{}'.format(self.base_url, key)

    def get_myself(self):
        # type: () -> Dict[str, Any]
        return self._request('GET', 'myself')

    def get_project(self, key):
        # type: (str) -> Optional[Dict[str, Any]]
        try:
            return self._request('GET', 'project/{}'.format(key))
        except JiraError as exc:
            if 'HTTP 404' in str(exc):
                return None
            raise

    def get_create_meta(self, project_key, issuetype=None):
        # type: (str, Optional[str]) -> Dict[str, Any]
        path = 'issue/createmeta?projectKeys={}&expand=projects.issuetypes.fields'.format(project_key)
        if issuetype:
            path += '&issuetypeNames={}'.format(issuetype)
        return self._request('GET', path)

    def test_connection(self, project=None, issue_key=None, issuetype=None):
        # type: (Optional[str], Optional[str], Optional[str]) -> Dict[str, Any]
        report = {
            'url': self.base_url,
            'api_version': self.api_version,
            'auth': 'ok',
            'user': None,
            'project': None,
            'issue': None,
            'create_meta': None,
            'can_create': None,
        }

        me = self.get_myself()
        report['user'] = {
            'accountId': me.get('accountId'),
            'name': me.get('name') or me.get('displayName'),
            'email': me.get('emailAddress'),
            'active': me.get('active', True),
        }

        if project:
            proj = self.get_project(project)
            if not proj:
                raise JiraError('Project {} not found or not visible'.format(project))
            report['project'] = {
                'key': proj.get('key'),
                'name': proj.get('name'),
                'id': proj.get('id'),
            }
            meta = self.get_create_meta(project, issuetype=issuetype)
            projects = meta.get('projects') or []
            if not projects:
                report['can_create'] = False
                report['create_meta'] = 'No create permission for project {}'.format(project)
            else:
                types = projects[0].get('issuetypes') or []
                report['can_create'] = True
                report['create_meta'] = [
                    {
                        'name': t.get('name'),
                        'id': t.get('id'),
                        'required_fields': sorted(
                            name for name, info in (t.get('fields') or {}).items()
                            if info.get('required')
                        ),
                    }
                    for t in types
                ]

        if issue_key:
            issue = self.get_issue(issue_key)
            if not issue:
                raise JiraError('Issue {} not found or not visible'.format(issue_key))
            fields = issue.get('fields') or {}
            report['issue'] = {
                'key': issue.get('key'),
                'summary': fields.get('summary'),
                'status': (fields.get('status') or {}).get('name'),
                'issuetype': (fields.get('issuetype') or {}).get('name'),
                'project': (fields.get('project') or {}).get('key'),
            }

        return report


def text_to_adf(text):
    # type: (str) -> Dict[str, Any]
    lines = text.split('\n')
    if not lines:
        lines = ['']
    return {
        'type': 'doc',
        'version': 1,
        'content': [
            {
                'type': 'paragraph',
                'content': [{'type': 'text', 'text': line if line else ' '}],
            }
            for line in lines
        ],
    }


def format_description(client, text):
    # type: (JiraClient, str) -> Any
    if client.api_version >= 3:
        return text_to_adf(text)
    return text


def ref(name):
    # type: (str) -> Dict[str, str]
    return {'name': name}


def project_ref(key):
    # type: (str) -> Dict[str, str]
    return {'key': key}


def user_ref(value):
    # type: (str) -> Dict[str, str]
    if '@' in value:
        return {'emailAddress': value}
    if value.startswith('account:'):
        return {'accountId': value.split(':', 1)[1]}
    return {'name': value}


def build_create_fields(client, issue):
    # type: (JiraClient, Dict[str, Any]) -> Dict[str, Any]
    fields = {}  # type: Dict[str, Any]

    project = issue.get('project')
    if project:
        fields['project'] = project_ref(str(project))

    summary = issue.get('summary')
    if summary:
        fields['summary'] = summary

    issuetype = issue.get('issuetype') or issue.get('type')
    if issuetype:
        fields['issuetype'] = ref(str(issuetype))

    if issue.get('description') is not None:
        fields['description'] = format_description(client, str(issue['description']))

    if issue.get('priority') is not None:
        fields['priority'] = ref(str(issue['priority']))

    if issue.get('assignee') is not None:
        fields['assignee'] = user_ref(str(issue['assignee']))

    if issue.get('labels') is not None:
        fields['labels'] = [str(x) for x in as_list(issue['labels'])]

    if issue.get('components') is not None:
        fields['components'] = [ref(str(x)) for x in as_list(issue['components'])]

    extra = issue.get('fields', {})
    if extra:
        if not isinstance(extra, dict):
            raise JiraError('fields must be a mapping')
        fields.update(extra)

    return fields


def build_update_payload(client, update):
    # type: (JiraClient, Dict[str, Any]) -> Tuple[Dict[str, Any], Dict[str, Any]]
    fields = {}  # type: Dict[str, Any]
    ops = {}  # type: Dict[str, Any]

    if 'summary' in update:
        fields['summary'] = update['summary']

    if 'description' in update:
        fields['description'] = format_description(client, str(update['description']))

    if 'priority' in update:
        fields['priority'] = ref(str(update['priority']))

    if 'assignee' in update:
        fields['assignee'] = user_ref(str(update['assignee']))

    if 'issuetype' in update or 'type' in update:
        fields['issuetype'] = ref(str(update.get('issuetype') or update.get('type')))

    if 'labels' in update:
        fields['labels'] = [str(x) for x in as_list(update['labels'])]
    else:
        label_ops = []  # type: List[Dict[str, str]]
        for label in as_list(update.get('remove_labels')):
            label_ops.append({'remove': str(label)})
        for label in as_list(update.get('add_labels')):
            label_ops.append({'add': str(label)})
        if label_ops:
            ops['labels'] = label_ops

    if 'components' in update:
        fields['components'] = [ref(str(x)) for x in as_list(update['components'])]

    extra = update.get('fields', {})
    if extra:
        if not isinstance(extra, dict):
            raise JiraError('fields must be a mapping')
        fields.update(extra)

    return fields, ops


def as_list(value):
    # type: (Any) -> List[Any]
    if value is None:
        return []
    if isinstance(value, list):
        return value
    return [value]


def client_from_mapping(connection):
    # type: (Dict[str, Any]) -> JiraClient
    url = connection.get('url') or os.environ.get('JIRA_URL')
    if not url:
        raise JiraError('JIRA URL is required. Set JIRA_URL or connection.url in YAML.')

    return JiraClient(
        url=url,
        email=connection.get('email'),
        token=connection.get('token'),
        username=connection.get('username') or connection.get('user'),
        password=connection.get('password'),
        api_version=connection.get('api_version'),
        verify_ssl=bool(connection.get('verify_ssl', True)),
        timeout=int(connection.get('timeout', DEFAULT_TIMEOUT)),
    )
