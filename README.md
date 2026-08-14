# Invoicing

A Rails application for running the billing side of a small UK practice that charges clients for
time-based sessions. It keeps a client list, tracks the rate each client is charged and how that
rate has changed over time, records individual sessions, gathers unbilled sessions into invoices,
emails those invoices out as PDFs, and issues credit notes when an invoice needs adjusting
downwards.

The application is single-tenant and password-protected: one practitioner signs in and manages
everything. There is no client-facing login.

## Domain model

| Model | Purpose |
| --- | --- |
| `Client` | A person receiving sessions. Holds contact details, an active flag, and an optional `paid_by` reference to a `Payee`. |
| `Payee` | A third party that pays for one or more clients' sessions, for example an employer or a family member. Adds a mandatory `organisation`. |
| `Person` | A concern shared by `Client` and `Payee` providing name, email and address validation, an `active` scope, and address formatting. |
| `Fee` | One rate for one client over one date period, via `from` and `to`. The open-ended record with `to: nil` is the current rate. |
| `ClientSession` | A single billable session: a date, a number of `units`, a `description`, and the rate that applied at the time. Optionally linked to an `Invoice`. |
| `Invoice` | A billing document addressed to a client or their payee, gathering `ClientSession` records. Carries rich text, a generated PDF, and a status. |
| `CreditNote` | A negative adjustment raised against a specific invoice, with a mandatory `reason`. Reaches its client and payee by delegation through the invoice. |
| `Message` | Rich-text boilerplate to fold into invoice drafts, with an optional active date window. |
| `MessagesForClient` | Join table between messages and clients. A row with `client_id: nil` means the message applies to every client. |
| `User` | The signed-in practitioner. Managed by Clearance. |

Relationships worth knowing:

- A `Client` has many `Fee` records, many `ClientSession` records and many `Invoice` records.
- A `Client` optionally belongs to a `Payee` through `paid_by`. Unset means the client pays for
  themselves.
- An `Invoice` belongs to a `Client` and optionally to a `Payee`, and has many `CreditNote` records.
- A `CreditNote` belongs to an `Invoice` and has no direct client or payee columns of its own.

Money is stored as integer pence with a currency column, handled by the Money gem through
`monetize`. The default currency is GBP.

## Business rules

These are enforced in the models, so they hold regardless of which screen or console you come in
through.

### Rates change over time

Each client's charge rate lives in a `Fee` row with a `from` and `to` date. Setting a new rate does
not overwrite the old one: `Client#create_new_rate` closes the current record off at the day before
the new rate starts and opens a fresh open-ended one. `current_rate` therefore always answers "what
do we charge today", while history stays intact for invoices raised in the past. Overlapping
periods are rejected by a validation, and every client must have at least one fee record.

A session captures the rate in force when it happened, so later rate changes never silently rewrite
the value of work already recorded.

### Sessions are billed in units

A session records `units` as a decimal, entered in steps of 0.5, rather than a start and end time.
Its value is simply `unit_session_rate * units`. New sessions default to 1 unit at the client's
current rate.  A single unit is typically 50 mins, giving the practitioner 10 mins to prepare
for the next session. 

### Invoices move forward only

Status runs `created` → `sent` → `paid`, and `Invoice#status_change_ok?` refuses anything else,
including reopening a paid invoice. While an invoice is still `created` it can be freely edited;
once it is sent or paid, any change to a field other than the status is rejected, rich text
included. Only a `created` invoice can be deleted.

The same immutability protects the sessions inside it: `ClientSession` blocks its own update and
destroy once its invoice has left `created`. While an invoice is still editable, changing a
session's units or rate recalculates the invoice total automatically.

### Invoices can be addressed to a payee or to the client

A new invoice inherits its payee from the client's `paid_by`, unless a payee was explicitly
assigned. `self_paid` flips this: setting it true clears the payee so the invoice is billed to the
client directly, and the invoice form offers this as a radio choice whenever the client has a payee
on file. `Invoice#self_paid` is simply "has no payee".

### Invoice drafts write their own first draft

Two `after_initialize` hooks populate the rich-text body of a new invoice:

- **Client messages.** Any `Message` currently inside its date window that applies to this client,
  or to all clients, is folded into the text.
- **Unpaid invoice reminders.** Any earlier invoice for the client that is not yet paid produces a
  chase line. One outstanding invoice gets a single sentence; several produce a bulleted list.

