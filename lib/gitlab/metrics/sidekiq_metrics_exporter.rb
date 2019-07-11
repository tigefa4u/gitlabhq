module Gitlab
  module Metrics
    class SidekiqMetricsExporter < Daemon
      LOG_FILENAME = File.join(Rails.root, 'log', 'sidekiq_exporter.log')

      def settings
        Settings.monitoring.sidekiq_exporter
      end

      def log_filename
        LOG_FILENAME
      end
    end
  end
end
