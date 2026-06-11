require "net/http"

module Synchify
  class NetRequest
    OPEN_TIMEOUT = 10
    READ_TIMEOUT = 15

    Result = Struct.new(:code, :body, keyword_init: true) do
      def success?
        code.between?(200, 299)
      end
    end

    def self.post(url, body:, headers: {}, open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT)
      new(url, open_timeout: open_timeout, read_timeout: read_timeout).post(body: body, headers: headers)
    end

    def initialize(url, open_timeout: OPEN_TIMEOUT, read_timeout: READ_TIMEOUT)
      @uri          = URI(url)
      @open_timeout = open_timeout
      @read_timeout = read_timeout
    end

    def post(body:, headers: {})
      response = http.request(build_request(body, headers))
      Result.new(code: response.code.to_i, body: response.body.to_s)
    end

    private

    def http
      Net::HTTP.new(@uri.host, @uri.port).tap do |h|
        h.use_ssl      = @uri.scheme == "https"
        h.open_timeout = @open_timeout
        h.read_timeout = @read_timeout
      end
    end

    def build_request(body, headers)
      Net::HTTP::Post.new(@uri.path).tap do |req|
        req["Content-Type"] = "application/json"
        headers.each { |k, v| req[k] = v }
        req.body = body.is_a?(String) ? body : body.to_json
      end
    end
  end
end
