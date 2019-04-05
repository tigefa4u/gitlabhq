# frozen_string_literal: true

# The pre-requisite for this spec is to run the rake task : rake generate_perf_testdata
# See `/qa/qa/tools/generate_perf_testdata.rb file` for the script that generates testdata.
# This generates a 'urls.yml' file, which is used as an input in this spec.
# Alternatively, the values can be fetched from the environment variables: URLS_FILE_PATH, HOST_URL, LARGE_ISSUE_URL, LARGE_MR_URL

require 'yaml'
require 'uri'
require 'benchmark'

module QA
  context 'Performance Tests', :performance do
    describe 'merge request' do
      let(:response_threshold) { 270 } # milliseconds
      let(:page_load_threshold) { 5000 } # milliseconds

      before(:all) do
        unless ENV['HOST_URL'] && ENV['LARGE_ISSUE_URL'] && ENV['LARGE_MR_URL']
          urls_file = ENV['URLS_FILE_PATH'] || 'urls.yml'

          unless File.exist?(urls_file)
            raise "\n#{urls_file} file is missing. Please provide correct URLS_FILE_PATH or all of HOST_URL, LARGE_ISSUE_URL and LARGE_MR_URL\n\n"
          end

          urls = YAML.safe_load(File.read(urls_file))
          ENV['HOST_URL'] = urls["host"]
          ENV['LARGE_ISSUE_URL'] = urls["large_issue"]
          ENV['LARGE_MR_URL'] = urls["large_mr"]
        end
      end

      it 'user adds comment to a large mr' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.perform(&:sign_in_using_credentials)

        samples_arr = []
        apdex_score = 0
        page_load_time = 0
        visit(ENV['LARGE_MR_URL'])

        Page::MergeRequest::Show.perform do |show_page|
          show_page.click_diffs_tab
          show_page.expand_diff
          5.times do |i|
            show_page.reply_to_discussion("Can you check this line of code?")
            samples_arr << show_page.response_time do
              show_page.comment
            end
          end
          QA::Runtime::Logger.info "Samples Array: #{samples_arr}"
          QA::Runtime::Logger.info "Response Threshold: #{response_threshold}"
          apdex_score = show_page.apdex(samples_arr, response_threshold)
          page_load_time = show_page.page_load_time
        end

        QA::Runtime::Logger.info "Page Load Time: #{page_load_time}"
        QA::Runtime::Logger.info "Apdex Score: #{apdex_score}"

        expect(page_load_time < page_load_threshold).to be true
        expect((apdex_score >= 0.5) && (apdex_score <= 1.0)).to be true
      end
    end
  end
end
