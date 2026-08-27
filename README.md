# Paracetacaro

*[Leia isso em português](README.pt-BR.md)*

A Rails app that searches medicine prices across multiple online pharmacies in parallel,
lets you choose the actual equivalent product in each store, and builds a comparison cart
without pretending that different catalogs match automatically.

Results arrive one pharmacy at a time as soon as each search finishes. You stay in control
of product equivalence, dosage, brand, and package size; Paracetacaro handles the repetitive
searching, price comparison, and checkout links.

## How it works

1. Enter a medicine or product name and choose which pharmacies to search.
2. A background job runs for each selected pharmacy. Cached searches return immediately;
   fresh results stream into the page through Turbo Streams.
3. Each pharmacy gets its own horizontal result row. Pick the product that is genuinely
   comparable in that store, or leave the pharmacy empty when no suitable match exists.
4. The cart shows one column per pharmacy plus an **Ideal purchase** column, which picks the
   lowest selected price for each item.
5. For compatible VTEX stores, the whole pharmacy cart can be opened directly in the
   store's checkout. Other selections link to the product page for manual purchase.

Paracetacaro deliberately does not use AI or automatic product normalization. Medicine
names, strengths, forms, and package quantities differ enough between stores that a visible
manual choice is safer than a confident but incorrect automatic match.

## Highlights

- Parallel searches with live, per-pharmacy results.
- Pharmacy selector, with all active pharmacies selected by default.
- Product cards with image, manufacturer, current price, original price, promotion, and
  marketplace seller indicators when available.
- Unavailable products filtered before display.
- Session cart with one selection per item and pharmacy.
- Per-pharmacy totals and an item-by-item lowest-price strategy.
- Direct VTEX checkout for supported stores.
- Roughly one-hour cache per pharmacy and query, reducing repeated requests.
- YAML-driven pharmacy extractors, with API and HTML modes.

## Supported pharmacies

| Pharmacy | Search | Checkout | Notes |
|---|---:|---:|---|
| Pague Menos | Yes | Yes | VTEX Catalog API |
| Drogaria São Paulo | Yes | Yes | VTEX Catalog API |
| Rosário | Yes | No | Search works; the store's checkout endpoint is not compatible |
| Drogasil | Disabled | No | The storefront blocks the available automated HTTP clients |

Storefronts and third-party APIs change without notice. A pharmacy marked as supported may
need a parser update when its catalog response or anti-bot policy changes.

## Quick start

### Requirements

- Docker
- Docker Compose

### Run locally

```bash
git clone https://github.com/marcelomogami/paracetacaro.git
cd paracetacaro
docker compose build
docker compose run --rm app bin/rails db:prepare
docker compose up
```

Open `http://localhost:3000/setup` and create the first user. That first account becomes the
local administrator; registration is not open after setup.

No hosted-instance credentials are required for local development. Stop the application
with:

```bash
docker compose down
```

The Compose file is intended for development and testing. It is not a production deployment
guide and should not be exposed directly to the internet without an appropriate deployment
and access-control design.

## Usage

### Search and compare

Type a query such as `paracetamol 500mg`, leave the pharmacies you want selected, and start
the search. Results appear independently, so one slow or failing store does not block the
others.

Review dosage, form, manufacturer, quantity, and seller before clicking **Add**. Selecting a
product in one pharmacy does not force a selection in any other pharmacy.

### Build the cart

The cart uses one row per search query and one column per active pharmacy. An empty cell is a
valid decision: it means that no acceptable equivalent was selected in that store.

The **Ideal purchase** column chooses the cheapest selected product in each row. It may split
the order across several pharmacies, so its total is a price comparison, not a promise of a
single checkout or of lower delivery costs.

### Open the store

When a pharmacy has compatible VTEX SKU data, **Buy everything at this pharmacy** builds a
store checkout URL from the selections in that column. Otherwise, use the product links and
complete the purchase manually on the pharmacy website.

## Adding or updating a pharmacy

Each integration lives in `config/pharmacies/<slug>.yml`. The generic extractor supports
JSON APIs and HTML selectors, so most pharmacy changes do not require a new Ruby class.

A minimal API configuration looks like this:

```yaml
name: Example Pharmacy
slug: example
enabled: true
mode: api

search:
  url: "https://www.example.com/api/products?query={query}"

fields:
  results: "products"
  nome: "name"
  fabricante: "brand"
  preco: "offers[0].price"
  preco_original: "offers[0].listPrice"
  url: "url"
  imagem: "images[0].url"
```

Inspect the parser against a live response with:

```bash
docker compose run --rm app bin/rails 'pharmacy:test[example,paracetamol]'
```

The command prints every extracted field and a coverage summary. A field empty in every
result usually means that its YAML path no longer matches the response. After changing a
parser, run the extractor specs:

