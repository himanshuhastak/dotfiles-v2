"""Load local config; identity + credentials from OS keyring (env fallback)."""

import os
from typing import Any, Dict, Optional

from dotfiles_tools.secrets_store import resolve as secret_resolve

DEFAULT_DOTFILES_DIR = os.path.expanduser('~/dotfiles_v2')


def dotfiles_dir():
    # type: () -> str
    return os.environ.get('DOTFILES_DIR', DEFAULT_DOTFILES_DIR)


def config_paths():
    # type: () -> list
    base = dotfiles_dir()
    return [
        os.path.join(base, 'local', 'tools', 'config.toml'),
        os.path.join(
            os.environ.get('XDG_CONFIG_HOME', os.path.expanduser('~/.config')),
            'dotfiles-tools',
            'config.toml',
        ),
    ]


def load_config():
    # type: () -> Dict[str, Any]
    for path in config_paths():
        if not os.path.isfile(path):
            continue
        try:
            import toml  # type: ignore
        except ImportError:
            raise RuntimeError(
                'toml missing — run: dotfiles update-tools dotfiles-tools'
            )
        with open(path, encoding='utf-8') as handle:
            data = toml.load(handle)
        if isinstance(data, dict):
            return data
    return {}


def _env_int(name):
    # type: (str) -> Optional[int]
    raw = os.environ.get(name)
    if raw is None or raw == '':
        return None
    try:
        return int(raw)
    except ValueError:
        return None


def _env_bool(name, default=None):
    # type: (str, Optional[bool]) -> Optional[bool]
    raw = os.environ.get(name)
    if raw is None or raw == '':
        return default
    return raw.lower() not in ('0', 'false', 'no', 'off')


def password_oracle(env_var):
    # type: (str) -> str
    """Bugwarrior reads from env; keyring is exported by the runner."""
    return '@oracle:eval:printenv {}'.format(env_var)


def _pick(overrides, key, secret_name, *config_fallback):
    # type: (Optional[Dict[str, Any]], str, str, *Any) -> Any
    """CLI override → keyring/env → optional config.toml fallback (legacy)."""
    if overrides and overrides.get(key) is not None:
        return overrides[key]
    value = secret_resolve(secret_name)
    if value:
        return value
    for item in config_fallback:
        if item is not None and item != '':
            return item
    return None


def jira_connection(overrides=None):
    # type: (Optional[Dict[str, Any]]) -> Dict[str, Any]
    file_cfg = load_config().get('jira') or {}
    cfg = dict(file_cfg)
    if overrides:
        cfg.update({k: v for k, v in overrides.items() if v is not None})

    # Identity + auth: keyring primary (not config.toml).
    cfg['url'] = _pick(overrides, 'url', 'jira_url', file_cfg.get('url'))
    cfg['email'] = _pick(overrides, 'email', 'jira_email', file_cfg.get('email'))
    cfg['username'] = _pick(
        overrides, 'username', 'jira_username',
        file_cfg.get('username'), file_cfg.get('user'),
    )
    cfg['token'] = _pick(overrides, 'token', 'jira_api_token', file_cfg.get('token'))
    cfg['password'] = _pick(
        overrides, 'password', 'jira_password', file_cfg.get('password'),
    )

    if cfg.get('api_version') is None:
        cfg['api_version'] = _env_int('JIRA_API_VERSION')
    if 'verify_ssl' not in cfg:
        env_verify = _env_bool('JIRA_VERIFY_SSL')
        cfg['verify_ssl'] = env_verify if env_verify is not None else True
    return cfg


def gitlab_connection(overrides=None):
    # type: (Optional[Dict[str, Any]]) -> Dict[str, Any]
    file_cfg = load_config().get('gitlab') or {}
    cfg = dict(file_cfg)
    if overrides:
        cfg.update({k: v for k, v in overrides.items() if v is not None})

    cfg['url'] = _pick(overrides, 'url', 'gitlab_url', file_cfg.get('url'))
    cfg['token'] = _pick(overrides, 'token', 'gitlab_token', file_cfg.get('token'))
    cfg['email_domain'] = _pick(
        overrides, 'email_domain', 'gitlab_email_domain',
        file_cfg.get('email_domain'),
    )

    if cfg.get('root_group_id') is None:
        cfg['root_group_id'] = _env_int('GITLAB_ROOT_GROUP_ID')
    if cfg.get('access_level') is None:
        cfg['access_level'] = _env_int('GITLAB_ACCESS_LEVEL')
    if 'verify_ssl' not in cfg:
        env_verify = _env_bool('GITLAB_VERIFY_SSL')
        cfg['verify_ssl'] = env_verify if env_verify is not None else True
    return cfg


def bugwarrior_settings():
    # type: () -> Dict[str, Any]
    return dict(load_config().get('bugwarrior') or {})


def bugwarrior_output_path():
    # type: () -> str
    bw = bugwarrior_settings()
    dest = (bw.get('output') or 'local').lower()
    base = dotfiles_dir()
    if dest == 'xdg':
        xdg = os.environ.get('XDG_CONFIG_HOME', os.path.expanduser('~/.config'))
        return os.path.join(xdg, 'bugwarrior', 'bugwarriorrc')
    if dest == 'home':
        return os.path.expanduser('~/.bugwarriorrc')
    return os.path.join(base, 'local', 'tools', 'bugwarriorrc')


def ensure_bugwarrior_env():
    # type: () -> None
    """Point BUGWARRIORRC at the generated local config if unset."""
    if os.environ.get('BUGWARRIORRC'):
        return
    path = bugwarrior_output_path()
    if os.path.isfile(path):
        os.environ['BUGWARRIORRC'] = path
