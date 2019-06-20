# frozen_string_literal: true

module Gitlab
  module Middleware
    # Middleware to handle a case where ActionDispatch's `Dispatcher` raises a
    # `RoutingError` when it attempts to resolve a route to a controller that
    # only exists in EE.
    #
    # We rescue the error and respond with a 404. This allows CE to include
    # EE-only routes without raising an exception.
    class EeOnlyRoute
      def initialize(app)
        @app = app
      end

      def call(env)
        @app.call(env)
      rescue ActionController::RoutingError => ex
        if ex.cause.is_a?(NameError) && ex.message.end_with?('Controller')
          [404, { "X-Cascade" => "pass" }, []]
        else
          raise
        end
      end
    end
  end
end
