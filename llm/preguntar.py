#!/usr/bin/env python3
"""preguntar.py — chat con el modelo local apoyado en la biblioteca de Kiwix (RAG).

Para cada pregunta busca en los ZIM servidos por kiwix-serve y en el índice local de PDF y
documentos (.arca/search.db, SQLite FTS5), extrae los fragmentos más relevantes y se los
entrega al modelo junto con la pregunta, citando cada fuente (artículo o archivo y página).

Modos según la categoría de la pregunta y de las fuentes encontradas:
  SOURCE_ONLY      medicina, agua y saneamiento, química industrial: solo responde con lo que
                   dicen las fuentes; si no hay, dice "No encontré esta respuesta en la
                   biblioteca local." y no improvisa.
  SOURCE_PREFERRED el resto: usa las fuentes si las hay; si no, responde con su conocimiento
                   avisando que no proviene de la biblioteca.

Uso:
  preguntar.py                      chat interactivo
  preguntar.py "¿cómo se hace jabón?"   una pregunta y sale
Órdenes dentro del chat: /solo (alterna búsqueda sí/no), /fuentes N, /salir

Solo usa la biblioteca estándar de Python 3. Variables de entorno opcionales:
  ARCA_KIWIX_URL   (http://localhost:8080)   ARCA_LLAMA_URL (http://localhost:8081)
  ARCA_MODELO      ruta al .gguf para arrancar llama-server si no está corriendo
  ARCA_LLAMA_BIN   ruta a llama-server        ARCA_CONTEXTO  tokens de contexto (4096)
  ARCA_HILOS       hilos de CPU (todos los núcleos)
  ARCA_SEARCH_DB   índice local (/srv/respaldo/.arca/search.db)   ARCA_RESPALDO (/srv/respaldo)
"""
import html
import json
import os
import re
import sqlite3
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from html.parser import HTMLParser

KIWIX = os.environ.get("ARCA_KIWIX_URL", "http://localhost:8080").rstrip("/")
LLAMA = os.environ.get("ARCA_LLAMA_URL", "http://localhost:8081").rstrip("/")
MODELO = os.environ.get("ARCA_MODELO", "")
LLAMA_BIN = os.environ.get("ARCA_LLAMA_BIN", "llama-server")
CONTEXTO = int(os.environ.get("ARCA_CONTEXTO", "4096"))
RESPALDO = os.environ.get("ARCA_RESPALDO", "/srv/respaldo")
SEARCH_DB = os.environ.get("ARCA_SEARCH_DB", os.path.join(RESPALDO, ".arca", "search.db"))
FRASE_SIN_FUENTES = "No encontré esta respuesta en la biblioteca local."
CATEGORIAS_SOURCE_ONLY = {"medicina", "agua", "industria", "quimica"}
PALABRAS_MEDICINA = {"dosis", "medicamento", "medicamentos", "antibiótico", "antibiotico", "herida", "fiebre", "infección",
                     "infeccion", "parto", "embarazo", "tratamiento", "tratar", "síntoma", "sintoma", "enfermedad",
                     "diarrea", "vacuna", "fractura", "quemadura", "hemorragia", "bebé", "bebe", "niño", "paciente",
                     "dose", "drug", "antibiotic", "wound", "fever", "infection", "childbirth", "pregnancy", "treatment",
                     "symptom", "disease", "vaccine", "fracture", "burn", "bleeding", "patient"}
PALABRAS_AGUA = {"agua", "potable", "cloro", "clorar", "cloración", "filtro", "letrina", "saneamiento", "pozo",
                 "hervir", "desinfectar", "water", "chlorine", "chlorination", "filter", "latrine", "sanitation",
                 "well", "boil", "disinfect", "sewage"}
PALABRAS_QUIMICA = {"ácido", "acido", "sulfúrico", "sulfurico", "nítrico", "nitrico", "sosa", "lejía", "lejia",
                    "cloro gas", "amoníaco", "amoniaco", "acid", "sulfuric", "nitric", "lye", "caustic", "ammonia",
                    "reactivo", "destilar", "distill"}
HILOS = os.environ.get("ARCA_HILOS", str(os.cpu_count() or 4))
N_FUENTES = 4
MAX_CARACTERES_POR_FUENTE = 3500
MAX_CARACTERES_CONTEXTO = 9000

