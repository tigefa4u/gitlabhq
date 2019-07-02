# frozen_string_literal: true

module HasProjectWiki
  extend ActiveSupport::Concern

  included do
    before_action :authorize_read_wiki!
    before_action :load_project_wiki
  end

  def load_project_wiki
    self.project_wiki = load_wiki

    # Call #wiki to make sure the Wiki Repo is initialized
    self.project_wiki.wiki

    self.sidebar_page = project_wiki.find_sidebar(params[:version_id])

    unless sidebar_page # Fallback to default sidebar
      self.sidebar_wiki_entries = WikiDirectory.group_by_directory(project_wiki.list_pages(limit: 15))
    end
  rescue ProjectWiki::CouldNotCreateWikiError
    flash[:notice] = _("Could not create Wiki Repository at this time. Please try again later.")
    redirect_to project_path(project)
    false
  end

  def load_wiki
    ProjectWiki.new(project, current_user)
  end
end
