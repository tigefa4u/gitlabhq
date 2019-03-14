# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20190221234852_int4_pk_stage1of2_fill_column.rb')

describe Int4PkStage1of2FillColumn, :migration do
  let(:users) { table(:users) }
  let(:events) { table(:events) }
  let(:push_event_payloads) { table(:push_event_payloads) }
  let(:ci_build_trace_sections) { table(:ci_build_trace_sections) }

  before do
    @user = users.create!(projects_limit: 10, name: 'The User')

    # Avoid transient errors
    events.delete_all
    push_event_payloads.delete_all
    ci_build_trace_sections.delete_all
    Sidekiq::Worker.clear_all
  end

  shared_examples 'updating column' do |old_column, new_column|
    it "migrates #{old_column} to #{new_column}" do
      migrate!

      expect(model_class.pluck(old_column)).to match_array(model_class.pluck(new_column))
    end
  end

  shared_examples 'scheduling migrations' do |old_column, new_column|
    it 'schedules migration concurrently' do
      stub_const("#{described_class.name}::BATCH_SIZE", 2)

      Sidekiq::Testing.fake! do
        Timecop.freeze do
          migration = described_class::MIGRATION
          concurrency = described_class::CONCURRENCY
          batch_size = described_class::BATCH_SIZE
          interval = described_class::DELAY
          batches_per_iteration = described_class::BATCHES_PER_ITERATION

          migrate!

          # Check how many times the migration has been scheduled
          # deleting the last job that updates the table and then checking again
          concurrency.times do
            expect(migration).to be_scheduled_delayed_migration(delay, model_class.table_name, old_column, new_column, interval, batch_size, batches_per_iteration)
            job_index = BackgroundMigrationWorker.jobs.index { |job| job['args'][1][0] == model_class.table_name}
            BackgroundMigrationWorker.jobs.delete_at(job_index)
          end
        end
      end
    end

    it 'reschedules migration if there are still outdated records' do
      # We will run two batches of 1 record in 2 concurrent jobs.
      stub_const("#{described_class.name}::CONCURRENCY", 2)
      stub_const("#{described_class.name}::BATCH_SIZE", 1)
      stub_const("#{described_class.name}::BATCHES_PER_ITERATION", 2)

      Sidekiq::Testing.fake! do
        Timecop.freeze do
          migration = described_class::MIGRATION
          concurrency = described_class::CONCURRENCY
          batches_per_iteration = described_class::BATCHES_PER_ITERATION

          migrate!

          # Delete unrelated jobs
          BackgroundMigrationWorker.jobs.delete_if do |job|
            job_params = job['args']
            job_params[0] == migration && job_params[1][0] != model_class.table_name
          end

          # Given 8 records, in each iteration we should have:
          # - 2 jobs rescheduled if there are still records
          # - 4 records processed on each interation since they run concurrently
          processed_rows = 0

          concurrency.times do |iteration_count|
            # They run concurrently so we perform both jobs here
            2.times { BackgroundMigrationWorker.perform_one }
            # Each iteration will run two batches
            processed_rows = described_class::BATCHES_PER_ITERATION * 2 * (iteration_count + 1)

            expect(BackgroundMigrationWorker.jobs.size).to eq(batches_per_iteration)
            expect(model_class.select { |e| e[new_column].present? }.count).to eq(processed_rows)
          end

          expect(model_class.where("#{new_column} IS NULL" ).count).to be_zero
        end
      end
    end
  end

  describe '#up' do
    context 'events' do
      before do
        8.times do |i|
          events.create!(author_id: @user.id, action: "#{i} - event")
        end
      end

      it_behaves_like 'updating column', 'id', 'id_new' do
        let(:model_class) { events }
      end

      it_behaves_like 'scheduling migrations', 'id', 'id_new' do
        let(:model_class) { events }
        let(:delay) { described_class::DELAY }
      end
    end

    context 'push_event_payloads' do
      before do
        8.times do |i|
          event = events.create!(author_id: @user.id, action: "#{i} - event")
          push_event_payloads.create!(event_id: event.id, commit_count: 1, action: i, ref_type: i)
        end
      end

      it_behaves_like 'updating column', 'event_id', 'event_id_new' do
        let(:model_class) { push_event_payloads }
      end

      it_behaves_like 'scheduling migrations', 'event_id', 'event_id_new' do
        let(:model_class) { push_event_payloads }
        let(:delay) { described_class::DELAY + 20 }
      end
    end

    context 'ci_build_trace_sections' do
      let(:namespaces) { table(:namespaces) }
      let(:projects) { table(:projects) }
      let(:ci_builds) { table(:ci_builds) }
      let(:ci_build_trace_section_names) { table(:ci_build_trace_section_names) }

      before do
        group = namespaces.create!(name: 'gitlab', path: 'gitlab')
        project = projects.create!(namespace_id: group.id)
        build = ci_builds.create!(name: "a build")
        build_section_name = ci_build_trace_section_names.create!(project_id: project.id, name: 'a section name')

        8.times do |i|
          build = ci_builds.create!(name: "a build")

          ci_build_trace_sections.create!(project_id: project.id,
                                          build_id: build.id,
                                          section_name_id: build_section_name.id,
                                          date_start: i.days.ago,
                                          date_end: i.days.from_now,
                                          byte_start: i,
                                          byte_end: i + 1
                                         )
        end
      end

      it_behaves_like 'updating column', 'id', 'id_new' do
        let(:model_class) { ci_build_trace_sections }
      end

      it_behaves_like 'scheduling migrations', 'id', 'id_new' do
        let(:model_class) { ci_build_trace_sections }
        let(:delay) { described_class::DELAY + 40 }
      end
    end
  end
end