SISTEMA = (
    "Eres arca, un asistente que funciona sin internet sobre una biblioteca local "
    "(Wikipedia, manuales técnicos y médicos, cursos). Responde siempre en el idioma de la "
    "pregunta, de forma clara y práctica. Si se te entregan fragmentos de la biblioteca, "
    "básate en ellos y cita cada dato con su número entre corchetes, por ejemplo [2]. "
    "Si los fragmentos no responden la pregunta, dilo con la frase '" + FRASE_SIN_FUENTES + "' "
    "y responde con tu propio conocimiento, advirtiendo que puede contener errores. "
    "Nunca inventes citas."
)
SISTEMA_SOLO_FUENTES = (
    "Eres arca, un asistente que funciona sin internet sobre una biblioteca local de manuales "
    "médicos, de agua y saneamiento y de química. Esta pregunta afecta a la salud o la seguridad: "
    "responde ÚNICAMENTE con lo que dicen los fragmentos entregados, en el idioma de la pregunta, "
    "citando cada dato con su número entre corchetes, por ejemplo [2]. No añadas dosis, pasos ni "
    "cantidades que no estén en los fragmentos. Si los fragmentos no responden la pregunta, "
    "contesta exactamente: '" + FRASE_SIN_FUENTES + "' y sugiere en qué manual buscar."
)

PALABRAS_ES = {"el", "la", "los", "las", "de", "del", "que", "cómo", "como", "qué", "por", "para",
               "una", "un", "es", "se", "con", "hacer", "puedo", "cuál", "dónde", "cuándo", "y"}
PALABRAS_EN = {"the", "how", "what", "is", "are", "to", "of", "and", "can", "do", "does", "in",
               "for", "with", "make", "why", "where", "when", "which", "a", "an"}
VACIAS = PALABRAS_ES | PALABRAS_EN | {"me", "te", "le", "mi", "tu", "su", "al", "en", "o", "u",
                                      "this", "that", "it", "my", "your", "i", "you", "we"}


class _Texto(HTMLParser):
    """Extrae el texto visible de un HTML, sin scripts, estilos ni tablas de navegación."""

    def __init__(self):
        super().__init__()
        self.partes = []
        self._omitir = 0

    def handle_starttag(self, tag, attrs):
        if tag in ("script", "style", "nav", "header", "footer", "table"):
            self._omitir += 1
        elif tag in ("p", "br", "li", "h1", "h2", "h3", "h4", "div", "tr"):
            self.partes.append("\n")

    def handle_endtag(self, tag):
        if tag in ("script", "style", "nav", "header", "footer", "table") and self._omitir:
            self._omitir -= 1

    def handle_data(self, data):
        if not self._omitir:
            self.partes.append(data)


def html_a_texto(cuerpo):
    p = _Texto()
    p.feed(cuerpo)
    texto = html.unescape("".join(p.partes))
    texto = re.sub(r"\[\d+\]", "", texto)          # notas al pie de Wikipedia
    texto = re.sub(r"[ \t]+", " ", texto)
    texto = re.sub(r"\n\s*\n+", "\n", texto)
    return texto.strip()


def http_get(url, timeout=60):
    req = urllib.request.Request(url, headers={"User-Agent": "arca-preguntar/1.0"})
    with urllib.request.urlopen(req, timeout=timeout) as r:
        return r.read().decode("utf-8", errors="replace")


def idioma_de(pregunta):
    palabras = set(re.findall(r"[a-záéíóúñü]+", pregunta.lower()))
    es = len(palabras & PALABRAS_ES) + sum(1 for c in pregunta if c in "áéíóúñ¿¡")
    en = len(palabras & PALABRAS_EN)
    return ["spa", "eng"] if es >= en else ["eng", "spa"]


def buscar(pregunta, n):
    """Busca en kiwix-serve por idioma. Devuelve lista de dict(titulo, ruta, libro, resumen)."""
    resultados = []
    consultas = [pregunta, " ".join(w for w in re.findall(r"\w+", pregunta) if len(w) > 3 and w.lower() not in VACIAS)]
    for lang in idioma_de(pregunta):
        for consulta in consultas:
            if not consulta.strip():
                continue
            url = f"{KIWIX}/search?{urllib.parse.urlencode({'pattern': consulta, 'books.filter.lang': lang, 'format': 'xml', 'pageLength': n})}"
            try:
                cuerpo = http_get(url, timeout=30)
                raiz = ET.fromstring(cuerpo)
            except (urllib.error.URLError, ET.ParseError, OSError):
                continue
            for item in raiz.iter("item"):
                ruta = item.findtext("link", "")
                if not ruta.startswith("/content/"):
                    continue
                if any(r["ruta"] == ruta for r in resultados):
                    continue
                libro = item.find("book")
                resultados.append({
                    "titulo": item.findtext("title", "").strip(),
                    "ruta": ruta,
                    "libro": libro.findtext("title", "").strip() if libro is not None else "",
                    "resumen": item.findtext("description", "").strip(),
                })
            if resultados:
                break
        if len(resultados) >= n:
            break
    return resultados[:n]


