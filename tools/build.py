#!/usr/bin/env python3
"""Build a deterministic, explicitly allowlisted public source archive."""
import argparse
import hashlib
import io
import json
from pathlib import Path
import re
import tarfile

ROOT = Path(__file__).resolve().parents[1]
VERSION = '3.0.0-rc1'

def inputs():
    names = (ROOT / 'PUBLIC_FILES.txt').read_text(encoding='utf-8').splitlines()
    if names != sorted(set(names)):
        raise ValueError('PUBLIC_FILES must be sorted and unique')
    result = {}
    for name in names:
        p = ROOT / name
        if Path(name).is_absolute() or '..' in Path(name).parts or p.is_symlink():
            raise ValueError(f'Unsafe publication path: {name}')
        data = p.read_bytes()
        text = data.decode('utf-8')
        if b'\r' in data or b'\x00' in data:
            raise ValueError(f'Non-LF or binary publication input: {name}')
        # This is a public source hygiene check, not a guarantee about runtime reports.
        for pattern in (r'(?i)[A-Z]:[/\\]Users[/\\](?!Public\b)[^/\\\s]+',
                        r'(?i)-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----\s*\n[A-Za-z0-9+/]{40}',
                        r'\bgh[pousr]_[A-Za-z0-9]{30,}\b', r'\bgithub_pat_[A-Za-z0-9_]{40,}\b'):
            if re.search(pattern, text):
                raise ValueError(f'Possible private material in {name}')
        result[name] = data
    actual = {p.relative_to(ROOT).as_posix() for p in ROOT.rglob('*') if p.is_file()
              and '__pycache__' not in p.parts and '.git' not in p.parts
              and not p.name.endswith('.pyc')}
    if actual != set(names):
        raise ValueError(f'Unreviewed files or missing allowlist entries: {sorted(actual ^ set(names))}')
    return result

def build(output):
    payload = inputs()
    manifest = ''.join(f'{hashlib.sha256(data).hexdigest()}  {name}\n'
                       for name, data in payload.items()).encode()
    identity = hashlib.sha256(manifest).hexdigest()
    output.mkdir(parents=True, exist_ok=True)
    destination = output / f'nethelp-{VERSION}-{identity[:12]}'
    destination.mkdir()  # Deliberately refuses to overwrite a prior build.
    archive = destination / f'nethelp-{VERSION}.tar'
    temporary = archive.with_suffix('.tar.partial')
    with tarfile.open(temporary, 'w', format=tarfile.USTAR_FORMAT) as tar:
        for name, data in {**payload, 'SHA256SUMS': manifest}.items():
            info = tarfile.TarInfo(f'nethelp-{VERSION}/{name}')
            info.size = len(data)
            info.mode = 0o755 if name == 'bin/nethelp' else 0o644
            info.mtime = 0
            info.uid = info.gid = 0
            info.uname = info.gname = ''
            tar.addfile(info, io.BytesIO(data))
    # Verify the packaged bytes, not just the source tree.
    with tarfile.open(temporary, 'r') as tar:
        for name, data in {**payload, 'SHA256SUMS': manifest}.items():
            member = tar.getmember(f'nethelp-{VERSION}/{name}')
            if not member.isfile() or tar.extractfile(member).read() != data:
                raise ValueError(f'Archive mismatch: {name}')
        if len(tar.getmembers()) != len(payload) + 1:
            raise ValueError('Unexpected archive member')
    temporary.rename(archive)
    (destination / 'SHA256SUMS').write_bytes(manifest)
    receipt = {
        'stage': 'packaged-local-candidate', 'version': VERSION,
        'source_files': len(payload), 'source_manifest_sha256': identity,
        'archive_sha256': hashlib.sha256(archive.read_bytes()).hexdigest(),
        'archive': archive.name, 'archive_bytes': archive.stat().st_size,
        'publication': 'not-performed', 'router_installation': 'not-performed',
        'privacy_scope': 'allowlisted source; automated scan plus separate manual review required',
    }
    (destination / 'BUILD.json').write_text(json.dumps(receipt, indent=2) + '\n', encoding='utf8', newline='\n')
    print(json.dumps({**receipt, 'directory': str(destination)}, indent=2))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output-dir', type=Path, required=True)
    args = parser.parse_args()
    build(args.output_dir.resolve())
