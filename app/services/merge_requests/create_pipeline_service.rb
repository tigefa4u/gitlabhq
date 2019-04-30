# frozen_string_literal: true

module MergeRequests
  class CreatePipelineService < MergeRequests::BaseService
    extend ::Gitlab::Utils::Override

    def execute(merge_request)
      create_pipeline_for(merge_request, current_user)
    end

    override :can_create_pipeline_for?
    def can_create_pipeline_for?(merge_request)
      super(merge_request, allow_duplicate: true)
    end
  end
end
