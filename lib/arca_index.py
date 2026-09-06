#!/usr/bin/env python3
"""arca_index.py — índice de búsqueda local de PDF, TXT, Markdown, HTML y EPUB (SQLite FTS5).

Uso:
  arca_index.py build [--root /srv/respaldo] [--db RUTA] [--ocr]   crea o actualiza el índice
  arca_index.py search "consulta" [--n 10] [--category CAT] [--json]
  arca_index.py stats

Arquitectura: PDF → pdftotext (una entrada por página) → SQLite FTS5 (BM25) → fragmentos.
Solo biblioteca estándar de Python 3 más pdftotext (poppler-utils). OCR opcional con ocrmypdf.
"""
import argparse
import html
import json
import os
import re
import sqlite3
import subprocess
import sys
import time
import zipfile
from html.parser import HTMLParser

ROOT = os.environ.get("RESPALDO", "/srv/respaldo")
DB_DEFAULT = os.path.join(ROOT, ".arca", "search.db")
CARPETAS = ["manuales", "libros", "referencia", "docs"]
EXTENSIONES = {".pdf", ".txt", ".md", ".epub", ".html", ".htm"}
MAX_CHUNK = 2000          # caracteres por fragmento en texto plano
MIN_TEXTO_PDF = 200       # menos que esto en un PDF de >3 páginas: probablemente escaneado sin OCR


class _Texto(HTMLParser):
    def __init__(self):
        super().__init__()
        self.partes, self._omitir = [], 0

    def handle_starttag(self, tag, attrs):
        if tag in ("script", "style"):
            self._omitir += 1
        elif tag in ("p", "br", "li", "h1", "h2", "h3", "h4", "div", "tr"):
            self.partes.append("\n")

    def handle_endtag(self, tag):
        if tag in ("script", "style") and self._omitir:
            self._omitir -= 1

    def handle_data(self, data):
        if not self._omitir:
            self.partes.append(data)


def html_a_texto(cuerpo):
    p = _Texto()
    p.feed(cuerpo)
    return html.unescape("".join(p.partes))


def limpiar(t):
    t = t.replace("\x00", " ")
    t = re.sub(r"[ \t]+", " ", t)
    t = re.sub(r"\n\s*\n+", "\n", t)
    return t.strip()


def trocear(texto, maximo=MAX_CHUNK):
    """Divide texto largo en trozos de ~maximo caracteres cortando en párrafos o frases."""
    if len(texto) <= maximo:
        return [texto] if texto else []
    trozos, actual = [], ""
    for parrafo in re.split(r"\n(?=\S)", texto):
        if len(actual) + len(parrafo) + 1 > maximo and actual:
            trozos.append(actual.strip())
            actual = ""
        if len(parrafo) > maximo:
            for frase in re.split(r"(?<=[.!?])\s+", parrafo):
                if len(actual) + len(frase) + 1 > maximo and actual:
                    trozos.append(actual.strip())
                    actual = ""
                actual += frase + " "
        else:
            actual += parrafo + "\n"
    if actual.strip():
        trozos.append(actual.strip())
    return trozos


# ------------------------------------------------------------------ extracción

def extraer_pdf(ruta):
    """Devuelve lista de (pagina, texto). Usa pdftotext; las páginas van separadas por \\f."""
    try:
        salida = subprocess.run(["pdftotext", "-enc", "UTF-8", ruta, "-"], capture_output=True,
                                timeout=600, check=False).stdout.decode("utf-8", errors="replace")
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return []
    paginas = salida.split("\f")
    return [(i + 1, limpiar(t)) for i, t in enumerate(paginas) if limpiar(t)]


def extraer_epub(ruta):
    partes = []
    try:
        with zipfile.ZipFile(ruta) as z:
            nombres = sorted(n for n in z.namelist() if n.lower().endswith((".xhtml", ".html", ".htm")))
            for n in nombres:
                partes.append(limpiar(html_a_texto(z.read(n).decode("utf-8", errors="replace"))))
    except (zipfile.BadZipFile, OSError):
        return []
    return [(None, t) for t in partes if t]


