# frozen_string_literal: true

require 'set'

module Gitlab
  module Metrics
    module Dashboard
      module Stages
        class AvailableMetricsFilter < BaseStage
          include Gitlab::Utils::StrongMemoize

          # Checks common metrics dashboard for metrics
          # which we actively do not expect to be available.
          def transform!
            return unless available_metrics

            missing_panel_groups! unless dashboard[:panel_groups].is_a?(Array)

            dashboard[:panel_groups].delete_if do |panel_group|
              has_unavailable_metrics?(panel_group)
            end
          end

          private

          def has_unavailable_metrics?(panel_group)
            required_metrics = required_metrics_for(panel_group)

            required_metrics&.any? { |metric| metric_unavailable?(metric) }
          end

          def required_metrics_for(panel_group)
            group_name = panel_group[:group]

            required_metrics = required_metrics_by_group[group_name]
          end

          def metric_unavailable?(metric)
            !available_metrics.include?(metric)
          end

          # Returns a mapping of group title to an array of
          # required metrics
          def required_metrics_by_group
            strong_memoize(:required_metrics_by_group) do
              PrometheusMetricEnums.group_details.each_with_object({}) do |(_, details), groups|
                groups[details[:group_title]] = details[:required_metrics]
              end
            end
          end

          # Returns an array of all metrics supported on the
          # prometheus instance
          #
          # NOTE: This circumvents ReactiveCache for the sake
          # of getting a working filter up quickly. We should
          # not have this here long term and should refactor
          # to cache this info and poll the metrics dashboard
          # endpoint or maybe place the whole thing in a job.
          #
          # TODO: INSERT A LINK TO AN ISSUE HERE
          def available_metrics
            strong_memoize(:available_metrics) do
              adapter = environment.prometheus_adapter

              return unless adapter&.can_query?

              adapter
                .prometheus_client_wrapper
                .label_values
            end
          end
        end
      end
    end
  end
end
