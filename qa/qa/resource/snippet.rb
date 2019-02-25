# frozen_string_literal: true

module QA
  module Resource
    class Snippet < Base
      attr_accessor :title, :description, :content, :visibility

      def initialize
        @title = 'New snippet title'
        @description = 'The snippet description'
        @content = 'The snippet content'
        @visibility = 'Public'
      end

      def fabricate!
        Page::Dashboard::Snippet::New.perform do |page|
          page.fill_title(@title)
          page.fill_description(@description)
          page.add_snippet_content(@content)
          page.set_visibility(@visibility)
          page.create_snippet
        end
      end
    end
  end
end
