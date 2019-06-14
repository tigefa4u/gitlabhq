# frozen_string_literal: true

require 'knapsack'
require 'open3'
require 'rspec/core'
require 'rspec/expectations'

module QA
  module Specs
    class Runner < Scenario::Template
      attr_accessor :tty, :tags, :options

      DEFAULT_TEST_PATH_ARGS = ['--', File.expand_path('./features', __dir__)].freeze

      def initialize
        @tty = false
        @tags = []
        @options = []
      end

      # TODO refactor so that the cops are not disabled
      def perform # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
        Runtime::Browser.configure!

        args = []
        args.push('--tty') if tty

        if tags.any?
          tags.each { |tag| args.push(['--tag', tag.to_s]) }
        else
          args.push(%w[--tag ~orchestrated]) unless (%w[-t --tag] & options).any?
        end

        args.push(%w[--tag ~skip_signup_disabled]) if QA::Runtime::Env.signup_disabled?

        QA::Runtime::Env.supported_features.each_key do |key|
          args.push(%W[--tag ~requires_#{key}]) unless QA::Runtime::Env.can_test? key
        end

        args.push(options)

        if Runtime::Env.knapsack?
          allocator = Knapsack::AllocatorBuilder.new(Knapsack::Adapters::RSpecAdapter).allocator

          QA::Runtime::Logger.info ''
          QA::Runtime::Logger.info 'Report specs:'
          QA::Runtime::Logger.info allocator.report_node_tests.join(', ')
          QA::Runtime::Logger.info ''
          QA::Runtime::Logger.info 'Leftover specs:'
          QA::Runtime::Logger.info allocator.leftover_node_tests.join(', ')
          QA::Runtime::Logger.info ''

          args.push(['--', allocator.node_tests])
        else
          args.push(DEFAULT_TEST_PATH_ARGS) unless options.any? { |opt| opt =~ %r{/features/} }
        end

        if Runtime::Scenario.attributes[:parallel]
          args.flatten!

          unless args.include?('--')
            index = args.index { |opt| opt =~ %r{/features/} }

            args.insert(index, '--') if index
          end

          env = { 'QA_RUNTIME_SCENARIO_ATTRIBUTES' => Runtime::Scenario.attributes.to_json }
          cmd = "bundle exec parallel_test -t rspec -- #{args.flatten.join(' ')}"
          ::Open3.popen2e(env, cmd) do |_, out, _|
            out.each { |line| puts line }
          end
        else
          RSpec::Core::Runner.run(args.flatten, $stderr, $stdout).tap do |status|
            abort if status.nonzero?
          end
        end
      end
    end
  end
end
