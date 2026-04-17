# Test Forge -- Testing Toolkit Skill for Claude Code

test documentation skills -- generate comprehensive test documents from Jira tickets, Confluence specs, local files, or pasted text. Built for **Claude Code**.

> **Human review required.** All output from these skills is AI-generated and must be treated as a **starting point, not a finished artefact**. You are responsible for reviewing, validating, and correcting everything before acting on it.

> **`--create` is untested against live Atlassian instances.** The dry run path (default, no `--create`) is well tested. The `--create` path -- posting comments, creating tickets, creating Zephyr test cases -- has not yet been validated end-to-end against real Jira or Confluence. Use with caution. See [ROADMAP.md](ROADMAP.md) for details.

---

## Which skill should I use?

| I have... | I want to... | Use this |
|---|---|---|
| A Jira ticket key | Generate clarification questions (preview only) | `/jira-clarify KEY` |
| A Jira ticket key | Generate clarification questions + post to Jira | `/jira-clarify KEY --create` |
| A Jira ticket key | Rewrite ACs as proper BDD Given/When/Then (preview only) | `/jira-improve KEY` |
| A Jira ticket key | Rewrite ACs + update the ticket in place | `/jira-improve KEY --create` |
| A Jira ticket key | Generate a full 12-section test document | `/jira-test-gen KEY` |
| A Jira ticket key | Generate doc + post comment + create Zephyr TCs | `/jira-test-gen KEY --create` |
| A Confluence page URL | Generate clarification questions (preview only) | `/confluence-clarify URL` |
| A Confluence page URL | Generate clarification questions + post to Confluence | `/confluence-clarify URL --create` |
| A Confluence page URL | Draft a Jira ticket breakdown (preview only) | `/confluence-breakdown URL` |
| A Confluence page URL | Draft + create tickets in Jira | `/confluence-breakdown URL --create` |
| A Confluence page URL | Generate a full test document + Test Data Catalogue | `/confluence-test-gen URL` |
| A local file or pasted text | Generate a test document (no API needed) | `/test-gen --file path` |
| A GitLab/GitHub MR or PR URL | Code review + testing analysis | `/mr-review URL` |
| MR + Jira ticket + Confluence spec | Full cross-referenced review | `/mr-review URL --jira KEY --confluence URL` |

> **All write-capable skills are dry run by default.** Pass `--create` when you're ready to actually post.

---

## Installation

### From GitHub (recommended)

```bash
claude skill install philmcneely/test-forge
```

### Manual install

```bash
git clone https://github.com/philmcneely/test-forge.git
# Copy each skill directory into your Claude skills folder:
cp -r test-forge/skills/* ~/.claude/skills/
```

### Verify

```bash
ls ~/.claude/skills/jira-test-gen/
# Should show: SKILL.md  sections/
```

Then test with a dry run:

```
/jira-clarify PROJ-123
```

---

## Skills included

### Jira skills (require Jira API access)

| Skill | Invoke | Description |
|---|---|---|
| `jira-clarify` | `/jira-clarify <KEY> [--create]` | Fetch a Jira ticket, generate clarification questions + assumptions. Dry run by default. |
| `jira-improve` | `/jira-improve <KEY> [--create]` | Fetch a Jira ticket, rewrite ACs as proper BDD Given/When/Then. Dry run by default; `--create` updates the ticket in place. |
| `jira-test-gen` | `/jira-test-gen <KEY> [--create] [flags]` | Full 12-section test document. Pass `--create` to post to Jira and create Zephyr Scale test cases. |

### Confluence skills (require Confluence API access)

| Skill | Invoke | Description |
|---|---|---|
| `confluence-clarify` | `/confluence-clarify <URL> [--create]` | Fetch spec page, generate clarification questions. |
| `confluence-breakdown` | `/confluence-breakdown <URL> [--create] [--parent KEY]` | Draft a Jira ticket breakdown (epic + stories). |
| `confluence-test-gen` | `/confluence-test-gen <URL> [--create] [flags]` | Full 12-section test document + Test Data Catalogue from a Confluence spec page. |

### API-free skill (no Jira or Confluence required)

| Skill | Invoke | Description |
|---|---|---|
| `test-gen` | `/test-gen --file <path> [--no-gherkin]` | Generate from a local file (PDF, Word, Excel, CSV, image, Markdown) or pasted text. |

### Code review skill (requires GitLab or GitHub API access -- or paste a diff)

