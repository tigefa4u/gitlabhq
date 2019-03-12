# frozen_string_literal: true

require 'spec_helper'
require Rails.root.join('db', 'post_migrate', '20190221234852_int4_pk_stage1of2_fill_column.rb')

describe Int4PkStage1of2FillColumn, :migration do
  let(:users) { table(:users) }
  let(:events) {table(:events) }

  before do
    Sidekiq::Worker.clear_all
    stub_const("#{described_class.name}::BATCH_SIZE", 2)
    @user = users.create!(projects_limit: 10, name: 'The User')
  end

  describe '#up' do
    context 'events' do
      it 'migrates id column values to id_new' do
        3.times do
          events.create!(author_id: @user.id, action: 'Open something')
        end

        migrate!

        Event.all.limit(3).each do |event|
          expect(event.id_new).to eq(event.id)
        end
      end

      it 'schedules migration correctly' do
        Sidekiq::Testing.fake! do
          Timecop.freeze do
            migration = described_class::MIGRATION
            concurrency = described_class::CONCURRENCY
            delay = described_class::DELAY
            batch_size = described_class::BATCH_SIZE
            batches_in_iteration = described_class::BATCHES_IN_ITERATION

            migrate!

            # Check how many times the migration has been scheduled
            # deleting the last job that updates the table and then checking again
            # Move to custom matcher?
            concurrency.times do
              expect(migration).to be_scheduled_delayed_migration(120, 'events', 'id', 'id_new', delay, batch_size, batches_in_iteration)
              job_index = BackgroundMigrationWorker.jobs.index { |job| job['args'][1][0] == 'events' }
              BackgroundMigrationWorker.jobs.delete_at(job_index)
            end
          end
        end
      end
    end
  end
end
