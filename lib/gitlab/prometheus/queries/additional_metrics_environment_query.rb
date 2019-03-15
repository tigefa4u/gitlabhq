# frozen_string_literal: true

module Gitlab
  module Prometheus
    module Queries
      class AdditionalMetricsEnvironmentQuery < BaseQuery
        include QueryAdditionalMetrics

        # rubocop: disable CodeReuse/ActiveRecord
        def query(environment_id, timeframe_start = nil, timeframe_end = nil)
          timeframe_start ||= 8.hours.ago.to_f
          timeframe_end ||= Time.now.to_f

          ::Environment.find_by(id: environment_id).try do |environment|
            query_metrics(
              environment.project,
              environment,
              common_query_context(
                environment,
                timeframe_start: timeframe_start.to_f,
                timeframe_end: timeframe_end.to_f
              )
            )
          end
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
