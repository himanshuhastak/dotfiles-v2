"""Run local/tools/invite_policy.py (company overlay — never in git)."""

import os
import runpy
import sys

from dotfiles_tools.config import dotfiles_dir


def main(argv=None):
    argv = list(sys.argv[1:] if argv is None else argv)
    # When called as `python -m dotfiles_tools invite …`, argv is rest only.
    path = os.path.join(dotfiles_dir(), 'local', 'tools', 'invite_policy.py')
    if not os.path.isfile(path):
        print(
            'invite: no local policy at {}\n'
            'Create a private invite_policy.py there (not committed).'.format(path),
            file=sys.stderr,
        )
        return 1
    sys.argv = [path] + argv
    runpy.run_path(path, run_name='__main__')
    return 0
