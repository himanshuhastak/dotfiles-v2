"""Unified secret storage: OS keyring when available, else local file (0600)."""

from __future__ import print_function

import json
import os
import stat

# Keyring service name (shared across jira, gitlab, bugwarrior).
SERVICE = 'dotfiles-tools'

# Secret name -> env var(s) used only by `dotfiles secrets export` (cron/CI).
# Identity (URLs, emails, usernames) and credentials all live here — not in config.toml.
SECRET_ENV = {
    'jira_url': ['JIRA_URL'],
    'jira_email': ['JIRA_EMAIL'],
    'jira_username': ['JIRA_USER', 'JIRA_USERNAME'],
    'jira_api_token': ['JIRA_API_TOKEN', 'JIRA_TOKEN'],
    'jira_password': ['JIRA_PASSWORD'],
    'gitlab_url': ['GITLAB_URL', 'GIT_INSTANCE'],
    'gitlab_token': ['GITLAB_TOKEN', 'GITLAB_PRIVATE_TOKEN'],
    'gitlab_email_domain': ['GITLAB_EMAIL_DOMAIN'],
}

SECRET_LABELS = {
    'jira_url': 'Jira base URL',
    'jira_email': 'Jira account email (Cloud)',
    'jira_username': 'Jira username (Server/DC)',
    'jira_api_token': 'Jira API token (Cloud)',
    'jira_password': 'Jira password (Server/DC)',
    'gitlab_url': 'GitLab base URL',
    'gitlab_token': 'GitLab personal access token',
    'gitlab_email_domain': 'GitLab email domain (for bare usernames)',
}

SECRET_HIDDEN = frozenset({
    'jira_api_token',
    'jira_password',
    'gitlab_token',
})

REQUIRED_FOR = {
    'jira_url': 'dotfiles jira, bugwarrior jira',
    'jira_email': 'dotfiles jira (Cloud), bugwarrior jira',
    'jira_api_token': 'dotfiles jira, bugwarrior jira',
    'gitlab_url': 'dotfiles gitlab, bugwarrior gitlab',
    'gitlab_token': 'dotfiles gitlab, bugwarrior gitlab',
}


def _dotfiles_dir():
    return os.environ.get('DOTFILES_DIR', os.path.expanduser('~/Git/dotfiles-chzemoi'))


def file_store_path():
    # type: () -> str
    """Fallback store for headless hosts without Secret Service / keychain."""
    return os.path.join(_dotfiles_dir(), 'local', 'tools', 'keyring.json')


def _backend():
    """Return ('keyring'|'file', handle). Prefer OS keyring; fall back to file."""
    try:
        import keyring  # type: ignore
        from keyring.errors import NoKeyringError  # type: ignore
        kr = keyring.get_keyring()
        # fail.Keyring raises on use; probe with get_password
        try:
            kr.get_password(SERVICE, '__probe__')
        except NoKeyringError:
            return 'file', None
        except Exception:
            # other backends may error on missing; still usable
            name = type(kr).__name__.lower()
            if 'fail' in name:
                return 'file', None
        name = type(kr).__name__.lower()
        if 'fail' in name:
            return 'file', None
        return 'keyring', kr
    except ImportError:
        return 'file', None


def _file_load():
    # type: () -> dict
    path = file_store_path()
    if not os.path.isfile(path):
        return {}
    try:
        with open(path, encoding='utf-8') as handle:
            data = json.load(handle)
        return data if isinstance(data, dict) else {}
    except (IOError, ValueError, TypeError):
        return {}


def _file_save(data):
    # type: (dict) -> None
    path = file_store_path()
    parent = os.path.dirname(path)
    if parent:
        os.makedirs(parent, exist_ok=True)
    tmp = path + '.tmp'
    with open(tmp, 'w', encoding='utf-8') as handle:
        json.dump(data, handle, indent=2, sort_keys=True)
        handle.write('\n')
    os.chmod(tmp, stat.S_IRUSR | stat.S_IWUSR)  # 0600
    os.replace(tmp, path)
    os.chmod(path, stat.S_IRUSR | stat.S_IWUSR)


def list_secrets():
    # type: () -> list
    kind, kr = _backend()
    found = []
    if kind == 'keyring' and kr is not None:
        for name in SECRET_ENV:
            try:
                if kr.get_password(SERVICE, name):
                    found.append(name)
            except Exception:
                continue
        return found
    data = _file_load()
    return [n for n in SECRET_ENV if data.get(n)]


def get_secret(name):
    # type: (str) -> str
    if name not in SECRET_ENV:
        raise KeyError('unknown secret: {}'.format(name))
    kind, kr = _backend()
    if kind == 'keyring' and kr is not None:
        try:
            value = kr.get_password(SERVICE, name)
            return value or ''
        except Exception:
            pass
    return str(_file_load().get(name) or '')


def set_secret(name, value):
    # type: (str, str) -> None
    if name not in SECRET_ENV:
        raise KeyError('unknown secret: {}'.format(name))
    if not value:
        raise ValueError('refusing to store empty secret')
    value = value.strip()
    kind, kr = _backend()
    if kind == 'keyring' and kr is not None:
        try:
            kr.set_password(SERVICE, name, value)
            return
        except Exception:
            pass
    data = _file_load()
    data[name] = value
    _file_save(data)


def clear_secret(name):
    # type: (str) -> None
    if name not in SECRET_ENV:
        raise KeyError('unknown secret: {}'.format(name))
    kind, kr = _backend()
    if kind == 'keyring' and kr is not None:
        try:
            kr.delete_password(SERVICE, name)
        except Exception:
            pass
    data = _file_load()
    if name in data:
        del data[name]
        _file_save(data)


def backend_info():
    # type: () -> str
    kind, kr = _backend()
    if kind == 'keyring' and kr is not None:
        return 'os-keyring ({})'.format(type(kr).__name__)
    return 'file ({})'.format(file_store_path())


def resolve(name, env_names=None):
    # type: (str, list) -> str
    """Read a secret from OS keyring / local file store only."""
    if name not in SECRET_ENV:
        raise KeyError('unknown secret: {}'.format(name))
    try:
        value = get_secret(name)
        if value:
            return value
    except Exception:
        pass
    return ''


def resolve_env(name):
    # type: (str) -> str
    """Optional env fallback — for cron/CI shells that cannot use keyring."""
    env_names = SECRET_ENV.get(name, [])
    for var in env_names:
        value = os.environ.get(var)
        if value:
            return value
    return ''


def resolve_any(name):
    # type: (str) -> str
    """Keyring first, then environment (cron/CI escape hatch)."""
    value = resolve(name)
    return value or resolve_env(name)


def export_env_shell():
    # type: () -> str
    lines = []
    for name, env_vars in SECRET_ENV.items():
        try:
            value = get_secret(name)
        except Exception:
            continue
        if not value:
            continue
        primary = env_vars[0]
        safe = value.replace("'", "'\"'\"'")
        lines.append("export {}='{}'".format(primary, safe))
    return '\n'.join(lines)


def export_to_environ():
    # type: () -> None
    """Load keyring secrets into the process env (for bugwarrior oracles / cron)."""
    for name, env_vars in SECRET_ENV.items():
        try:
            value = get_secret(name)
        except Exception:
            continue
        if not value:
            continue
        for var in env_vars:
            if not os.environ.get(var):
                os.environ[var] = value
