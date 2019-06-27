# frozen_string_literal: true

module QA
  module Resource
    ##
    # Ensure we're in our sandbox namespace, either by navigating to it or by
    # creating it if it doesn't yet exist.
    #
    class Sandbox < Base
      attr_reader :path

      attribute :id

      def initialize
        @path = Runtime::Namespace.sandbox_name
      end

      def fabricate!
        Page::Main::Menu.perform(&:go_to_groups)

        Page::Dashboard::Groups.perform do |page|
          if page.has_group?(path)
            page.click_group(path)
          else
            page.click_new_group

            Page::Group::New.perform do |group|
              group.set_path(path)
              group.set_description('GitLab QA Sandbox Group')
              group.set_visibility('Public')
              group.create
            end
          end
        end
      end

      def fabricate_via_api!
        # When the tests are run in parallel 2 might try to create the same
        # sandbox group at once. One will succeed and the other will raise an
        # exception because the group already exists. This will allow the failed
        # test to retry and GET the group that now exists.
        QA::Support::Retrier.retry_on_exception do
          resource_web_url(api_get)
        rescue ResourceNotFoundError
          super
        end
      end

      def api_get_path
        "/groups/#{path}"
      end

      def api_members_path
        "#{api_get_path}/members"
      end

      def api_post_path
        '/groups'
      end

      def api_post_body
        {
          path: path,
          name: path,
          visibility: 'public'
        }
      end
    end
  end
end
