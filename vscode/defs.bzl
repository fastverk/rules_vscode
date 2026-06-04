"""Public API for rules_vscode.

```python
load("@rules_vscode//vscode:defs.bzl",
     "vscode_workspace", "vscode_workspace_merge", "vscode_settings", "vscode_folder")
```
"""

load(":folder.bzl", _vscode_folder = "vscode_folder", _vscode_folder_aspect = "vscode_folder_aspect")
load(":merge.bzl", _vscode_workspace_merge = "vscode_workspace_merge")
load(":providers.bzl", _VscodeFolderInfo = "VscodeFolderInfo", _VscodeWorkspaceInfo = "VscodeWorkspaceInfo")
load(":settings.bzl", _vscode_settings = "vscode_settings")
load(":workspace.bzl", _vscode_workspace = "vscode_workspace")

vscode_workspace = _vscode_workspace
vscode_workspace_merge = _vscode_workspace_merge
vscode_settings = _vscode_settings
vscode_folder = _vscode_folder
vscode_folder_aspect = _vscode_folder_aspect
VscodeWorkspaceInfo = _VscodeWorkspaceInfo
VscodeFolderInfo = _VscodeFolderInfo
