"""`vscode_folder` + `vscode_folder_aspect` — assemble a workspace's
folder list from the build graph rather than hand-listing paths.

A `vscode_folder` declares one workspace folder (a path, a display name,
and optional settings/extensions it recommends) plus `deps` on other
`vscode_folder` targets. `vscode_workspace(folder_deps = [...])` then
collects the transitive closure. `vscode_folder_aspect` lets a workspace
harvest contributions reachable through an arbitrary target's `deps`
edges (e.g. point it at a top-level target whose graph contains folder
declarations).
"""

load(":providers.bzl", "VscodeFolderInfo")

def _contrib(path, name, settings_json, extensions):
    return struct(
        path = path,
        name = name if name else path,
        settings_json = settings_json,
        extensions = tuple(extensions),
    )

def _vscode_folder_impl(ctx):
    transitive = [d[VscodeFolderInfo].folders for d in ctx.attr.deps]
    own = _contrib(
        ctx.attr.path,
        ctx.attr.display_name,
        ctx.attr.settings_json,
        ctx.attr.extensions,
    )
    return [VscodeFolderInfo(
        folders = depset(direct = [own], transitive = transitive),
    )]

vscode_folder = rule(
    implementation = _vscode_folder_impl,
    attrs = {
        "path": attr.string(mandatory = True, doc = "Workspace-relative folder path."),
        "display_name": attr.string(doc = "Display name (defaults to `path`)."),
        "settings_json": attr.string(doc = "Pre-encoded JSON settings this folder recommends."),
        "extensions": attr.string_list(doc = "Recommended extension ids."),
        "deps": attr.label_list(
            providers = [[VscodeFolderInfo]],
            doc = "Other `vscode_folder` targets to fold in transitively.",
        ),
    },
    doc = "Declare one workspace folder contribution (graph-assemblable).",
)

def _vscode_folder_aspect_impl(target, ctx):
    # A vscode_folder already exposes its own + transitive closure; for any
    # other rule, gather VscodeFolderInfo reachable through its `deps`.
    if VscodeFolderInfo in target:
        return []
    transitive = [
        d[VscodeFolderInfo].folders
        for d in getattr(ctx.rule.attr, "deps", [])
        if VscodeFolderInfo in d
    ]
    if not transitive:
        return []
    return [VscodeFolderInfo(folders = depset(transitive = transitive))]

vscode_folder_aspect = aspect(
    implementation = _vscode_folder_aspect_impl,
    attr_aspects = ["deps"],
    doc = "Walk `deps` edges collecting `vscode_folder` contributions.",
)
