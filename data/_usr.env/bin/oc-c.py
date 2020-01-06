#!/usr/bin/env python2

import yunionclient.api.client

import sys
import os

def api_client():
    rc = os.environ
    desc = {
        'project_name': rc.get('OS_PROJECT_NAME'),
        'project_id': rc.get('OS_PROJECT_ID'),
        'args': (
            rc.get('OS_AUTH_URL'),
            rc.get('OS_USERNAME'),
            rc.get('OS_PASSWORD'),
            rc.get('OS_DOMAIN_NAME'),
        ),
        'kwargs': {
            'region': rc.get('OS_REGION_NAME'),
            'zone': None,
            'insecure': rc.get('YUNION_INSECURE'),
        },
    }
    args = desc['args']
    kwargs = desc['kwargs']
    if rc.get('OS_ENDPOINT_TYPE'):
        kwargs['endpoint_type'] = rc.get('OS_ENDPOINT_TYPE')
    client = yunionclient.api.client.Client(*args, **kwargs)
    project_name = desc.get('project_name')
    project_id = desc.get('project_id')
    if project_name is not None or project_id is not None:
        client.set_project(project_name=project_name, project_id=project_id)
    return client

def upd_ep():
    a_svc = sys.argv[2]
    a_url = sys.argv[3]

    cli = api_client()
    svc = cli.services.get_by_id_or_name(a_svc)
    eps, total, limit, offset = cli.endpoints.list(**{'service': svc['id']})
    for ep in eps:
        if ep.get('url') == a_url:
            continue
        sys.stderr.write('updating endpoint %s url: %s -> %s\n' % (ep['id'], ep.get('url'), a_url))
        cli.endpoints.update(ep['id'], **{
            'url': a_url,
        })

def add_usr():
    a_usr = sys.argv[2]

    cli = api_client()
    usr = cli.users.create(**{
        'name': a_usr,
        'password': '111111',
    })
    cli.projects.update_descendent(
        'system',
        cli.users, usr['id'],
        cli.roles, 'admin')

cmds = (
    ('upd-ep', 'svc', 'ep', ),
    ('add-usr', 'usr', ),
)

def cmd_usg(cmd):
    sys.stderr.write('  ' + cmd[0])
    sys.stderr.write(''.join(' <%s>' % a for a in cmd[1:]))
    sys.stderr.write('\n')

if len(sys.argv) < 2:
    sys.stderr.write('usage:\n')
    for cmd in cmds:
        cmd_usg(cmd)
    sys.exit(1)

arg0 = sys.argv[1]
for cmd in cmds:
    if arg0 != cmd[0]:
        continue
    narg = len(cmd)
    if len(sys.argv) < narg + 1:
        cmd_usg(cmd)
        sys.exit(1)
    fn = arg0.replace('-', '_', -1)
    f = globals()[fn]
    f()
