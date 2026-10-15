# Releasing

1. Bump the version in `lib/ternwire/version.rb` and merge it to `main`.
2. Tag that commit and push the tag:

   ```sh
   git tag v0.1.1 && git push origin v0.1.1
   ```

3. The Publish workflow checks that the tag matches the version, runs the checks, and
   waits for a maintainer to approve the `release` environment. Approve it in the
   workflow run.

Published versions are immutable, and the repository blocks moving or deleting `v*`
tags. To fix a bad release, publish a new version.

## One-time setup

Publishing uses RubyGems trusted publishing, so no token is stored. On rubygems.org,
add a GitHub trusted publisher to the `ternwire` gem with owner `ternwire`, repository
`ternwire-ruby`, workflow `publish.yml`, and environment `release`. Before the first
release, add it as a pending trusted publisher under your profile instead.
