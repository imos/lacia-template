import importlib.util
import json
import os
from pathlib import Path
import tempfile
import unittest

spec = importlib.util.spec_from_file_location('storage', Path(__file__).with_name('local-storage.py'))
storage = importlib.util.module_from_spec(spec)
spec.loader.exec_module(storage)


class InventoryTest(unittest.TestCase):
    def test_missing_local_and_default_limit(self):
        with tempfile.TemporaryDirectory() as tmp:
            result = storage.inventory(Path(tmp).resolve())
            self.assertEqual(result['allocated_bytes'], 0)
            self.assertEqual(result['limit_gib'], 10)
            self.assertFalse(result['exceeds_limit'])

    def test_links_hidden_changes_and_hardlinks(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            local = root / 'local'
            local.mkdir()
            target = local / 'old'
            target.mkdir()
            payload = target / '.draft'
            payload.write_bytes(b'x' * 10000)
            os.utime(payload, (20000000, 20000000))
            os.utime(target, (0, 0))
            os.link(payload, local / 'hardlink')
            outside = root / 'do-not-touch'
            outside.write_text('original')
            (target / 'link').symlink_to(outside)
            os.utime(target / 'link', (0, 0), follow_symlinks=False)
            os.utime(target, (0, 0))
            before = outside.read_bytes()
            result = storage.inventory(root, now=20000001)
            self.assertEqual(outside.read_bytes(), before)
            old = next(item for item in result['entries'] if item['symlinks'])
            self.assertFalse(old['review_due'])
            expected = sum(p.stat().st_blocks * 512 for p in (local, target, payload))
            self.assertEqual(result['allocated_bytes'], expected)
            self.assertEqual(old['symlinks'], ['old/link'])

    def test_limit_boundary_and_invalid_config(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            (root / '.lacia').mkdir()
            (root / 'local').mkdir()
            (root / 'local/data').write_bytes(b'x' * 10000)
            amount = storage.inventory(root)['allocated_bytes']
            config = root / '.lacia/local-storage.json'
            config.write_text(json.dumps({'limit_gib': amount / 1024**3}))
            self.assertFalse(storage.inventory(root)['exceeds_limit'])
            config.write_text(json.dumps({'limit_gib': (amount - 1) / 1024**3}))
            self.assertTrue(storage.inventory(root)['exceeds_limit'])
            config.write_text('{"limit_gib": 0}')
            with self.assertRaises(ValueError):
                storage.inventory(root)

    def test_root_link_rejected(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp).resolve()
            (root / 'real').mkdir()
            (root / 'link').symlink_to(root / 'real')
            with self.assertRaises(ValueError):
                storage.inventory(root / 'link')


if __name__ == '__main__':
    unittest.main()
