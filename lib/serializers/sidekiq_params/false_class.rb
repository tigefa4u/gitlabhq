# frozen_string_literal: true

module Serializers
  module SidekiqParams
    class FalseClass < Serializers::SidekiqParams::Base
      def serialize
        @value.to_s
      end

      def self.parse(value)
        false
      end
    end
  end
end
