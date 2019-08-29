# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UpdateFingerprintsOnNonDefaultBranchFeedback < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  # When a migration requires downtime you **must** uncomment the following
  # constant and define a short and easy to understand explanation as to why the
  # migration requires downtime.
  # DOWNTIME_REASON = ''

  # When using the methods "add_concurrent_index", "remove_concurrent_index" or
  # "add_column_with_default" you must disable the use of transactions
  # as these methods can not run in an existing transaction.
  # When using "add_concurrent_index" or "remove_concurrent_index" methods make sure
  # that either of them is the _only_ method called in the migration,
  # any other changes should go in a separate migration.
  # This ensures that upon failure _only_ the index creation or removing fails
  # and can be retried or reverted easily.
  #
  # To disable transactions uncomment the following line and remove these
  # comments:
  # disable_ddl_transaction!

  def up
    Feedback.all.each do |feedback|
      artifact = feedback.pipeline.report_for_feedback(feedback)
      report = JSON.parse(artifact.file.read)

      vulnerability = report['vulnerabilities'].find do |vuln|
        old_fingerprint(vuln, feedback) == feedback.project_fingerprint
      end

      if vulnerability.present?
        begin
          feedback.update(project_fingerprint: new_fingerprint(vulnerability, feedback))
        rescue ActiveRecord::RecordNotUnique
          feedback.destroy
        end
      end
    end
  end

  def down
    # We don't want to re-break the fingerprints if a user needs to rollback
    # any number of migrations that include this one.
  end

  class Artifact < ActiveRecord::Base
    self.table_name = 'ci_job_artifacts'

    mount_uploader :file, JobArtifactUploader

    enum file_location: {
      legacy_path: 1,
      hashed_path: 2
    }
  end

  class Build < ActiveRecord::Base
    self.table_name = 'ci_builds'

    has_many :artifacts, foreign_key: :job_id
  end
  private_constant :Build

  class Pipeline < ActiveRecord::Base
    self.table_name = 'ci_pipelines'

    has_many :builds, foreign_key: :commit_id
    has_many :artifacts, through: :builds

    def report_for_feedback(feedback)
      report_type = if feedback.dependency_scanning?
                      7
                    elsif feedback.container_scanning?
                      6
                    end

      artifacts.where('ci_job_artifacts.file_type = ?', report_type).first
    end
  end
  private_constant :Pipeline

  class Feedback < ActiveRecord::Base
    self.table_name = 'vulnerability_feedback'

    belongs_to :pipeline

    enum category: { dependency_scanning: 1, container_scanning: 2 }
  end
  private_constant :Feedback

  private

  def old_fingerprint(vulnerability, feedback)
    if feedback.dependency_scanning?
      Digest::SHA1.hexdigest(vulnerability['message'])
    elsif feedback.container_scanning?
      Digest::SHA1.hexdigest(
        "#{vulnerability['namespace']}:#{vulnerability['vulnerability']}" \
        ":#{vulnerability['featurename']}:#{vulnerability['featureversion']}"
      )
    end
  end

  def new_fingerprint(vulnerability, feedback)
    if feedback.dependency_scanning?
      Digest::SHA1.hexdigest(vulnerability['cve'])
    elsif feedback.container_scanning?
      Digest::SHA1.hexdigest(vulnerability['vulnerability'])
    end
  end
end
