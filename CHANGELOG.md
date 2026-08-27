# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project follows [Semantic Versioning](https://semver.org/).

## [2.4.2] - 2026-06-11

### Changed

- Added cart icons and clearer labels to add, remove, and pharmacy checkout actions.
- Added a warning that the Ideal purchase strategy may require separate manual purchases.
- Pharmacy result rows now disappear immediately when their selector is disabled.

## [2.4.1] - 2026-06-11

### Fixed

- Promotion badges keep consistent card alignment regardless of text length.
- Numeric VTEX teasers are formatted as `-N% description`.
- Unavailable products are filtered consistently.
- Pharmacy rows react to selector changes without another search.

## [2.4.0] - 2026-06-11

### Added

- Marketplace seller badges for VTEX offers fulfilled by third parties.
- YAML fallback paths through `dig_path_first`.

### Fixed

- Promotion extraction for Rosário and Pague Menos when VTEX uses alternate teaser fields.
- Filtering for offers with `IsAvailable: false`.

## [2.3.0] - 2026-06-11

### Added

- User menu with avatar, display name, and optional Beta tester badge.
- User administration screen with listing, editing, and removal.
- User display names.
- Password-recovery email delivery.

## [2.2.0] - 2026-06-10

### Added

- Pharmacy selector below the search form. Only selected pharmacies enqueue jobs and render
  result rows; all active pharmacies start selected.

## [2.1.5] - 2026-06-10

### Fixed

- The session cart is cleared on login and logout, preventing it from leaking between users.

## [2.1.4] - 2026-06-10

### Fixed

- Logout can also terminate the optional external access session, preventing immediate
  proxy-based auto-login.

## [2.1.3] - 2026-06-10

### Fixed

- Long promotion text wraps inside product cards.

## [2.1.2] - 2026-06-10

### Changed

- Updated the hosted identity-provider flow and session policy. These changes affected the
  private deployment configuration rather than the public application setup.

## [2.1.1] - 2026-06-10

### Added

- Admin-only user registration at `/cadastro`, with the first database user acting as admin.

## [2.1.0] - 2026-06-11

### Added

- Devise authentication with database login, password recovery, remember-me support, and
  email validation.
- Optional JWT auto-login for requests coming from a verified access proxy.
- Dismissible success and alert messages.

### Changed

- Migrated users from `has_secure_password` to Devise's `encrypted_password` and recovery
  fields.
- Logout now uses `DELETE /logout` through Turbo.

## [2.0.0] - 2026-06-10

### Changed

- Moved from separately packaged single-user instances to a shared multi-user application
  model.
- Production runtime changed from a published Docker image to a directly managed Rails
  process. Docker remains available for development and tests.
- Pharmacy YAML files became source-controlled application configuration with no runtime
  editor or writable configuration volume.

### Removed

- Production Docker packaging and its wrapper CLI.
- Runtime pharmacy configuration volume.
- Published container-image workflow.

## [1.2.0] - 2026-06-10

### Added

- `pharmacy:test[slug,query]` task, which exercises a live pharmacy parser and reports field
  coverage for diagnosis.

### Changed

- Pharmacy YAML files are shipped with the application, making parser fixes reviewable,
  reversible, and testable in Git.
- Removed runtime parser administration and editable deployment volumes.

## [1.1.1] - 2026-06-10

### Fixed

- Corrected the VTEX promotion path to the serialized
  `Teasers[0].<Name>k__BackingField` field.

## [1.1.0] - 2026-06-10

### Added

- Promotion badges in product cards and cart selections.
- Per-pharmacy `promocao` field mapping in YAML.

### Fixed

- Test environment now sets `RAILS_ENV=test` before Rails boots.
- Explicit Shoulda Matchers loading for version 7.
- Browser and host-authorization checks no longer block request specs.
- Job and request specs consistently use the test queue adapter.

## [1.0.1] - 2026-06-10

### Fixed

- Solid Queue now starts with the web process in the original packaged deployment, allowing
  searches to progress beyond the loading state.

## [1.0.0] - 2026-06-08

### Added

- Parallel pharmacy searches with live Turbo Stream results.
- Horizontal product carousel per pharmacy.
- Product image, manufacturer, current price, and original price fields.
- Roughly one-hour cache per pharmacy and query.
- Generic JSON API and HTML extraction modes configured through YAML.
- Session cart with one row per query and one column per pharmacy.
- Ideal purchase column with the lowest selected price for each item.
- Per-pharmacy totals and visual lowest/highest comparison.
- Direct cart URL generation for compatible VTEX stores.
- Initial Pague Menos, Drogaria São Paulo, and Rosário configurations.
- Rails 8.1, SQLite, Solid Queue, Solid Cache, Solid Cable, Bootstrap 5.3, Turbo Streams,
  and RSpec foundation.
