# frozen_string_literal: true

module Gitlab
  module SidekiqStatus
    class BaseMiddleware
      # @param [Hash] job the full job payload
      def status_enabled?(job)
        worker = job['class']&.constantize

        byebug
        return worker.sidekiq_status_enabled? if worker&.respond_to?(:sidekiq_status_enabled?)

        true
      rescue NameError
        true
      end
    end
  end
end
