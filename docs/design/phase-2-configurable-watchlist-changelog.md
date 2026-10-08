# Phase 2: Configurable Watch List + Sentinel Changelog

Status: staged (design only, not implemented).

## Goal

Agent Guardian stops knowing only about Hermes paths and learns to watch
anything enrolled. Every change to a watched file gets a tamper-evident
changelog entry: timestamp, SHA-before, SHA-after. The watcher never writes
to what it watches.

## 1. Watch list configuration

Watched targets move from hardcoded paths to an enrolled list.

```yaml
# watchlist.yaml (proposed)
version: 1
targets:
  - path: ~/AGENTS.md
    label: root agent guide
  - path: ~/Developer/AGENTS.md
    label: workspace conventions
  - path: ~/.agents/
    label: skills directory
    recursive: true
  - path: ~/wolfbbs/AGENTS.md
    label: wolfbbs project guide
  - path: ~/wolfbbs/ASSIGNMENTS.md
    label: wolfbbs roster
```

Rules:

- Paths may be files or directories. Directories are watched recursively
  unless `recursive: false`.
- `~` expands to the user's home. No other expansion.
- Enrollment is explicit: nothing is watched unless listed. Removing a path
  from the list un-enrolls it (history stays in the changelog).
- The current Hermes paths (`.hermes/config.yaml`, `.hermes/skills`,
  `.hermes/pending/skills`) become default entries, not special cases.
- Symlinks are not followed for enrollment (one symlink all agents sip
  from is a single point of failure; each target stands on its own).

## 2. Sentinel changelog

One append-only document. Every observed change to a watched target
produces exactly one entry:

```markdown
## 2026-10-08T14:32:11-04:00

- path: ~/AGENTS.md
- sha_before: 9f2c…a41b
- sha_after:  77d0…e902
- kind: modified
- summary: 3 lines added, 1 removed
```

Rules:

- The changelog lives in the Guardian's own state directory. It is never
  written into a watched file or directory.
- Entries are append-only. No editing, no deleting. If an entry is wrong,
  a correcting entry follows it.
- `sha_before` of the first observation of a file is `null` (enrollment,
  not a change).
- `kind` is one of: `enrolled`, `modified`, `deleted`, `restored`,
  `permissions-changed`.
- The changelog itself is checksummed on every write; a broken chain is
  reported, not silently repaired.

## 3. Safety properties

- **Read-only watcher.** The Guardian never writes to, moves, or deletes
  a watched target. It reads, snapshots, and logs. This is what keeps it
  outside every other system's sentinel logic: there is no write to flag.
- **Separate ledger.** All Guardian writes go to its own state: the
  changelog, snapshots, pending approvals. Watched files are never a
  write destination.
- **No inference.** A changed file is reported as changed. The Guardian
  does not guess why, who, or whether it matters. Triage is the human's.
- **Approval stays.** The existing approve/reject snapshot machinery is
  unchanged; it now operates over enrolled targets instead of hardcoded
  Hermes paths.

## 4. Code changes (high level)

- `DirectoryWatcher` generalizes: takes enrolled targets instead of
  Hermes-specific paths.
- New `WatchList` type: parses `watchlist.yaml`, expands `~`, validates
  targets exist at enrollment.
- New `Changelog` writer: append-only, checksummed, one entry per change.
- `GuardianCore` stays neutral; Hermes path defaults move into the
  default watchlist config.
- UI: enrolled-target list view; changelog viewer. No new permissions.

## 5. Explainer (adapted from Hermes Guardian)

The existing three-tier explainer survives the fork. Only its grounding
source changes.

- **Tier 1 — deterministic.** Simple changes get a built-in plain
  explanation ("3 lines added, 1 removed in `~/AGENTS.md`"). No model
  involved.
- **Tier 2 — grounded.** For Hermes config, grounding meant installed vs.
  hosted Hermes docs. For Agent Guardian, grounding is the watched file's
  own history plus the diff itself. There is no hosted doc to compare
  against; the file's past is the reference.
- **Tier 3 — LLM, provider-agnostic.** A stateless request goes out —
  diff plus grounding over stdin, never args — and a plain-language
  explanation comes back. The backend is just "an API pointed at a model":
  OpenRouter free tier via API key, local LM Studio (Bionic), any
  OpenAI-compatible endpoint. Same theory as OpenWhispr: local or cloud
  doesn't matter, the shape is the same.

Design principle: **explanations are advisory; receipts are authoritative.**
The explainer doesn't have to get it right every time. The changelog is
the source of truth. A poor explanation gets revisited later; a missing
receipt doesn't get a second chance.

The existing safety properties carry over: stateless, no agent constructed,
no tools loaded, no history written, secrets never in the process arg list.

## 6. Out of scope (Phase 3 or later)

- No syncing, no auto-remediation, no writing to watched targets. Ever
  in this phase.
- No agent inventory scan (known-path probing). Deferred.
- No network calls beyond what exists. The watcher is local.

## 6. Open questions

- Where does `watchlist.yaml` live? Candidate: `~/.agent-guardian/watchlist.yaml`.
- Should enrollment of a new target require explicit approval, or is
  editing the YAML enough?
- Changelog retention: bound it (e.g. rotate yearly), or unbounded?
