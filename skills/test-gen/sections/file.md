## File mode (--file)

**Only execute this section if `PROMPT_MODE=false` (i.e. `--file` was given or content was pasted).**

### Step 1: Read and extract content from the file

Detect file type from extension and extract plain text:

**Plain text / Markdown (`.txt`, `.md`):**
```bash
# Read directly using the Read tool
cat "$FILE_PATH"
```

**PDF (`.pdf`):**

Try the built-in `Read` tool first — it supports PDF natively (Claude can read PDF files directly) and is the most reliable method.

If MCP Read is unavailable, use the Python fallback below. **No pip install is required** — `pdfminer` is attempted opportunistically if already present in the environment, but the code falls back to a stdlib-only raw-bytes extraction. The raw fallback is intentionally basic: it works for most text-layer PDFs but will produce poor results on scanned PDFs, compressed streams, or image-heavy files. If it yields too little text the skill stops and asks the user to convert.

```bash
"$PYEXE" << 'PYEOF'
import sys, re
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

filepath = "$FILE_PATH"
try:
    # Optional: use pdfminer if already installed — gives much better results
    from pdfminer.high_level import extract_text
    print(extract_text(filepath))
except ImportError:
    # Stdlib-only fallback: parse visible text from uncompressed PDF byte stream.
    # Works for many simple text-layer PDFs; fails on compressed/scanned PDFs.
    with open(filepath, 'rb') as f:
        raw = f.read().decode('latin-1', errors='replace')
    chunks = re.findall(r'BT.*?ET', raw, re.DOTALL)
    for chunk in chunks:
        strings = re.findall(r'\(([^)]*)\)', chunk)
        line = ' '.join(strings).strip()
        if line:
            print(line)
PYEOF
```

If extraction yields fewer than 20 words → treat as a hard extraction failure. Tell user: *"Could not extract readable text from this PDF. The PDF may be scanned, image-based, or use compressed streams. Try exporting to .txt or .md and re-running, or install pdfminer (`pip install pdfminer.six`) for better PDF support."* and stop.

**Word (.docx):**

`.docx` files are ZIP archives containing XML. Extract text from `word/document.xml` using stdlib only:

```bash
"$PYEXE" << 'PYEOF'
import sys, zipfile, re
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

filepath = "$FILE_PATH"
try:
    with zipfile.ZipFile(filepath) as z:
        with z.open('word/document.xml') as f:
            xml = f.read().decode('utf-8', errors='replace')
    # Strip XML tags, collapse whitespace
    text = re.sub(r'<[^>]+>', ' ', xml)
    text = re.sub(r'\s{2,}', '\n', text).strip()
    print(text)
except Exception as e:
    print(f"ERROR: {e}")
PYEOF
```

If extraction yields fewer than 20 words → treat as a hard extraction failure. Tell user: *"Could not extract readable text from this Word file. Try saving as .txt or .md and re-running."* and stop.

**Excel (.xlsx):**

`.xlsx` files are also ZIP archives. Extract text from `xl/sharedStrings.xml` and `xl/worksheets/sheet*.xml`:

```bash
"$PYEXE" << 'PYEOF'
import sys, zipfile, re
sys.stdout.reconfigure(encoding='utf-8', errors='replace')

filepath = "$FILE_PATH"
try:
    with zipfile.ZipFile(filepath) as z:
        strings = []
        if 'xl/sharedStrings.xml' in z.namelist():
            with z.open('xl/sharedStrings.xml') as f:
                xml = f.read().decode('utf-8', errors='replace')
            strings = re.findall(r'<t[^>]*>([^<]+)</t>', xml)

        sheet_text = []
        for name in z.namelist():
            if name.startswith('xl/worksheets/sheet') and name.endswith('.xml'):
                with z.open(name) as f:
                    sheet_xml = f.read().decode('utf-8', errors='replace')
                indices = re.findall(r'<c[^>]*t="s"[^>]*><v>(\d+)</v>', sheet_xml)
                for idx in indices:
                    i = int(idx)
                    if i < len(strings):
                        sheet_text.append(strings[i])
                inline = re.findall(r'<is><t>([^<]+)</t>', sheet_xml)
                sheet_text.extend(inline)

        print('\n'.join(sheet_text))
except Exception as e:
    print(f"ERROR: {e}")
PYEOF
```

If extraction yields fewer than 20 words → treat as a hard extraction failure. Tell user: *"Could not extract readable text from this Excel file. Try saving as .csv and re-running."* and stop.

**Visio (`.vsdx`, `.vsd`) or other unsupported formats:**

Tell the user:
```
⚠️  Visio files cannot be parsed directly.
    Please export your diagram to PDF (File → Save As → PDF) or copy the
    relevant text content into a .md or .txt file, then re-run:
    /test-gen --file your-spec.pdf
```
Stop.

**Images (`.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`):**

Use the Read tool — it supports image files natively and Claude can interpret visual content:
```
Read(file_path = FILE_PATH)
```
Describe what is visible in the image and use that as the spec input. Note in the output file header that the source was an image.

If the image content is too sparse to generate meaningful tests → tell the user and stop.

**Python executable detection (file mode fallback only):**

This is a best-effort scan. On most systems `python3` or `python` will be found. The Windows absolute paths cover common Python installer locations — adjust them if your install is in a different directory. If no candidate is found, tell the user: *"Python 3.9+ is required for .docx/.xlsx/.pdf extraction. Install it from python.org and ensure it is on your PATH, then re-run."* and stop.

```bash
for candidate in python3 python "/c/Program Files/Python313/python.exe" "/c/Program Files/Python312/python.exe"; do
  if command -v "$candidate" &>/dev/null || [ -f "$candidate" ]; then
    PYEXE="$candidate"; break
  fi
done
```

### Step 2: Validate extracted content

If extracted text is fewer than 50 words → warn the user:
```
⚠️  Very little content was extracted from this file (<N> words).
    The generated test document may be sparse. Consider providing more detailed spec content.
    Proceeding anyway...
```

If extracted text is more than ~8000 words → warn:
```
⚠️  This file is very large (~N words). Generation may be slow or hit context limits.
    Consider trimming to the relevant sections before re-running.
    Proceeding anyway...
```

### Step 3: Generate the test document

Same 12-section structure as `jira-test-gen` Step 5.

Apply GHERKIN format by default (markdown pipe tables, Given/When/Then for all test sections).
Apply tab-separated multi-line format if `GHERKIN=false` (`--no-gherkin`).
Apply any domain context from `.test-gen.json` if present.

Header of output file:
```
<OUTPUT_STEM> — Test Document
Source: <FILE_PATH or "Pasted content">
Generated: <date>
Format: Standard | Gherkin
```

### Step 4: Write the output file

Save to `<OUTPUT_DIR>/<OUTPUT_FILE>`. Confirm full absolute path to user: `<cwd>/<OUTPUT_DIR>/<OUTPUT_FILE>`.

Then print:
```
💡 Done! Your output file is ready.
   VS Code / Copilot Chat: start a NEW chat thread before your next ticket —
   this keeps each ticket's context clean and prevents earlier results from
   interfering. Use the + New Conversation button in the Copilot Chat panel.
   Claude Code: run /clear (wipe context) or /compact (summarise and continue).
```
