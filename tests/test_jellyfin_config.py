"""Test reconciliation decisions independently of a running Jellyfin server."""
import copy
import importlib.util
from pathlib import Path
import unittest
from urllib.error import HTTPError
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location(
    'jellyfin_config', Path(__file__).parents[1] / 'ansible/library/jellyfin_config.py')
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class FakeJellyfin(MODULE.Jellyfin):
    def __init__(self, check=False):
        super().__init__('http://localhost', 'admin', 'test-secret', check)
        self.writes = []
        self.data = {
            '/System/Info/Public': {'StartupWizardCompleted': True},
            '/System/Configuration': {'EnableFolderView': False, 'Unmanaged': 42},
            '/Library/VirtualFolders': [],
            '/Plugins': [{'Id': '33eba9cd-7da1-4720-967f-dd7dae7b74a1',
                          'Version': '14.0.0.0', 'Status': 'Active'}],
            '/Plugins/33eba9cd-7da1-4720-967f-dd7dae7b74a1/Configuration': {
                'EnablePlayTo': True},
        }

    def request(self, path, body=None, method=None):
        if path == '/Users/AuthenticateByName':
            return {'AccessToken': 'test-token'}
        if body is not None or method == 'DELETE':
            self.writes.append((path, body, method))
            self.data[path] = copy.deepcopy(body)
            return None
        return copy.deepcopy(self.data[path])

    def apply(self, libraries=None):
        return self.reconcile({'EnableFolderView': True}, libraries or [],
                              '14.0.0.0', {'EnablePlayTo': True})


class ReconciliationTests(unittest.TestCase):
    def test_fresh_setup_creates_administrator(self):
        client = FakeJellyfin()
        client.data['/System/Info/Public']['StartupWizardCompleted'] = False
        client.data['/Startup/User'] = {'Name': 'default'}
        with patch.object(client, 'login', side_effect=[
                HTTPError('http://localhost', 401, 'Unauthorized', {}, None), None]):
            client.apply()
        paths = [p for p, _, _ in client.writes]
        self.assertLess(paths.index('/Startup/User'), paths.index('/Startup/Complete'))

    def test_interrupted_setup_keeps_existing_password(self):
        client = FakeJellyfin()
        client.data['/System/Info/Public']['StartupWizardCompleted'] = False
        client.data['/Startup/User'] = {'Name': 'admin'}
        client.apply()
        self.assertNotIn('/Startup/User', [p for p, _, _ in client.writes])
        self.assertIn('/Startup/Complete', [p for p, _, _ in client.writes])

    def test_preserve_unmanaged_settings_and_second_apply(self):
        client = FakeJellyfin()
        self.assertFalse(client.apply())
        self.assertEqual(client.data['/System/Configuration']['Unmanaged'], 42)
        client.changes.clear()
        client.writes.clear()
        client.apply()
        self.assertEqual(client.changes, [])
        self.assertEqual(client.writes, [])

    def test_check_mode_does_not_write(self):
        client = FakeJellyfin(check=True)
        client.data['/Plugins'] = []
        self.assertTrue(client.apply([{'name': '録画', 'type': 'movies',
                                       'paths': ['/media']}]))
        self.assertTrue(client.changes)
        self.assertEqual(client.writes, [])

    def test_library_path_drift(self):
        client = FakeJellyfin()
        client.data['/Library/VirtualFolders'] = [
            {'Name': '録画', 'CollectionType': 'movies', 'Locations': ['/old']}]
        client.apply([{'name': '録画', 'type': 'movies', 'paths': ['/media']}])
        self.assertIn('add library path /media', client.changes)
        self.assertIn('remove library path /old', client.changes)

    def test_type_change_refuses_library_deletion(self):
        client = FakeJellyfin()
        client.data['/Library/VirtualFolders'] = [
            {'Name': '録画', 'CollectionType': 'tvshows', 'Locations': ['/media']}]
        with self.assertRaisesRegex(ValueError, 'refusing to delete'):
            client.apply([{'name': '録画', 'type': 'movies', 'paths': ['/media']}])

    def test_missing_plugin_requires_restart(self):
        client = FakeJellyfin()
        client.data['/Plugins'] = []
        self.assertTrue(client.apply())
        self.assertTrue(any(p.startswith('/Packages/Installed/DLNA?')
                            for p, _, _ in client.writes))

    def test_disabled_plugin_is_failure(self):
        client = FakeJellyfin()
        client.data['/Plugins'][0]['Status'] = 'Disabled'
        with self.assertRaisesRegex(ValueError, 'not active'):
            client.apply()


if __name__ == '__main__':
    unittest.main()
