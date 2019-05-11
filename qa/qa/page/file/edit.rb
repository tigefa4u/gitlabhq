module QA
  module Page
    module File
      class Edit < Page::Base
        include Shared::CommitMessage
        include Shared::CommitButton
        include Shared::Editor
        # view 'app/views/projects/blob/_editor.html.haml'
      end
    end
  end
end
