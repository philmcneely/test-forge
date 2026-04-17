## Prompt mode (no --file / --prompt)

**Only execute this section if `PROMPT_MODE=true` and no content has been pasted.**

1. Choose which prompt file to read:
   - If `GHERKIN=true` (default): read the `copilot-prompt.md` file from the skill install directory
   - If `GHERKIN=false` (`--no-gherkin`): read the `copilot-prompt-no-gherkin.md` file from the skill install directory
2. Read the chosen file using the Read tool.
3. Print its full contents verbatim to the terminal, preceded by this header:

```
========================================
TEST-GEN — Rovo / AI Prompt
Copy the RAW text below (not from a rendered Markdown preview — use the Raw view on
GitHub/GitLab, or open the file in a plain-text editor like VS Code or Notepad).
Paste it into Rovo, Copilot, ChatGPT, or any AI assistant.
If the tool already has your Confluence page or Jira ticket open, you don't need to
paste the spec — just send the prompt as-is.
========================================
```

Then print the full contents of the chosen prompt file verbatim. Do not summarise, truncate, or reformat it.

If the file cannot be read, fall back to printing this notice and stopping:
```
Could not read the prompt file. Clone the repo or point to the correct path.
```

If the user pastes content into the chat after this prompt, detect it and proceed to generate the full document from that content (same as `--file` mode but with pasted text as input). Save output to `pasted_content_tests.md`.
