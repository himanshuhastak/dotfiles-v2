"""Generic GitLab invite library (python-gitlab)."""

import json

import gitlab
import gitlab.const as glconst
import urllib3

urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

DEVELOPER = getattr(gitlab, 'DEVELOPER_ACCESS', glconst.DEVELOPER_ACCESS)


def gl(url, token, verify_ssl=False):
    return gitlab.Gitlab(url, private_token=token, ssl_verify=verify_ssl, timeout=120)


def test_connection(gl, root_group_id=None):
    """Verify token auth; optionally confirm visibility of a root group."""
    import gitlab.exceptions as glexc

    report = {
        'url': gl.url,
        'auth': 'ok',
        'user': None,
        'root_group': None,
    }

    try:
        gl.auth()
    except glexc.GitlabAuthenticationError as exc:
        raise ValueError('authentication failed: {}'.format(exc)) from exc
    except glexc.GitlabError as exc:
        raise ValueError('connection failed: {}'.format(exc)) from exc

    user = gl.user
    if user is None:
        raise ValueError('authentication succeeded but no user profile returned')

    report['user'] = {
        'id': user.id,
        'username': user.username,
        'name': getattr(user, 'name', None),
        'email': getattr(user, 'email', None),
        'state': getattr(user, 'state', None),
    }

    if root_group_id is not None:
        try:
            group = gl.groups.get(int(root_group_id))
        except glexc.GitlabGetError as exc:
            raise ValueError(
                'root group {} not found or not visible: {}'.format(root_group_id, exc)
            ) from exc
        report['root_group'] = {
            'id': group.id,
            'name': group.name,
            'full_path': _group_full_path(group),
        }

    return report


def emails(users, domain=None):
    out = []
    for u in users:
        if '@' in u:
            out.append(u)
        elif domain:
            out.append(f'{u}@{domain}')
        else:
            raise ValueError(f'{u}: not an email; pass --email-domain or use full addresses')
    return out


# GitLab list pagination (python-gitlab 2.x uses all=, not get_all=).
_LIST_KW = {'all': True, 'per_page': 100}


def _group_full_path(group):
    fp = getattr(group, 'full_path', None)
    if fp:
        return fp
    return (getattr(group, 'full_name', None) or group.name).replace(' / ', '/')


def _rel_path(root, group):
    """Group path relative to root (e.g. dept/team/subteam)."""
    root_fp = _group_full_path(root).rstrip('/')
    g_fp = _group_full_path(group).rstrip('/')
    if g_fp == root_fp:
        return ''
    prefix = root_fp + '/'
    if g_fp.startswith(prefix):
        return g_fp[len(prefix):]
    # full_path may omit ancestors on shared groups — fall back to full_name
    rname = (getattr(root, 'full_name', None) or root.name) + ' / '
    gname = getattr(group, 'full_name', None) or group.name
    if gname.startswith(rname):
        return gname[len(rname):].replace(' / ', '/')
    return None


def index_groups(gl, root_id, debug=False):
    root = gl.groups.get(root_id)
    print('Fetching groups under {}...'.format(root.full_name), flush=True)
    out = {}

    def _add(group):
        rel = _rel_path(root, group)
        if rel is not None:
            out[rel] = group.id

    # Walk direct subgroups recursively (complete tree).
    def _walk(group_id):
        group = gl.groups.get(group_id)
        for sg in group.subgroups.list(**_LIST_KW):
            _add(sg)
            _walk(sg.id)

    _walk(root_id)

    # Union with descendant_groups (catches anything the walk missed).
    desc = root.descendant_groups.list(**_LIST_KW)
    for g in desc:
        _add(g)

    if debug:
        print('  descendant_groups API: {}'.format(len(desc)), flush=True)
        print('  unique groups after union: {}'.format(len(out)), flush=True)
    print('  {} groups indexed'.format(len(out)), flush=True)
    return out


def _project_rel_path(root, project):
    """Project path relative to root group (e.g. dept/team/subteam/repo)."""
    root_fp = _group_full_path(root).rstrip('/')
    full = getattr(project, 'path_with_namespace', None)
    if not full:
        ns = project.namespace
        if isinstance(ns, dict):
            ns_fp = ns.get('full_path') or ns.get('path', '')
        else:
            ns_fp = getattr(ns, 'full_path', None) or getattr(ns, 'path', '')
        full = '{}/{}'.format(ns_fp, project.path)
    full = full.rstrip('/')
    prefix = root_fp + '/'
    if full.startswith(prefix):
        return full[len(prefix):]
    if full == root_fp:
        return project.path
    # path_with_namespace may not include the root prefix — return as-is if it
    # already looks like a tree path under the org namespace.
    if '/' in full:
        return full
    return None


