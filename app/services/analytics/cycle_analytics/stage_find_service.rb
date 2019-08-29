# frozen_string_literal: true

module Analytics
  module CycleAnalytics
    class StageFindService
      def initialize(parent:, id:)
        @parent = parent
        @id = id
      end

      def execute
        find_in_memory_stage_by_name!
      end

      private

      attr_reader :parent, :id

      def find_in_memory_stage_by_name!
        raw_stage = Gitlab::Analytics::CycleAnalytics::DefaultStages.all.find do |hash|
          hash[:name].eql?(id.to_s)
        end || raise(ActiveRecord::RecordNotFound)

        parent.cycle_analytics_stages.build(raw_stage)
      end
    end
  end
end
