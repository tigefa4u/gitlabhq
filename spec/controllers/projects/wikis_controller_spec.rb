# frozen_string_literal: true

require 'spec_helper'

describe Projects::WikisController do
  set(:project) { create(:project, :public, :repository) }
  set(:user) { project.owner }
  let(:project_wiki) { ProjectWiki.new(project, user) }
  let(:wiki) { project_wiki.wiki }
  let(:wiki_title) { 'page title test' }

  before do
    create_page(wiki_title, 'hello world')

    sign_in(user)
  end

  after do
    destroy_page(wiki_title)
  end

  describe 'GET #pages' do
    subject do
      get :pages, params: { namespace_id: project.namespace, project_id: project, id: wiki_title }.merge(extra_params)
    end
    let(:extra_params) { {} }

    it 'does not load the pages content' do
      expect(controller).to receive(:load_wiki).and_return(project_wiki)

      expect(project_wiki).to receive(:list_pages).twice.and_call_original

      subject
    end

    shared_examples 'sorting-and-nesting' do |sort_key, default_nesting|
      context "the user is sorting by #{sort_key}" do
        let(:extra_params) { sort_params.merge(nesting_params) }
        let(:sort_params) { { sort: sort_key } }
        let(:nesting_params) { {} }
        before do
          subject
        end

        it "sets nesting to #{default_nesting} by default" do
          expect(assigns :nesting).to eq default_nesting
        end

        it 'shows children by default' do
          expect(assigns :show_children).to be true
        end

        %w[hidden tree flat].each do |nesting|
          context "the user explicitly passes show_children = #{nesting}" do
            let(:nesting_params) { { show_children: nesting } }

            it 'sets nesting to the provided value' do
              expect(assigns :nesting).to eq nesting
            end
          end
        end

        context 'the user wants children hidden' do
          let(:nesting_params) { { show_children: 'hidden' } }

          it 'hides children' do
            expect(assigns :show_children).to be false
          end
        end
      end
    end

    include_examples 'sorting-and-nesting', 'created_at', 'flat'
    include_examples 'sorting-and-nesting', 'title', 'tree'
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
