# frozen_string_literal: true

class Projects::WikisController < Projects::ApplicationController
  include HasProjectWiki

  attr_accessor :project_wiki, :sidebar_page, :sidebar_wiki_entries

  def pages
    @nesting = show_children_param
    @show_children = @nesting != 'hidden'
    @wiki_pages = Kaminari.paginate_array(
      @project_wiki.list_pages(sort: params[:sort], direction: params[:direction])
    ).page(params[:page])

    @wiki_entries = case @nesting
                    when 'flat'
                      @wiki_pages
                    else
                      WikiDirectory.group_by_directory(@wiki_pages)
                    end
  end

  def git_access
  end

  private

  # One of ['tree', 'hidden', 'flat']
  def show_children_param
    params.permit(:show_children).fetch(:show_children, params[:sort] == 'created_at' ? 'flat' : 'tree')
  end
end
