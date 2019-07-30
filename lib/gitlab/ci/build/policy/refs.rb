# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Policy
        class Refs < Policy::Specification
          def initialize(refs)
            @patterns = Array(refs)
          end

          def satisfied_by?(pipeline, seed = nil)
            @patterns.any? do |pattern|
              pattern, path = pattern.split('@', 2)

              matches_path?(path, pipeline) &&
                matches_pattern?(pattern, pipeline)
            end
          end

          private

          def matches_path?(path, pipeline)
            return true unless path

            pipeline.project_full_path == path
          end

          def matches_pattern?(pattern, pipeline)
            matches_tags_keyword?(pattern, pipeline) ||
              matches_branches_keyword?(pattern, pipeline) ||
              matches_pipeline_source?(pattern, pipeline) ||
              matches_single_ref?(pattern, pipeline) ||
              matches_external_merge_request_source?(pattern, pipeline)
          end

          def matches_tags_keyword?(pattern, pipeline)
            pipeline.tag? && pattern == 'tags'
          end

          def matches_branches_keyword?(pattern, pipeline)
            pipeline.branch? && pattern == 'branches'
          end

          def matches_pipeline_source?(pattern, pipeline)
            sanitized_source_name(pipeline) == pattern ||
              sanitized_source_name(pipeline)&.pluralize == pattern
          end

          def matches_single_ref?(pattern, pipeline)
            # patterns can be matched only when branch or tag is used
            # the pattern matching does not work for merge requests pipelines
            if pipeline.branch? || pipeline.tag?
              if regexp = Gitlab::UntrustedRegexp::RubySyntax.fabricate(pattern, fallback: true)
                regexp.match?(pipeline.ref)
              else
                pattern == pipeline.ref
              end
            end
          end

          # TODO: best would be to support 'only/except: external_merge_requests'
          # but for now we reuse 'merge_requests'
          def matches_external_merge_request_source?(pattern, pipeline)
            sanitized_source_name(pipeline) == 'external_merge_request' &&
              pattern == 'merge_requests'
          end

          def sanitized_source_name(pipeline)
            # TODO Memoizing this doesn't seem to make sense with
            #   pipelines being passed in to #satsified_by? as a param.
            @sanitized_source_name ||= pipeline&.source&.delete_suffix('_event')
          end
        end
      end
    end
  end
end
