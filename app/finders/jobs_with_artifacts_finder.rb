# frozen_string_literal: true

# TODO: This is only temporary so we can get a review app running
# rubocop:disable CodeReuse/ActiveRecord

class JobsWithArtifactsFinder
  NUMBER_OF_JOBS_PER_PAGE = 30

  def initialize(project:, params:)
    @project = project
    @params = params
  end

  def execute
    jobs = jobs_with_size
    jobs = filter_by_name(jobs)
    jobs = filter_by_deleted_branches(jobs)
    jobs = sorted(jobs)
    jobs = paginated(jobs)
    jobs
  end

  def total_size
    job_ids = @project.builds.select(:id)

    @project.builds.where(id: job_ids).sum(:artifacts_size) +
      @project.job_artifacts.where(job_id: job_ids).sum(:size)
  end

  def sort_key
    @params[:sort].presence || 'created_asc'
  end

  private

  def filter_by_name(jobs)
    return jobs if @params[:search].blank?

    jobs.search(@params[:search])
  end

  def filter_by_deleted_branches(jobs)
    deleted_branches = @params[:'deleted_branches_deleted-branches']

    return jobs if deleted_branches.blank?

    deleted_branches = ActiveModel::Type::Boolean.new.cast(deleted_branches)

    if deleted_branches
      jobs.where.not(ref: @project.repository.ref_names)
    else
      jobs.where(ref: @project.repository.ref_names)
    end
  end

  def sorted(jobs)
    jobs.order_by(sort_key)
  end

  def paginated(jobs)
    jobs.page(@params[:page]).per(NUMBER_OF_JOBS_PER_PAGE).without_count
  end

  def jobs_with_size
    @project.builds.with_sum_artifacts_size
  end
end
