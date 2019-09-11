# frozen_string_literal: true

module Groups::GroupMembersHelper
  def group_member_select_options
    { multiple: true, class: 'input-clamp qa-member-select-field ', scope: :all, email_user: true }
  end
end
