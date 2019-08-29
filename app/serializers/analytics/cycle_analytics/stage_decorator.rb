# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class StageDecorator < SimpleDelegator
      DEFAULT_STAGE_ATTRIBUTES = {
        issue: {
          title: -> { s_('CycleAnalyticsStage|Issue') },
          description: -> { _("Time before an issue gets scheduled") }
        },
        plan: {
          title: -> { s_('CycleAnalyticsStage|Plan') },
          description: -> { _("Time before an issue starts implementation") }
        },
        code: {
          title: -> { s_('CycleAnalyticsStage|Code') },
          description: -> { _("Time until first merge request") }
        },
        test: {
          title: -> { s_('CycleAnalyticsStage|Test') },
          description: -> { _("Total test time for all commits/merges") }
        },
        review: {
          title: -> { s_('CycleAnalyticsStage|Review') },
          description: -> { _("Time between merge request creation and merge/close") }
        },
        staging: {
          title: -> { s_('CycleAnalyticsStage|Staging') },
          description: -> { _("From merge request merge until deploy to production") }
        },
        production: {
          title: -> { s_('CycleAnalyticsStage|Production') },
          description: -> { _("From issue creation until deploy to production") }
        }
      }.freeze

      def title
        extract_default_stage_attribute(:title) || name
      end

      def description
        extract_default_stage_attribute(:description) || ''
      end

      def legend
        if matches_with_stage_params?(Gitlab::Analytics::CycleAnalytics::DefaultStages.params_for_test_stage)
          _("Related Jobs")
        elsif matches_with_stage_params?(Gitlab::Analytics::CycleAnalytics::DefaultStages.params_for_staging_stage)
          _("Related Deployed Jobs")
        elsif subject_model.eql?(Issue)
          _("Related Issues")
        elsif subject_model.eql?(MergeRequest)
          _("Related Merged Requests")
        end
      end

      private

      def extract_default_stage_attribute(attribute)
        DEFAULT_STAGE_ATTRIBUTES.dig(name.to_sym, attribute.to_sym)&.call
      end
    end
  end
end
