# frozen_string_literal: true

module Serializers
  module SidekiqParams
    class Id < Serializers::SidekiqParams::Base
      def serialize
        { id: @value.id, class: @value.class.name }.to_json
      end

      def self.parse(instance_json)
        params = JSON.parse(instance_json, symbolize_names: true)
        klass = params[:class].constantize
        klass.find(params[:id])
      end
    end
  end
end
