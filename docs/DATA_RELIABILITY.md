# Vehicle Maintenance Tracker - Data Reliability Principles

> Data loss is the #1 reason users abandon maintenance apps. This document outlines our commitment to bulletproof data reliability.

---

## The Stakes

From market research, the single most-cited complaint across all competitor apps is **data loss**. Users report losing years of maintenance records to:

- Sync errors between devices
- Database corruption after updates
- Cloud service failures
- App abandonment by developers

One user review captured the sentiment perfectly:

> "I've been using and paying for this app for a couple years. In that time frame twice I've had data loss. All fuel logs from two of my vehicles are completely gone. I don't trust this app anymore."

**Our commitment: This will never happen to our users.**

---

## Core Principles

### 1. Local-First, Always

> The device is the source of truth. Cloud is a convenience, not a requirement.

- All data stored locally on device using SwiftData/Core Data
- App works fully offline — no internet required for core features
- Cloud sync is additive, not essential
- Users who never enable sync still have a complete, reliable app

**Why this matters:**
- No server dependency for basic functionality
- No data loss if our servers go down
- No data loss if user loses internet access
- Simpler architecture, fewer failure points

### 2. Never Delete Without Confirmation

> Destructive actions require explicit user intent.

- Deleting a vehicle requires confirmation dialog
- Deleting service history requires confirmation
- "Are you sure?" is not annoying here — it's protective
- Soft delete where possible (mark as deleted, purge later)

**Implementation:**
- 30-day "trash" for deleted items before permanent removal
- "Undo" available immediately after deletion
- Deleted data can be recovered from local backup

### 3. Automatic Local Backups

> Silent, automatic protection against corruption and accidents.

- App creates periodic local backups (daily when app is used)
- Backups stored in app's sandboxed container
- Keep last 7 daily backups, last 4 weekly backups
- User can manually trigger backup anytime
- Restore from backup available in settings (hidden but accessible)

**Backup contents:**
- Complete database snapshot
- All service records, vehicles, schedules
- User preferences and settings
- Attachment references (photos stored separately)

### 4. Graceful Sync Failures

> When sync fails, data survives. Always.

- Sync failures never corrupt local data
- Conflicts resolved conservatively (keep both versions, let user choose)
- Clear error messages when sync fails — no silent failures
- Automatic retry with exponential backoff
- User can force manual sync anytime

**Conflict resolution strategy:**
- If same record modified on two devices: keep both, mark as conflict
- Present conflict to user: "This service was edited on two devices. Which version?"
- Never auto-merge in ways that could lose information

### 5. Export Everything, Anytime

> Users own their data. They can take it with them.

- Full data export available to all users (not paywalled)
- Export formats: JSON (complete), CSV (human-readable)
- Export includes all vehicles, services, schedules, notes
- Export works offline — no server dependency
- Clear documentation of export format for portability

**Why free export matters:**
- Builds trust — users aren't trapped
- Reduces anxiety about app abandonment
- Differentiator vs competitors with poor/paywalled export

### 6. Migration Safety

> Updates should never break user data.

- Database migrations tested extensively before release
- Migrations are non-destructive — add columns, don't remove
- Pre-migration backup automatically created
- Rollback path available if migration fails
- Version compatibility maintained for at least 2 major versions

**Testing requirements:**
- Test migration from every previous version
- Test with large datasets (1000+ services)
- Test with edge cases (empty database, corrupted entries)
- Beta test migrations with real user data patterns

---

## iCloud Sync (Subscription Feature)

> Cloud sync adds convenience but must never compromise reliability.

### Architecture Principles

- **Local database is authoritative** — cloud is a replica
- **Sync is eventually consistent** — not real-time, and that's okay
- **Offline edits queue and sync later** — no data loss during outages
- **User can disable sync anytime** — local data preserved

### Sync Guarantees

| Scenario | Behavior |
| -------- | -------- |
| No internet | App works normally, changes queued |
| Sync conflict | Both versions preserved, user resolves |
| iCloud quota full | Warning shown, local data unaffected |
| Subscription lapses | Sync stops, all local data remains accessible |
| Re-subscribe | Sync resumes, merges cleanly |

### What We Sync

- Vehicles and their metadata
- Service records and history
- Maintenance schedules
- User preferences (opt-in)

### What We Don't Sync (Initially)

- Attachment photos (storage concerns — may add later)
- App state (current tab, scroll position)

---

## Family Sharing (Subscription Feature)

> Multiple users, shared vehicles, complex sync — handled carefully.

### Data Model

- Vehicles can be "owned" or "shared"
- Owner has full control; shared users have configurable permissions
- Changes propagate to all users with access
- Each user's local database contains shared vehicle data

### Conflict Handling

- Last-write-wins for simple fields (mileage, notes)
- Append-only for service logs (no overwrites)
- Owner can resolve disputes by reverting changes

### Permission Levels

| Level | Can View | Can Log Services | Can Edit Vehicle | Can Delete |
| ----- | -------- | ---------------- | ---------------- | ---------- |
| Owner | Yes | Yes | Yes | Yes |
| Editor | Yes | Yes | Limited | No |
| Viewer | Yes | No | No | No |

---

## Error Handling Philosophy

### User-Facing Errors

- **Clear language** — "Sync failed" not "Error code 5012"
- **Actionable guidance** — "Check your internet connection" or "Try again later"
- **No panic** — Reassure user their data is safe locally
- **Easy recovery** — One-tap retry, clear path forward

### Developer Logging

- Comprehensive error logging for debugging
- Anonymized crash reports (opt-in)
- Sync failure patterns tracked for improvement
- No PII in logs — ever

---

## Testing Requirements

### Data Integrity Tests

- [ ] Create 1000+ services, verify all persist after app restart
- [ ] Force-kill app mid-save, verify no corruption
- [ ] Simulate sync failure, verify local data intact
- [ ] Test migration from every previous version
- [ ] Test restore from backup

### Sync Tests

- [ ] Edit same record on two devices, verify conflict handling
- [ ] Go offline, make changes, come back online, verify sync
- [ ] Exceed iCloud quota, verify graceful degradation
- [ ] Cancel subscription, verify data accessibility

### Edge Cases

- [ ] Empty database edge cases
- [ ] Very old data (10+ years of records)
- [ ] Special characters in all text fields
- [ ] Maximum field lengths
- [ ] Timezone changes and date handling

---

## Monitoring & Alerts

### What We Track

- Sync success/failure rates
- Database migration success rates
- Backup completion rates
- Data recovery requests (support tickets)

### Red Flags

- Sync failure rate > 1%
- Any migration failure in production
- Any user-reported data loss
- Backup not completing for 7+ days

---

## Long-Term Commitment

### App Continuity

- Commitment to maintain app for minimum 5 years
- If discontinuing: 12-month notice to users
- If discontinuing: ensure export works indefinitely
- Consider open-sourcing data format for community tools

### User Trust

- Transparent communication about any data incidents
- Post-mortem published for any significant issues
- User data is never sold, shared, or monetized beyond stated features
- Privacy policy clearly states data handling

---

## Summary

**The hierarchy of priorities:**

1. **Never lose user data** — This is non-negotiable
2. **Work offline** — Cloud is a bonus, not a requirement
3. **User owns their data** — Export always available
4. **Fail gracefully** — Errors don't cascade to data loss
5. **Communicate clearly** — Users know what's happening

If we have to choose between a feature and data reliability, **reliability wins every time.**

---

_Last updated: January 2026_
