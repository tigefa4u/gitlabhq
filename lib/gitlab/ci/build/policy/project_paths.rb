# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Policy
        class ProjectPaths < Policy::Specification
          def initialize(project_paths)
            @patterns = Array(project_paths)
          end

          def satisfied_by?(pipeline, seed = nil)
            return false unless pipeline.project && !pipeline.project.pending_delete?

            @patterns.any? do |pattern|
              matches_pattern?(pattern, pipeline.project_full_path)
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
