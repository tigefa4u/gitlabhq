# frozen_string_literal: true

class ArtifactsFinder
  def initialize(project, params = {})
    @project = project
    @params = params
  end

  def execute
    artifacts = @project.job_artifacts
    artifacts = by_job_name(artifacts)

    sort(artifacts)
  end

  def by_job_name(artifacts)
    return artifacts unless @params[:search].present?

    artifacts.search_by_job_name(@params[:search])
  end

  def total_size
    Ci::JobArtifact.artifacts_size_for(@project)
  end

  private

  def sort_key
    @params[:sort] || 'created_asc'
  end

  def sort(artifacts)
    artifacts.order_by(sort_key)
  end
end
