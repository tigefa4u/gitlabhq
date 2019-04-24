# frozen_string_literal: true

module HasRef
  extend ActiveSupport::Concern

  def branch?
    !tag? && !merge_request_event?
  end

  def git_ref
    if branch?
      Gitlab::Git::BRANCH_REF_PREFIX + ref.to_s
    elsif tag?
      Gitlab::Git::TAG_REF_PREFIX + ref.to_s
    end
  end

  # A slugified version of the build ref, suitable for inclusion in URLs and
  # domain names. Rules:
  #
  #   * Lowercased
  #   * Anything not matching [a-z0-9-] is replaced with a -
  #   * Maximum length is 63 bytes
  #   * First/Last Character is not a hyphen
  def ref_slug
    Gitlab::Utils.slugify(generic_ref_name.to_s)
  end

  def generic_ref_name
    if merge_request_ref?
      merge_request.source_branch
    else
      ref
    end
  end
end
