# frozen_string_literal: true

module Git
  class ExternalMergeRequestPushService < ::BaseService
    def execute
      return unless Gitlab::Git.tag_ref?(params[:ref])

      TagHooksService.new(project, current_user, params).execute

      true
    end
  end
end
