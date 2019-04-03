# frozen_string_literal: true

module Serializers
  module SidekiqParams
    class Hash < Serializers::SidekiqParams::Base
      def serialize
        @value.each_with_object({}) do |(key, value), object|
          object[key] = Serializers::Sidekiq.serialize(value).first
        end
      end

      def self.parse(value)
        value.each_with_object({}) do |(key, value), object|
          object[key] = Serializers::Sidekiq.parse(value).first
        end
      end
    end
  end
end