| Skill | Invoke | Description |
|---|---|---|
| `mr-review` | `/mr-review <URL> [--jira KEY] [--confluence URL] [--create] [--blackbox]` | Fetch a GitLab MR or GitHub PR, analyse the diff, and produce a code review + testing analysis document. |

---

## Flag reference

### `/jira-test-gen` flags

| Flag | Effect |
|---|---|
| *(none)* | Dry run -- generates document, nothing posted |
| `--create` | Posts clarification questions to Jira and creates Zephyr Scale test cases |
| `--no-gherkin` | Tab-separated multi-line format instead of Gherkin |
| `--blackbox` | Observable language only -- no internal class/DB/queue names |
| `--no-clarify` | Omit Section 1 and skip comment post |
| `--neg-only` | Negative/boundary sections only (implies `--no-clarify`) |
| `--follow` | Pull linked Confluence pages and extended ticket graph |
| `--system-context <path>` | Load system context from a custom path |
| `--no-system-context` | Skip system context loading entirely |

### `/confluence-test-gen` flags

| Flag | Effect |
|---|---|
| *(none)* | Dry run -- generates test document + Test Data Catalogue |
| `--create` | Posts clarification questions as a Confluence comment |
| `--no-gherkin` | Tab-separated multi-line format |
| `--blackbox` | Observable language only |
| `--no-clarify` | Omit Section 1 |
| `--neg-only` | Negative/boundary sections only |
| `--include-children` | Also fetch up to 5 child pages |
| `--no-testdata` | Skip Test Data Catalogue |
| `--testdata-only` | Generate only the Test Data Catalogue |

### `/mr-review` flags

| Flag | Effect |
|---|---|
| *(none)* | Dry run -- generates review document |
| `--create` | Posts review as an MR/PR comment |
| `--jira <KEY>` | Cross-reference Jira ticket ACs against the diff |
| `--confluence <URL>` | Check spec compliance |
| `--no-gherkin` | Tab-separated format for test cases |
| `--blackbox` | Observable language only |

---

## Test document structure (12 sections + Test Data Catalogue)

All test generation skills produce the same 12 sections:

1. Clarification Questions & Requirement Gaps
2. Assumptions
3. Happy Path Scenarios (min 10)
4. Edge Cases (min 10)
5. Data Variation Testing (min 7)
6. Error Conditions (min 10)
7. Negative / Compatibility Test Cases (min 10)
8. Cross-Platform / Compatibility Testing
9. Accessibility Tests (min 8)
10. Exploratory Test Charter
11. Risk Assessment (min 6)
12. Test Execution Priority

`confluence-test-gen` also produces a **Test Data Catalogue** (`_testdata.md`).

---

## Prerequisites

### Atlassian MCP server (for `jira-*` and `confluence-*` skills)

The skills read and write Jira/Confluence via an MCP server. **MCP is the primary path -- set it up first.** The curl fallback exists for environments where MCP cannot run, but it is not the recommended setup.

There are two MCP options -- you can configure one or both:

---

#### Option 1: mcp-atlassian (community, recommended)

