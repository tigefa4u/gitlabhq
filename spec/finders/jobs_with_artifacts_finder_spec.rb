# frozen_string_literal: true

require 'spec_helper'

describe JobsWithArtifactsFinder do
  describe '#execute' do
    context 'with empty params' do
      it 'returns all jobs belonging to the project' do
        project = create(:project)

        pipeline1 = create(:ci_empty_pipeline, project: project)
        job1 = create(:ci_build, pipeline: pipeline1)
        create(:ci_job_artifact, job: job1)

        pipeline2 = create(:ci_empty_pipeline, project: project)
        job2 = create(:ci_build, pipeline: pipeline2)
        create(:ci_job_artifact, job: job2)

        # without artifacts
        pipeline3 = create(:ci_empty_pipeline, project: project)
        create(:ci_build, pipeline: pipeline3)

        create(:ci_job_artifact)

        jobs = described_class.new(project: project, params: {}).execute

        expect(jobs).to match_array [job1, job2]
      end
    end

    context 'filter by search term' do
      it 'calls Ci::Runner.search' do
        project = create(:project)

        expect(Ci::Build).to receive(:search).with('term').and_call_original

        described_class.new(project: project, params: { search: 'term' }).execute
      end
    end

    context 'filter by deleted branch' do
      before do
        @project = create(:project)

        pipeline1 = create(:ci_empty_pipeline, project: @project)
        @job1 = create(:ci_build, pipeline: pipeline1, ref: 'deleted_branches')
        create(:ci_job_artifact, job: @job1)

        pipeline2 = create(:ci_empty_pipeline, project: @project)
        @job2 = create(:ci_build, pipeline: pipeline2, ref: 'master')
        create(:ci_job_artifact, job: @job2)

        allow(project.repository).to receive(:ref_names).and_return(['master'])
      end

      let(:project) { @project }
      let(:job1) { @job1 }
      let(:job2) { @job2 }

      context 'deleted is set to true' do
        it 'returns the jobs that belong to a deleted branch' do
          jobs = described_class.new(project: project, params: { 'deleted_branches_deleted-branches': 'true' }).execute

          expect(jobs).to eq [job1]
        end
      end

      context 'deleted is set to false' do
        it 'returns the jobs that belong to an existing branch' do
          jobs = described_class.new(project: project, params: { 'deleted_branches_deleted-branches': 'false' }).execute

          expect(jobs).to eq [job2]
        end
      end
    end

    context 'sort' do
      context 'without sort param' do
        it 'sorts by created_at' do
          project = create(:project)

          pipeline1 = create(:ci_empty_pipeline, project: project)
          job1 = create(:ci_build, pipeline: pipeline1, created_at: '2018-07-12 07:00')
          create(:ci_job_artifact, job: job1)

          pipeline2 = create(:ci_empty_pipeline, project: project)
          job2 = create(:ci_build, pipeline: pipeline2, created_at: '2018-07-12 09:00')
          create(:ci_job_artifact, job: job2)

          pipeline3 = create(:ci_empty_pipeline, project: project)
          job3 = create(:ci_build, pipeline: pipeline3, created_at: '2018-07-12 08:00')
          create(:ci_job_artifact, job: job3)

          jobs = described_class.new(project: project, params: {}).execute

          expect(jobs).to eq [job1, job3, job2]
        end
      end

      context 'with sort param' do
        it 'sorts by size_desc' do
          project = create(:project)

          pipeline1 = create(:ci_empty_pipeline, project: project)
          job1 = create(:ci_build, pipeline: pipeline1)
          create(:ci_job_artifact, job: job1, size: 2 * 1024)

          pipeline2 = create(:ci_empty_pipeline, project: project)
          job2 = create(:ci_build, pipeline: pipeline2)
          create(:ci_job_artifact, job: job2, size: 1024)

          pipeline3 = create(:ci_empty_pipeline, project: project)
          job3 = create(:ci_build, pipeline: pipeline3)
          create(:ci_job_artifact, job: job3, size: 3 * 1024)

          jobs = described_class.new(project: project, params: { sort: 'size_desc' }).execute

          expect(jobs).to eq [job3, job1, job2]
        end

        it 'sorts by expire_date_asc' do
          project = create(:project)

          pipeline1 = create(:ci_empty_pipeline, project: project)
          job1 = create(:ci_build, pipeline: pipeline1, artifacts_expire_at: '2018-07-12 07:00')
          create(:ci_job_artifact, job: job1)

          pipeline2 = create(:ci_empty_pipeline, project: project)
          job2 = create(:ci_build, pipeline: pipeline2, artifacts_expire_at: '2018-07-12 09:00')
          create(:ci_job_artifact, job: job2)

          pipeline3 = create(:ci_empty_pipeline, project: project)
          job3 = create(:ci_build, pipeline: pipeline3, artifacts_expire_at: '2018-07-12 08:00')
          create(:ci_job_artifact, job: job3)

          jobs = described_class.new(project: project, params: { sort: 'expired_asc' }).execute

          expect(jobs).to eq [job1, job3, job2]
        end
      end
    end

    context 'paginate' do
      it 'returns the runners for the specified page' do
        stub_const('JobsWithArtifactsFinder::NUMBER_OF_JOBS_PER_PAGE', 1)

        project = create(:project)

        pipeline1 = create(:ci_empty_pipeline, project: project)
        job1 = create(:ci_build, pipeline: pipeline1)
        create(:ci_job_artifact, job: job1)

        pipeline2 = create(:ci_empty_pipeline, project: project)
        job2 = create(:ci_build, pipeline: pipeline2)
        create(:ci_job_artifact, job: job2)

        expect(described_class.new(project: project, params: { page: 1 }).execute).to eq [job1]
        expect(described_class.new(project: project, params: { page: 2 }).execute).to eq [job2]
      end
    end
  end
end