def _register_namespace(groups, root, project, debug=False):
    """Add a project's parent group to the index when missing."""
    gid = _ns_id(project)
    known = set(groups.values())
    if gid in known:
        return
    ns = project.namespace
    if isinstance(ns, dict):
        ns_fp = ns.get('full_path') or ns.get('path')
        ns_name = ns.get('full_name') or ns.get('name')
    else:
        ns_fp = getattr(ns, 'full_path', None) or getattr(ns, 'path', None)
        ns_name = getattr(ns, 'full_name', None) or getattr(ns, 'name', None)
    rel = None
    if ns_fp:
        root_fp = _group_full_path(root).rstrip('/')
        prefix = root_fp + '/'
        if ns_fp.startswith(prefix):
            rel = ns_fp[len(prefix):]
        elif '/' in ns_fp:
            rel = ns_fp
    if rel is None and ns_name:
        rname = (getattr(root, 'full_name', None) or root.name) + ' / '
        if ns_name.startswith(rname):
            rel = ns_name[len(rname):].replace(' / ', '/')
    if rel is not None:
        groups[rel] = gid
        if debug:
            print('  +group from repo ns: {} ({})'.format(rel, gid), flush=True)


def index_projects(gl, root_id, groups, debug=False):
    root = gl.groups.get(root_id)
    groups = dict(groups)  # extend while indexing repos
    id2path = {gid: p for p, gid in groups.items()}
    id2path[root_id] = ''
    out = {}
    skipped = 0
    api_total = 0
    seen_ids = set()
    print('Fetching repos...', flush=True)

    def _add(project):
        nonlocal skipped, api_total
        if project.id in seen_ids:
            return
        seen_ids.add(project.id)
        api_total += 1
        _register_namespace(groups, root, project, debug=debug)
        id2path.update({gid: p for p, gid in groups.items()})
        id2path[root_id] = ''

        path = _project_rel_path(root, project)
        if path is None:
            base = id2path.get(_ns_id(project))
            if base is None:
                skipped += 1
                if debug:
                    ns = _ns_id(project)
                    full = getattr(project, 'path_with_namespace', project.path)
                    print('  skip ns={} {}'.format(ns, full), flush=True)
                return
            path = '{}/{}'.format(base, project.path) if base else project.path
        out[path] = project.id

    # Bulk: all projects in subtree (+ shared into groups).
    bulk_kw = dict(_LIST_KW)
    bulk_kw.update(include_subgroups=True, with_shared=True)
    for project in root.projects.list(**bulk_kw):
        _add(project)

    # Per-group direct projects (union; catches edge cases on some instances).
    for _path, gid in list(groups.items()):
        for project in gl.groups.get(gid).projects.list(**_LIST_KW, with_shared=True):
            _add(project)

    if debug:
        print('  {} project(s) from API, {} skipped, {} indexed'.format(
            api_total, skipped, len(out)), flush=True)
    print('  {} repos indexed'.format(len(out)), flush=True)
    return out, groups


def _ns_id(project):
    ns = project.namespace
    return ns['id'] if isinstance(ns, dict) else ns.id


def resolve(path, groups, projects):
    if path in groups:
        return 'group', groups[path]
    if path in projects:
        return 'project', projects[path]
    tail = path.split('/')[-1]
    similar = sorted(p for p in groups if tail in p)[:8]
    raise ValueError(f'not found: {path}\nsimilar: {similar}')


def _invite(gl, kind, target_id, user_list, level, dry_run, label):
    print(f'  {target_id:>8}  {label}')
    if dry_run:
        print(f'    dry-run: {user_list} -> {label} (level {level})')
        return
    # python-gitlab 2.x has no invitations manager — call the REST API directly.
    path = '/{kind}s/{tid}/invitations'.format(kind=kind, tid=target_id)
    body = gl.http_post(path, post_data={
        'email': ','.join(user_list),
        'access_level': level,
    })
    print(json.dumps({'target': label, 'response': body}, indent=2))


def invite(gl, users, *, group_ids=(), project_ids=(), root_id=None, paths=(),
           level=DEVELOPER, dry_run=False, domain=None):
    user_list = emails([u.strip() for u in users if u.strip()], domain)
    targets = []

    for gid in group_ids:
        targets.append(('group', int(gid), f'group:{gid}'))
    for pid in project_ids:
        targets.append(('project', int(pid), f'project:{pid}'))

    if paths:
        if root_id is None:
            raise ValueError('root_id required with paths')
        print('Indexing groups...', flush=True)
        groups = index_groups(gl, root_id)
        projects = {}
        if any(p not in groups for p in paths):
            projects, groups = index_projects(gl, root_id, groups)
        for path in paths:
            kind, tid = resolve(path, groups, projects)
            targets.append((kind, tid, path))

    if not targets:
        raise ValueError('no targets')

    print(f'Inviting {user_list} to {len(targets)} target(s):')
    for kind, tid, label in targets:
        _invite(gl, kind, tid, user_list, level, dry_run, label)


def list_tree(gl, root_id, groups_only=False, debug=False):
    groups = index_groups(gl, root_id, debug=debug)
    if groups_only:
        projects = {}
    else:
        projects, groups = index_projects(gl, root_id, groups, debug=debug)
    for path in sorted(groups):
        print(f'  {groups[path]:>8}  [group] {path}')
    for path in sorted(projects):
        print(f'  {projects[path]:>8}  [repo]  {path}')


def _split(s):
    return [x.strip() for x in s.split(',') if x.strip()]
