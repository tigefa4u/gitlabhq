# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Limit
          class RateLimit < Chain::Base
            include Gitlab::Utils::StrongMemoize

            RATE_LIMIT_PER_SOURCE = {
              push: 10,
              web: 10,
              merge_request_event: 10
            }.freeze

            def initialize
              super

              limiter = ::Gitlab::ActionRateLimiter.new(action: "pipeline_creation:#{command.source}")
            end

            def perform!
              return unless Feature.enable?(:ci_pipeline_rate_limit, pipeline.project)
              return unless rate_limit_for_source
              return unless throttled?

              if command.save_incompleted
                pipeline.drop!(:rate_limit_exceeded)
              end

              error('Pipeline rate limit exceeded. Please wait a minute and retry again.')
            end

            def break?
              throttled?
            end

            private

            def rate_limit_for_source
              strong_memoize(:rate_limit_for_source) do
                RATE_LIMIT_PER_SOURCE[command.source]
              end
            end

            def throttled?
              strong_memoize(:throttled) do
                limiter.throttled?([pipeline.user], rate_limit_for_source)
              end
            end
          end
        end
      end
    end
  end
end
