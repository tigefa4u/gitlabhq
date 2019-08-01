# frozen_string_literal: true

module Gitlab
  module Middleware
    class CspNonce
      def initialize(app)
        @app = app
      end

      def call(env)
        @env = env
        ::Gitlab::SafeRequestStore[:csp_nonce] = request.content_security_policy_nonce

        @app.call(env)
      end

      def request
        @env['actionpack.request'] ||= ActionDispatch::Request.new(@env)
      end
    end
  end
end