Both are only a starting point. The text is editable before the invoice is created, which is the
whole point of generating it into the draft rather than bolting it on at send time.

### Credit notes only ever reduce

A credit note can be raised only against an invoice that has been sent or paid, so nothing is
credited before it was ever billed. Its amount is forced negative on validation, cannot be zero,
and cannot exceed the invoice it credits. A `reason` is required. The lifecycle is just
`created` → `sent`; once sent it is final and can be neither edited nor deleted.

Credit notes do **not** automatically adjust the parent invoice's balance. That reconciliation is
treated as an accounting concern outside this system.

### Clients are hard to delete on purpose

`Client#deleteable?` refuses deletion of an active client, of one with unpaid invoices, of one with
uninvoiced sessions, and of one with any invoice less than five years old. A `before_destroy` hook
enforces this and returns the reason, which the UI surfaces.

Payees are protected too, but only in `PayeesController#destroy`, which rejects deletion while any
client still references the payee. Unlike the client rules, that guard is not enforced at the model
level and so does not apply from the console.

## Sending invoices and credit notes

Sending is a single action from the invoice or credit note page:

1. The show page is rendered to HTML against a dedicated `pdf` layout.
2. `FerrumPdf` converts that HTML to a PDF using headless Chrome.
3. The PDF is attached to the record via Active Storage, so the document that was sent stays
   retrievable and is not regenerated on later sends.
4. `InvoiceMailer` or `CreditNoteMailer` emails it to the client, with the PDF attached.
5. The record is marked `sent`.

