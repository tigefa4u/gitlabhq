# frozen_string_literal: true

module Gitlab
  module Analytics
    module CycleAnalytics
      class RecordsFetcher
        include Gitlab::Utils::StrongMemoize
        include StageQueryHelpers
        include Gitlab::CycleAnalytics::MetricsTables

        MAX_RECORDS = 20

        MAPPINGS = {
          Issue => {
            finder_class: IssuesFinder,
            serializer_class: AnalyticsIssueSerializer,
            includes_for_query: { project: [:namespace] },
            columns_for_select: %I[title iid id created_at author_id project_id]
          },
          MergeRequest => {
            finder_class: MergeRequestsFinder,
            serializer_class: AnalyticsMergeRequestSerializer,
            includes_for_query: { target_project: [:namespace] },
            columns_for_select: %I[title iid id created_at author_id state target_project_id]
          }
        }.freeze

        delegate :subject_model, to: :stage

        def initialize(stage:, query:, params: {})
          @stage = stage
          @query = query
          @params = params
        end

        def serialized_records
          strong_memoize(:serialized_records) do
            # special case (legacy): 'Test' and 'Staging' stages should show Ci::Build records
            if default_test_stage? || default_staging_stage?
              AnalyticsBuildSerializer.new.represent(ci_build_records.map { |e| e['build'] })
            else
              records.map do |record|
                attributes = record.attributes.merge({
                  project_path: record.project.path,
                  namespace_path: record.project.namespace.path
                })
                serializer.represent(attributes)
              end
            end
          end
        end

        private

        attr_reader :stage, :query, :params

        def finder_query
          MAPPINGS
            .fetch(subject_model)
            .fetch(:finder_class)
            .new(params.fetch(:current_user), finder_params.fetch(stage.parent.class))
            .execute
        end

        def columns
          MAPPINGS.fetch(subject_model).fetch(:columns_for_select).map do |column_name|
            subject_model.arel_table[column_name]
          end
        end

        # EE will override this to include Group rules
        def finder_params
          {
            Project => { project_id: stage.parent.id }
          }
        end

        def default_test_stage?
          stage.matches_with_stage_params?(Gitlab::Analytics::CycleAnalytics::DefaultStages.params_for_test_stage)
        end

        def default_staging_stage?
          stage.matches_with_stage_params?(Gitlab::Analytics::CycleAnalytics::DefaultStages.params_for_staging_stage)
        end

        def serializer
          MAPPINGS.fetch(subject_model).fetch(:serializer_class).new
        end

        # Loading Ci::Build records instead of MergeRequest records
        # rubocop: disable CodeReuse/ActiveRecord
        def ci_build_records
          ci_build_join = mr_metrics_table
            .join(build_table)
            .on(mr_metrics_table[:pipeline_id].eq(build_table[:commit_id]))
            .join_sources

          q = ordered_and_limited_query
            .joins(ci_build_join)
            .select(build_table[:id], round_duration_to_seconds.as('total_time'))

          result = execute_query(q).to_a

          Gitlab::CycleAnalytics::Updater.update!(result, from: 'id', to: 'build', klass: ::Ci::Build)
        end

        def ordered_and_limited_query
          query
            .reorder(stage.end_event.timestamp_projection.desc)
            .limit(MAX_RECORDS)
        end

        def records
          results = finder_query
            .merge(ordered_and_limited_query)
            .select(*columns, round_duration_to_seconds.as('total_time'))

          # using preloader instead of includes to avoid AR generating a large column list
          ActiveRecord::Associations::Preloader.new.preload(results, MAPPINGS.fetch(subject_model).fetch(:includes_for_query))

          results
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
