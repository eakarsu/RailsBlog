# RailsBlog

RailsBlog is an editorial publishing application with role-based authoring, independent review, immutable revisions, comment moderation, taxonomy, search, RSS, media attachments, and versioned JSON portability.

For local development, set a random `SECRET_KEY_BASE`, run `bundle install`, prepare the database explicitly with `bundle exec rails db:prepare`, and launch with `./start.sh`. Normal development and production startup never migrate or seed automatically. See `RUNBOOK.md` for release, backup, restore, and incident procedures.
