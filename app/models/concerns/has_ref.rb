# frozen_string_literal: true

module HasRef
  extend ActiveSupport::Concern

  REFSPEC_DELIMITER = ' '.freeze

  def branch?
    !tag? && !merge_request?
  end

  def git_ref
    if merge_request?
      ##
      # In the future, we're going to change this ref to
      # merge request's merged reference, such as "refs/merge-requests/:iid/merge".
      # In order to do that, we have to update GitLab-Runner's source pulling
      # logic.
      # See https://gitlab.com/gitlab-org/gitlab-runner/merge_requests/1092
      git_branch_ref
    elsif branch?
      git_branch_ref
    elsif tag?
      git_tag_ref
    end
  end

  def ref_type
    if merge_request?
      'branch'
    elsif branch?
      'branch'
    elsif tag?
      'tag'
    end
  end

  private

  def git_branch_ref
    Gitlab::Git::BRANCH_REF_PREFIX + ref.to_s
  end

  def git_tag_ref
    Gitlab::Git::TAG_REF_PREFIX + ref.to_s
  end
end