def extraer_texto(ruta):
    try:
        with open(ruta, encoding="utf-8", errors="replace") as f:
            t = f.read()
    except OSError:
        return []
    if ruta.lower().endswith((".html", ".htm")):
        t = html_a_texto(t)
    return [(None, limpiar(t))] if limpiar(t) else []


def titulo_de(ruta, texto_inicial):
    base = os.path.splitext(os.path.basename(ruta))[0]
    if ruta.lower().endswith(".md"):
        m = re.search(r"^#\s+(.+)$", texto_inicial, re.M)
        if m:
            return m.group(1).strip()[:200]
    return base.replace("-", " ").replace("_", " ")


# ------------------------------------------------------------------ metadatos del manifiesto

def cargar_manifiesto(root):
    meta = {}
    ruta = os.path.join(root, "MANIFEST.tsv")
    if not os.path.exists(ruta):
        return meta
    with open(ruta, encoding="utf-8", errors="replace") as f:
        cab = f.readline().rstrip("\n").split("\t")
        for linea in f:
            campos = linea.rstrip("\n").split("\t")
            if len(campos) < len(cab):
                continue
            fila = dict(zip(cab, campos))
            meta[fila["path"]] = fila
    return meta


def categoria_por_ruta(rel):
    partes = rel.split("/")
    if partes[0] == "manuales" and len(partes) > 2:
        return partes[1]
    if partes[0] == "libros":
        return "libros"
    if partes[0] == "referencia":
        return "referencia"
    if partes[0] == "docs":
        return "documentacion"
    return partes[0]


ES_MARCAS = re.compile(r"\b(el|la|los|las|de|que|para|con|una|por)\b", re.I)
EN_MARCAS = re.compile(r"\b(the|and|of|to|with|for|that|is|are)\b", re.I)


def idioma_de(rel, texto):
    if re.search(r"(-|_)es(\.|/|$)|espa[ñn]ol|openstax-es|autores-espanoles", rel, re.I):
        return "es"
    muestra = texto[:5000]
    es, en = len(ES_MARCAS.findall(muestra)), len(EN_MARCAS.findall(muestra))
    if es == en == 0:
        return "unknown"
    return "es" if es > en else "en"


# ------------------------------------------------------------------ base de datos

def abrir(db):
    os.makedirs(os.path.dirname(db), exist_ok=True)
    con = sqlite3.connect(db)
    con.execute("PRAGMA journal_mode=WAL")
    con.execute("""CREATE TABLE IF NOT EXISTS docs (
        id INTEGER PRIMARY KEY, path TEXT UNIQUE, title TEXT, category TEXT, language TEXT,
        priority TEXT, size INTEGER, mtime INTEGER, pages INTEGER, chunks INTEGER,
        needs_ocr INTEGER DEFAULT 0, indexed_at TEXT)""")
    con.execute("""CREATE VIRTUAL TABLE IF NOT EXISTS chunks USING fts5(
        text, title, path UNINDEXED, doc_id UNINDEXED, page UNINDEXED, category UNINDEXED,
        tokenize='unicode61 remove_diacritics 2')""")
    return con


def indexar_archivo(con, root, rel, meta):
    ruta = os.path.join(root, rel)
    st = os.stat(ruta)
    fila = con.execute("SELECT id, size, mtime, needs_ocr FROM docs WHERE path=?", (rel,)).fetchone()
    if fila and fila[1] == st.st_size and fila[2] == int(st.st_mtime):
        return "igual"
    ext = os.path.splitext(rel)[1].lower()
    if ext == ".pdf":
        entradas = extraer_pdf(ruta)
    elif ext == ".epub":
        entradas = extraer_epub(ruta)
    else:
        entradas = extraer_texto(ruta)
    texto_total = sum(len(t) for _, t in entradas)
    paginas = max((p for p, _ in entradas if p), default=0)
    needs_ocr = 1 if (ext == ".pdf" and texto_total < MIN_TEXTO_PDF and paginas > 3) else 0
    if ext == ".pdf" and needs_ocr:
        # Sin texto: se registra el documento para poder hacer OCR después.
        entradas = []
    m = meta.get(rel, {})
    titulo = titulo_de(rel, entradas[0][1] if entradas else "")
    cat = m.get("category") if m.get("category", "unknown") != "unknown" else categoria_por_ruta(rel)
    lang = m.get("language") if m.get("language", "unknown") != "unknown" else idioma_de(rel, entradas[0][1] if entradas else "")
    prio = m.get("priority", "unknown")
    if fila:
        con.execute("DELETE FROM chunks WHERE doc_id=?", (fila[0],))
        con.execute("DELETE FROM docs WHERE id=?", (fila[0],))
    cur = con.execute("INSERT INTO docs(path,title,category,language,priority,size,mtime,pages,chunks,needs_ocr,indexed_at) VALUES (?,?,?,?,?,?,?,?,?,?,?)",
                      (rel, titulo, cat, lang, prio, st.st_size, int(st.st_mtime), paginas, 0, needs_ocr, time.strftime("%Y-%m-%dT%H:%M:%S")))
    doc_id = cur.lastrowid
    n = 0
    for pagina, texto in entradas:
        for trozo in trocear(texto):
            con.execute("INSERT INTO chunks(text,title,path,doc_id,page,category) VALUES (?,?,?,?,?,?)",
                        (trozo, titulo, rel, doc_id, pagina, cat))
            n += 1
    con.execute("UPDATE docs SET chunks=? WHERE id=?", (n, doc_id))
    return "ocr-pendiente" if needs_ocr else "indexado"


