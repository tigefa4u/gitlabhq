# frozen_string_literal: true

module Gitlab
  class MergeRequestsServiceLogger < Gitlab::JsonLogger
    def self.file_name_noext
      'merge_requests_service_json'
    end
  end
end
