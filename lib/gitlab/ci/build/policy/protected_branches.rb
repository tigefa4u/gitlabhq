# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Policy
        class ProtectedBranches < Policy::Specification
          def initialize(protected_branches)
            @patterns = Array(protected_branches)
          end

          def satisfied_by?(pipeline, seed = nil)
            return false unless pipeline.protected?

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
