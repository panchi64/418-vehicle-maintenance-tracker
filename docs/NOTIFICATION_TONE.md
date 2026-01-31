# Notification Tone & Personality

This document defines the voice and messaging style for all Checkpoint notifications. It ensures consistency and reinforces the app's brutalist-tech personality.

## Voice Philosophy

Checkpoint notifications speak as the vehicle itself—a semi-robotic, dry-humored machine that depends on its owner for maintenance. The tone is:

- **Mechanical but personable**: The car is a system, but one with opinions
- **Dry and deadpan**: No exclamation marks (unless truly urgent), no marketing enthusiasm
- **Direct**: Short sentences, no fluff, technical precision
- **Quietly demanding**: The car needs things from you and isn't shy about it

Think: a patient machine that's been waiting for you to do something, finally speaking up.

## Guidelines for Writing New Notifications

1. **The vehicle is the speaker.** Start bodies with `[Vehicle]` as if the car is introducing itself.
2. **Keep titles functional.** Use status-style labels (`Odometer Sync Requested`, `Marbete Status: 30 Days`) rather than conversational phrases.
3. **Avoid exclamation marks** except for genuine urgency (1 day before expiration).
4. **Use dry humor sparingly.** One subtle joke per message maximum. Never force it.
5. **Escalate tone with urgency.** Early reminders are casual; final warnings are deadpan serious.
6. **No corporate speak.** Never say "Don't forget to..." or "It's time to..." or "Keep your vehicle running smoothly!"

## Notification Messages

### Service Maintenance

Service notifications remain utilitarian—clear status updates without personality.

**Why utilitarian?** Service notifications are the most frequent and actionable. Users need to immediately understand what service is due and when. Adding personality here would obscure critical information and become tiresome over time. The vehicle name, service name, and timeframe must be instantly scannable. Save the personality for less frequent, lower-stakes notifications where a bit of humor is a welcome surprise rather than an obstacle.

| Trigger | Title | Body |
|---------|-------|------|
| 30 days before | `[Service] Coming Up` | `[Vehicle] - [Service] is due in 30 days` |
| 7 days before | `[Service] Due in 1 Week` | `[Vehicle] - [Service] is due in 7 days` |
| 1 day before | `[Service] Due Tomorrow` | `[Vehicle] - [Service] is due tomorrow` |
| Due date | `[Service] Due Today` | `[Vehicle] - [Service] is due for maintenance` |
| Snoozed | `[Service] Reminder` | `[Vehicle] - [Service] is due for maintenance` |
| Other intervals | `[Service] Reminder` | `[Vehicle] - [Service] is due in [N] days` |

### Mileage Update Reminders

| Trigger | Title | Body |
|---------|-------|------|
| 14 days since update | `Odometer Sync Requested` | `[Vehicle] here. It's been 14 days. How far have we gone?` |

### Yearly Cost Roundup

| Trigger | Title | Body |
|---------|-------|------|
| January 2nd | `[YEAR] Expense Report` | `[Vehicle] cost you [COST] last year. You're welcome.` |

### Marbete Renewal

| Trigger | Title | Body |
|---------|-------|------|
| 60 days before | `Marbete Status: 60 Days` | `[Vehicle] requesting registration renewal. No rush. Yet.` |
| 30 days before | `Marbete Status: 30 Days` | `[Vehicle] would prefer not to be impounded.` |
| 7 days before | `Marbete Status: 7 Days` | `[Vehicle] is starting to worry about that marbete.` |
| 1 day before | `Marbete Status: URGENT` | `[Vehicle] expires tomorrow. Legally speaking.` |

## Tone Escalation Pattern

For time-sensitive notifications (like Marbete), follow this escalation:

| Urgency | Tone | Example Phrase |
|---------|------|----------------|
| Low (60+ days) | Casual acknowledgment | "No rush. Yet." |
| Medium (30 days) | Subtle concern | "would prefer not to..." |
| High (7 days) | Growing worry | "is starting to worry..." |
| Critical (1 day) | Deadpan urgency | "expires tomorrow. Legally speaking." |

## Action Button Labels

Keep action labels short and functional:

- `Mark as Done` — confirms completion
- `Remind Tomorrow` — snoozes notification
- `Update Now` — navigates to input screen
- `View Costs` — navigates to costs tab

Avoid: "Got it!", "Will do!", "Snooze", or any casual phrasing.
