"""Providers for rules_vscode.

`VscodeWorkspaceInfo` carries a fully-resolved workspace (folders +
settings + recommended extensions) through the analysis graph so that
workspaces can be *merged* (`vscode_workspace_merge`) before emission —
the "single pane of glass".

`VscodeFolderInfo` carries folder *contributions* gathered transitively
by `vscode_folder` / `vscode_folder_aspect`, so a workspace can be
assembled from the build graph rather than a hand-written folder list.
"""

VscodeWorkspaceInfo = provider(
    doc = "A resolved VSCode multi-root workspace, mergeable in analysis.",
    fields = {
        "folders": "list of {\"path\": str, \"name\": str} dicts, path-unique.",
        "settings": "dict: the workspace `settings` block (JSON-encodable).",
        "extensions": "list[str]: recommended extension ids (de-duplicated).",
    },
)

VscodeFolderInfo = provider(
    doc = "Folder contributions for graph/aspect assembly. Each contribution " +
          "is a hashable struct(path, name, settings_json, extensions) so it " +
          "can ride a depset.",
    fields = {
        "folders": "depset of struct(path, name, settings_json, extensions).",
    },
)
