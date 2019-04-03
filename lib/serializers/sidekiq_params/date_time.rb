# frozen_string_literal: true

module Serializers
  module SidekiqParams
    class DateTime < Serializers::SidekiqParams::Base
      def serialize
        @value.to_s
      end

      def self.parse(value)
        ::DateTime.parse(value)
      end
    end
  end
end
