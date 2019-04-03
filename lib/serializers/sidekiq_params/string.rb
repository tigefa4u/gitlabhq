# frozen_string_literal: true

module Serializers
  module SidekiqParams
    class String < Serializers::SidekiqParams::Base
      def serialize
        @value.to_s
      end

      def self.parse(value)
        value
      end
    end
  end
end
