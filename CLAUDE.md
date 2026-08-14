# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

`README.md` describes the application in full. This file covers what is needed to change it safely.

## Common Commands

Prefer the `bin/` binstubs over bare `rails`, so the correct bundle is always used.

### Development

```bash
bundle install
bin/rails db:setup        # create and load schema (db/seeds.rb is an empty stub)
bin/rails server
bin/rails console
```

### Testing

```bash
bundle exec rspec                          # all specs
bundle exec rspec spec/models              # one directory
bundle exec rspec spec/path/to/file_spec.rb
bundle exec rspec spec/path/to/file_spec.rb:42
bundle exec rspec --tag focus
```

### Static analysis

```bash
bundle exec brakeman     # security scan
bundle exec rubocop      # lint
bundle exec rubocop -a   # safe autocorrect
```

Both must stay clean: CI fails on any RuboCop offence, as the lint step has no `--fail-level`.

### Database

```bash
bin/rails db:migrate
bin/rails db:rollback
bin/rails db:test:prepare
bin/rails generate migration MigrationName
```

## Architecture

A single-tenant billing application for a UK practice charging clients for time-based sessions.
One practitioner signs in; there is no client-facing login and sign-up is disabled.

### Domain models

- **`Client`** — contact details, `active` flag, optional `paid_by` reference to a `Payee`, and an
  optional `payee_reference`.
- **`Payee`** — a third party paying for one or more clients. Adds a mandatory `organisation`.
- **`Person`** (`app/models/concerns/person.rb`) — concern shared by `Client` and `Payee` supplying
  name, email and UK postcode validation, the `active` scope, and address formatting. **Not** single
  table inheritance: `clients` and `payees` are separate tables.
- **`Fee`** — one rate for one client over one period, via `from` and `to`. The row with `to: nil`
  is the current rate. Column is `unit_charge_rate`.
- **`ClientSession`** — a billable session: `session_date`, `units` (decimal, entered in 0.5 steps),
  `description`, and `unit_session_rate` captured at the time. Value is `unit_session_rate * units`.
  A unit is typically 50 minutes, leaving the practitioner 10 minutes to prepare for the next
  session, but that is a working convention rather than anything the code enforces. There is no
  duration-in-minutes field, and nothing converts units to time.
- **`Invoice`** — belongs to a client and optionally a payee, has many client sessions and credit
  notes, plus rich text and an attached PDF. Status `created` → `sent` → `paid`.
- **`CreditNote`** — a negative adjustment against one invoice, with a mandatory `reason`. Status
  `created` → `sent`. Reaches `client` and `payee` by delegation through the invoice, having no
  columns of its own for them.
- **`Message`** — rich-text boilerplate folded into invoice drafts, with an optional date window.
- **`MessagesForClient`** — join table. A row with `client_id: nil` means "all clients".
- **`User`** — the practitioner, managed by Clearance.

Money is integer pence plus a currency column, via `monetize`. Default currency GBP.

### Invariants not to break

These are enforced in the models, and specs cover each one. Take care when touching them.

1. **Rate history is append-only.** Setting a new rate closes the current `Fee` at the day before
   the new one starts and opens a fresh open-ended record; it never overwrites. Overlapping periods
   fail validation, and every client must have at least one fee.
2. **Invoice status only moves forward.** `created` → `sent` → `paid`. A paid invoice cannot be
   reopened.
3. **Sent and paid invoices are immutable.** Any change to a field other than the status is
   rejected, rich text included. Only a `created` invoice can be deleted. `ClientSession` enforces
   the matching rule, refusing update and destroy once its invoice has left `created`.
4. **Credit notes only reduce.** Allowed only against a sent or paid invoice; amount forced
   negative, non-zero, and no greater than the invoice. Final once sent. They do not adjust the
   parent invoice's balance, which is deliberate.
5. **Client deletion is guarded.** `Client#deleteable?` blocks active clients, unpaid invoices,
   uninvoiced sessions, and any invoice under five years old, returning a reason.

Note the asymmetry: the payee deletion guard lives only in `PayeesController#destroy`, not in the
model, so it does not apply from the console.

### Invoice drafts populate themselves

Two `after_initialize` hooks on new invoices write the rich-text body: applicable `Message` records,
then a reminder listing the client's unpaid invoices. Both are editable before creation, which is
the point of generating them into the draft rather than at send time. When changing reminder
wording, note that specs assert on the exact text.

### Sending

