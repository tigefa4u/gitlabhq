# frozen_string_literal: true

class Projects::WikiDirectoriesController < Projects::ApplicationController
  include HasProjectWiki
  include Gitlab::Utils::StrongMemoize

  before_action :load_dir, only: [:show]

  def self.local_prefixes
    [controller_path, 'shared/wiki']
  end

  def show
    return render('empty') if @wiki_dir.empty?

    @wiki_entries = @wiki_pages = Kaminari
      .paginate_array(@wiki_dir.pages)
      .page(params[:page])

    render 'show'
  end

  private

  def load_dir
    strong_memoize(:wiki_dir) do
      project_wiki.find_dir(*dir_params) || WikiDirectory.new(params[:id])
    end
  end

  def dir_params
    keys = [:id, :sort, :direction]

    params.values_at(*keys)
  end
end
