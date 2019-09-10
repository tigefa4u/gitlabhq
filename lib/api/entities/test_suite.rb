# frozen_string_literal: true

module API
  module Entities
    class TestCase < Grape::Entity
      expose :classname
      expose :execution_time
      expose :file
      expose :key
      expose :name
      expose :stack_trace
      expose :status
      expose :system_output
    end

    class TestSuite < Grape::Entity
      expose :name
      expose :total_time

      Gitlab::Ci::Reports::TestCase::STATUS_TYPES.each do |status|
        expose status, using: TestCase do |test_suite|
          test_suite.test_cases[status]&.values || []
        end
      end
    end
  end
end
