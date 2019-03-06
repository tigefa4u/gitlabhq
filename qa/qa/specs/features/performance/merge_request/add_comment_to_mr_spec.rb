# frozen_string_literal: true
require 'faker'
require 'uri'
require 'benchmark'

module QA
  context :performance do
    describe 'merge request' do
      let(:response_threshold) { 270 } # milliseconds
      let(:page_load_threshold) { 5000 } # milliseconds

      def fetch_url(url_key)
        my_hash  = eval(File.read('urls.txt'))
        my_hash[url_key]
      end

      it 'user adds comment to a large mr' do
        puts Time.now
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
          1.times do |i|
            show_page.add_comment_to_diff("Can you check this line of code?", i)
            puts "dd"
            samples_arr.push(show_page.response_time(:comment))
            puts "ee"
          end
          puts samples_arr.to_s
          apdex_score = show_page.apdex(samples_arr, response_threshold)
          page_load_time = show_page.page_load_time
        end

        expect(page_load_time < page_load_threshold).to be true
        puts page_load_time
        puts apdex_score
        expect((apdex_score >= 0.5) && (apdex_score <= 1.0)).to be true
      end
    end
  end
end