def build(args):
    root = args.root
    con = abrir(args.db)
    meta = cargar_manifiesto(root)
    archivos = []
    for carpeta in CARPETAS:
        base = os.path.join(root, carpeta)
        for dirpath, _, nombres in os.walk(base):
            for n in nombres:
                if os.path.splitext(n)[1].lower() in EXTENSIONES and not n.endswith((".part", ".tmp")):
                    archivos.append(os.path.relpath(os.path.join(dirpath, n), root))
    for n in ("START_HERE.txt", "START_HERE_ES.txt", "START_HERE_EN.txt", "README.txt"):
        if os.path.exists(os.path.join(root, n)):
            archivos.append(n)
    archivos.sort()
    # Documentos que ya no existen.
    existentes = set(archivos)
    for (doc_id, rel) in con.execute("SELECT id, path FROM docs").fetchall():
        if rel not in existentes:
            con.execute("DELETE FROM chunks WHERE doc_id=?", (doc_id,))
            con.execute("DELETE FROM docs WHERE id=?", (doc_id,))
    total, hechos, nuevos, ocr = len(archivos), 0, 0, 0
    inicio = time.time()
    for rel in archivos:
        try:
            r = indexar_archivo(con, root, rel, meta)
        except Exception as e:  # noqa: BLE001 — un archivo roto no debe parar el índice
            r = f"error: {e}"
        hechos += 1
        if r == "indexado":
            nuevos += 1
        elif r == "ocr-pendiente":
            ocr += 1
        if hechos % 10 == 0 or hechos == total:
            con.commit()
            sys.stderr.write(f"\r  {hechos}/{total} archivos ({nuevos} indexados, {ocr} sin texto)   ")
    con.commit()
    sys.stderr.write("\n")
    if args.ocr:
        ocr_pendientes(con, root)
    con.execute("INSERT OR REPLACE INTO docs(id,path,title,category,language,priority,size,mtime,pages,chunks,needs_ocr,indexed_at) "
                "SELECT id,path,title,category,language,priority,size,mtime,pages,chunks,needs_ocr,indexed_at FROM docs WHERE 0")
    con.commit()
    d = con.execute("SELECT count(*), sum(chunks), sum(needs_ocr) FROM docs").fetchone()
    print(f"Índice {args.db}: {d[0]} documentos, {d[1] or 0} fragmentos, {d[2] or 0} PDF sin texto (OCR pendiente). {int(time.time()-inicio)} s.")


