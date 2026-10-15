require "ternwire"

client = Ternwire::Client.new(
  api_key: ENV.fetch("TERNWIRE_API_KEY"),
  base_url: ENV.fetch("TERNWIRE_API_ORIGIN")
)
accepted = client.submit_email({
  "from" => ENV.fetch("TERNWIRE_FROM"),
  "to" => [ENV.fetch("TERNWIRE_TO")],
  "subject" => "Your receipt",
  "text" => "Thanks for your order."
}, "order-123-receipt")
puts JSON.pretty_generate(accepted)
puts JSON.pretty_generate(client.get_message(accepted.fetch("id")))
