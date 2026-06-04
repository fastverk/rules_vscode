# rules_vscode

Bazel-idiomatic, **deterministic** generation of VSCode artifacts —
multi-root `.code-workspace` files and `settings.json` — with aspect-driven
folder assembly and workspace merging ("single pane of glass") for org-root
Bazel workspaces.

Emission is pure `ctx.actions.write` of canonical JSON (folders ordered by
path, root `.` first; setting keys sorted) — bit-exact for a given input, so
`write_source_files` diffs stay minimal. The emitted document conforms to a
pinned JSON Schema (see [`//schema`](schema/code-workspace.schema.json)).

## Install

`MODULE.bazel`:

```python
bazel_dep(name = "rules_vscode", version = "0.0.1")
```

## Public API — `@rules_vscode//vscode:defs.bzl`

| Symbol | Purpose |
|--------|---------|
| `vscode_workspace` | Emit a multi-root `.code-workspace`; provides `VscodeWorkspaceInfo`. |
| `vscode_workspace_merge` | Merge N workspaces (under path prefixes) into one — the "single pane of glass". |
| `vscode_settings` | Emit a canonical `settings.json`. |
| `vscode_folder` / `vscode_folder_aspect` | Declare folder contributions assembled from the build graph. |

### Per-org workspace generator

```python
load("@rules_vscode//vscode:defs.bzl", "vscode_workspace")

vscode_workspace(
    name = "workspace",
    root_label = "fastverk (meta)",
    folders = {
        "repos/rules_uv": "rules_uv",
        "repos/bazel-registry": "bazel-registry",
    },
    settings = {"files.exclude": {"**/bazel-*": True}},
    extensions = ["BazelBuild.vscode-bazel"],
    # `bazel run //:workspace.update` writes the file into the source tree;
    # `bazel test //:workspace.update` checks it is current.
    write_to = "fastverk.code-workspace",
)
```

### Single pane of glass

```python
load("@rules_vscode//vscode:defs.bzl", "vscode_workspace_merge")

vscode_workspace_merge(
    name = "ecosystem",
    workspaces = {
        ":fastverk_ws": "fastverk",   # value = path prefix applied to that
        ":other_ws": "other",         # workspace's folders
    },
    write_to = "ecosystem.code-workspace",
)
```

### Graph-assembled folders

`vscode_folder` targets (and `vscode_folder_aspect` on `folder_deps`) let a
workspace gather its folder list from the build graph instead of hand-listing
paths. Each folder may carry recommended settings/extensions that merge into
the workspace.

## Determinism & the pinned schema

- Folder order is canonical (root `.` first, then lexicographic by path);
  duplicates are removed (first wins). Settings' top-level keys are sorted.
- `//schema/code-workspace.schema.json` pins the document structure; a
  `rules_jsonschema` codegen + `diff_test` (`bazel run //schema:update`) keeps a
  typed Starlark layer in sync with the schema.

## Examples

See [`examples/`](examples/BUILD.bazel) — a per-org workspace, a graph-assembled
folder chain, a merged ecosystem workspace, and golden tests.
