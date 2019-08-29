# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20190827193201_update_fingerprints_on_non_default_branch_feedback.rb')

describe UpdateFingerprintsOnNonDefaultBranchFeedback, :migration do
  let(:jobs) { table(:ci_builds) }
  let(:namespaces) { table(:namespaces) }
  let(:pipelines) { table(:ci_pipelines) }
  let(:projects) { table(:projects) }
  let(:vulnerability_feedback) { table(:vulnerability_feedback) }
  let(:users) { table(:users) }

  let(:namespace) { namespaces.create(name: 'gitlab', path: 'gitlab') }
  let(:pipeline) { pipelines.create }
  let(:project) { projects.create(name: 'gitlab', path: 'gitlab', namespace_id: namespace.id) }
  let(:user) { users.create(projects_limit: 1) }

  before(:all) do
    artifacts = table(:ci_job_artifacts)

    class Artifact < artifacts
      mount_uploader :file, JobArtifactUploader

      enum file_location: {
        legacy_path: 1,
        hashed_path: 2
      }
    end
  end

  describe '#up' do
    it 'updates project_fingerprint on feedback for dependency scanning vulnerabilities' do
      report = fixture_file_upload(Rails.root.join(
        'spec/fixtures/security_reports/master/gl-dependency-scanning-report.json'
      ), 'text/plain')
      artifact = create_artifact(file_type: 7, report: report)
      vulnerability = JSON.parse(artifact.file.read)['vulnerabilities'].first
      old_fingerprint = Digest::SHA1.hexdigest(vulnerability['message'])
      new_fingerprint = Digest::SHA1.hexdigest(vulnerability['cve'])
      feedback = create_feedback(fingerprint: old_fingerprint, category: 1)

      migrate!

      expect(feedback.reload.project_fingerprint).to eq(new_fingerprint)
    end

    it 'updates project_fingerprint on feedback for container scanning vulnerabilities' do
      report = fixture_file_upload(Rails.root.join(
        'spec/fixtures/security_reports/master/gl-container-scanning-report.json'
      ), 'text/plain')
      artifact = create_artifact(file_type: 6, report: report)
      vulnerability = JSON.parse(artifact.file.read)['vulnerabilities'].first
      old_fingerprint = Digest::SHA1.hexdigest(
        "#{vulnerability['namespace']}:#{vulnerability['vulnerability']}" \
        ":#{vulnerability['featurename']}:#{vulnerability['featureversion']}"
      )
      new_fingerprint = Digest::SHA1.hexdigest(vulnerability['vulnerability'])
      feedback = create_feedback(fingerprint: old_fingerprint, category: 2)

      migrate!

      expect(feedback.reload.project_fingerprint).to eq(new_fingerprint)
    end

    context 'when a feedback of the same type with a new fingerprint exists' do
      it 'deletes the old feedback' do
        report = fixture_file_upload(Rails.root.join(
          'spec/fixtures/security_reports/master/gl-dependency-scanning-report.json'
        ), 'text/plain')
        artifact = create_artifact(file_type: 7, report: report)
        vulnerability = JSON.parse(artifact.file.read)['vulnerabilities'].first
        old_fingerprint = Digest::SHA1.hexdigest(vulnerability['message'])
        new_fingerprint = Digest::SHA1.hexdigest(vulnerability['cve'])
        old_feedback = create_feedback(fingerprint: old_fingerprint, category: 1)
        _new_feedback = create_feedback(fingerprint: new_fingerprint, category: 1)

        migrate!

        expect { old_feedback.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  def create_artifact(file_type:, report:)
    job = jobs.create(commit_id: pipeline.id)

    Artifact.create(
      file: report,
      file_format: 1,
      file_location: 2,
      file_type: file_type,
      job_id: job.id,
      project_id: project.id
    )
  end

  def create_feedback(category:, fingerprint:)
    vulnerability_feedback.create(
      author_id: user.id,
      category: category,
      feedback_type: 0,
      pipeline_id: pipeline.id,
      project_fingerprint: fingerprint,
      project_id: project.id
    )
  end
end

