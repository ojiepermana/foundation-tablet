"""List or select numbered features from the repository's scope index."""

import argparse
import re
from dataclasses import dataclass
from pathlib import Path


ROOT = Path(__file__).resolve().parents[4]
SCOPE = Path("docs/scope")


@dataclass
class Feature:
    number: int
    title: str
    path: Path
    status: str
    open_steps: int


def count_open_steps(markdown):
    count = 0
    fence = ""
    for line in markdown.splitlines():
        stripped = line.strip()
        if fence:
            if stripped.startswith(fence) and not stripped.strip(fence[0]):
                fence = ""
        elif marker := re.match(r"(`{3,}|~{3,})", stripped):
            fence = marker[1]
        elif re.match(r"^[-*+]\s+\[ \](?:\s|$)", stripped):
            count += 1
    return count


def read_index():
    directory = ROOT / SCOPE
    features = {}
    for line in (directory / "index.md").read_text(encoding="utf-8").splitlines():
        if not re.match(r"^\s*\|\s*\d+\s*\|", line):
            continue
        cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
        if len(cells) != 4:
            raise ValueError(f"Baris fitur tidak valid pada indeks: {line}")
        link = re.fullmatch(r"\[([^\]]+)\]\(([^)]+)\)", cells[1])
        if not link:
            raise ValueError(f"Baris fitur tidak valid pada indeks: {line}")
        number = int(cells[0])
        title, filename = link.groups()
        prefix = re.fullmatch(r"(\d+)-[^/]+\.md", filename)
        if not prefix or int(prefix[1]) != number or number in features:
            raise ValueError(f"Nomor atau nama file tidak konsisten pada indeks: {line}")
        page = (directory / filename).read_text(encoding="utf-8")
        heading = re.search(r"^# (\d+)\. (.+)$", page, re.MULTILINE)
        metadata = heading[2].split(" · ") if heading else []
        if not heading or int(heading[1]) != number or metadata[:2] != [title, cells[3]]:
            raise ValueError(f"Nomor, judul atau status {filename} berbeda dari indeks")
        features[number] = Feature(number, title, SCOPE / filename, cells[3], count_open_steps(page))

    if not features:
        raise ValueError("Indeks scope tidak memuat fitur bernomor")
    listed = {f.path.name for f in features.values()}
    unlisted = [p.name for p in directory.glob("[0-9]*-*.md") if p.name not in listed]
    if unlisted:
        raise ValueError("File fitur belum masuk indeks: " + ", ".join(sorted(unlisted)))
    return list(features.values())


def select_feature(features, query):
    path = Path(query.strip())
    if path.is_absolute():
        path = path.resolve()
    for feature in features:
        if path in (feature.path, ROOT / feature.path, Path(feature.path.name)):
            return feature

    term = query.strip().casefold()
    selector = re.fullmatch(r"(?:(?:scope|fitur|f)\s*)?(\d+)(?:(?:\s*[·.]\s*|\s+)(.+))?", term)
    if selector:
        features = [f for f in features if f.number == int(selector[1])]
        term = selector[2] or ""

    exact = [f for f in features if f.title.casefold() == term]
    matches = exact or [f for f in features if term in f.title.casefold()]
    if len(matches) == 1:
        return matches[0]
    if matches:
        raise ValueError(f"Pilihan '{query}' cocok dengan: " + ", ".join(f.title for f in matches))
    raise ValueError(f"Fitur tidak ditemukan pada indeks: {query}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("selector", nargs="*", help="Nomor, F04, judul, atau path file fitur")
    args = parser.parse_args()
    try:
        features = read_index()
        if args.selector:
            print(select_feature(features, " ".join(args.selector)).path.as_posix())
        else:
            for f in features:
                print(f"{f.number:02d}\t{f.title}\t{f.status}\t{f.open_steps} terbuka\t{f.path.as_posix()}")
            print(f"Total: {len(features)} fitur, {sum(f.open_steps for f in features)} langkah terbuka")
    except (ValueError, OSError) as error:
        parser.exit(1, f"{error}\n")


if __name__ == "__main__":
    main()
