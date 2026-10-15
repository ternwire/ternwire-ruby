require "openssl"

module Ternwire
  module Webhooks
    def self.verify(header, body, secret, tolerance_seconds: 300)
      return false if secret.empty? || !tolerance_seconds.finite? || tolerance_seconds.negative?
      match = /\A\s*t=([1-9][0-9]{0,11})\s*,\s*v1=([a-f0-9]{64})\s*\z/.match(header)
      return false unless match && (Time.now.to_i - match[1].to_i).abs <= tolerance_seconds
      payload = "#{match[1]}.".b + body.b
      expected = OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
      OpenSSL.fixed_length_secure_compare(expected, match[2])
    end
  end
end
