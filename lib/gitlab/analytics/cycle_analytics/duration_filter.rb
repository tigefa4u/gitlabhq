# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      # This class ensures that negative durations won't be returned by the query. Sometimes checking for negative duration is unnecessary, in that case the duration check won't be executed.
      #
      # Example: issues.closed_at - issues.created_at
      # Check is not needed because issues.created_at will be always earlier than closed_at.
      class DurationFilter
        include StageQueryHelpers

        def initialize(stage:)
          @stage = stage
        end

        # rubocop: disable CodeReuse/ActiveRecord
        def apply(query)
          skip_duration_check? ? query : query.where(stage.end_event.timestamp_projection.gteq(stage.start_event.timestamp_projection))
        end
        # rubocop: enable CodeReuse/ActiveRecord

        private

        attr_reader :stage

        def skip_duration_check?
          starts_with_issue_creation? ||
            starts_with_mr_creation? ||
            mr_merged_at_with_deployment? ||
            mr_build_started_and_finished?
        end

        def starts_with_issue_creation?
          stage.start_event.is_a?(StageEvents::IssueCreated)
        end

        def starts_with_mr_creation?
          stage.start_event.is_a?(StageEvents::MergeRequestCreated)
        end

        def mr_merged_at_with_deployment?
          stage.start_event.is_a?(StageEvents::MergeRequestMerged) &&
            stage.end_event.is_a?(StageEvents::MergeRequestFirstDeployedToProduction)
        end

        def mr_build_started_and_finished?
          stage.start_event.is_a?(StageEvents::MergeRequestLastBuildStarted) &&
            stage.end_event.is_a?(StageEvents::MergeRequestLastBuildFinished)
        end
      end
    end
  end
end
