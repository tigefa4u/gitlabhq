# frozen_string_literal: true

module Gitlab
  module Git
    module RuggedImpl
      module UseRugged
        def use_rugged?(storage_name, feature_key)
          feature = Feature.get(feature_key)
          return feature.enabled? if Feature.persisted?(feature)

          Gitlab.config.repositories.storages[storage_name].can_use_disk?
        end
      end
    end
  end
end
