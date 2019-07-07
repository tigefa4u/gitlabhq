# frozen_string_literal: true

module Gitlab
  module Ci
    module Status
      class Running < Status::Core
        def text
          s_('CiStatus|running')
        end

        def label
          s_('CiStatus|running')
        end

        def icon
          'status_running'
        end

        def favicon
          if subject.respond_to?(:progress)
            progress = subject.progress

            if progress < 25.0
              'favicon_status_running_25'
            elsif progress < 50.0
              'favicon_status_running_50'
            elsif progress < 75.0
              'favicon_status_running_75'
            elsif progress < 100.0
              'favicon_status_running_100'
            end
          else
            'favicon_status_running'
          end
        end
      end
    end
  end
end
