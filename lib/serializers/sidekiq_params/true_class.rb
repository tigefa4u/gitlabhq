# frozen_string_literal: true

module Serializers
  module SidekiqParams
    class TrueClass < Serializers::SidekiqParams::Base
      def serialize
        @value.to_s
      end

      def self.parse(value)
        true
      end
    end
  end
end
