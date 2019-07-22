# frozen_string_literal: true

# Responsible for returning a dashboard containing a specified
# custom metric. Creates panels based on the matching metric
# stored in the database.
#
# Use Gitlab::Metrics::Dashboard::Finder to retrive dashboards.
module Metrics
  module Dashboard
    class CustomMetricEmbedService < ::Metrics::Dashboard::BaseEmbedService
      include Gitlab::Metrics::Dashboard::Defaults

      # Returns a new dashboard with only the matching
      # metrics from the system dashboard, stripped of
      # group info.
      #
      # Note: This overrides the method #raw_dashboard,
      # which means the result will not be cached. This
      # is because we are inserting DB info into the
      # dashboard before post-processing. This ensures
      # we aren't acting on deleted or out-of-date metrics.
      #
      # @return [Hash]
      def raw_dashboard
        panels_not_found!(identifiers) if panels.empty?

        { 'panel_groups' => [{ 'panels' => panels }] }
      end

      private

      # Generated dashboard panels for each metric which
      # matches the provided input.
      # @return [Array<Hash>]
      def panels
        @panels ||= metrics.map { |metric| panel_for_metric(metric) }
      end

      # Metrics which match the provided inputs.
      # @return [ActiveRecordRelation<PromtheusMetric>]
      def metrics
        project.prometheus_metrics.select do |metric|
          metric.group == group_key &&
          metric.title == title &&
          metric.y_label == y_label
        end
      end

      # Returns a symbol representing the group that
      # the dashboard's group title belongs to.
      # It will be one of the keys found under
      # PrometheusMetricEnums.custom_groups.
      #
      # @return [String]
      def group_key
        PrometheusMetricEnums
          .group_details
          .find { |_, details| details[:group_title] == group }
          &.first
          &.to_s
      end

      # Returns a representation of a PromtheusMetric
      # as a dashboard panel. As the panel is generated
      # on the fly, we're using the default values for
      # info we can't get from the DB.
      #
      # @return [Hash]
      def panel_for_metric(metric)
        {
          type: DEFAULT_PANEL_TYPE,
          weight: DEFAULT_PANEL_WEIGHT,
          title: metric.title,
          y_label: metric.y_label,
          metrics: [metric.queries.first.merge(metric_id: metric.id)]
        }
      end
    end
  end
end
