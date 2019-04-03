# frozen_string_literal: true

module Serializers
  module SidekiqParams
    class Float < Serializers::SidekiqParams::Base
      def serialize
        @value.to_s
      end

      def self.parse(value)
        value.to_f
      end
    end
  end
end
