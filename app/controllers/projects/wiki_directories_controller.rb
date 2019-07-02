# frozen_string_literal: true

class Projects::WikiDirectoriesController < Projects::ApplicationController
  include HasProjectWiki

  before_action :load_dir, only: [:show_dir]

  # Share the templates from the wikis controller.
  def self.local_prefixes
    [controller_path, 'projects/wikis']
  end

  attr_accessor :project_wiki, :sidebar_page, :sidebar_wiki_entries

  def show_dir
    @show_children = true # or false, it doesn't matter, since we only support one-level
    if @wiki_dir
      @wiki_pages = Kaminari
        .paginate_array(@wiki_dir.pages)
        .page(params[:page])
      @wiki_entries = @wiki_pages
      render 'show_dir'
    else
      render 'empty'
    end
  end

  private

  def load_dir
    @wiki_dir ||= @project_wiki.find_dir(*dir_params)
  end

  def dir_params
    keys = [:id, :sort, :direction]

    params.values_at(*keys)
  end
end
