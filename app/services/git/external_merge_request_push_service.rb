# frozen_string_literal: true

module Git
  class ExternalMergeRequestPushService < ::BaseService
    def execute
      return unless Gitlab::Git.external_merge_request_ref?(params[:ref])

      ExternalMergeRequestHooksService.new(project, current_user, params).execute

      true
    end
  end
end
