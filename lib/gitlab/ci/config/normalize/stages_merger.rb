# frozen_string_literal: true

module Gitlab
  module Ci
    class Config
      module Normalize
        class StagesMerger
          def initialize(base_config, additional_config)
            @base_config = base_config
            @additional_config = additional_config
          end

          def normalize_stages
            @base_config.deep_merge(@additional_config)
          end
        end
      end
    end
  end
end
