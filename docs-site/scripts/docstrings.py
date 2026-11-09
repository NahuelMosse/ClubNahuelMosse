"""Builds docs-site/docs/code/ with the docstrings of the API, one page per layer.

Reads the code with `ast`, without importing it: the API does not need to be installed nor have its variables.
"""

import ast
import json
import sys
from pathlib import Path

SITE = Path(__file__).resolve().parent.parent
APP = SITE.parent / "apps" / "api" / "app"
DESTINATION = SITE / "docs" / "code"
GITHUB = "https://github.com/NahuelMosse/ClubNahuelMosse/blob/main/apps/api/app/"

LAYERS = [
    ("interfaz", "Interface", "The HTTP routes, the middleware and the console commands."),
    ("aplicacion", "Application", "The use cases: they orchestrate the rules and the repositories."),
    ("dominio", "Domain", "The business rules, with no database or network."),
    ("infraestructura", "Infrastructure", "The SQL, Firebase, the mail and the notifications."),
    ("", "Root", "The application assembly, the configuration and the dependencies."),
]


def text(docstring: str | None) -> str:
    if not docstring:
        return ""
    # Plain Markdown: a loose `<` would be read as HTML.
    return docstring.strip().replace("<", "&lt;") + "\n\n"


def signature(node: ast.FunctionDef | ast.AsyncFunctionDef) -> str:
    prefix = "async def" if isinstance(node, ast.AsyncFunctionDef) else "def"
    returns = f" -> {ast.unparse(node.returns)}" if node.returns else ""
    return f"{prefix} {node.name}({ast.unparse(node.args)}){returns}"


def is_public(name: str) -> bool:
    return not name.startswith("_") or name == "__init__"


def module(path: Path) -> str:
    tree = ast.parse(path.read_text(encoding="utf-8"))
    relative = path.relative_to(APP).as_posix()
    name = "app." + relative.removesuffix(".py").replace("/", ".")
    output = [f"## `{name}`\n\n", f"[View the code]({GITHUB}{relative})\n\n", text(ast.get_docstring(tree))]
    for node in tree.body:
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)) and is_public(node.name):
            output += [f"### `{node.name}`\n\n", f"```python\n{signature(node)}\n```\n\n", text(ast.get_docstring(node))]
        elif isinstance(node, ast.ClassDef) and is_public(node.name):
            bases = ", ".join(ast.unparse(b) for b in node.bases)
            output += [
                f"### `{node.name}`\n\n",
                f"```python\nclass {node.name}({bases})\n```\n\n" if bases else "",
                text(ast.get_docstring(node)),
            ]
            for method in node.body:
                if isinstance(method, (ast.FunctionDef, ast.AsyncFunctionDef)) and is_public(method.name):
                    doc = ast.get_docstring(method)
                    if doc:
                        output += [f"- **`{method.name}`**: {text(doc).strip()}\n"]
            output.append("\n")
    return "".join(output)


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    DESTINATION.mkdir(parents=True, exist_ok=True)
    for position, (folder, title, summary) in enumerate(LAYERS, start=1):
        base = APP / folder
        files = sorted(base.glob("*.py")) if folder else sorted(APP.glob("*.py"))
        files = [f for f in files if f.name != "__init__.py"]
        body = "".join(module(f) for f in files)
        name = folder or "root"
        (DESTINATION / f"{name}.md").write_text(
            f"---\nsidebar_position: {position}\nsidebar_label: {json.dumps(title)}\n---\n\n"
            f"# {title}\n\n{summary} Generated from the docstrings of `apps/api/app/{folder}`.\n\n{body}",
            encoding="utf-8",
        )
    (DESTINATION / "_category_.json").write_text(
        json.dumps({"label": "Code reference (API)", "position": 7, "link": {"type": "generated-index"}}, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"{len(LAYERS)} pages in {DESTINATION.relative_to(SITE.parent)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
