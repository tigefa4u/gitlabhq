# frozen_string_literal: true

require 'spec_helper'

describe Projects::WikiDirectoriesController do
  let(:project) { create(:project, :public, :repository) }
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

  describe 'GET #show_dir' do
    let(:show_dir_params) do
      {
        namespace_id: project.namespace,
        project_id: project,
        id: dir_slug
      }
    end
    subject { get :show_dir, params: show_dir_params }

    context 'the directory does not exist' do
      let(:dir_slug) { 'this-does-not-exist' }

      it { is_expected.to render_template('empty') }
    end

    context 'the directory does exist' do
      let(:wiki_title) { 'some-dir/some-page' }
      let(:dir_slug) { 'some-dir' }
      let(:visit_page) { subject }

      it { is_expected.to render_template('show_dir') }

      it 'sets the wiki_dir attribute' do
        visit_page
        expect(assigns(:wiki_dir)).to eq WikiDirectory.new('some-dir', [project_wiki.find_page(wiki_title)])
      end

      it 'sets show_children to true' do
        visit_page
        expect(assigns(:show_children)).to be true
      end
    end
  end

  private

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
