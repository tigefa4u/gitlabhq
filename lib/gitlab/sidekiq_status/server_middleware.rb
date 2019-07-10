# frozen_string_literal: true

module Gitlab
  module SidekiqStatus
    class ServerMiddleware < BaseMiddleware
      def call(worker, job, queue)
        ret = yield

        Gitlab::SidekiqStatus.unset(job['jid']) if status_enabled?(job)

        ret
      end
    end
  end
end
