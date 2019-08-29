# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UpdateFingerprintsOnNonDefaultBranchFeedback < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    Feedback.where_might_need_update.each do |feedback|
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

  class Occurrence < ActiveRecord::Base
    self.table_name = 'vulnerability_occurrences'
  end
  private_constant :Occurrence

  class OccurrencePipeline < ActiveRecord::Base
    self.table_name = 'vulnerability_occurrence_pipelines'

    belongs_to :occurrence
  end
  private_constant :OccurrencePipeline

  class Pipeline < ActiveRecord::Base
    self.table_name = 'ci_pipelines'

    has_many :builds, foreign_key: :commit_id
    has_many :artifacts, through: :builds
    has_many :occurrence_pipelines
    has_many :occurrences, through: :occurrence_pipelines

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
    has_many :occurrences, through: :pipeline

    enum category: { dependency_scanning: 1, container_scanning: 2 }

    # Feedback that might need update are feedback on vulnerabilities reported
    # by container scanning or dependency scanning jobs run on any branch except
    # the default branch
    def self.where_might_need_update
      left_outer_joins(:occurrences).where('vulnerability_occurrences IS NULL')
    end
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
