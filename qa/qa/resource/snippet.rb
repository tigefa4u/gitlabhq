# frozen_string_literal: true

module QA
  module Resource
    class Snippet < Base
      attr_accessor :title, :description, :content, :type

      def initialize
        @title = 'New snippet title'
        @description = 'The snippet description'
        @content = 'The snippet content'
        @type = 'Public'
      end

      def fabricate!
        Page::Dashboard::Snippet::New.perform do |page|
          page.fill_title(@title)
          page.fill_description(@description)
          page.add_snippet_content(@content)
          page.change_snippet_type(@type)
          page.create_snippet
        end
      end
    end
  end
end
