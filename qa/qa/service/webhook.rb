# frozen_string_literal: true

require 'securerandom'

module QA
  module Service
    class Webhook
      include Service::Shellout

      attr_reader :port

      def initialize(name)
        @image = 'sliaquat/calls-counter-api:latest'
        @name = name || "calls-counter-api-#{SecureRandom.hex(4)}"
        @network = Runtime::Scenario.attributes[:network] || 'test'
        @port = 3002
      end

      def network
        shell "docker network inspect #{@network}"
      rescue CommandError
        'bridge'
      else
        @network
      end

      def hostname
        "#{@name}.#{network}"
      end

      def pull
        shell "docker pull #{@image}"
      end

      def run!
        shell <<~CMD.tr("\n", ' ')
          docker run -d --rm
          --network #{network} --name #{@name}
          --hostname #{hostname}
          --publish #{@port}:3000
          #{@image}
        CMD
      end

      def remove!
        shell "docker rm -f #{@name}"
      end
    end
  end
end
