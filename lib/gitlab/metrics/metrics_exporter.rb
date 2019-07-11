# frozen_string_literal: true

require 'webrick'
require 'prometheus/client/rack/exporter'

module Gitlab
  module Metrics
    class MetricsExporter < Daemon
      def enabled?
        ::Gitlab::Metrics.metrics_folder_present? && settings.enabled
      end

      def settings
        throw NotImplementedError
      end

      def log_filename
        throw NotImplementedError
      end

      private

      attr_reader :server

      def start_working
        logger = WEBrick::Log.new(log_filename)
        access_log = [
          [logger, WEBrick::AccessLog::COMBINED_LOG_FORMAT]
        ]

        @server = ::WEBrick::HTTPServer.new(Port: settings.port, BindAddress: settings.address,
                                            Logger: logger, AccessLog: access_log)
        server.mount "/", Rack::Handler::WEBrick, rack_app
        server.start
      end

      def stop_working
        server.shutdown if server
        @server = nil
      end

      def rack_app
        Rack::Builder.app do
          use Rack::Deflater
          use ::Prometheus::Client::Rack::Exporter
          run -> (env) { [404, {}, ['']] }
        end
      end
    end
  end
end
