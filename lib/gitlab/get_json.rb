# frozen_string_literal: true

require 'json'
require 'faraday'

# Gitlab::GetJSON is a very thin layer over Faraday to `GET` a resource
# at a URL, and decode it into JSON. HTTP errors and JSON decoding errors
# are treated as exceptional states and errors are thrown.
module Gitlab
  module GetJSON
    Error = Class.new(StandardError)
    HTTPError = Class.new(::Gitlab::GetJSON::Error)
    JSONError = Class.new(::Gitlab::GetJSON::Error)

    def http_get_json(url)
      rsp = Faraday.get(url)

      unless rsp.success?
        raise HTTPError, "Failed to read #{url}: #{rsp.status}"
      end

      JSON.parse(rsp.body)
    rescue Faraday::ConnectionFailed
      raise HTTPError, "Could not connect to #{url}"
    rescue JSON::ParserError
      raise JSONError, "Failed to parse JSON response from #{url}"
    end
  end
end
