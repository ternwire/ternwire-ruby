require "ipaddr"
require "json"
require "net/http"
require "uri"

module Ternwire
  class APIError < StandardError
    attr_reader :status, :raw_body, :body, :headers

    def initialize(status, raw_body, headers)
      super("Ternwire API returned HTTP #{status}")
      @status, @raw_body, @headers = status, raw_body, headers
      @body = begin
        JSON.parse(raw_body)
      rescue JSON::ParserError
        nil
      end
    end
  end

  class Client
    def initialize(api_key:, base_url:, timeout: 30)
      unless /\Aem_(live|test)_[A-Za-z0-9_-]+\z/.match?(api_key)
        raise ArgumentError, "Use an em_live_ or em_test_ API key"
      end
      origin = URI.parse(base_url)
      unless %w[http https].include?(origin.scheme) && origin.host && !origin.userinfo &&
          ["", "/"].include?(origin.path) && !origin.query && !origin.fragment
        raise ArgumentError, "base_url must be an HTTP(S) origin without /v1"
      end
      if origin.scheme == "http" && !loopback_host?(origin.hostname)
        raise ArgumentError, "base_url must use https unless it points at localhost or a loopback address"
      end
      unless timeout.is_a?(Numeric) && timeout.finite? && timeout.positive?
        raise ArgumentError, "timeout must be positive and finite"
      end
      @api_key, @base_url, @timeout = api_key, base_url.sub(%r{/+\z}, ""), timeout
    end

    # BEGIN GENERATED OPERATIONS
    def submit_email(input, idempotency_key)
      raise ArgumentError, "input must be a Hash" unless input.is_a?(Hash)
      raise ArgumentError, "idempotency_key is required" unless idempotency_key.is_a?(String)
      request("POST", "/v1/emails", 202, input, idempotency_key)
    end

    def get_message(message_id)
      request("GET", "/v1/emails/" + resource_id(message_id), 200, nil, nil)
    end

    def create_email_template(input)
      raise ArgumentError, "input must be a Hash" unless input.is_a?(Hash)
      request("POST", "/v1/templates", 201, input, nil)
    end

    def list_email_templates(cursor: nil, limit: nil)
      request("GET", "/v1/templates" + query_string(cursor: cursor, limit: limit), 200, nil, nil)
    end

    def get_email_template(template_id)
      request("GET", "/v1/templates/" + resource_id(template_id), 200, nil, nil)
    end

    def replace_email_template(template_id, input)
      raise ArgumentError, "input must be a Hash" unless input.is_a?(Hash)
      request("PUT", "/v1/templates/" + resource_id(template_id), 200, input, nil)
    end

    def delete_email_template(template_id)
      request("DELETE", "/v1/templates/" + resource_id(template_id), 204, nil, nil)
    end

    def create_attachment_upload_slot(input)
      raise ArgumentError, "input must be a Hash" unless input.is_a?(Hash)
      request("POST", "/v1/attachments", 201, input, nil)
    end

    def get_attachment(attachment_id)
      request("GET", "/v1/attachments/" + resource_id(attachment_id), 200, nil, nil)
    end

    def complete_attachment_upload(attachment_id)
      request("POST", "/v1/attachments/" + resource_id(attachment_id) + "/complete", 202, nil, nil)
    end

    def create_sending_domain(input)
      raise ArgumentError, "input must be a Hash" unless input.is_a?(Hash)
      request("POST", "/v1/domains", 201, input, nil)
    end

    def get_sending_domain(domain_id)
      request("GET", "/v1/domains/" + resource_id(domain_id), 200, nil, nil)
    end

    def delete_sending_domain(domain_id)
      request("DELETE", "/v1/domains/" + resource_id(domain_id), 202, nil, nil)
    end

    def create_webhook_endpoint(input)
      raise ArgumentError, "input must be a Hash" unless input.is_a?(Hash)
      request("POST", "/v1/webhook-endpoints", 201, input, nil)
    end

    def rotate_webhook_endpoint_signing_secret(endpoint_id)
      request("POST", "/v1/webhook-endpoints/" + resource_id(endpoint_id) + "/rotate-signing-secret", 200, nil, nil)
    end

    def get_webhook_attempt(attempt_id)
      request("GET", "/v1/webhook-attempts/" + resource_id(attempt_id), 200, nil, nil)
    end

    def replay_webhook_attempt(attempt_id)
      request("POST", "/v1/webhook-attempts/" + resource_id(attempt_id) + "/replay", 202, nil, nil)
    end
    # END GENERATED OPERATIONS

    private

    def resource_id(value)
      raise ArgumentError, "Invalid Ternwire resource ID" unless /\A[a-z0-9][a-z0-9_-]{7,127}\z/.match?(value)
      value
    end

    def query_string(values)
      present = values.compact
      present.empty? ? "" : "?" + URI.encode_www_form(present)
    end

    def loopback_host?(host)
      host = host.downcase
      return true if host == "localhost" || host.end_with?(".localhost")
      IPAddr.new(host).loopback?
    rescue IPAddr::Error
      false
    end

    def request(method, path, expected_status, body = nil, idempotency_key = nil)
      headers = { "Authorization" => "Bearer #{@api_key}", "Accept" => "application/json" }
      if idempotency_key
        unless /\A[\x21-\x7e]{1,128}\z/.match?(idempotency_key)
          raise ArgumentError, "idempotency_key must contain 1-128 visible ASCII characters"
        end
        headers["Idempotency-Key"] = idempotency_key
      end
      uri = URI.parse(@base_url + path)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = @timeout
      http.read_timeout = @timeout
      http.write_timeout = @timeout
      http.max_retries = 0
      request = Net::HTTPGenericRequest.new(method, !body.nil?, true, uri.request_uri, headers)
      unless body.nil?
        raise ArgumentError, "body must be a Hash" unless body.is_a?(Hash)
        request["Content-Type"] = "application/json"
        request.body = JSON.generate(body)
      end
      response = http.request(request)
      raw = response.body || ""
      raise APIError.new(response.code.to_i, raw, response.to_hash) unless response.code.to_i == expected_status
      return nil if expected_status == 204
      result = JSON.parse(raw)
      raise JSON::ParserError, "Ternwire API returned a non-object JSON response" unless result.is_a?(Hash)
      result
    end
  end
end
