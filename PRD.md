# Gauge Reading & Approval — Product Requirements

**Author:** Dean
**Context:** SmartTrackers coding assignment
**Stack:** Rails 8, PostgreSQL, Devise, Hotwire (Turbo + Stimulus — bulk-select optional), Tailwind, RSpec + Capybara
**Budget:** 8–12 hours

---

## 1. Problem

Administrative data processing splits into two jobs done by two people: someone enters data, someone else checks it. In SmartTrackers' domain, an employee transcribes figures from a power company invoice and a manager verifies them.

The system exists to make that handoff explicit — to track who entered what, who approved it, and to guarantee that approved figures cannot silently change afterwards.

## 2. Users and roles

Two roles, **mutually exclusive**. Neither can perform the other's work.

| Role | Can | Cannot |
|---|---|---|
| Employee | Create gauges, enter readings, edit own pending readings | Approve anything |
| Manager | View gauges, approve pending readings | Create gauges, enter or edit readings |

This is deliberately not a hierarchy. A manager does not "outrank" an employee and inherit their abilities — the separation of duties *is* the control being modelled. Enforced server-side on every action, not by hiding buttons.

## 3. Core concepts

### Gauge

A measurement definition: a name, a date range, a unit, and a time unit. Together these determine a fixed list of **periods** the employee reports against.

A gauge covering 1 Jan – 31 Dec at `monthly` has 12 periods. The same range at `daily` has 365. The date range says *what is covered*; the time unit says *at what granularity*.

One time unit per gauge. A gauge cannot mix monthly and daily periods. *(Confirmed with SmartTrackers.)*

### Period

A date range generated from the gauge, not stored. Periods align to calendar boundaries, with the first and last truncated to fit the gauge's date range.

A monthly gauge from 14 Mar to 20 Jun yields:

```
14 Mar – 31 Mar    (truncated head)
 1 Apr – 30 Apr
 1 May – 31 May
 1 Jun – 20 Jun    (truncated tail)
```

*(Head truncation confirmed with SmartTrackers; tail truncation follows by symmetry — a final period running past the end date would contradict it.)*

### Reading

One value for one period of one gauge. Identified by `(gauge, period_start)`, which is unique. A reading is in exactly one of three states:

| State | Condition | Employee | Manager |
|---|---|---|---|
| Not entered | no record | editable, empty | nothing to approve |
| Pending | `approved_at` null | editable | can approve |
| Approved | `approved_at` set | read-only | read-only |

## 4. The invariant

> **An approved reading never changes again.**

This is the system's reason for existing and is defended at three levels:

1. **Database** — check constraint requiring `approved_at` and `approved_by_id` to be both null or both present.
2. **Model** — `before_update` and `before_destroy` callbacks abort if the record was already approved. Keys off `approved_at_was`, so the approval transition itself passes while every subsequent write fails.
3. **Controller / view** — approved rows render as static text with no form and no approve action.

The model guard is load-bearing. A rule enforced only in a controller is violated by `Reading.find(1).update(value: 0)` in a console.

## 5. Workflows

### Employee — entering data

1. Signs in, lands on the gauge index.
2. Opens a gauge, or creates a new one (name, start date, end date, unit, time unit).
3. The gauge page shows one row per period, each in one of the three states.
4. Clicks an empty or pending row → inline form → saves. The row updates in place.
5. Corrects a pending value the same way. *(Confirmed with SmartTrackers: pending values remain editable.)*
6. Signs out.

### Manager — approving

1. Signs in, lands on the gauge index.
2. Opens a gauge and sees the entered values, visually distinguishing pending from approved.
3. Approves individual pending readings.
4. Each approval locks that reading permanently and records who approved it and when.
5. Signs out.

## 6. Screens

| Screen | Path | Employee | Manager |
|---|---|---|---|
| Sign in | `/users/sign_in` | ✓ | ✓ |
| Gauge index | `/gauges` | ✓ | ✓ |
| New gauge | `/gauges/new` | ✓ | redirect + alert |
| Gauge detail | `/gauges/:id` | period grid, editable | period grid, approvable |

Both roles see the same index. Row affordances differ by role on the detail page; the underlying data does not.

Forbidden actions are refused by a redirect to root with a flash alert (302), not a bare 403. The separation of duties is enforced server-side on every action; the redirect is the user-facing surface of that enforcement.

## 7. Interaction design

