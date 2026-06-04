"""`vscode_workspace` — emit a multi-root `.code-workspace` and expose a
`VscodeWorkspaceInfo` so it can be merged.

Set `write_to` to also get the `bazel run //:<name>.update` generator
target (writes the file back into the source tree, with a bazel-test
up-to-date check) via aspect_bazel_lib's `write_source_files`.
"""

load("@aspect_bazel_lib//lib:write_source_files.bzl", "write_source_files")
load("//vscode/private:render.bzl", "dedup_extensions", "dedup_folders", "merge_settings", "workspace_json")
load(":folder.bzl", "vscode_folder_aspect")
load(":providers.bzl", "VscodeFolderInfo", "VscodeWorkspaceInfo")

def _vscode_workspace_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.out)

    folder_dicts = []
    if ctx.attr.root_label:
        folder_dicts.append({"path": ".", "name": ctx.attr.root_label})
    for path in ctx.attr.folders:
        folder_dicts.append({"path": path, "name": ctx.attr.folders[path]})

    settings_list = [json.decode(ctx.attr.settings_json)] if ctx.attr.settings_json else []
    ext_lists = [list(ctx.attr.extensions)] if ctx.attr.extensions else []

    # Graph-assembled folder contributions (via vscode_folder_aspect).
    for d in ctx.attr.folder_deps:
        if VscodeFolderInfo in d:
            for c in d[VscodeFolderInfo].folders.to_list():
                folder_dicts.append({"path": c.path, "name": c.name})
                if c.settings_json:
                    settings_list.append(json.decode(c.settings_json))
                if c.extensions:
                    ext_lists.append(list(c.extensions))

    folders = dedup_folders(folder_dicts)
    settings = merge_settings(settings_list)
    extensions = dedup_extensions(ext_lists)

    ctx.actions.write(output = out, content = workspace_json(folders, settings, extensions))
    return [
        DefaultInfo(files = depset([out])),
        VscodeWorkspaceInfo(folders = folders, settings = settings, extensions = extensions),
    ]

_vscode_workspace = rule(
    implementation = _vscode_workspace_impl,
    attrs = {
        "out": attr.string(mandatory = True, doc = "Output filename (e.g. `fastverk.code-workspace`)."),
        "root_label": attr.string(doc = "Display name for the implicit `.` folder."),
        "folders": attr.string_dict(doc = "Map of workspace-relative path -> display name."),
        "settings_json": attr.string(doc = "Pre-encoded JSON `settings` block (use the macro)."),
        "extensions": attr.string_list(doc = "Recommended extension ids."),
        "folder_deps": attr.label_list(
            aspects = [vscode_folder_aspect],
            doc = "Targets whose graph contributes `vscode_folder`s.",
        ),
    },
    doc = "Generate a VSCode `.code-workspace` and expose `VscodeWorkspaceInfo`.",
)

def vscode_workspace(
        name,
        out = None,
        root_label = "",
        folders = {},
        settings = {},
        extensions = [],
        folder_deps = [],
        write_to = None,
        **kwargs):
    """Emit a multi-root VSCode workspace.

    Args:
      name: target name (e.g. `workspace`).
      out: output filename; defaults to `<name>.code-workspace`.
      root_label: display name for the implicit `.` folder (the org root).
      folders: dict mapping workspace-relative path -> display name.
      settings: dict embedded under the workspace `settings` block.
      extensions: list of recommended VSCode extension ids.
      folder_deps: targets whose dep graph contributes `vscode_folder`s.
      write_to: if set (a source-relative path, e.g. `fastverk.code-workspace`),
        also create `<name>.update` — `bazel run //...:<name>.update` writes the
        generated file back into the source tree, and `bazel test //...:<name>.update`
        checks it is up to date.
      **kwargs: forwarded to the rule (visibility, tags, …).
    """
    out = out if out else (name + ".code-workspace")
    _vscode_workspace(
        name = name,
        out = out,
        root_label = root_label,
        folders = folders,
        settings_json = json.encode(settings) if settings else "",
        extensions = extensions,
        folder_deps = folder_deps,
        **kwargs
    )
    if write_to:
        write_source_files(
            name = name + ".update",
            files = {write_to: ":" + name},
            visibility = kwargs.get("visibility", None),
        )