Organisation details on the document and bank details in the email body are read from encrypted
credentials rather than hard-coded. See [Credentials](#credentials).

In development, mail opens in the browser through `letter_opener` instead of being delivered.

## Conventions

The application follows UK conventions throughout, and the tests assert on them:

- **Dates** display as `31 May 2025`, via `strftime("%d %B %Y")`.
- **Currency** is pounds sterling, formatted through the Money gem.
- **Postcodes** are validated against a UK-format regular expression.
- **Date entry fields** are `date_field` inputs, so the browser renders them `dd/mm/yyyy`. This
  depends on the browser's locale, which is why CI pins Chrome to `en_GB`.

## Technology

| Area | Choice |
| --- | --- |
| Language | Ruby 4.0.6, pinned in `.ruby-version` |
| Framework | Rails 8.1.3.1, with `config.load_defaults 8.1` |
| Database | SQLite in all environments |
| Money | `money-rails` |
| Auth | Clearance |
| Assets | Propshaft, with importmap-rails for JavaScript |
| Front end | Turbo and Stimulus, plus Pure.css and Material Symbols |
| Rich text | Action Text |
| Files | Active Storage, with `image_processing` for variants |
| PDF | `ferrum_pdf`, driving headless Chrome |
| Background jobs, cache, cable | Solid Queue, Solid Cache, Solid Cable, all database-backed |
| Deployment | Docker image deployed with Kamal, fronted by Thruster |
| Tests | RSpec, FactoryBot, Faker, Capybara, Selenium, SimpleCov |
| Static analysis | Brakeman, plus RuboCop via `rubocop-rails-omakase` |

There is no separate Redis or Postgres to run: the queue, cache and cable adapters all sit in
SQLite, and `SOLID_QUEUE_IN_PUMA` runs the worker inside the web process in production.

The interface is deliberately server-rendered. Sixteen small Stimulus controllers handle the
interactive parts, chiefly delete and send confirmation modals, the active/inactive filters, live
rate lookup when picking a client, and showing the payee reference field only when a payee is
selected. Styling comes from Pure.css with Material Symbols icons loaded from Google Fonts.

## Getting started

Requires Ruby 4.0.6 and a Chrome or Chromium binary on `PATH` for PDF generation and system tests.

```bash
bundle install
bin/rails db:setup      # create and load schema
bin/rails server
```

`db/seeds.rb` is still the generated stub, so `db:setup` leaves you with an empty database.

Then sign in at <http://localhost:3000>. The root path is the client index.

Sign-up is disabled, via `config.allow_sign_up = false` in `config/initializers/clearance.rb`, so
create the first user from the console:

```bash
bin/rails console
User.create!(email: "you@example.com", password: "a-strong-password")
```

### Credentials

The application reads organisation and bank details from encrypted credentials, and views will
raise without them. Two credential sets are in play:

| Environment | File | Key |
| --- | --- | --- |
| development, production | `config/credentials.yml.enc` | `config/master.key` |
| test | `config/credentials/test.yml.enc` | `config/credentials/test.key` |

Both key files are gitignored. Edit them with
`bin/rails credentials:edit` and `bin/rails credentials:edit --environment test`. The expected
shape is:

```yaml
org_details:
  name: ...
  address1: ...
  address2: ...
  town: ...
  postcode: ...
  email: ...
payment_details:
  bank: ...
  account_name: ...
  account_number: ...
  sort_code: ...
```

## Testing

```bash
bundle exec rspec                        # everything
bundle exec rspec spec/models            # one directory
bundle exec rspec spec/path/to_spec.rb:42 # one example
bundle exec rspec --tag focus            # focused examples
```

The suite is around 440 examples across model, system, mailer and routing specs. System specs drive
a real browser through Selenium. They run headless by default; examples tagged `js: true` use a
visible Chrome instead, which is handy locally but needs a virtual display on a build server.

Database state is managed by DatabaseCleaner, truncating for browser-driven specs because the
application under test does not share the spec's connection. `spec/rails_helper.rb` signs a user in
before every system spec, so specs start from an authenticated session.

Two environment requirements are easy to trip over when running the suite outside a normal desktop:

- **`LANGUAGE=en_GB`.** Date inputs take their format from Chrome's UI locale. Under a US-English
  Chrome the fields become `mm/dd/yyyy`, and a date typed as `13/08/2026` is silently stored as
  8 December instead of 13 August. The failure looks like a wrong-date assertion, not a parse error.
- **The test credentials key**, as either `config/credentials/test.key` or `RAILS_MASTER_KEY`.
  Without it, views that read `credentials.org_details` fail on `nil`.

### Static analysis

```bash
bundle exec brakeman   # security scan
bundle exec rubocop    # lint
bundle exec rubocop -a # autocorrect
```

## Continuous integration

`.github/workflows/ci.yml` runs four jobs on every pull request and every push to `main`:

| Job | Command |
| --- | --- |
| `test` | `xvfb-run -a bundle exec rspec` |
| `lint` | `bin/rubocop -f github` |
| `scan_ruby` | `bin/brakeman --no-pager` |
| `scan_js` | `bin/importmap audit` |

All four take their Ruby version from `.ruby-version`. The test job supplies `LANGUAGE=en_GB` and
`RAILS_MASTER_KEY` for the reasons above, and uploads screenshots from `tmp/capybara` when a system
spec fails. It deliberately does not install `google-chrome-stable`, because the runner image
already ships Chrome with a matching chromedriver and installing it introduces a version mismatch.

## Deployment

Deployment is a Docker image driven by Kamal. `config/deploy.yml` carries placeholder values for
the server address, registry and hostname, so it needs filling in before first use. The image
expects `RAILS_MASTER_KEY` in the environment and runs Solid Queue inside Puma.

```bash
bin/kamal setup    # first deploy
bin/kamal deploy   # subsequent deploys
```

`/up` returns 200 once the application has booted, for load balancers and uptime checks.

## Repository layout

```
app/            models, controllers, views, mailers, Stimulus controllers
config/         routes, environments, credentials, Kamal deploy config
db/             migrations and schema
spec/           RSpec specs, factories and support
DesignDocs/     feature specifications and implementation notes
TODO.md         outstanding ideas
CLAUDE.md       guidance for Claude Code
```

## Design documents

`DesignDocs/` holds two kinds of file: short requirement statements written before a feature was
built, such as `Billing.md`, `CreateMessages.md` and `SeparatePayeeFromClient.md`, and longer
implementation notes written afterwards.

**Treat them as a historical record rather than as a description of the code.** Two significant
designs in there were implemented and then reversed, and the documents were not all updated:

- `Billing.md` and `CREDIT_NOTES_GUIDE.md` describe a `Billing` superclass using single table
  inheritance, a `billings` table, a `BillingsController` and an `applied` credit note status. That
  was built, then unwound. `SEPARATION_COMPLETION.md` and `APPLIED_STATUS_REMOVAL.md` record the
  reversal. Today `Invoice` and `CreditNote` are separate models on separate tables, the invoice
  index shows both, and credit notes stop at `sent`.
- `SeparatePayeeFromClient.md` proposes a single `Person` table using single table inheritance with
  a `type` column. What was actually built is a `Person` *concern* shared by two independent
  `clients` and `payees` tables.

The schema in `db/schema.rb` and the models themselves are the authority.
