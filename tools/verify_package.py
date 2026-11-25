from pathlib import Path, PurePosixPath
import hashlib, json
root = Path(__file__).resolve().parents[1]
payload = (root / 'payload').resolve()
manifest = json.loads((root / 'payload-manifest.json').read_text(encoding='utf-8-sig'))
seen = set()
for entry in manifest:
    rel = PurePosixPath(entry['path'])
    if rel.is_absolute() or '..' in rel.parts or ':' in str(rel) or '\\' in str(rel):
        raise SystemExit('Unsafe manifest path: '+str(rel))
    path = (payload / str(rel)).resolve()
    if not path.is_relative_to(payload) or path in seen:
        raise SystemExit('Escaping or duplicate path: '+str(rel))
    seen.add(path)
    actual = hashlib.sha256(path.read_bytes()).hexdigest()
    if actual.lower() != entry['sha256'].lower():
        raise SystemExit('Hash mismatch: '+str(rel))
actual_files = {p.resolve() for p in payload.rglob('*') if p.is_file()}
if actual_files != seen:
    raise SystemExit('Unlisted or missing payload files')
print('PASS: '+str(len(seen))+' payload files; exact manifest match; no install performed.')
