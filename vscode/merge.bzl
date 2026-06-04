"""`vscode_workspace_merge` — merge N `VscodeWorkspaceInfo`s into one
`.code-workspace` (the "single pane of glass").

Each input workspace is given a path *prefix* (the value in the
`workspaces` dict). A prefix re-roots that workspace's folders under a
subdirectory — so merging the per-org workspaces (each with their own `.`
root) into an ecosystem workspace at the parent dir keeps every folder
addressable (`fastverk`, `fastverk/repos/rules_uv`, `acme/lib`, …).
"""

load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_files")
load(
    "//vscode/private:render.bzl",
    "dedup_extensions",
    "dedup_folders",
    "merge_settings",
    "prefix_path",
    "workspace_json",
)
load(":providers.bzl", "VscodeWorkspaceInfo")

def _vscode_workspace_merge_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.out)

    folder_dicts = []
    settings_list = []
    ext_lists = []
    for w, prefix in ctx.attr.workspaces.items():
        info = w[VscodeWorkspaceInfo]
        for f in info.folders:
            folder_dicts.append({"path": prefix_path(prefix, f["path"]), "name": f["name"]})
        if info.settings:
            settings_list.append(info.settings)
        if info.extensions:
            ext_lists.append(info.extensions)

    folders = dedup_folders(folder_dicts)
    settings = merge_settings(settings_list)
    extensions = dedup_extensions(ext_lists)

    ctx.actions.write(output = out, content = workspace_json(folders, settings, extensions))
    return [
        DefaultInfo(files = depset([out])),
        VscodeWorkspaceInfo(folders = folders, settings = settings, extensions = extensions),
    ]

_vscode_workspace_merge = rule(
    implementation = _vscode_workspace_merge_impl,
    attrs = {
        "out": attr.string(mandatory = True, doc = "Output filename."),
        "workspaces": attr.label_keyed_string_dict(
            providers = [[VscodeWorkspaceInfo]],
            mandatory = True,
            doc = "Map of `vscode_workspace` target -> path prefix (\"\" = no prefix).",
        ),
    },
    doc = "Merge multiple `vscode_workspace`s into one ecosystem workspace.",
)

def vscode_workspace_merge(name, workspaces, out = None, write_to = None, **kwargs):
    """Merge multiple workspaces into one.

    Args:
      name: target name (e.g. `ecosystem`).
      workspaces: dict mapping each `vscode_workspace` target -> a path prefix
        applied to that workspace's folders ("" for none).
      out: output filename; defaults to `<name>.code-workspace`.
      write_to: optional source-relative path to also create `<name>.update`.
      **kwargs: forwarded to the rule.
    """
    out = out if out else (name + ".code-workspace")
    _vscode_workspace_merge(name = name, out = out, workspaces = workspaces, **kwargs)
    if write_to:
        write_source_files(
            name = name + ".update",
            files = {write_to: ":" + name},
            visibility = kwargs.get("visibility", None),
        )
