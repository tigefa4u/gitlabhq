# frozen_string_literal: true

module Banzai
  module Filter
    # HTML filter that inserts a placeholder element for each
    # reference to a metrics dashboard.
    class InlineMetricsFilter < Banzai::Filter::InlineEmbedsFilter
      # Placeholder element for the frontend to use as an
      # injection point for charts.
      def create_element(params)
        doc.document.create_element(
          'div',
          class: 'js-render-metrics',
          'data-dashboard-url': metrics_dashboard_url(params)
        )
      end

      # Endpoint FE should hit to collect the appropriate
      # chart information
      def metrics_dashboard_url(params)
        Gitlab::Metrics::Dashboard::Url.build_dashboard_url(
          params['namespace'],
          params['project'],
          params['environment'],
          embedded: true,
          **query_params(params)
        )
      end

      # Parses query params out from full string into hash.
      # If multiple values are given for a parameter, they
      # will be captured in an array.
      # Ex) '?title=Title&group=Group' --> { title: 'Title', group: Group }
      def query_params(params)
        return {} unless params['query']

        Gitlab::Metrics::Dashboard::Url.parse_query(params['query'][1..-1])
      end

      # Search params for selecting metrics links. A few
      # simple checks is enough to boost performance without
      # the cost of doing a full regex match.
      def xpath_search
        "descendant-or-self::a[contains(@href,'metrics') and \
          starts-with(@href, '#{Gitlab.config.gitlab.url}')]"
      end

      # Regular expression matching metrics urls
      def link_pattern
        Gitlab::Metrics::Dashboard::Url.regex
      end
    end
  end
end
