# frozen_string_literal: true

module Serializers
  module SidekiqParams
    class Base
      def initialize(value)
        @value = value
      end

      def serialize
        @value.to_json
      end

      def self.parse(value)
        JSON.parse(value)
      end
    end
  end
end
