# frozen_string_literal: true

module Gitlab
  module Auth
    class UserAccessDeniedReason
      def initialize(user)
        @user = user
      end

      def rejection_message
        case rejection_type
        when :internal
          _("This action cannot be performed by internal users")
        when :terms_not_accepted
          _("You (%{user_to_reference}) must accept the Terms of Service in order to perform this action. "\
          "Please access GitLab from a web browser to accept these terms.") % { user_to_reference: @user.to_reference }
        else
          _("Your account has been blocked.")
        end
      end

      private

      def rejection_type
        if @user.internal?
          :internal
        elsif @user.required_terms_not_accepted?
          :terms_not_accepted
        else
          :blocked
        end
      end
    end
  end
end
