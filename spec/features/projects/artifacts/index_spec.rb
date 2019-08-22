# frozen_string_literal: true

require 'spec_helper'

describe 'Index artifacts', :js do
  include SortingHelper
  include FilteredSearchHelpers

  let(:jobs_values) do
    [
      { created_at: 1.day.ago, artifacts_expire_at: '', name: 'b_position', artifacts_size: 2 * 10**9 },
      { created_at: 2.days.ago, artifacts_expire_at: 3.days.ago, name: 'c_position', artifacts_size: 3 * 10**9 },
      { created_at: 3.days.ago, artifacts_expire_at: 2.days.ago, name: 'a_position', artifacts_size: 1 * 10**9 }
    ]
  end

  describe 'non destructive functionality' do
    let(:project) { create(:project, :public, :repository) }
    let(:pipeline) { create(:ci_empty_pipeline, project: project) }
    let!(:jobs) do
      jobs_values.map do |values|
        create(:ci_build, :artifacts, pipeline: pipeline,
                                      created_at: values[:created_at], artifacts_expire_at: values[:artifacts_expire_at], name: values[:name])
      end
    end

    before do
      visit project_artifacts_path(project)
    end

    context 'when sorting' do
      using RSpec::Parameterized::TableSyntax

      where(:sort_column, :first, :second, :third) do
        'Oldest created' | 2 | 1 | 0
        'Oldest expired' | 1 | 2 | 0
        'Largest size'   | 1 | 0 | 2
      end

      with_them do
        before do
          jobs.each_with_index { |job, index| job.job_artifacts_archive.update!(size: jobs_values[index][:artifacts_size]) }
        end

        subject(:names) do
          page
            .all('.artifacts-content .gl-responsive-table-row:not(.table-row-header) .table-section:nth-child(2)')
            .map { |job_row| job_row.text }
        end

        it 'sorts the result by the specified sort key' do
          sorting_by sort_column

          expect(names).to eq [jobs[first], jobs[second], jobs[third]].map { |job| job.name }
        end
      end
    end

    context 'when searching' do
      using RSpec::Parameterized::TableSyntax

      where(:query_name, :job_indexes) do
        'b_po'     | [0]
        'a_posi'   | [2]
        'position' | [2, 1, 0]
      end

      with_them do
        subject(:names) do
          page
            .all('.artifacts-content .gl-responsive-table-row:not(.table-row-header) .table-section:nth-child(2)')
            .map { |job_row| job_row.text }
        end

        it 'filters jobs' do
          input_filtered_search_keys(query_name)

          expect(names).to eq job_indexes.map { |index| jobs[index].name }
        end
      end
    end
  end

  describe 'destructive functionality' do
    def let_there_be_users_and_projects
      # FIXME: Because of an issue: https://github.com/tomykaira/rspec-parameterized/issues/8#issuecomment-381888428
      # setup needs to be made here instead of using let syntax

      if user_type
        @user = case user_type
                when :regular
                  create(:user)
                when :admin
                  create(:user, :admin)
                end
      end

      @project = if project_association == :owner
                   create(:project, :private, :repository, namespace: @user.namespace)
                 else
                   create(:project, :private, :repository)
                 end

      @project.add_master(@user) if project_association == :master
      @project.add_developer(@user) if project_association == :developer
      @project.add_reporter(@user) if project_association == :reporter

      pipeline = create(:ci_empty_pipeline, project: @project)
      @jobs = jobs_values.map do |values|
        create(:ci_build, :artifacts,
               pipeline: pipeline, created_at: values[:created_at], artifacts_expire_at: values[:artifacts_expire_at],
               name: values[:name])
      end
    end

    context 'with user roles allowed to delete artifacts' do
      using RSpec::Parameterized::TableSyntax

      where(:user_type, :project_association) do
        :regular | :master
        :regular | :owner
        :admin   | nil
        :admin   | :developer
        :admin   | :master
        :admin   | :owner
      end

      with_them do
        before do
          let_there_be_users_and_projects
          sign_in(@user)
        end

        it 'can delete artifacts of job' do
          visit project_artifacts_path(@project)

          accept_alert { click_on 'Delete artifacts', match: :first }

          expect(page).to have_content('Artifacts were successfully deleted.')

          rows = page
            .all('.artifacts-content .gl-responsive-table-row:not(.table-row-header) .table-section:nth-child(2)')
            .map { |job_row| job_row.text }

          expect(rows).to eq %w(c_position b_position)
        end
      end
    end
  end
end
