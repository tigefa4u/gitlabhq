# frozen_string_literal: true

module Projects
  module CycleAnalytics
    class EventsController < Projects::ApplicationController
      include CycleAnalyticsParams

      before_action :authorize_read_cycle_analytics!
      before_action :authorize_read_issue!, if: -> { stage.subject_model.eql?(Issue) }
      before_action :authorize_read_merge_request!, if: -> { stage.subject_model.eql?(MergeRequest) }

      def show
        render json: { events: data_collector.records_fetcher.serialized_records }
      end

      private

      def stage
        @stage ||= Analytics::CycleAnalytics::StageFindService.new(parent: project, id: params[:stage_id]).execute
      end

      def data_collector
        @data_collector ||= Gitlab::Analytics::CycleAnalytics::DataCollector.new(
          stage: stage,
          params: options(params)
        )
      end
    end
  end
end
