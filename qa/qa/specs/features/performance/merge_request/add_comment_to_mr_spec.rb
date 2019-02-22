# frozen_string_literal: true
require 'faker'
require 'uri'
require 'benchmark'

module QA
  context :performance do
    describe 'merge request' do
      let(:api_client) do
        Runtime::API::Client.new(:gitlab)
      end
      let(:response_threshold) { 270 } # milliseconds
      let(:page_load_threshold) { 5000 } # milliseconds
      let(:project) do
        puts "here1"
        Resource::Project.fabricate! do |resource|
          resource.name = 'perf-test-project'
        end
      end

      def create_request(api_endpoint)
        Runtime::API::Request.new(api_client, api_endpoint)
      end

      def project_id
        request = create_request("/projects")
        get request.url, search: project.name
        puts json_body[0][:id].to_s
        json_body[0][:id]
      end

      def push_new_file(branch, content, commit_message, file_path, exists = false)
        proj_id = project_id
        request = create_request("/projects/#{proj_id}/repository/files/#{file_path}")
        if exists
          put request.url, branch: branch, content: content, commit_message: commit_message
          expect_status(200)
        else
          post request.url, branch: branch, content: content, commit_message: commit_message
          expect_status(201)
        end
      end

      def create_branch(branch_name)
        proj_id = project_id
        request = create_request("/projects/#{proj_id}/repository/branches")
        post request.url, branch: branch_name, ref: 'master'
        expect_status(201)
      end

      def populate_data_for_mr
        content_arr = []

        2.times do |i|
          faker_line_arr = Faker::Lorem.sentences(1500)
          content = faker_line_arr.join("\n\r")
          push_new_file('master', content, "Add testfile-#{i}.md", "testfile-#{i}.md")
          content_arr[i] = faker_line_arr
        end

        create_branch("perf-testing")

        content = ""
        1.times do |i|
          missed_line_array = content_arr[i].each_slice(2).map(&:first)
          content = missed_line_array.join("\n\rIm new!:D \n\r ")
        #   push_new_file('perf-testing', content, "Update testfile-#{i}.md", "testfile-#{i}.md", true)
        end
        return content
      end

      it 'user adds comment to mr' do
        big_content = populate_data_for_mr
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }
        merge_request = Resource::MergeRequest.fabricate! do |merge_request|
          merge_request.title = 'My MR for Perf Testing'
          merge_request.description = 'My MR for Perf Testing'
          merge_request.project = project
          merge_request.source_branch = 'perf-testing'
          merge_request.file_name = "blah.txt"
          merge_request.file_content = big_content
        end

        samples_arr = []
        apdex_score = 0
        page_load_time = 0

        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }

        merge_request.visit!

        Page::MergeRequest::Show.perform do |show_page|
          show_page.go_to_diffs_tab
          show_page.expand_diff
          5.times do |i|
            show_page.add_comment_to_diff("Can you check this line of code?", i)
            samples_arr.push(show_page.response_time(:comment))
          end
          apdex_score = show_page.apdex(samples_arr, response_threshold)
          page_load_time = show_page.page_load_time
        end

        expect(page_load_time < page_load_threshold).to be true
        expect((apdex_score >= 0.5) && (apdex_score <= 1.0)).to be true
      end
    end
  end
end
