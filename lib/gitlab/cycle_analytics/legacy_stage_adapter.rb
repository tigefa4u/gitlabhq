# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    # Translates Analytics::CycleAnalytics::ProjectStage to mimic the old interface (Gitlab::CycleAnalytics::BaseStage)
    class LegacyStageAdapter < SimpleDelegator
      def initialize(stage, options)
        @stage = ::Analytics::CycleAnalytics::StageDecorator.new(stage)
        @options = options
        super(@stage)
      end

      def project_median
        @project_median ||= Gitlab::Analytics::CycleAnalytics::DataCollector.new(stage: stage, params: options).median.seconds
      end

      def events
        @events ||= data_collector.records_fetcher.serialized_records
      end

      def as_json(serializer: AnalyticsStageSerializer)
        serializer.new.represent(self)
      end

      private

      attr_reader :stage, :options

      def data_collector
        @data_collector ||= Gitlab::Analytics::CycleAnalytics::DataCollector.new(stage: stage, params: options)
      end
    end
  end
end
