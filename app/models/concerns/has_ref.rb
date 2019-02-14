# frozen_string_literal: true

module HasRef
  extend ActiveSupport::Concern

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

  def refspecs
    spec = []

    if git_depth > 0
      if branch? || merge_request?
        spec << "+#{git_branch_ref}:refs/remotes/origin/#{ref}"
      elsif tag?
        spec << "+#{git_tag_ref}:#{git_tag_ref}"
      end
    else
      if branch? || merge_request? || tag?
        spec << '+refs/heads/*:refs/remotes/origin/*'
        spec << '+refs/tags/*:refs/tags/*'
      end
    end

    spec
  end

  private

  def git_branch_ref
    Gitlab::Git::BRANCH_REF_PREFIX + ref.to_s
  end

  def git_tag_ref
    Gitlab::Git::TAG_REF_PREFIX + ref.to_s
  end
end
