# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      class BaseQueryBuilder
        include Gitlab::CycleAnalytics::MetricsTables
        include StageQueryHelpers

        delegate :subject_model, to: :stage

        # rubocop: disable CodeReuse/ActiveRecord
        PROJECT_QUERY_RULES = {
          Project => {
            Issue => ->(query) { query.where(project_id: stage.parent.id) },
            MergeRequest => ->(query) { query.where(target_project_id: stage.parent.id) }
          }
        }.freeze

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
          instance_exec(query, &query_rules.fetch(stage.parent.class).fetch(subject_model))
        end

        def filter_by_time_range(query)
          from = params[:from] || 30.days.ago
          to = params[:to] || nil

          query = query.where(subject_table[:created_at].gteq(from))
          query = query.where(subject_table[:created_at].lteq(to)) if to
          query
        end

        def subject_table
          subject_model.arel_table
        end

        # EE will override this to include Group rules
        def query_rules
          PROJECT_QUERY_RULES
        end
      end
    end
  end
end
