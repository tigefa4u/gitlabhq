# frozen_string_literal: true

# See http://doc.gitlab.com/ce/development/migration_style_guide.html
# for more information on how to write migrations for GitLab.

class UpdateFingerprintsOnNonDefaultBranchFeedback < ActiveRecord::Migration[5.2]
  include Gitlab::Database::MigrationHelpers

  # Set this constant to true if this migration requires downtime.
  DOWNTIME = false

  disable_ddl_transaction!

  def up
    Feedback.where_might_need_update.find_in_batches(batch_size: 500) do |feedback_batch|
      feedback_batch.each do |feedback|
        if feedback.needs_update?
          begin
            feedback.update_fingerprint!
          rescue ActiveRecord::RecordNotUnique
            feedback.destroy
          end
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

    enum file_type: {
      dependency_scanning: 6,
      container_scanning: 7
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
    has_many :artifacts, through: :pipeline
    has_many :occurrences, through: :pipeline

    enum category: { dependency_scanning: 1, container_scanning: 2 }

    # Feedback that might need update are feedback on vulnerabilities reported
    # by container scanning or dependency scanning jobs run on any branch except
    # the default branch
    def self.where_might_need_update
      left_outer_joins(:occurrences)
        .joins(:artifacts)
        .includes(:artifacts)
        .where(ci_job_artifacts: { file_type: [6, 7] })
        .where('vulnerability_occurrences IS NULL')
    end

    def update_fingerprint!
      update(project_fingerprint: new_fingerprint)
    end

    def needs_update?
      vulnerability.present?
    end

    private

    def vulnerability
      @vulnerability ||= report['vulnerabilities'].find do |vuln|
        old_fingerprint(vuln) == project_fingerprint
      end
    end

    def report
      @report ||= artifact.present? ? JSON.parse(artifact.file.read) : { 'vulnerabilities' => [] }
    end

    def artifact
      @artifact ||= artifacts.find { |artifact| artifact.file_type == category }
    end

    def old_fingerprint(vuln)
      if dependency_scanning?
        Digest::SHA1.hexdigest(vuln['message'])
      elsif container_scanning?
        Digest::SHA1.hexdigest(
          "#{vuln['namespace']}:#{vuln['vulnerability']}" \
          ":#{vuln['featurename']}:#{vuln['featureversion']}"
        )
      end
    end

    def new_fingerprint
      if dependency_scanning?
        Digest::SHA1.hexdigest(vulnerability['cve'])
      elsif container_scanning?
        Digest::SHA1.hexdigest(vulnerability['vulnerability'])
      end
    end
  end
  private_constant :Feedback
end
