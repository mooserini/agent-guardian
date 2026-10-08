# Receipt-only witness and investigation handoff

- **Decision date:** 2026-10-08
- **Decision status:** Accepted by the repository owner
- **Implementation status:** Not implemented; this is a documentation-only decision

## Decision

Shadow Sepulcher is a best-effort, receipt-only witness of observed configuration
changes. Its single purpose is recording: preserve best-effort evidence of
changes that could otherwise silently alter an agent's behavior. It must never
restore, rewrite, reconfigure, or enforce the contents of a watched target.

Replace the **Restore** concept with **Send for investigation**. This is the
boundary between Sepulcher's recording role and a separately authorized
investigation by another agent. The owner selects recorded changes, previews a
secret-redacted evidence packet, explicitly chooses the recipient agent, and
approves that handoff. The handoff authorizes
investigation only. Any repair is a separate decision requiring the owner's
separate approval; it is not an action performed by the witness.

## Context and precedence

The [Phase 2 watch list and changelog design](phase-2-configurable-watchlist-changelog.md)
establishes a read-only watcher, a separate history, and the principle that
receipts are authoritative while explanations are advisory. This decision
preserves those boundaries and resolves conflicting design intent:

- Statements such as “every change” mean every change the watcher actually
  observes, on a best-effort basis. They are not a promise to capture every
  intermediate write.
- Retaining approve/reject machinery must not retain authority to write a
  watched target.
- The prohibition on restoring or reconfiguring watched targets is the product
  boundary, not a temporary Phase 2 restriction.
- An explanation or investigation feature does not authorize automatic
  disclosure to an external agent or service.

This decision supersedes contradictory design intent in the Phase 2 document,
the [durable maintenance window design](durable-maintenance-window.md), and
other earlier documentation. It does not edit those documents or remove their
existing implementation.

### Current behavior gap

At the inspected main revision
[`4f9083c`](https://github.com/mooserini/shadow-sepulcher/commit/4f9083c81dfca48b8fd2df6ad80d22f3719aae4f),
the public code still exposes **Restore approved version**, **Reject**, and
**Reject and restore checkpoint** in
[`GuardianView.swift`](https://github.com/mooserini/shadow-sepulcher/blob/4f9083c81dfca48b8fd2df6ad80d22f3719aae4f/Sources/AgentGuardian/GuardianView.swift).
[`GuardianModel.swift`](https://github.com/mooserini/shadow-sepulcher/blob/4f9083c81dfca48b8fd2df6ad80d22f3719aae4f/Sources/AgentGuardian/GuardianModel.swift)
routes those actions to snapshot or checkpoint restoration.

The receipt-only boundary and owner-directed investigation workflow described
here are not implemented. Recording this decision does not make the current
application read-only or make its existing restore actions safe to use as
investigation actions.

## Observation and notification

Observation history continues independently of whether an earlier notice is
pending, open, dismissed, or awaiting investigation. A pending notice must not
prevent a later observed change from receiving its own record.

Notification deduplication is separate from recording. Suppressing a repeated
bell or consolidating notices must not suppress distinct observed changes,
overwrite an earlier receipt, or make acknowledgement a prerequisite for
continued recording.

Receipts describe what was observed: the target, observation time, available
before/after fingerprints, and available change evidence. They must not invent
missing observations or claim that a timestamp proves the exact write time,
actor, cause, or intent. Missed intermediate writes remain possible. Known
observation or recording failures must be visible rather than presented as
complete history.

## Send for investigation

1. **Select evidence.** The owner selects the recorded changes to investigate.
   An unrelated configuration history is not included by default.
2. **Preview the packet.** Show the exact evidence intended for handoff after
   local secret redaction. Exclude credentials and unrelated private
   information. Preserve links or identifiers back to the selected receipts
   where available, and make redactions and evidence gaps clear.
3. **Choose the recipient.** The owner explicitly chooses the recipient agent.
   When the affected configuration belongs to that agent, suggest choosing a
   different investigator. The owner retains the choice.
4. **Approve the handoff.** Show the chosen recipient and the previewed packet
   before explicit approval. Cancelling sends nothing. A changed recipient or
   packet requires a new preview and approval.
5. **Investigate only.** The recipient may examine the approved evidence and
   return findings or recommendations. The handoff grants no permission to
   write, restore, repair, reconfigure, or enforce anything. A proposed repair
   returns to the owner as a separate decision.

A recorded change, pending notice, or selected default does not authorize
external disclosure. Redaction is required before preview and transmission;
the preview is an additional owner review, not a claim that automated redaction
can recognize every secret.

Original receipts remain authoritative for what Sepulcher observed.
Investigator findings and generated explanations are advisory and must remain
distinguishable from those receipts. They must not replace or rewrite the
original evidence.

## Scope and non-goals

This decision covers the witness boundary, continued observation, notification
separation, and the owner-approved investigation handoff.

It does not specify a transport, scheduler, agent-discovery mechanism, provider,
model, storage format, or implementation plan. It does not authorize automatic
handoffs, credential sharing, disclosure of unrelated private information,
self-repair, or any other remediation. It does not promise complete capture of
all writes, prevention of changes, or proof of why a configuration changed.

## Acceptance criteria for future implementation

- Every Sepulcher action leaves watched target contents unchanged, including
  legacy restore, reject, and maintenance paths. The investigation action
  replaces restoration rather than invoking it under a new label.
- If changes A, B, and C are observed while the notice for A remains pending,
  all three remain available as separate historical observations. Notification
  deduplication does not collapse or discard that history.
- Rapid-write and failure cases report only observed evidence and known gaps;
  neither the interface nor tests claim lossless capture of intermediate writes.
- The owner can select recorded changes and inspect the exact redacted packet.
  Credentials and unrelated private information are excluded, and the original
  receipts remain unchanged.
- No packet is sent without explicit recipient selection and approval of that
  packet. Cancellation sends nothing; changing the packet or recipient requires
  renewed review and approval.
- Selecting an investigator whose own configuration is affected produces a
  suggestion to choose another agent, without silently changing the recipient.
- The handoff explicitly limits authority to investigation. Findings remain
  advisory, and any repair requires a separate owner decision and authorization.

