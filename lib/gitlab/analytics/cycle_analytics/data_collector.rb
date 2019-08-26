# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      # Arguments:
      #   stage - an instance of CycleAnalytics::ProjectStage or CycleAnalytics::GroupStage
      #   params:
      #     current_user: an instance of User
      #     from: DateTime
      #     to: DateTime
      class DataCollector
        def initialize(stage, params = {})
          @stage = stage
          @params = params
        end

        def records_fetcher
          RecordsFetcher.new(stage: stage, query: query, params: params)
        end

        def median
          Median.new(stage: stage, query: query)
        end

        private

        attr_reader :stage, :params

        def query
          BaseQueryBuilder.new(stage: stage, params: params).run
        end
      end
    end
  end
end
