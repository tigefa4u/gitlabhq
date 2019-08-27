# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      class BaseQueryBuilder
        include Gitlab::CycleAnalytics::MetricsTables
        include StageQueryHelpers

        delegate :subject_model, to: :stage

        # rubocop: disable CodeReuse/ActiveRecord

        def initialize(stage:, params: {})
          @stage = stage
          @params = params
        end

        def run
          query = subject_model
          query = filter_by_parent_model(query)
          query = filter_by_time_range(query)
          query = stage.start_event.apply_query_customization(query)
          query = stage.end_event.apply_query_customization(query)
          exclude_negative_durations(query)
        end

        private

        attr_reader :stage, :params

        def exclude_negative_durations(query)
          query.where(duration.gt(zero_interval))
        end

        def filter_by_parent_model(query)
          parent_class = stage.parent.class

          if parent_class.eql?(Project)
            if subject_model.eql?(Issue)
              query.where(project_id: stage.parent_id)
            elsif subject_model.eql?(MergeRequest)
              query.where(target_project_id: stage.parent_id)
            else
              raise ArgumentError, "unknown subject_model: #{subject_model}"
            end
          else
            raise ArgumentError, "unknown parent_class: #{parent_class}"
          end
        end

        def filter_by_time_range(query)
          from = params.fetch(:from, 30.days.ago)
          to = params[:to]

          query = query.where(subject_table[:created_at].gteq(from))
          query = query.where(subject_table[:created_at].lteq(to)) if to
          query
        end

        def subject_table
          subject_model.arel_table
        end
      end
    end
  end
end