def ocr_pendientes(con, root):
    """OCR con ocrmypdf (si está instalado) sobre los PDF marcados; reemplaza el PDF por uno con capa de texto."""
    pendientes = [r for (r,) in con.execute("SELECT path FROM docs WHERE needs_ocr=1").fetchall()]
    if not pendientes:
        print("No hay PDF pendientes de OCR.")
        return
    if subprocess.run(["which", "ocrmypdf"], capture_output=True, check=False).returncode != 0:
        print(f"{len(pendientes)} PDF sin texto. Instala ocrmypdf (sudo apt install ocrmypdf tesseract-ocr-spa tesseract-ocr-eng) y repite con --ocr.")
        return
    for rel in pendientes:
        ruta = os.path.join(root, rel)
        print(f"OCR: {rel} (puede tardar varios minutos)...")
        salida = ruta + ".ocr.pdf"
        r = subprocess.run(["ocrmypdf", "--skip-text", "-l", "spa+eng", "--quiet", ruta, salida], check=False)
        if r.returncode == 0 and os.path.exists(salida):
            os.replace(salida, ruta)
            con.execute("UPDATE docs SET needs_ocr=0, mtime=0 WHERE path=?", (rel,))
            con.commit()
            indexar_archivo(con, root, rel, cargar_manifiesto(root))
            con.commit()
        else:
            print(f"  falló el OCR de {rel}")


# ------------------------------------------------------------------ búsqueda

VACIAS = {"el", "la", "los", "las", "de", "del", "que", "como", "cómo", "qué", "por", "para", "una", "un",
          "es", "se", "con", "sin", "en", "al", "y", "o", "the", "how", "what", "is", "are", "to", "of", "and",
          "can", "do", "in", "for", "with", "a", "an", "on", "or"}


def consulta_fts(q):
    terminos = [t for t in re.findall(r"[\w\-]+", q) if len(t) > 1 and t.lower() not in VACIAS]
    return " ".join('"' + t.replace('"', "") + '"' for t in terminos), terminos


def search(args, imprimir=True):
    con = abrir(args.db)
    q_and, terminos = consulta_fts(args.query)
    if not terminos:
        return []
    filtro = " AND category=?" if args.category else ""
    params = [args.category] if args.category else []
    sql = ("SELECT path, page, title, category, snippet(chunks, 0, '»', '«', '…', 24) AS s, bm25(chunks, 1.0, 0.5) AS r "
           "FROM chunks WHERE chunks MATCH ?" + filtro + " ORDER BY r LIMIT ?")
    filas = con.execute(sql, [q_and] + params + [args.n]).fetchall()
    if not filas and len(terminos) > 1:
        q_or = " OR ".join('"' + t + '"' for t in terminos)
        filas = con.execute(sql, [q_or] + params + [args.n]).fetchall()
    resultados = [{"path": f[0], "page": f[1], "title": f[2], "category": f[3], "snippet": f[4], "score": f[5]} for f in filas]
    if imprimir:
        if args.json:
            print(json.dumps(resultados, ensure_ascii=False, indent=1))
        elif not resultados:
            print("Sin resultados en el índice local.")
        else:
            for i, r in enumerate(resultados, 1):
                pag = f" — página {r['page']}" if r["page"] else ""
                print(f"[{i}] {r['title']} ({r['category']})\n    {r['path']}{pag}\n    {r['snippet']}\n")
    return resultados


def stats(args):
    con = abrir(args.db)
    d = con.execute("SELECT count(*), coalesce(sum(chunks),0), coalesce(sum(needs_ocr),0), max(indexed_at) FROM docs").fetchone()
    print(f"documentos={d[0]} fragmentos={d[1]} ocr_pendiente={d[2]} ultima_indexacion={d[3] or 'nunca'}")
    for cat, n in con.execute("SELECT category, count(*) FROM docs GROUP BY category ORDER BY 2 DESC").fetchall():
        print(f"  {cat}: {n}")


def main():
    comun = argparse.ArgumentParser(add_help=False)
    comun.add_argument("--root", default=ROOT)
    comun.add_argument("--db", default=os.environ.get("ARCA_SEARCH_DB", DB_DEFAULT))
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter, parents=[comun])
    sub = ap.add_subparsers(dest="cmd", required=True)
    b = sub.add_parser("build", parents=[comun]); b.add_argument("--ocr", action="store_true")
    s = sub.add_parser("search", parents=[comun]); s.add_argument("query"); s.add_argument("--n", type=int, default=10)
    s.add_argument("--category"); s.add_argument("--json", action="store_true")
    sub.add_parser("stats", parents=[comun])
    args = ap.parse_args()
    if args.cmd == "build":
        build(args)
    elif args.cmd == "search":
        search(args)
    else:
        stats(args)


if __name__ == "__main__":
    main()
