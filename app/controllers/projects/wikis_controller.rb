# frozen_string_literal: true

class Projects::WikisController < Projects::ApplicationController
  include HasProjectWiki

  def pages
    @nesting = show_children_param
    @show_children = @nesting != ProjectWiki::NESTING_CLOSED
    @wiki_pages = Kaminari.paginate_array(
      project_wiki.list_pages(**sort_params)
    ).page(params[:page])

    @wiki_entries = case @nesting
                    when ProjectWiki::NESTING_FLAT
                      @wiki_pages
                    else
                      WikiDirectory.group_by_directory(@wiki_pages)
                    end
  end

  def git_access
  end

  private

  def sort_params
    config = project_wiki.sort_params_config
    base_params = params.permit(:sort, :direction)

    ps = base_params
          .with_defaults(config[:defaults])
          .allow(config[:allowed])
          .to_hash
          .transform_keys(&:to_sym)

    raise ActionController::BadRequest, "illegal sort parameters: #{base_params}" unless ps.size == 2

    ps
  end

  # One of ProjectWiki::NESTINGS
  def show_children_param
    default_val = case params[:sort]
                  when ProjectWiki::CREATED_AT_ORDER
                    ProjectWiki::NESTING_FLAT
                  else
                    ProjectWiki::NESTING_CLOSED
                  end

    params
      .with_defaults(show_children: default_val)
      .permit(:show_children)
      .allow(show_children: ProjectWiki::NESTINGS)
      .fetch(:show_children) { raise ActionController::BadRequest, 'illegal value for show_children' }
  end
end
