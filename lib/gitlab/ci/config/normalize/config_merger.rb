# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Normalize
        class ConfigMerger
          StageMergeError = Class.new(StandardError)

          def initialize(base_config, additional_config)
            @base_config = base_config
            @additional_config = additional_config
          end

          def merge
            @base_config.deep_merge(@additional_config).tap do |config|
              config[:stages] = normalize_stages if both_configs_have_stages? && Feature.enabled?(:merge_stages_across_includes)
            end
          end

          private

          def all_stages
            [
              @base_config[:stages],
              @additional_config[:stages]
            ]
          end

          def both_configs_have_stages?
            @base_config[:stages]&.any? && @additional_config[:stages]&.any?
          end

          def graph_stages(stages, graph)
            stages.each_with_index do |stage, index|
              graph[stage] ||= []
              graph[stage] << stages[index - 1] if index > 0
            end
          end

          def normalize_stages
            Gitlab::Utils::TopologicalSort.new.tap do |thash|
              all_stages.each { |stages| graph_stages(stages, thash) }
            end.tsort
          rescue TSort::Cyclic => e
            raise StageMergeError, e.message
          end
        end
      end
    end
  end
end