The frontend is Hotwire-only. No React, no client-side framework.

- **Reading entry** uses Turbo Frames. Each period row is its own frame; clicking swaps it for an inline form, and saving re-renders just that frame.
- **Approval** uses Turbo Streams. One `POST` returns two stream actions: replace the approved row, and update the "*n* of *m* approved" counter in the header.
- **Stimulus** is used once, for *optional* bulk selection of pending readings on the manager view. One well-scoped controller rather than several thin ones. This is the single cuttable feature (see §11); if time runs short it is dropped and the README says so, leaving the app Turbo-only.
- Approved rows contain no frame and no form — there is nothing to click.

## 8. Data model

```
users            id, email, encrypted_password, name, role
gauges           id, created_by_id, name, starts_on, ends_on, unit, time_unit
readings         id, gauge_id, entered_by_id, approved_by_id,
                 period_start, value, approved_at
```

Key constraints:

- `readings (gauge_id, period_start)` — unique. Makes duplicate entry structurally impossible.
- `readings` approval-pair check — approved-by-nobody is unrepresentable.
- `gauges` date-order check — `ends_on > starts_on`.
- User foreign keys restrict on delete; readings cascade from their gauge.

Design decisions worth defending:

- **`period_start` is the canonical key.** Every period collapses to one start date, so uniqueness is a database concern rather than a hopeful validation.
- **Approval is two nullable columns, not a status enum.** An enum would need the same columns anyway and would admit an invalid state.
- **No `periods` table.** Periods are a pure function of three columns. Materialising them means regenerating rows when a gauge changes and pointing readings at IDs that shift underneath them.
- **Column is `time_unit`, not `interval`.** `interval` is a PostgreSQL reserved word, and `time_unit` matches the assignment's own wording.

## 9. Testing

System tests are an explicit requirement and carry the most weight.

**System (Capybara + Cuprite)**
- Employee: sign in → create gauge → enter readings → sign out
- Manager: sign in → open gauge → distinguish pending from approved → approve → confirm locked
- Employee is refused the approve action
- Manager is refused the new-gauge form

**Model**
- Period generation: head truncation, tail truncation, range shorter than one unit, each time unit
- Immutability: pending edits allowed, approval transition allowed, post-approval edit and destroy both refused
- Validations: period must exist on the gauge grid, no duplicate period per gauge

**Request** (`spec/requests/role_enforcement_spec.rb`)
- Role enforcement on every non-GET endpoint: the wrong role is refused with a redirect to root and a flash alert (not a 403). Covers gauge create, reading create/update, and approve.
- Employees may edit only readings they entered — another employee's pending reading is refused.

## 10. Out of scope

Deliberate omissions, each with a reason:

| Excluded | Why |
|---|---|
| Organizations / multi-tenancy | "Branches" is scenario colour, not a requirement. Adds scoping to every query and doubles the auth surface. |
| Invoice upload or parsing | The bill is the input to typing, not an entity in the system. |
| Gauge editing and deletion | Not specified. Editing dates would strand readings outside the new grid. |
| Unapproving / rejection | Approval is specified as terminal. Rejection implies a return-to-employee flow that isn't described. |
| Audit log | `entered_by`, `approved_by`, and timestamps already answer who-did-what for the operations that exist. |
| Bulk import | Not specified. |
| Mixed granularity per gauge | Confirmed unnecessary. Two gauges cover the case. |

## 11. Delivery

Nine commits, each a working slice (mirrors the step sequence in `SPEC.md`):

0. `chore: rails new with postgres, rspec, tailwind`
1. `feat: devise authentication with employee and manager roles`
2. `feat: gauge model with period generation and index page`
3. `feat: employee gauge creation`
4. `feat: reading model with immutability guard and period grid`
5. `feat: inline reading entry with turbo frames`
6. `feat: manager approval with turbo streams`
7. `feat: bulk approval selection` *(optional — the one cuttable slice; see §7)*
8. `chore: seeds and readme`

Steps 0–6 plus 8 are a complete, honest submission; step 7 is dropped first if time runs short. Model work (period generation, the immutability guard) is front-loaded because it is expensive to get wrong and fully testable without UI.

Seeds ship two demo users and one gauge containing approved, pending, and empty periods, so a reviewer sees all three states on first sign-in.

The README carries setup instructions, both demo logins, the design decisions above in short form, and this out-of-scope list.
