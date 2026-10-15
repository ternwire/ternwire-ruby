require "minitest/autorun"
require "socket"
require_relative "../lib/ternwire"

class BaseUrlTransportTest < Minitest::Test
  API_KEY = "em_test_origincheck".freeze

  def test_rejects_cleartext_non_loopback_origins
    ["http://api.example.com", "http://10.0.0.5:3001", "http://api:3001",
     "http://localhost.example.com", "http://127.0.0.1.nip.io", "http://[::2]"].each do |base_url|
      error = assert_raises(ArgumentError, base_url) { Ternwire::Client.new(api_key: API_KEY, base_url: base_url) }
      assert_match(/must use https/, error.message)
    end
  end

  def test_accepts_https_and_loopback_origins
    ["https://api.example.com", "http://localhost:3001", "http://LOCALHOST:3001",
     "http://api.localhost:3001", "http://127.10.20.30", "http://[::1]:3001"].each do |base_url|
      Ternwire::Client.new(api_key: API_KEY, base_url: base_url)
    end
  end

  def test_loopback_client_sends_the_key
    server = TCPServer.new("127.0.0.1", 0)
    authorization = nil
    thread = Thread.new do
      socket = server.accept
      while (line = socket.gets) && line != "\r\n"
        authorization = line.split(": ", 2).last.strip if line.downcase.start_with?("authorization:")
      end
      socket.write("HTTP/1.1 204 No Content\r\nConnection: close\r\n\r\n")
      socket.close
    end
    client = Ternwire::Client.new(api_key: API_KEY, base_url: "http://127.0.0.1:#{server.addr[1]}")
    assert_nil client.delete_email_template("tpl_00000001")
    thread.join
    assert_equal "Bearer #{API_KEY}", authorization
  ensure
    server&.close
  end

  def test_list_email_templates_sends_cursor_and_limit
    server = TCPServer.new("127.0.0.1", 0)
    targets = []
    page = '{"data":[],"page":{"nextCursor":null,"hasMore":false}}'
    thread = Thread.new do
      2.times do
        socket = server.accept
        targets << socket.gets.split(" ")[1]
        while (line = socket.gets) && line != "\r\n"; end
        socket.write("HTTP/1.1 200 OK\r\nContent-Length: #{page.bytesize}\r\nConnection: close\r\n\r\n#{page}")
        socket.close
      end
    end
    client = Ternwire::Client.new(api_key: API_KEY, base_url: "http://127.0.0.1:#{server.addr[1]}")
    result = client.list_email_templates(cursor: "c+/= x", limit: 10)
    client.list_email_templates
    thread.join
    assert_equal({ "data" => [], "page" => { "nextCursor" => nil, "hasMore" => false } }, result)
    assert_equal ["/v1/templates?cursor=c%2B%2F%3D+x&limit=10", "/v1/templates"], targets
  ensure
    server&.close
  end
end
