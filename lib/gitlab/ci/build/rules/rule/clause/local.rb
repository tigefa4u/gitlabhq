# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Rules::Rule::Clause::Local < Rules::Rule::Clause
        MATCH_LIMIT = 10_000

        def initialize(globs)
          @globs = Array(globs)
        end

        def satisfied_by?(pipeline, seed)
          paths = if top_level_only?
                    pipeline.project.repository.tree(pipeline.sha).blobs.map(&:path)
                  else
                    pipeline.project.repository.ls_files(pipeline.sha)
                  end

          simple, complex = @globs.partition { |glob| simple_glob?(glob) }

          matches = 0
          simple.any? { |glob| paths.bsearch { |path| glob <=> path } } ||
            complex.any? do |glob|
              paths.any? do |path|
                matches += 1
                matches > MATCH_LIMIT || glob_match?(glob, path)
              end
            end
        end

        private

        def glob_match?(glob, path)
          File.fnmatch?(glob, path, File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB)
        end

        def top_level_only?
          @globs.all? { |glob| top_level_glob?(glob) }
        end

        # matches glob patterns that only match files in the top level directory
        def top_level_glob?(glob)
          !glob.include?('/') && !glob.include?('**')
        end

        # matches glob patterns that have no metacharacters for File#fnmatch?
        def simple_glob?(glob)
          !glob.include?('*') && !glob.include?('?') && !glob.include?('[') && !glob.include?('{')
        end
      end
    end
  end
end
