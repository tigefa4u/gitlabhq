# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Policy
        class Events < Policy::Specification
          def initialize(events)
            @events = Array(events)
          end

          def satisfied_by?(pipeline, seed = nil)
            return false unless pipeline.source

            @events.any? do |event|
              matches_event?(event, pipeline.source)
            end
          end

          private

          def matches_event?(event, source)
            event == source || event == source.pluralize
          end
        end
      end
    end
  end
end
