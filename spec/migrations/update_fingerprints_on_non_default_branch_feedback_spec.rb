require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20190827193201_update_fingerprints_on_non_default_branch_feedback.rb')

describe UpdateFingerprintsOnNonDefaultBranchFeedback, :migration do
  let(:artifacts) { table(:ci_job_artifacts) }
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

  let(:vulnerability) { ci_report['vulnerabilities'].first }
  let(:ci_report) do
    { 'vulnerabilities' => [
      {
        'cve' => 'new_fingerprint',
        'featurename' => 'old_fingerprint',
        'featureversion' => 'old_fingerprint',
        'message' => 'old_fingerprint',
        'namespace' => 'old_fingerprint',
        'vulnerability' => 'new_fingerprint'
      }
    ] }
  end

  describe '#up' do
    it 'updates project_fingerprint on feedback for dependency scanning vulnerabilities' do
      report = fixture_file_upload(Rails.root.join(
        'spec/fixtures/security_reports/master/gl-container-scanning-report.json'
      ), 'text/plain')
      job = jobs.create
      artifact = artifacts.create(
        file: report,
        file_format: 1,
        file_type: 7,
        job_id: job.id,
        project_id: project.id
      )
      vulnerability = JSON.parse(artifact.file)['vulnerabilities'].first
      old_fingerprint = Digest::SHA1.hexdigest(vulnerability['message'])
      new_fingerprint = Digest::SHA1.hexdigest(vulnerability['cve'])
      feedback = create_feedback(fingerprint: old_fingerprint)

      migrate!

      expect(feedback.reload.project_fingerprint).to eq(new_fingerprint)
    end

    it 'updates project_fingerprint on feedback for container scanning vulnerabilities' do
      report = fixture_file_upload(Rails.root.join(
        'spec/fixtures/security_reports/master/gl-dependency-scanning-report.json'
      ), 'text/plain')
      job = jobs.create
      artifact = artifacts.create(
        file: report,
        file_format: 1,
        file_type: 6,
        job_id: job.id,
        project_id: project.id
      )
      vulnerability = JSON.parse(artifact.file.body)['vulnerabilities'].first
      old_fingerprint = Digest::SHA1.hexdigest(
        "#{vulnerability['namespace']}:#{vulnerability['vulnerability']}" \
        ":#{vulnerability['featurename']}:#{vulnerability['featureversion']}"
      )
      new_fingerprint = Digest::SHA1.hexdigest(vulnerability['vulnerability'])
      feedback = create_feedback(fingerprint: old_fingerprint)

      migrate!

      expect(feedback.reload.project_fingerprint).to eq(new_fingerprint)
    end

    context 'when a feedback of the same type with a new fingerprint exists' do
      it 'deletes the old feedback' do
        report = fixture_file_upload(Rails.root.join(
          'spec/fixtures/security_reports/master/gl-container-scanning-report.json'
        ), 'text/plain')
        job = jobs.create
        artifact = artifacts.create(
          file: report,
          file_format: 1,
          file_type: 7,
          job_id: job.id,
          project_id: project.id
        )
        vulnerability = JSON.parse(artifact.file.body)['vulnerabilities'].first
        old_fingerprint = Digest::SHA1.hexdigest(vulnerability['message'])
        new_fingerprint = Digest::SHA1.hexdigest(vulnerability['cve'])
        old_feedback = create_feedback(fingerprint: old_fingerprint)
        _new_feedback = create_feedback(fingerprint: new_fingerprint)

        migrate!

        expect { old_feedback.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  def create_feedback(fingerprint:)
    vulnerability_feedback.create(
      author_id: user.id,
      category: 1,
      feedback_type: 0,
      pipeline_id: pipeline.id,
      project_fingerprint: fingerprint,
      project_id: project.id
    )
  end
end

