# frozen_string_literal: true

module Serializers
  class Sidekiq
    SERIALIZER_OVERRIDES = {
      Time => Serializers::SidekiqParams::DateTime,
      ActiveSupport::TimeWithZone => Serializers::SidekiqParams::DateTime
    }.freeze

    class << self
      def serialize(*args)
        args.map { |arg| serialize_value(arg) }
      end

      def parse(*args)
        args.map { |arg| parse_value(arg) }
      end

      def serialize_value(value)
        serializer = find_serializer(value)

        {
          value: serializer.new(value).serialize,
          serializer: serializer.name
        }.to_json
      end

      def parse_value(value_params_json)
        value_params = ::JSON.parse(value_params_json, symbolize_names: true)
        serializer = value_params[:serializer].constantize
        serializer.parse(value_params[:value])
      end

      def find_serializer(value)
        serializer_override(value) ||
          sidekiq_serialzer(value) ||
          id_serializer(value) ||
          Serializers::SidekiqParams::Base
      end

      def serializer_override(value)
        SERIALIZER_OVERRIDES[value.class]
      end

      def sidekiq_serialzer(value)
        "Serializers::SidekiqParams::#{value.class}".constantize
      rescue NameError
      end

      def id_serializer(value)
        Serializers::SidekiqParams::Id if value.respond_to?(:id)
      end
    end
  end
end
