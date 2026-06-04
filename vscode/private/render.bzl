"""Deterministic JSON rendering for VSCode artifacts.

VSCode consumes JSON — it publishes JSON Schemas for `.code-workspace`
and `settings.json` — so these emitters serialize to canonical JSON
rather than protobuf (the JSON-Schema layer is pinned via
`rules_jsonschema`; see `//schema`). Output is *canonicalized* (dict
keys sorted recursively, folders ordered by path with the `.` root
first), so the generated file is bit-exact for a given logical input
regardless of attribute ordering — which keeps `write_source_files`
diffs minimal.

Hermeticity: emission is pure `ctx.actions.write` — no subprocess, no
toolchain. The output is bit-exact for a given input.
"""

def _sorted_top(d):
    # Sort a dict's top-level keys for a stable encoding. Starlark forbids
    # recursion, so nested values keep their (input-deterministic) order;
    # `json.encode_indent` preserves dict insertion order. This is enough for
    # diff-stable output because the BUILD input is itself the source of truth.
    return {k: d[k] for k in sorted(d.keys())}

def _folder_sort_key(path):
    # The meta-repo's own folder (path ".") always sorts first.
    return "" if path == "." else path

def dedup_folders(folder_dicts):
    """De-duplicate {path, name} dicts by path (first wins), then return
    them in canonical order (root `.` first, then lexicographic by path)."""
    seen = {}
    for f in folder_dicts:
        if f["path"] not in seen:
            seen[f["path"]] = {"path": f["path"], "name": f["name"]}
    return [seen[p] for p in sorted(seen.keys(), key = _folder_sort_key)]

def merge_settings(dicts):
    """Merge a list of settings dicts (later wins). When both sides map a
    key to a dict (e.g. two contributors to `files.exclude`) the dicts are
    merged one level deep rather than clobbered."""
    out = {}
    for d in dicts:
        for k, v in d.items():
            if k in out and type(out[k]) == "dict" and type(v) == "dict":
                merged = dict(out[k])
                merged.update(v)
                out[k] = merged
            else:
                out[k] = v
    return out

def dedup_extensions(lists):
    """Flatten + de-duplicate extension-id lists, preserving first-seen order."""
    out = []
    seen = {}
    for lst in lists:
        for e in lst:
            if e not in seen:
                seen[e] = True
                out.append(e)
    return out

def prefix_path(prefix, p):
    """Re-root a folder path under `prefix` (used when merging org
    workspaces into one ecosystem workspace). `prefix` "" is identity;
    a `.` folder becomes the prefix itself."""
    if not prefix:
        return p
    if p == ".":
        return prefix
    return prefix + "/" + p

def workspace_json(folders, settings, extensions):
    """Render the canonical `.code-workspace` JSON (trailing newline).

    Top-level keys are emitted in a fixed order (folders, settings,
    extensions); folders are pre-ordered by `dedup_folders`; settings'
    top-level keys are sorted. Bit-exact for a given logical input."""
    ws = {"folders": folders}
    if settings:
        ws["settings"] = _sorted_top(settings)
    if extensions:
        ws["extensions"] = {"recommendations": extensions}
    return json.encode_indent(ws, indent = "  ") + "\n"

def settings_json(settings):
    """Render a canonical `settings.json` (trailing newline)."""
    return json.encode_indent(_sorted_top(settings) if settings else {}, indent = "  ") + "\n"
