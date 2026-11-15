# Read and retrieval workflows

Use this reference for reading, searching, summarizing, refreshing, or downloading WhatsApp data.

## Preflight and output

```bash
command -v wacli
wacli --version
wacli --read-only --json auth status
wacli --read-only --json doctor
```

JSON commands normally return:

```json
{"success": true, "data": {}, "error": null}
```

Check `success` before consuming `data`. Message-list data is shaped as `data.fts` plus `data.messages`. Common message fields include `ChatJID`, `ChatName`, `MsgID`, `SenderJID`, `SenderName`, `Timestamp`, `FromMe`, `Text`, `DisplayText`, media metadata, and edit/deletion flags. Treat missing or empty fields as unavailable, not as evidence that an event did not occur.

## Discover chats and contacts

```bash
wacli --read-only --json chats list --limit 50
wacli --read-only --json chats list --query "project name" --limit 20
wacli --read-only --json chats list --unread --limit 50
wacli --read-only --json chats show --jid 'CHAT_JID'
wacli --read-only --json contacts search "contact name" --limit 20
wacli --read-only --json contacts show --jid 'CONTACT_JID'
```

Prefer `chats list --query` when the user refers to a conversation by display name. Contact identity and chat identity are not always interchangeable; use the returned chat JID for message filters.

## Read and search messages

```bash
wacli --read-only --json messages list --limit 20
wacli --read-only --json messages list --chat 'CHAT_JID' --limit 50
wacli --read-only --json messages list --chat 'CHAT_JID' --after '2026-08-01' --before '2026-09-01' --asc --limit 200
wacli --read-only --json messages list --from-them --after '2026-08-25T00:00:00-03:00' --limit 100
wacli --read-only --json messages search "meeting" --limit 50
wacli --read-only --json messages search "invoice" --chat 'CHAT_JID' --has-media --limit 25
wacli --read-only --json messages show --chat 'CHAT_JID' --id 'MESSAGE_ID'
wacli --read-only --json messages context --chat 'CHAT_JID' --id 'MESSAGE_ID' --before 10 --after 10
wacli --read-only --json messages starred --chat 'CHAT_JID' --limit 50
```

Start with the smallest useful limit. For chronological summaries, request `--asc`. Search uses FTS5 when available and otherwise falls back to `LIKE`; if a complex search returns nothing, retry with simpler literal terms rather than assuming absence.

Use `messages context` after locating a relevant hit so the summary preserves nearby conversation context. Do not bulk-export all messages when a filtered list or search answers the request.

## Other local reads

```bash
wacli --read-only --json calls list --after '2026-08-01' --limit 50
wacli --read-only --json polls list --chat 'CHAT_JID' --limit 20
wacli --read-only --json store stats
wacli --read-only --json history coverage --query "chat name" --limit 20
```

Use the relevant `--help` for less common read-only commands, including group listings, profile lookups, and poll inspection. Some apparently informational commands connect live and update the local database; do not label those read-only without checking whether `--read-only` accepts them.

## Freshness, sync, and older history

The message index is a local mirror. Do not claim it is current merely because a query succeeded.

- If the user asks for the latest/current messages and no continuous sync is running, a bounded refresh is appropriate:

  ```bash
  wacli --json sync --once --presence-mode quiet --idle-exit 30s
  ```

  This connects to WhatsApp and updates the local store. If it reports lock contention, a follow-mode sync may already own the store; query the mirror instead of terminating it.

- WhatsApp history availability is best effort. Inspect coverage before requesting older messages:

  ```bash
  wacli --read-only --json history coverage --only-actionable --query "chat name"
  wacli --read-only --json history fill --dry-run --query "chat name" --limit 10
  wacli --json history backfill --chat 'CHAT_JID' --requests 1 --count 50
  ```

  Backfill writes the local store, connects to WhatsApp, and may require the primary phone online. Keep requests bounded and only backfill when the user needs missing older history.

## Media retrieval

First inspect the stored message and its `LocalPath`. If the user asks to retrieve media that is not local, choose an explicit destination:

```bash
wacli --read-only --json media download --chat 'CHAT_JID' --id 'MESSAGE_ID' --output '/explicit/output/path'
```

This writes the requested output file. `media backfill` and `media retry` connect and update local state; use them only when explicitly needed, with a chat and small limit where possible. Never open or execute downloaded files automatically.
