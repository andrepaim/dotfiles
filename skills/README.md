# Agent skills

Skills vendored here are linked into the agent skill directories by
`bootstrap.sh` (group `skills`). Edits in the installed location land in this
checkout.

| Skill | Source | License | Installed to |
| --- | --- | --- | --- |
| `loopy` | [Forward-Future/loopy](https://github.com/Forward-Future/loopy) (tracked in `.agents/.skill-lock.json`) | MIT | `~/.agents/skills`, `~/.claude/skills` |
| `wacli` | local skill for the `wacli` WhatsApp CLI | — | `~/.agents/skills`, `~/.claude/skills`, `~/.codex/skills` |
| `pluggy-doctor`, `pluggy-integration`, `pluggy-open-finance`, `pluggy-payments` | Pluggy | MIT | `~/.codex/skills` |

Skills that belong to another project are linked from that project's checkout
instead of being copied, and are skipped when the checkout is missing:

| Skill | Expected checkout |
| --- | --- |
| `pdfpal-cli` | `~/src/pdfpal/skills/pdfpal-cli` |
| `saldo-cli` | `~/src/saldo/skills/saldo-cli` |

Set `DOTFILES_SRC_DIR` to use a directory other than `~/src`.
