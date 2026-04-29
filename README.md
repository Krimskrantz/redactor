# PII Redactor

A local, privacy-first tool for detecting and redacting personally identifiable information (PII) from PDF and Word documents — built for the Swedish public sector.

Documents are processed entirely on-device. Nothing is sent to external services.

---

## Why this exists

Swedish public authorities are required by law (*offentlighetsprincipen*) to release documents upon request, but must first redact personal data under GDPR. This tool automates the detection step while keeping a human in the loop for the final decision — and crucially, keeps all data inside the organisation's network.

Built as a proof-of-concept for [GR (Göteborgsregionens Innovationsarena)](https://www.gr.to) to explore how municipalities can use locally running AI models in document workflows without violating data protection requirements.

---

## Features

- **Local model inference** — uses [`openai/privacy-filter`](https://huggingface.co/openai/privacy-filter) via HuggingFace Transformers, runs on CPU, no GPU required
- **Human-in-the-loop** — review every detected entity before exporting; accept or dismiss individual findings with a single click
- **Manual additions** — select any text in the document to add masking for things the model missed
- **Confidence filter** — slider to show only high-confidence detections
- **PDF and DOCX support** — coordinate-based PDF redaction (black boxes at exact positions), run-aware DOCX redaction covering body text, tables, headers and footers
- **Audit log** — download a JSON log of all detections, decisions and the confidence threshold used
- **No external dependencies** — works fully offline after the initial model download (~2 GB, cached locally)

### Detected PII categories

| Category | Examples |
|---|---|
| `private_person` | Personal names |
| `private_email` | Email addresses |
| `private_phone` | Phone numbers |
| `private_address` | Physical addresses |
| `private_url` | URLs |
| `private_date` | Dates |
| `account_number` | Personal identity numbers, account numbers |
| `secret` | Passwords, tokens, keys |

---

## Requirements

- Python 3.11+
- ~4 GB RAM
- ~2 GB disk space (model weights, downloaded once on first run)
- No GPU required

---

## Getting started

```bash
git clone https://github.com/Krimskrantz/redact.git
cd redact
./start.sh
```

Open [http://localhost:8000](http://localhost:8000) in your browser.

The model downloads automatically on first use (~30 seconds). Subsequent starts load from local cache.

### Manual install

```bash
pip install -r requirements.txt
uvicorn backend.main:app --host 127.0.0.1 --port 8000
```

> **Note:** `start.sh` runs with `--reload` (development hot-reload) and binds to `0.0.0.0`. For a shared or persistent deployment, remove `--reload` and change the host to `127.0.0.1`.

---

## How it works

```
Upload PDF / DOCX
       │
       ▼
Extract text + word coordinates
(pdfplumber / python-docx)
       │
       ▼
Run NER model locally
(openai/privacy-filter, 1.5B params)
       │
       ▼
Review detections in browser
  • Accept or dismiss each finding
  • Manually select additional text to mask
  • Adjust confidence threshold with slider
       │
       ▼
Download redacted document
  PDF  → black boxes drawn at exact word coordinates (PyMuPDF)
  DOCX → █-characters replacing text in runs, tables, headers/footers
```

### API

**`POST /api/analyze`**
Upload a file (PDF or DOCX). Returns extracted text, detected spans with character positions, confidence scores, and per-word page coordinates for PDF files.

**`POST /api/redact`**
Send accepted spans and the original file (base64-encoded). Returns the redacted document as a binary download.

---

## Stack

| Layer | Technology |
|---|---|
| Backend | FastAPI + Python 3.11 |
| NER model | [`openai/privacy-filter`](https://huggingface.co/openai/privacy-filter) via HuggingFace Transformers |
| PDF text extraction | pdfplumber |
| PDF redaction | PyMuPDF (fitz) |
| DOCX | python-docx |
| Frontend | Vanilla HTML/CSS/JS — no build step, no framework |

---

## Known limitations

- **Scanned PDFs** — requires extractable text. Pre-process scanned documents with OCR (e.g. [`ocrmypdf`](https://github.com/ocrmypdf/OCRmyPDF)) before uploading.
- **DOCX formatting** — run-level text replacement can lose bold/italic/colour styling on the redacted words.
- **Large documents** — no background task processing; very long documents may time out on the default HTTP timeout.
- **Swedish language precision** — the model performs best on English. Swedish-specific formats (personnummer, Swedish addresses) are detected but with variable recall.
- **Not a guarantee** — always review the output before releasing a document. The model is a first-pass assistant, not an infallible classifier.

---

## Potential improvements

- [ ] Fine-tune the model on Swedish municipal documents for better precision on Swedish PII formats
- [ ] Coordinate-based DOCX redaction (currently word-string based)
- [ ] Background task processing for large files
- [ ] Batch mode — queue of multiple documents
- [ ] Preview of the redacted document before download
- [ ] Authentication for shared deployments (HTTP Basic Auth or SSO)

---

## Privacy & security

- All document processing is local — no data leaves the machine
- No database, no server-side logging of document content
- The audit log (downloaded by the user) contains the detected PII words and should be treated as a sensitive internal document
- File uploads are limited to 50 MB
- No authentication by default — suitable for local or isolated-network use

---

## License

MIT
