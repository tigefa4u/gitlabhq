# frozen_string_literal: true

module Serializers
  module SidekiqParams
    class NilClass < Serializers::SidekiqParams::Base
      def serialize
        @value.to_json
      end

      def self.parse(value)
        nil
      end
    end
  end
end