```bash
docker compose run --rm app bundle exec rspec spec/services/pharmacy_extractor_spec.rb
```

For VTEX APIs, browser-like request headers may be required. Use the application's extractor
when inspecting responses instead of assuming that a plain `curl` request is equivalent.

## Optional hosted configuration

Local development works without these values. A production deployment can provide them
through its environment:

| Variable | Purpose |
|---|---|
| `APP_HOST` | Host used in links generated by mailers |
| `MAILER_FROM` | Full sender used by Devise mailers |
| `RESEND_API_KEY` | SMTP credential for password-recovery email |
| `CLOUDFLARE_ACCESS_ISSUER` | Optional HTTPS Cloudflare Access team issuer |
| `CLOUDFLARE_ACCESS_AUD` | Optional audience tag used to verify Access JWTs |
| `RAILS_MASTER_KEY` | Standard Rails key for the deployment's encrypted credentials |

`APP_HOST`, `MAILER_FROM`, and `RESEND_API_KEY` are required by the current production
environment. The Cloudflare Access values are optional; without both, proxy-based auto-login
stays disabled and normal Devise login remains available.

## Development checks

Prepare the test database and run the full suite:

```bash
docker compose run --rm -e RAILS_ENV=test app bin/rails db:prepare
docker compose run --rm -e RAILS_ENV=test app bundle exec rspec
```

The CI workflow also runs:

```bash
docker compose run --rm app bin/rubocop
docker compose run --rm app bin/brakeman --no-pager
docker compose run --rm app bin/bundler-audit
docker compose run --rm app bin/importmap audit
```

Changes to application code follow Red, Green, Refactor: write the failing RSpec example
first, implement the smallest working change, then refactor while keeping the suite green.

## Architecture

Paracetacaro runs on Ruby 3.4 and Rails 8.1. SQLite stores application data and also backs
Solid Queue, Solid Cache, and Solid Cable, so the app does not require PostgreSQL or Redis.
Each selected pharmacy is searched by an independent background job, and Turbo Streams
deliver its result row as soon as it is ready.

The generic extractor uses Faraday and Nokogiri for JSON APIs and HTML pages. Ferrum is
available as a fallback for integrations that require JavaScript. The interface uses
Bootstrap 5.3, Bootstrap Icons, Turbo, and Stimulus.

## Security and data notes

- The first local account is stored in SQLite with a Devise password hash. Use a development
  password, not a password reused elsewhere.
- Searches make live requests to third-party pharmacy websites. Their availability, terms,
  rate limits, and responses remain outside this project's control.
- Search results are cached temporarily; Paracetacaro is not a historical price database.
- Product and checkout links leave the application and open third-party websites. Always
  verify the final product, quantity, seller, price, delivery fee, and prescription rules in
  the store before purchasing.
- Credentials, access to hosted instances, and specific production procedures are
  intentionally outside this public README.

## Known limitations

- Product equivalence is manual. The application does not prove that two selected medicines
  have the same active ingredient, strength, form, or package quantity.
- Price-per-unit comparison is not implemented yet, so different package sizes require extra
  attention.
- Scrapers can break when a pharmacy changes its API, HTML, or bot protection.
- Prices and availability may vary by region, account, loyalty program, or marketplace
  seller.
- Checkout support is limited to compatible VTEX configurations; it does not automate login,
  payment, delivery selection, or prescription handling.
- Carts are session-oriented. Named, user-owned saved carts and search history are not part of
  the current scope.

## Structure

```text
app/
  controllers/             # search, cart, setup, sessions, and user administration
  jobs/search_job.rb        # background search, caching, and Turbo Stream broadcasts
  models/                   # users, carts, pharmacy configuration, and result value objects
  services/
    pharmacy_extractor.rb   # generic API/HTML extraction
    vtex_checkout_service.rb
config/
  pharmacies/              # one YAML parser per pharmacy
spec/                       # RSpec models, services, jobs, requests, and views
```

## Contributing

Issues and pull requests are welcome. For parser changes, include the pharmacy slug, an
example query, the observed field coverage, and the relevant specs. Run the development
checks above before opening a pull request, and never include real credentials, user data,
or private deployment details.

## Current scope

Paracetacaro is a small, self-hosted comparison tool for a limited set of Brazilian online
pharmacies. The source can be studied, forked, and extended, but there is no public hosted
service, guaranteed pharmacy coverage, or commercial support.

The application interface and domain vocabulary intentionally remain in Brazilian
Portuguese. Paracetacaro is localized for Brazilian users and pharmacies; English is used
for the primary public documentation, not as the product language.

## License

[MIT](LICENSE). Built for personal use, but free to use, fork, and adapt.
