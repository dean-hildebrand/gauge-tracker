# Gauge Tracker

A two-person data-entry and approval workflow: an **employee** transcribes meter
readings against a gauge's periods, and a **manager** approves them. Once approved,
a reading can never change again — that invariant is the reason the system exists.

## Stack

Rails 8.1 · PostgreSQL · Devise · Hotwire (Turbo) · Tailwind · RSpec + Capybara/Cuprite

Ruby **3.4.10** (see `.ruby-version`).

## Setup

```bash
bin/setup          # installs gems, prepares the database, seeds it, starts the app
```

Or step by step:

```bash
bundle install
bin/rails db:prepare   # create + migrate + seed
bin/rails s
```

Then visit http://localhost:3000.

## Demo logins

Users are seeded (there is no public signup — `:registerable` is intentionally omitted).

| Role | Email | Password |
|---|---|---|
| Employee | `employee@example.com` | `password` |
| Employee | `employee2@example.com` | `password` |
| Manager | `manager@example.com` | `password` |

Two seeded gauges, owned by **different** employees:

- **2026 Electricity** (owned by Emma) — 12 monthly periods showing all three states at once: Jan–Mar approved, Apr–May pending, Jun onward not entered.
- **Water — Q2** (owned by Emily) — starts mid-month (14 Mar) so the truncated head period is visible. Sign in as Emma to confirm she *cannot* add or edit readings on a gauge she didn't create.

## Running the tests

```bash
bundle exec rspec
```

System specs via Cuprite (headless Chrome), so Chrome/Chromium must be installed.

## Design decisions

- **The immutability guard is model-level.** `before_update` and `before_destroy` callbacks keyed off `approved_at_was` abort any write to (or deletion of) an already-approved reading.
- **Periods are derived, not stored.** A gauge's periods are a pure function of its date range and time unit, calendar-aligned with the first and last truncated to fit. No `periods` table to keep in sync when a gauge changes.
- **`period_start` is the canonical reading key.** `(gauge_id, period_start)` is unique at the database level, avoiding duplicate entry, and a model validation requires it to fall on one of the gauge's period boundaries.
- **Approval is two nullable columns (`approved_at`, `approved_by_id`), not a status enum** — an enum would need the same columns anyway and would admit an invalid "approved by nobody" state.
- **Reading entry uses Turbo Frames** (each period row is a turbo_frame_tag); **approval uses Turbo Streams** (one POST replaces the row *and* updates the header counter — two targets, which is why I used streams).

## Access model

Roles are mutually exclusive and enforced **server-side on every action** (forbidden actions redirect to root with a flash alert)

- **Employees** create gauges, enter readings, and edit their own pending readings.
- **Managers** view gauges and approve pending readings. They cannot create gauges or enter readings.

Reading management is further scoped by **gauge ownership**: only the employee who *created* a gauge may add or edit its readings. Everyone else sees a read-only grid. 

Decided this made the most sense for this type of application (alternative thought was to only allow `employees` to only see the gauges that they created - out of scope)

## Gauge editing/updating

- **Gauge editing is partially in scope.** 
- In interest of time, I decided to `lock` a gauge's period *shape* (`starts_on`, `ends_on`, `time_unit`) once it has readings, to avoid complications with existing readings. The lock is a model validation. For a fully fledged app, I would think about converting the existing reading into the appropriate `new` time_unit when editing to avoid mismatching readings based on a particular `time range` and `period`

## Cut for time

- **Bulk approval (Stimulus).** would be nice to have used a Stimulus controller to select multiple (or all) readings for a gauge and bulk approve
- **Pagination** - Gauges with a lot of `periods` render all on a single page - would like to have implemented `pagination` to clean up the UI and also to avoid ALL the turbo frames rendering all at once.
- Some flash messages persist until page refresh - need to fix for better experience

## Out of scope

Deliberate omissions: user signup, password reset etc, organizations/multi-tenancy, invoice upload/parsing, gauge deletion, unapproving/rejection, a separate audit log, and bulk import.
