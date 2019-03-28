# frozen_string_literal: true
require 'yaml'
require 'uri'
require 'benchmark'

module QA
  context :performance do
    describe 'merge request' do
      let(:response_threshold) { 270 } # milliseconds
      let(:page_load_threshold) { 5000 } # milliseconds

      def fetch_url(url_key)
        urls = YAML.load(File.read('urls.yml'))
        urls[url_key]
      end

      it 'user adds comment to a large mr' do
        Runtime::Browser.visit(:gitlab, Page::Main::Login)
        Page::Main::Login.act { sign_in_using_credentials }

        samples_arr = []
        apdex_score = 0
        page_load_time = 0
        mr_url = fetch_url(:large_mr)
        visit(mr_url)

        Page::MergeRequest::Show.perform do |show_page|
          show_page.go_to_diffs_tab
          show_page.expand_diff
          5.times do |i|
            show_page.reply_to_discussion("Can you check this line of code?")
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
