# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Policy
        class Tags < Policy::Specification
          def initialize(patterns)
            @patterns = Array(patterns)
          end

          def satisfied_by?(pipeline, seed = nil)
            return false unless pipeline.tag?

            @patterns.any? do |pattern|
              matches_pattern?(pattern, pipeline.ref)
            end
          end

          private

          def matches_pattern?(pattern, subject)
            if pattern.first == "/" && pattern.last == "/"
              Regexp.new(pattern[1...-1]) =~ subject
            else
              pattern == subject
            end
          end
        end
      end
    end
  end
end
