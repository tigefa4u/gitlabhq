# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Validate
          class Repository < Chain::Base
            include Chain::Helpers

            def perform!
              unless ref_exists?
                return error('Reference not found')
              end

              unless @command.sha
                return error('Commit not found')
              end

              if @command.ambiguous_ref?
                return error('Ref is ambiguous')
              end
            end

            def break?
              @pipeline.errors.any?
            end

            def ref_exists?
              @command.branch_exists? ||
                @command.tag_exists? ||
                @command.merge_request_ref_exists? ||
                @command.external_merge_request_ref_exists?
            end
          end
        end
      end
    end
  end
end
