# Roadmap

Ideas and possible improvements, tracked here for visibility. Nothing here is committed to — items are promoted to Jira tickets when there's enough need to act on them.

---

## Known gaps — needs testing and validation

### `--create` path untested against real Atlassian instances

All skills with a `--create` flag (post Jira comment, post Confluence comment, create Jira tickets, create Zephyr test cases) have been built and dry-run tested, but **have not been tested end-to-end against real Jira and Confluence instances**. The following flows are unvalidated:

| Skill | `--create` action | Status |
|---|---|---|
| `jira-clarify --create` | Post clarification questions as Jira comment | ⚠️ Untested |
| `jira-test-gen --create` | Post Jira comment + create Zephyr Scale test cases | ⚠️ Untested |
| `confluence-clarify --create` | Post clarification questions as Confluence comment | ⚠️ Untested |
| `confluence-breakdown --create` | Create Jira epic + stories | ⚠️ Untested |
| `confluence-test-gen --create` | Post Confluence comment | ⚠️ Untested |
| `mr-review --create` | Post MR/PR comment + optional Jira comment | ⚠️ Untested |

**What needs to happen:**
- Run each skill with `--create` against a real non-production Jira/Confluence instance (e.g. a sandbox project or a test page)
- Verify comments are posted correctly, tickets are created with the right fields, Zephyr TCs appear in the right cycle
- Verify the **idempotency / double-submit guards** work — re-running with `--create` should not post duplicate comments or create duplicate tickets
- Verify the **dry run output accurately reflects what `--create` will do** — no surprises

**Also needed — undo / rollback:**
- Currently there is no automated way to undo a `--create` action. If a comment is posted incorrectly or tickets are created with wrong data, it must be cleaned up manually in Jira/Confluence.
- Consider adding a `--delete` or `--undo` flag (or a separate skill) that can reverse the last `--create` action — e.g. delete the comment just posted, or delete the tickets just created (using the keys recorded in the output file).
- At minimum, the output file from each `--create` run should record exactly what was created (comment ID, ticket keys) so manual cleanup is straightforward.

---

## Possible improvements

### Visio (`.vsdx`) support in `test-gen --file`

**What:** Add native `.vsdx` parsing to `/test-gen --file` using the [`vsdx`](https://github.com/dave-howard/vsdx) Python library. Would extract page names, shape text, and connector relationships into a readable text representation, then feed that into the normal test generation flow.

**Why not yet:** `vsdx` is the first hard Python dependency the skill would have (no stdlib fallback). Current approach tells users to export to PDF instead. Worth revisiting if `.vsdx` input becomes a common request.

**Install path when ready:**
```bash
pip install -e ~/git/vsdx   # local clone
# or once available on PyPI:
pip install vsdx
```

**Also consider:** a `requirements.txt` listing optional dependencies (`vsdx`, `pdfminer.six`) so new users can get everything working upfront with one command, rather than hitting install prompts one format at a time.

---

### Atlassian Rovo MCP -- `--rovo` flag and deeper integration

**Background:**

The [official Atlassian Rovo MCP server](https://github.com/atlassian/atlassian-mcp-server) ships 5 built-in skills that overlap significantly with this toolset:

| Rovo Skill | Overlap with our skills |
|---|---|
| `spec-to-backlog` | Direct overlap with `/confluence-breakdown` -- same job, different approach |
| `triage-issue` | Partial overlap with `/jira-clarify` -- finds duplicates, creates/comments on tickets |
| `generate-status-report` | No equivalent -- Jira → Confluence status report; adjacent to our domain |
| `capture-tasks-from-meeting-notes` | No equivalent -- meeting notes → Jira tasks; useful for PMs |
| `search-company-knowledge` | No equivalent -- semantic search across Confluence + Jira using Rovo Search AI |

The key difference: Rovo's skills are PM/project-ops focused. Ours are testing/spec-quality focused. `/confluence-clarify`, `/jira-test-gen`, `/confluence-test-gen`, `/mr-review` have no Rovo equivalent at all.

**What `--rovo` could mean (in priority order):**

1. **Rovo semantic search for context gathering** *(buildable now)*
   The Rovo MCP exposes a `search` tool that uses Rovo's AI-powered semantic search -- not REST keyword matching. Skills like `/jira-test-gen` currently fetch only the target ticket. With `--rovo`, they could use the `search` tool to find related tickets, prior art, existing test docs, and linked specs -- enriching the context before generating output. This is real and available today.

2. **Use Rovo's native skills where they overlap** *(buildable now)*
   When `--rovo` is passed to `/confluence-breakdown`, instead of Claude reasoning about the breakdown, invoke the Rovo `spec-to-backlog` skill via the MCP. Claude orchestrates, Rovo does the backlog reasoning, Claude captures and writes the output file. Same for `triage-issue` as an input path for `/jira-clarify`.

3. **Full Rovo AI reasoning delegation** *(not yet possible)*
   The ideal: Claude passes our full prompt (the 12-section test doc structure, RISE framework, etc.) to Rovo Chat for reasoning, then captures the output. Rovo Chat is not currently accessible as a callable API -- it's UI only. Watch for Atlassian to expose a `/rovo/v1/chat` or similar endpoint. When they do, this becomes possible and would offload AI reasoning tokens entirely to Atlassian's infrastructure.

**Recommended first step:** Add `--rovo` to the skills that have a direct Rovo equivalent first (`/confluence-breakdown`, `/jira-clarify`). Use the Rovo MCP `spec-to-backlog` and `triage-issue` skills as the reasoning engine when `--rovo` is passed, and fall back to Claude reasoning when it's not.

**Also consider:** A `--rovo-search` flag (separate from `--rovo`) that uses Rovo semantic search for context enrichment on any skill, without delegating the reasoning. Cleaner separation of concerns -- one flag controls reasoning delegation, the other controls search quality.

---

### Mermaid diagram generation from `system-context.md`

**What:** A small utility (or skill flag) that reads `system-context.md` and outputs a Mermaid flowchart of the integration map. Mermaid renders natively in GitHub, GitLab, Confluence (via macro), and VS Code — useful for architecture reviews and onboarding.

**Why not yet:** `system-context.md` is freeform markdown, not structured data — parsing it reliably into a graph requires either tighter schema constraints on the file or a Claude-assisted extraction step. Worth doing once the file format stabilises across a few team examples.

**Also consider (reverse direction):** generate `system-context.md` from an architecture diagram image. If someone screenshots their draw.io, Lucidchart, or Visio diagram, Claude can read it visually and produce the system-context.md format. Compelling onboarding story: *"screenshot your architecture diagram → get a system-context.md in one step."*

---

---
