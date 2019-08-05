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
      @token_expires_in = token_expires_in
      @debug_output = debug_output
    end

    def list_users(status: 'active', page: 1, per_page: 30)
      query = {
        status: status,
        page_size: per_page,
        page_number: page
      }

      paginated(page: page, item_key: 'users') do |page|
        request(:get, '/users', query: query.merge(page_number: page))
      end
    end

    def list_meetings(user_id:, per_page: 30, page: 1)
      query = {
        page_size: per_page
      }

      paginated(page: page, item_key: 'meetings') do |page|
        request(:get, "/users/#{user_id}/meetings", query: query.merge(page_number: page))
      end
    end

    def create_meeting(user_id:, topic: nil, agenda: nil, password: nil, enforce_login: false, enforce_login_domains: nil)
       payload = {
        topic: topic,
        agenda: agenda,
        password: password,
        settings: {
          enforce_login: enforce_login,
        }.tap do |hash|
          hash[:enforce_login_domains] = enforce_login_domains if enforce_login_domains
        end
      }

      request(:post, "/users/#{user_id}/meetings", json: payload)
    end

    def delete_meeting(meeting_id:)
      request(:delete, "/meetings/#{meeting_id}")
    end

    private

    def paginated(item_key:, page:)
      Enumerator.new do |y|
        loop do
          response = yield(page)
          response.fetch(item_key).each { |item| y.yield item }

          break if response.fetch('page_number') >= response.fetch('page_count')

          page += 1
        end
      end
    end

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
        hash[:debug_output] = @debug_output if @debug_output
      end
    end

    def access_token
      payload = { iss: @api_key, exp: Time.now.to_i + @token_expires_in }

      JWT.encode(payload, @api_secret, 'HS256', { typ: 'JWT' })
    end
  end
end
