#!/usr/bin/env python3
"""local/ の容量と更新日を読みます。削除の可否は判定しません。"""
import argparse
import datetime
import json
import os
from pathlib import Path
import stat
import time


def inventory(root, now=None):
    root = Path(os.path.abspath(root))
    if any(p.is_symlink() for p in (root, *root.parents)):
        raise ValueError('リポジトリーへの経路にシンボリックリンクがあります。')
    limit = 10
    config = root / '.lacia/local-storage.json'
    if config.exists():
        if config.is_symlink():
            raise ValueError('設定がシンボリックリンクです。')
        values = json.loads(config.read_text())
        if not isinstance(values, dict):
            raise ValueError('設定にはJSONのオブジェクトを指定してください。')
        limit = values.get('limit_gib', 10)
    if isinstance(limit, bool) or not isinstance(limit, (int, float)) or not 0 < limit < float('inf'):
        raise ValueError('limit_gib には0より大きい有限の数を指定してください。')
    base = root / 'local'
    now = time.time() if now is None else now
    seen = set()
    errors = []

    def measure(path):
        try:
            info = path.lstat()
            if stat.S_ISLNK(info.st_mode):
                return 0, info.st_mtime, [str(path.relative_to(base))]
            key = (info.st_dev, info.st_ino)
            size = info.st_blocks * 512 if key not in seen else 0
            seen.add(key)
            latest, links = info.st_mtime, []
            if stat.S_ISDIR(info.st_mode):
                for child in sorted(path.iterdir()):
                    amount, updated, found = measure(child)
                    size += amount
                    latest = max(latest, updated)
                    links.extend(found)
            return size, latest, links
        except OSError as error:
            errors.append(f'{path}: {error.strerror}')
            return 0, now, []

    if base.is_symlink():
        raise ValueError('local/ がシンボリックリンクです。リンク先は読みません。')
    entries = []
    if base.exists():
        if not base.is_dir():
            raise ValueError('local/ はディレクトリーではありません。')
        # 親ディレクトリーの占有分も合計に含めます。
        info = base.stat()
        total = info.st_blocks * 512
        seen.add((info.st_dev, info.st_ino))
        for path in sorted(base.iterdir()):
            size, latest, links = measure(path)
            days = 7 if size >= 1024**3 else 30 if size >= 100 * 1024**2 else 90
            entries.append(dict(name=path.name, allocated_bytes=size,
                                age_days=max(0, (now - latest) / 86400),
                                review_after_days=days,
                                review_due=now - latest >= days * 86400,
                                symlinks=links))
            total += size
    else:
        total = 0
    return dict(root=str(root), measured_at=datetime.datetime.fromtimestamp(now, datetime.timezone.utc).isoformat(),
                allocated_bytes=total, limit_gib=limit,
                exceeds_limit=total > limit * 1024**3, complete=not errors,
                errors=errors, entries=sorted(entries, key=lambda item: -item['allocated_bytes']))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('root', nargs='?', default='.')
    args = parser.parse_args()
    try:
        result = inventory(args.root)
        print(json.dumps(result, ensure_ascii=False, indent=2))
        raise SystemExit(0 if result['complete'] else 1)
    except (ValueError, OSError) as error:
        parser.exit(1, f'点検できませんでした: {error}\n')
