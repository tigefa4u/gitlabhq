# frozen_string_literal: true

require 'jwt'

module Zoom
  class Client
    Error = Class.new(StandardError)

    def initialize(api_url: 'https://api.zoom.us/v2', api_key:, api_secret:,
                   token_expires_in: 90, debug_output: nil)
      @api_url = api_url
      @api_key = api_key
      @api_secret = api_secret
      @token_expire = token_expire
      @debug_output = debug_output
    end

    private

    def request(method, path, **params)
      url = @api_url + path

      # TODO separate methods?
      Gitlab::HTTP.public_send(method, url, **request_params(**params))
    rescue => e
      # TODO log? + sentry
      raise Error, e.message
    end

    def request_params(json: nil, query: nil)
      {
        headers: {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{access_token}"
        },
        follow_redirects: false
      }.tap do |hash|
        hash[:query] = query if query
        hash[:body] = json.to_json if json
        hash[:debug_output] = debug_output if debug_output
      end
    end

    def access_token
      payload = { iss: @api_key, exp: Time.now.to_i + @token_expires_in }

      JWT.encode(payload, @api_secret, 'HS256', { typ: 'JWT' })
    end
  end
end
