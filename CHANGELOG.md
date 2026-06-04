# Changelog

All notable changes to rules_vscode. The format is loosely
[Keep a Changelog](https://keepachangelog.com/) — version headers
mirror the published bazel-registry entries.

## 0.0.1

- Initial public API in `@rules_vscode//vscode:defs.bzl`:
  - `vscode_workspace` — emit a deterministic multi-root `.code-workspace`;
    provides `VscodeWorkspaceInfo`. Optional `write_to` wires the
    `bazel run //:<name>.update` write-back + up-to-date check
    (aspect_bazel_lib `write_source_files`).
  - `vscode_workspace_merge` — merge N workspaces under path prefixes into one
    ecosystem workspace ("single pane of glass").
  - `vscode_settings` — emit a canonical `settings.json`.
  - `vscode_folder` + `vscode_folder_aspect` — assemble folders (with their
    recommended settings/extensions) from the build graph.
- Canonical JSON emission (folders root-`.`-first then path-sorted; settings
  keys sorted) — bit-exact for a given input.
- `//schema/code-workspace.schema.json` pins the document structure; a
  `rules_jsonschema` Starlark codegen + `diff_test` gates schema drift.
- Golden tests in `examples/`.