`send_invoice` and `send_credit_note` render the show page against the `pdf` layout, convert it with
`FerrumPdf` (headless Chrome), attach the result via Active Storage, mail it, then mark the record
sent. An already-attached PDF is not regenerated. Organisation and bank details come from encrypted
credentials, so views raise without them.

## Conventions

- **Dates** display as `31 May 2025`, via `strftime("%d %B %Y")`. Never US ordering.
- **Currency** is GBP. Both `number_to_currency(amount, unit: "£")` and Money's `.format` are in
  use; match whichever the surrounding file uses.
- **Postcodes** validate against a UK-format regular expression.
- **Style** is `rubocop-rails-omakase`: double-quoted strings, spaces inside array brackets.

## Testing

RSpec with FactoryBot. Specs live under `spec/models`, `spec/system`, `spec/mailers`, `spec/lib` and
`spec/routing`. Around 440 examples, one of which is pending by design.

Factories in `spec/factories`, with useful traits:

- `:client` — traits `:inactive`, `:with_fees`, `:with_client_sessions`, `:with_payee`; plus
  `:client_with_random_name`
- `:invoice` — plus `:invoice_with_client_sessions`
- `:message` — traits `:for_all_clients`, `:for_specific_clients`, `:without_dates`
- `:payee`, `:fee`, `:client_session`, `:credit_note`, `:user`

Names come from `numbers_and_words` via `to_words`, so they are word-based rather than numeric.

### System specs

Driven by real Chrome through Selenium. Headless by default; examples tagged `js: true` use a
**visible** Chrome, so they need a display. `spec/rails_helper.rb` signs a user in before every
system spec.

DatabaseCleaner truncates for browser-driven specs, because the application under test does not
share the spec's database connection. Do not set `use_transactional_fixtures = true`; a guard
deliberately raises if you do.

Assert on paths with `expect(page).to have_current_path(...)`, never `expect(current_path).to eq`.
The latter does not wait and races the browser after `click_link`, which caused a long-standing
intermittent failure.

### Two environment gotchas

1. **Browser locale affects date entry.** Date fields are `date_field` inputs, whose format follows
   Chrome's UI locale. Specs type `dd/mm/yyyy`. Under a US-English Chrome the field becomes
   `mm/dd/yyyy`, and `13/08/2026` is silently stored as 8 December rather than 13 August. The
   symptom is a wrong-date assertion, not a parse error. CI sets `LANGUAGE=en_GB`; reproduce the
   failure locally with `LANG=en_US.UTF-8`.
2. **Specs need the test credentials key.** In test, credentials resolve to
   `config/credentials/test.yml.enc` with `config/credentials/test.key`, which is gitignored. Views
   read `credentials.org_details` and `credentials.payment_details`, so without the key they fail on
   `nil`. CI supplies it as `RAILS_MASTER_KEY`.

## CI

`.github/workflows/ci.yml` runs four jobs on pull requests and pushes to `main`: `test`
(`xvfb-run -a bundle exec rspec`), `lint`, `scan_ruby` (Brakeman) and `scan_js` (importmap audit).
All read `.ruby-version`.

Do not add `google-chrome-stable` to the test job's package list. The runner image already ships
Chrome with a matching chromedriver, and installing it upgrades Chrome past the bundled driver.

## Stack

- Ruby 4.0.6 (`.ruby-version`), Rails 8.1.3.1, `config.load_defaults 8.1`
- SQLite in every environment
- `money-rails` for currency; Clearance for authentication
- Propshaft and importmap-rails; Turbo and Stimulus; Pure.css with Material Symbols
- Action Text for rich text; Active Storage with `image_processing`
- `ferrum_pdf` for PDF generation
- Solid Queue, Solid Cache and Solid Cable, all database-backed, so no Redis is needed
- Kamal and Docker for deployment, fronted by Thruster
- `letter_opener` shows mail in the browser in development

## DesignDocs are historical

`DesignDocs/` holds pre-build requirement statements and post-build notes. **Do not treat them as a
description of the current code.** Two designs were built and then reversed without all the
documents being updated:

- `Billing.md` and `CREDIT_NOTES_GUIDE.md` describe a `Billing` STI superclass, a `billings` table,
  a `BillingsController` and an `applied` credit note status. All were removed;
  `SEPARATION_COMPLETION.md` and `APPLIED_STATUS_REMOVAL.md` record the reversal.
- `SeparatePayeeFromClient.md` proposes a single `Person` STI table. A shared concern over two
  tables was built instead.

`db/schema.rb` and the models are the authority.
