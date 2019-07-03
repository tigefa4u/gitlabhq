# frozen_string_literal: true

require 'spec_helper'

# We build URIs to wiki pages manually in various places (most notably
# in markdown generation). To ensure these do not get out of sync, these
# tests verify that our path generation assumptions are sound.
describe 'Wiki path generation assumptions', 'routing' do
  let(:project) { create(:project, :public, :repository) }
  let(:project_wiki) { ProjectWiki.new(project, project.owner) }

  describe 'WikiProject#wiki_page_path' do
    it 'is consistent with routing to wiki#show' do
      uri = URI.parse(project_wiki.wiki_page_path)
      some_page_name = 'some-wiki-page'
      path = ::File.join(uri.path, some_page_name)

      expect(get('/' + path)).to route_to('projects/wiki_pages#show',
                                          id: some_page_name,
                                          namespace_id: project.namespace.to_param,
                                          project_id: project.to_param)
    end
  end
end
