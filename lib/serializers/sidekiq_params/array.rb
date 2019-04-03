# frozen_string_literal: true

module Serializers
  module SidekiqParams
    class Array < Serializers::SidekiqParams::Base
      def serialize
        @value.map { |element| Serializers::Sidekiq.serialize(element).first }
      end

      def self.parse(value)
        value.map { |element| Serializers::Sidekiq.parse(element).first }
      end
    end
  end
end
