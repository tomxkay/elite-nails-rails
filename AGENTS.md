# Repository Guidelines

## Project Structure & Module Organization
- Rails 8 app with Propshaft, Hotwire (Turbo + Stimulus), esbuild, and Tailwind CLI (output in `app/assets/builds`).
- Domain code follows Rails defaults: `app/models`, `app/controllers`, `app/views`, `app/jobs`; UI JS lives in `app/javascript` (one ESM entry per bundle), styles start at `app/assets/stylesheets/application.tailwind.css`.
- Configuration is under `config/` (routes, environment settings), migrations live in `db/migrate`, and schema is tracked in `db/schema.rb`.
- Tests use Minitest in `test/` (unit, controllers, system with Capybara/Selenium); fixtures reside in `test/fixtures`.
- Public assets are in `public/`; user uploads or Active Storage artifacts sit in `storage/` (keep it out of commits).

## Build, Test, and Development Commands
- `bundle install` / `yarn install` once per environment.
- `bin/dev` (Foreman via `Procfile.dev`) runs Rails, esbuild, and Tailwind watchers; defaults to port 9000 unless `PORT` is set.
- `bin/rails server` is a single-process alternative when you do not need JS/CSS watchers.
- `yarn build` bundles JS to `app/assets/builds`; `yarn build:css` builds Tailwind CSS for production.
- `bin/rails test` runs the suite; `bin/rails test:system` executes browser/system specs (ensure Chrome/WebDriver available).

## Coding Style & Naming Conventions
- Ruby: 2-space indent, snake_case for methods/variables, CamelCase for classes/modules; lean on Rails patterns (service objects or helpers in `app/services`/`app/helpers` if added).
- JavaScript: ES modules, Stimulus controllers named `*_controller.js`, prefer descriptive imports and const bindings.
- CSS: Use Tailwind utilities; keep any custom CSS in `application.tailwind.css` with clear comments.
- Linting: `bundle exec rubocop` (Omakase config) for Ruby; keep build output (`app/assets/builds/`) generated, not hand-edited.

## Testing Guidelines
- Place tests alongside feature type (`test/models`, `test/controllers`, `test/system`); name files `*_test.rb` and assertions descriptively.
- For system tests, tag JS-heavy flows and use fixtures/factories to keep setup minimal; clean up created records in teardown if needed.
- Aim for coverage on new controllers/models and any data migrations; prefer exercising service objects through their public API.

## Commit & Pull Request Guidelines
- Commits: imperative present-tense summaries (`Add booking form validation`), group logically, and include schema dumps when migrations change.
- Pull requests: short description of intent, linked issue/task, testing notes (`bin/rails test`, manual steps), and screenshots for UI changes.
- Call out config or migration steps needed after deploy, and avoid committing secrets (`config/credentials.yml.enc` is tracked; keep the key local).

## Security & Configuration Tips
- Manage secrets with Rails credentials (`bin/rails credentials:edit`) or environment variables; never commit `.key` files.
- Before deployment, run `yarn build`, `yarn build:css`, and `bin/rails assets:precompile` in the target environment to ensure asset fingerprints are current.
