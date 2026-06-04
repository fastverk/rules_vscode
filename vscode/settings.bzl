"""`vscode_settings(name, settings, out)` — emit a canonical `settings.json`."""

load("//vscode/private:render.bzl", "settings_json")

def _vscode_settings_impl(ctx):
    out = ctx.actions.declare_file(ctx.attr.out)
    settings = json.decode(ctx.attr.settings_json) if ctx.attr.settings_json else {}
    ctx.actions.write(output = out, content = settings_json(settings))
    return [DefaultInfo(files = depset([out]))]

_vscode_settings = rule(
    implementation = _vscode_settings_impl,
    attrs = {
        "out": attr.string(mandatory = True, doc = "Output filename."),
        "settings_json": attr.string(doc = "Pre-encoded JSON settings (use the macro)."),
    },
    doc = "Emit a canonical (key-sorted) VSCode `settings.json`.",
)

def vscode_settings(name, settings = {}, out = "settings.json", **kwargs):
    """Emit a `settings.json` from a Starlark dict.

    Args:
      name: target name.
      settings: dict embedded as the settings document.
      out: output filename (default `settings.json`).
      **kwargs: forwarded to the rule (visibility, tags, …).
    """
    _vscode_settings(
        name = name,
        out = out,
        settings_json = json.encode(settings) if settings else "",
        **kwargs
    )
