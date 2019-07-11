module Gitlab
  module Metrics
    class WebMetricsExporter < MetricsExporter
      LOG_FILENAME = File.join(Rails.root, 'log', 'web_exporter.log')

      def settings
        Settings.monitoring.web_exporter
      end

      def log_filename
        LOG_FILENAME
      end
    end
  end
end