def buscar_docs(pregunta, n):
    """Busca en el índice local (SQLite FTS5). Devuelve dicts con archivo, página, título, categoría, texto."""
    if not os.path.exists(SEARCH_DB):
        return []
    terminos = [t for t in re.findall(r"[\w\-]+", pregunta) if len(t) > 2 and t.lower() not in VACIAS]
    if not terminos:
        return []
    try:
        con = sqlite3.connect(f"file:{SEARCH_DB}?mode=ro", uri=True)
        sql = ("SELECT path, page, title, category, text FROM chunks WHERE chunks MATCH ? "
               "ORDER BY bm25(chunks, 1.0, 0.5) LIMIT ?")
        filas = con.execute(sql, [" ".join('"' + t.replace('"', '') + '"' for t in terminos), n]).fetchall()
        if not filas and len(terminos) > 1:
            filas = con.execute(sql, [" OR ".join('"' + t.replace('"', '') + '"' for t in terminos), n]).fetchall()
        con.close()
    except sqlite3.Error:
        return []
    return [{"tipo": "doc", "archivo": f[0], "pagina": f[1], "titulo": f[2], "categoria": f[3], "texto": f[4]} for f in filas]


def modo_de(pregunta, fuentes):
    """SOURCE_ONLY si la pregunta o la mayoría de las fuentes son de salud/agua/química; si no SOURCE_PREFERRED."""
    palabras = set(re.findall(r"[\wáéíóúñü]+", pregunta.lower()))
    if palabras & (PALABRAS_MEDICINA | PALABRAS_AGUA | PALABRAS_QUIMICA):
        return "SOURCE_ONLY"
    cats = [f.get("categoria", "") for f in fuentes if f.get("categoria")]
    if cats and sum(1 for c in cats if c in CATEGORIAS_SOURCE_ONLY) * 2 > len(cats):
        return "SOURCE_ONLY"
    return "SOURCE_PREFERRED"


def texto_de(resultado):
    ruta = resultado["ruta"][len("/content/"):]
    libro, _, camino = ruta.partition("/")
    try:
        cuerpo = http_get(f"{KIWIX}/raw/{libro}/content/{camino}", timeout=60)
        texto = html_a_texto(cuerpo)
    except (urllib.error.URLError, OSError):
        texto = resultado["resumen"]
    return texto[:MAX_CARACTERES_POR_FUENTE]


def etiqueta_de(f):
    if f.get("tipo") == "doc":
        pag = f" — página {f['pagina']}" if f.get("pagina") else ""
        return f"{f['titulo']} ({f['archivo']}{pag})"
    return f"{f['titulo']} ({f.get('libro', 'Kiwix')})"


def contexto_de(fuentes):
    bloques, total = [], 0
    for i, f in enumerate(fuentes, 1):
        texto = f["texto"][:MAX_CARACTERES_POR_FUENTE] if f.get("tipo") == "doc" else texto_de(f)
        if total + len(texto) > MAX_CARACTERES_CONTEXTO:
            texto = texto[: max(0, MAX_CARACTERES_CONTEXTO - total)]
        if not texto:
            continue
        bloques.append(f"[{i}] {etiqueta_de(f)}\n{texto}")
        total += len(texto)
        if total >= MAX_CARACTERES_CONTEXTO:
            break
    return "\n\n".join(bloques)


def llama_listo():
    try:
        http_get(f"{LLAMA}/health", timeout=5)
        return True
    except (urllib.error.URLError, OSError):
        return False


