#!/usr/bin/python
"""Reconcile Jellyfin configuration through its API, preserving runtime data."""
import json
from urllib.error import HTTPError
from urllib.parse import urlencode
from urllib.request import Request, urlopen

from ansible.module_utils.basic import AnsibleModule


class Jellyfin:
    def __init__(self, url, username, password, check=False):
        self.url = url.rstrip('/')
        self.username = username
        self.password = password
        self.check = check
        self.token = None
        self.changes = []

    def request(self, path, body=None, method=None):
        headers = {'Content-Type': 'application/json', 'Authorization':
                   'MediaBrowser Client="Ansible", Device="IaC", '
                   'DeviceId="my-kitchen-ansible", Version="1"'}
        if self.token:
            headers['Authorization'] += ', Token="' + self.token + '"'
        data = None if body is None else json.dumps(body).encode()
        with urlopen(Request(self.url + path, data=data, headers=headers,
                             method=method), timeout=180) as response:
            raw = response.read()
            return json.loads(raw) if raw else None

    def login(self):
        result = self.request('/Users/AuthenticateByName',
                              {'Username': self.username, 'Pw': self.password})
        self.token = result['AccessToken']

    def update(self, path, desired):
        current = self.request(path)
        if any(current.get(k) != v for k, v in desired.items()):
            self.changes.append(path)
            if not self.check:
                self.request(path, dict(current, **desired))

    def reconcile(self, server, libraries, dlna_version, dlna_config):
        public = self.request('/System/Info/Public')
        if not public['StartupWizardCompleted']:
            if self.check:
                self.changes.append('initial setup')
                return False
            # Initialize the first user before setting its password. Authenticate
            # first so interrupted provisioning with an existing password resumes.
            self.request('/Startup/User')
            try:
                self.login()
            except HTTPError as error:
                if error.code not in (400, 401, 403):
                    raise
                self.request('/Startup/User',
                             {'Name': self.username, 'Password': self.password})
                self.login()
            self.request('/Startup/Complete', {}, method='POST')
            self.changes.append('initial setup')
        else:
            self.login()
        self.update('/System/Configuration', server)
        existing = self.request('/Library/VirtualFolders')
        for library in libraries:
            matches = [v for v in existing if v['Name'] == library['name']]
            if len(matches) > 1:
                raise ValueError('Duplicate library name: ' + library['name'])
            if not matches:
                self.changes.append('library ' + library['name'])
                if not self.check:
                    query = urlencode({'name': library['name'],
                                       'collectionType': library['type']})
                    self.request('/Library/VirtualFolders?' + query, {
                        'LibraryOptions': {'PathInfos': [
                            {'Path': p} for p in library['paths']]}})
                continue
            current = matches[0]
            if current['CollectionType'] != library['type']:
                raise ValueError('Library type differs; refusing to delete library: '
                                 + library['name'])
            for path in sorted(set(library['paths']) - set(current['Locations'])):
                self.changes.append('add library path ' + path)
                if not self.check:
                    self.request('/Library/VirtualFolders/Paths', {
                        'Name': library['name'], 'PathInfo': {'Path': path}})
            for path in sorted(set(current['Locations']) - set(library['paths'])):
                self.changes.append('remove library path ' + path)
                if not self.check:
                    self.request('/Library/VirtualFolders/Paths?' + urlencode({
                        'name': library['name'], 'path': path}), method='DELETE')

        plugin_id = '33eba9cd-7da1-4720-967f-dd7dae7b74a1'
        plugins = self.request('/Plugins')
        matching = [p for p in plugins if p['Id'].replace('-', '') ==
                    plugin_id.replace('-', '') and p['Version'] == dlna_version]
        if not matching:
            self.changes.append('install DLNA ' + dlna_version)
            if not self.check:
                self.request('/Packages/Installed/DLNA?' + urlencode({
                    'assemblyGuid': plugin_id, 'version': dlna_version}),
                    {}, method='POST')
            return True
        if matching[0]['Status'] == 'Restart':
            return True
        if matching[0]['Status'] != 'Active':
            raise ValueError('DLNA plugin is not active: ' + matching[0]['Status'])
        self.update('/Plugins/' + plugin_id + '/Configuration', dlna_config)
        return False


def main():
    module = AnsibleModule(argument_spec={
        'url': {'type': 'str', 'default': 'http://127.0.0.1:8096'},
        'username': {'type': 'str', 'required': True},
        'password': {'type': 'str', 'required': True, 'no_log': True},
        'server': {'type': 'dict', 'required': True},
        'libraries': {'type': 'list', 'elements': 'dict', 'required': True},
        'dlna_version': {'type': 'str', 'required': True},
        'dlna_config': {'type': 'dict', 'required': True},
    }, supports_check_mode=True)
    p = module.params
    client = Jellyfin(p['url'], p['username'], p['password'], module.check_mode)
    try:
        restart = client.reconcile(p['server'], p['libraries'],
                                   p['dlna_version'], p['dlna_config'])
        module.exit_json(changed=bool(client.changes), changes=client.changes,
                         restart_required=restart)
    except HTTPError as error:
        # Never include API bodies or headers: they can contain credentials.
        module.fail_json(msg='Jellyfin API returned HTTP ' + str(error.code)
                         + ' at ' + error.url.split('?', 1)[0],
                         changed=bool(client.changes))
    except (OSError, ValueError, KeyError) as error:
        module.fail_json(msg=str(error), changed=bool(client.changes))


if __name__ == '__main__':
    main()
