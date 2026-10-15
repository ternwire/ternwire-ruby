# Ternwire Ruby SDK

Ruby client for the Ternwire transactional email API, for Ruby 3.1+. Uses Net::HTTP,
JSON, and OpenSSL from the Ruby distribution, with no other dependencies.

Add `gem "ternwire"` to your Gemfile, or run `gem install ternwire`.

```ruby
require "ternwire"

client = Ternwire::Client.new(api_key: ENV.fetch("TERNWIRE_API_KEY"))
message = client.submit_email({
  "from" => "notifications@your-verified-domain.com",
  "to" => ["recipient@example.com"],
  "subject" => "Your receipt",
  "text" => "Thanks for your order."
}, "order-123-receipt")
puts client.get_message(message.fetch("id"))
```

The client sends requests to `Ternwire::DEFAULT_BASE_URL`, `https://ternwire.com`.
Pass `base_url:` only to reach another origin, such as a local or staging server, as
in `Ternwire::Client.new(api_key: key, base_url: "http://localhost:3001")`. Plain HTTP
is accepted only for localhost and loopback addresses. The optional `timeout:`
keyword sets the per-request timeout in seconds and defaults to 30.

All 17 operations use snake_case names and accept or return hashes with camelCase
JSON keys. Template deletion returns `nil`. The client is synchronous.
`list_email_templates(cursor: nil, limit: nil)` returns one page of summaries;
pass the previous `page.nextCursor` as `cursor` to fetch the next page.

Rescue `Ternwire::APIError` to inspect `status`, `body`, `raw_body`, and `headers`.
Response headers are lowercase and map to arrays of values. Native network and
timeout exceptions propagate separately.

Use `Ternwire::Webhooks.verify(signature_header, raw_body, signing_secret)` before
parsing the request. The optional `tolerance_seconds:` keyword defaults to 300.
Use the exact body string without re-encoding or normalizing it.

Set `TERNWIRE_API_KEY`, `TERNWIRE_FROM`, and `TERNWIRE_TO` before deliberately
running `ruby -Ilib examples/send.rb` from this directory. Set `TERNWIRE_API_ORIGIN`
as well only to send to another origin, such as `http://localhost:3001`.

Read the full documentation at [ternwire.com/docs](https://ternwire.com/docs), or
contact support@ternwire.com.
Released under the MIT License.
