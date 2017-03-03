require "open-uri"

module LimeExt
  class API
    def initialize service_url=nil
      u = service_url.nil? ? LimeExt.config.service_url : service_url
      @uri = URI.parse u
    end

    def method_missing name, *args
      s_key = get_session_key
      body = {
        "method" => name,
        "params" => [s_key] + args,
        "id"     => "jsonrpc"
      }.to_json

      pp "performing rc post to #{name} with #{args}, called from #{Kernel.caller.first}"
      r = JSON.parse(perform_post(body))
      raise LimeExt::Errors::JSONRPCError, r["error"] if r["error"]
      raise LimeExt::Errors::InvalidCredentials if r["result"] == {"status"=>"Invalid session key"}
      release_session_key s_key
      r["result"]
    end

    def perform_post body
      http = Net::HTTP.new(@uri.host, @uri.port)
      http.use_ssl = true if @uri.port == 443
      req = Net::HTTP::Post.new(@uri.request_uri)
      req.content_type = "application/json"
      req.body = body
      http.request(req).body
    end

    private

    def get_session_key
      body = {
        "method" => "get_session_key",
        "params" => LimeExt.credentials,
        "id"     => "jsonrpc"
      }.to_json

      JSON.parse(perform_post(body))["result"]
    end

    def release_session_key s_key
      body = {
        "method" => "release_session_key",
        "params" => s_key,
        "id"     => "jsonrpc"
      }.to_json

      resp = JSON.parse(perform_post(body))
    end
  end
end
