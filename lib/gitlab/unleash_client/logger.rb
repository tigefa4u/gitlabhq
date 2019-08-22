# frozen_string_literal: true

module Gitlab
  module UnleashClient
    class Logger < ::Gitlab::Logger
      def self.file_name_noext
        'unleash_client'
      end
    end
  end
end