def arrancar_llama():
    if llama_listo():
        return None
    if not MODELO or not os.path.exists(MODELO):
        sys.exit(f"llama-server no responde en {LLAMA} y no hay modelo en ARCA_MODELO={MODELO!r}.")
    puerto = urllib.parse.urlparse(LLAMA).port or 8081
    print(f"Arrancando llama-server con {os.path.basename(MODELO)} (tarda ~30 s)...", file=sys.stderr)
    proc = subprocess.Popen([LLAMA_BIN, "-m", MODELO, "-c", str(CONTEXTO), "-t", HILOS, "--host", "127.0.0.1",
                             "--port", str(puerto)], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    for _ in range(120):
        time.sleep(2)
        if llama_listo():
            return proc
        if proc.poll() is not None:
            break
    sys.exit("No se pudo arrancar llama-server (¿falta RAM o el binario?).")


def preguntar_modelo(mensajes):
    datos = json.dumps({"messages": mensajes, "stream": True, "temperature": 0.3,
                        "max_tokens": 1024}).encode()
    req = urllib.request.Request(f"{LLAMA}/v1/chat/completions", data=datos,
                                 headers={"Content-Type": "application/json"})
    respuesta = []
    with urllib.request.urlopen(req, timeout=600) as r:
        for linea in r:
            linea = linea.decode("utf-8", errors="replace").strip()
            if not linea.startswith("data:"):
                continue
            carga = linea[5:].strip()
            if carga == "[DONE]":
                break
            try:
                trozo = json.loads(carga)["choices"][0]["delta"].get("content") or ""
            except (KeyError, IndexError, json.JSONDecodeError):
                continue
            sys.stdout.write(trozo)
            sys.stdout.flush()
            respuesta.append(trozo)
    print()
    return "".join(respuesta)


def responder(pregunta, historial, usar_biblioteca, n_fuentes):
    fuentes = []
    if usar_biblioteca:
        # Mitad documentos locales (PDF, manuales), mitad Kiwix; los documentos van primero.
        docs = buscar_docs(pregunta, max(2, n_fuentes // 2 + 1))
        kiwix = buscar(pregunta, n_fuentes)
        fuentes = (docs + kiwix)[:n_fuentes + 1]
    modo = modo_de(pregunta, fuentes) if usar_biblioteca else "SOURCE_PREFERRED"
    contexto = contexto_de(fuentes) if fuentes else ""
    if modo == "SOURCE_ONLY" and not contexto:
        print(f"\narca> {FRASE_SIN_FUENTES} (modo solo-fuentes: {'medicina, agua o química'}). "
              "Busca en manuales/medicina/, manuales/agua/ o en Wikipedia médica (Kiwix).")
        historial.append({"role": "user", "content": pregunta})
        historial.append({"role": "assistant", "content": FRASE_SIN_FUENTES})
        return FRASE_SIN_FUENTES
    if contexto:
        usuario = f"Fragmentos de la biblioteca:\n\n{contexto}\n\n---\nPregunta: {pregunta}"
    else:
        usuario = pregunta if not usar_biblioteca else (
            f"La biblioteca no devolvió resultados para esta pregunta. Responde con tu conocimiento "
            f"y avisa que no está en la biblioteca.\n\nPregunta: {pregunta}")
    sistema = SISTEMA_SOLO_FUENTES if modo == "SOURCE_ONLY" else SISTEMA
    mensajes = [{"role": "system", "content": sistema}] + historial[-6:] + [{"role": "user", "content": usuario}]
    print(f"\narca [{modo}]> ", end="", flush=True)
    texto = preguntar_modelo(mensajes)
    historial.append({"role": "user", "content": pregunta})
    historial.append({"role": "assistant", "content": texto})
    if fuentes:
        print("\nFuentes en la biblioteca:")
        for i, f in enumerate(fuentes, 1):
            if f.get("tipo") == "doc":
                pag = f" — página {f['pagina']}" if f.get("pagina") else ""
                print(f"  [{i}] {f['archivo']}{pag}")
            else:
                print(f"  [{i}] {f['titulo']} — {KIWIX}{f['ruta']}")
    return texto


def main():
    proc = arrancar_llama()
    historial, usar_biblioteca, n_fuentes = [], True, N_FUENTES
    try:
        if len(sys.argv) > 1:
            responder(" ".join(sys.argv[1:]), historial, usar_biblioteca, n_fuentes)
            return
        print("arca: pregunta lo que quieras (la biblioteca se consulta sola). /solo, /fuentes N, /salir")
        while True:
            try:
                pregunta = input("\ntú> ").strip()
            except (EOFError, KeyboardInterrupt):
                print()
                break
            if not pregunta:
                continue
            if pregunta in ("/salir", "/exit", "/quit"):
                break
            if pregunta == "/solo":
                usar_biblioteca = not usar_biblioteca
                print("Búsqueda en la biblioteca:", "activada" if usar_biblioteca else "desactivada")
                continue
            if pregunta.startswith("/fuentes"):
                try:
                    n_fuentes = max(1, min(10, int(pregunta.split()[1])))
                except (IndexError, ValueError):
                    pass
                print("Fuentes por pregunta:", n_fuentes)
                continue
            responder(pregunta, historial, usar_biblioteca, n_fuentes)
    finally:
        if proc:
            proc.terminate()


if __name__ == "__main__":
    main()
