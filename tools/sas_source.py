"""Small SAS lexical checks, not a SAS compiler or numerical execution engine."""

from __future__ import annotations

import re
from pathlib import Path


def active_source(source: str) -> tuple[str, list[str]]:
    """Mask comments, preserve strings/newlines, and report unfinished tokens.

    SAS block comments do not nest. Quoted literals can contain doubled quotes.
    Statement comments start with * at a statement boundary; %* also works.
    """
    result = list(source)
    issues: list[str] = []
    i = 0
    boundary = True
    while i < len(source):
        if source.startswith("/*", i):
            end = source.find("*/", i + 2)
            if end < 0:
                issues.append(f"unclosed block comment at line {source.count(chr(10), 0, i) + 1}")
                end = len(source)
            else:
                end += 2
            for j in range(i, end):
                if source[j] != "\n":
                    result[j] = " "
            i = end
        elif source.startswith("%*", i) or (source[i] == "*" and boundary):
            end = source.find(";", i)
            if end < 0:
                issues.append("unclosed statement comment")
                end = len(source)
            else:
                end += 1
            for j in range(i, end):
                if source[j] != "\n":
                    result[j] = " "
            i = end
            boundary = True
        elif source[i] in "\"'":
            quote = source[i]
            start = i
            i += 1
            while i < len(source):
                if source[i] == quote:
                    if i + 1 < len(source) and source[i + 1] == quote:
                        i += 2
                        continue
                    i += 1
                    break
                i += 1
            else:
                issues.append(f"unclosed string at line {source.count(chr(10), 0, start) + 1}")
            boundary = False
        else:
            if source[i] == ";":
                boundary = True
            elif not source[i].isspace():
                boundary = False
            i += 1
    return "".join(result), issues


def mask_strings(source: str) -> str:
    return re.sub(r"'(?:''|[^'])*'|\"(?:\"\"|[^\"])*\"", "''", source)


def check_file(path: Path) -> list[str]:
    active, issues = active_source(path.read_text())
    code = mask_strings(active)
    depth = 0
    for token in code:
        if token == "(":
            depth += 1
        elif token == ")":
            depth -= 1
            if depth < 0:
                issues.append("unmatched closing parenthesis")
                break
    if depth:
        issues.append(f"unbalanced parentheses: {depth}")
    if re.search(r",\s*,", code):
        issues.append("empty argument or column between commas")
    if len(re.findall(r"%macro\b", code, re.I)) != len(re.findall(r"%mend\b", code, re.I)):
        issues.append("unbalanced macro definitions")
    return issues


if __name__ == "__main__":
    root = Path(__file__).resolve().parents[1]
    failures = []
    for path in sorted(root.rglob("*.sas")):
        for issue in check_file(path):
            failures.append(f"{path.relative_to(root)}: {issue}")
    print("\n".join(failures) if failures else "SAS lexical checks passed")
    raise SystemExit(bool(failures))