[sooperset/mcp-atlassian](https://github.com/sooperset/mcp-atlassian) -- authenticates with your Atlassian API token. Works headlessly with no browser required.

Add to `~/.claude/.mcp.json` (create if it doesn't exist):

```json
{
  "mcpServers": {
    "mcp-atlassian": {
      "type": "stdio",
      "command": "uvx",
      "args": ["mcp-atlassian==1.6.0"],
      "env": {
        "JIRA_URL": "https://yourcompany.atlassian.net/",
        "JIRA_USERNAME": "your@email.com",
        "JIRA_API_TOKEN": "your-atlassian-api-token",
        "CONFLUENCE_URL": "https://yourcompany.atlassian.net/wiki/",
        "CONFLUENCE_USERNAME": "your@email.com",
        "CONFLUENCE_API_TOKEN": "your-atlassian-api-token"
      }
    }
  }
}
```

Corporate proxy users: also add `"SSL_CERT_FILE": "C:\\path\\to\\ca-bundle.pem"` and `"UV_NATIVE_TLS": "true"` to the `env` block.

**Version pinning:** the skills are tested against `mcp-atlassian==1.6.0`. Specify the version in your `uvx` args to avoid unexpected breakage from upstream changes.

Verify: run `/jira-clarify PROJ-123` with a known ticket (dry run -- nothing is posted).

---

#### Option 2: Atlassian Rovo MCP (official, remote)

The [official Atlassian Rovo MCP server](https://github.com/atlassian/atlassian-mcp-server) is hosted by Atlassian at `https://mcp.atlassian.com/v1/mcp`. It covers Jira, Confluence, and Compass. Included with Atlassian Premium and Enterprise plans.

Add to `~/.claude/.mcp.json` alongside or instead of mcp-atlassian:

```json
{
  "mcpServers": {
    "atlassian-rovo": {
      "type": "stdio",
      "command": "npx",
      "args": ["-y", "mcp-remote", "https://mcp.atlassian.com/v1/mcp"]
    }
  }
}
```

Corporate proxy users: add `"env": { "NODE_EXTRA_CA_CERTS": "C:\\path\\to\\ca-bundle.pem" }`.

> **First-time auth:** on first connection, `mcp-remote` will open a browser window for an OAuth 2.1 flow against your Atlassian site. Complete it once -- the token is cached for subsequent sessions. Requires Node.js v18+.
>
> **Admin note:** a site admin must complete the OAuth consent flow before other users can connect. If you see "Your site admin must authorize this app", ask your Atlassian org admin to connect first.

---

**Fallback: curl + environment variables**

> ⚠️ **This is a fallback, not the recommended setup.** Use MCP (Option 1 or 2 above) wherever possible -- it is more reliable, handles pagination better, and is what the skills are primarily tested against. Only use the curl fallback if you cannot run MCP in your environment.

If MCP is unavailable, skills automatically fall back to direct curl calls using credentials from `~/.claude/settings.json` under `env`:

```json
{
  "env": {
    "JIRA_URL": "https://yourcompany.atlassian.net",
    "JIRA_USERNAME": "your@email.com",
    "JIRA_API_TOKEN": "your-atlassian-api-token"
  }
}
```

### GitLab / GitHub (for `/mr-review`)

Add the relevant token to `~/.claude/settings.json` under `env`:

| Variable | Required for | Where to get it |
|---|---|---|
| `GITLAB_TOKEN` | GitLab MRs | GitLab -> User Settings -> Access Tokens |
| `GITLAB_URL` | Self-hosted GitLab | Your GitLab instance base URL |
| `GITHUB_TOKEN` | GitHub PRs | GitHub -> Settings -> Developer settings -> PAT |
| `GITHUB_URL` | GitHub Enterprise Server | Your GHE base URL |

If no token is set, `/mr-review` will ask you to paste the diff directly.

### Zephyr Scale (optional, `/jira-test-gen --create` only)

Add `ZEPHYR_API_TOKEN` to `~/.claude/settings.json` under `env`. If not set, Zephyr steps are skipped gracefully.

---

## Project config (optional)

Drop `.test-gen.json` in the directory where you run the skill for project-specific context.

```bash
cp .test-gen.example.json /path/to/your/project/.test-gen.json
```

---

## System context file (optional)

`system-context.md` provides your platform's integration map -- which systems exist, how they connect, and which cross-system concerns to flag. The repo includes a generic template. Copy and customise it for your platform.

Skills pick up `system-context.md` automatically from the working directory. Override with `--system-context <path>` or `--no-system-context`.

### Customising for your team

`system-context.md` is designed to be forked and edited:

- Teams working only on specific flows can trim it to the relevant subsystem
- Partner teams can annotate their entry point routing
- Each team can add their specific call chain details
- Add new services as the platform evolves -- no need to touch the prompts themselves

---

## Removing

```bash
rm -rf ~/.claude/skills/jira-clarify
rm -rf ~/.claude/skills/jira-test-gen
rm -rf ~/.claude/skills/confluence-clarify
rm -rf ~/.claude/skills/confluence-breakdown
rm -rf ~/.claude/skills/confluence-test-gen
rm -rf ~/.claude/skills/test-gen
rm -rf ~/.claude/skills/mr-review
```

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `Ticket not found` / 404 | Wrong key, or MCP not connected | Check key exists. Verify MCP config in `~/.claude/.mcp.json`. If misconfigured Claude will report "MCP tool unavailable" -- check credentials and restart. |
| `Could not extract PAGE_ID from URL` | Legacy Confluence URL | Use full modern URL: `.../wiki/spaces/KEY/pages/123/Title` |
| `JIRA_URL is not set` | MCP unavailable, no curl fallback | Add credentials to `~/.claude/settings.json` |
| `SSL certificate error` | Corporate proxy | Set `SSL_CERT_FILE` and `JIRA_SSL_NO_REVOKE=true` |
| Zephyr steps skipped | `ZEPHYR_API_TOKEN` not set | Add token to settings.json |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT -- see [LICENSE](LICENSE).
