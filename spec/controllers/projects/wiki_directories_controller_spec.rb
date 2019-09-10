# frozen_string_literal: true

require 'spec_helper'

describe Projects::WikiDirectoriesController do
  set(:project) { create(:project, :public, :repository) }

  let(:user) { project.owner }
  let(:project_wiki) { ProjectWiki.new(project, user) }
  let(:wiki) { project_wiki.wiki }
  let(:wiki_title) { 'page-title-test' }

  before do
    create_page(wiki_title, 'hello world')

    sign_in(user)
  end

  after do
    destroy_page(wiki_title)
  end

  describe 'GET #show' do
    let(:show_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: dir_slug
      }
    end

    before do
      visit_page
    end

    context 'the directory does not exist' do
      let(:dir_slug) { 'this-does-not-exist' }

      it { is_expected.to render_template('empty') }
    end

    context 'the directory does exist' do
      let(:wiki_title) { 'some-dir/some-page' }
      let(:dir_slug) { 'some-dir' }
      let(:the_directory) { WikiDirectory.new('some-dir', [project_wiki.find_page(wiki_title)]) }

      it { is_expected.to render_template('show') }

      it 'sets the wiki_dir attribute' do
        expect(assigns(:wiki_dir)).to eq(the_directory)
      end
    end
  end

  private

  def visit_page
    get :show, params: show_params
  end

  def create_page(name, content)
    wiki.write_page(name, :markdown, content, commit_details(name))
  end

  def commit_details(name)
    Gitlab::Git::Wiki::CommitDetails.new(user.id, user.username, user.name, user.email, "created page #{name}")
  end

  def destroy_page(title, dir = '')
    page = wiki.page(title: title, dir: dir)
    project_wiki.delete_page(page, "test commit")
  end
end
