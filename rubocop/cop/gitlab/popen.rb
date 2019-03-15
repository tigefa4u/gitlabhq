# frozen_string_literal: true
require_relative '../../spec_helpers'

module RuboCop
  module Cop
    module Gitlab
      class Popen < RuboCop::Cop::Cop
        include SpecHelpers

        MSG = <<~EOL.freeze
          Use methods in the `Gitlab::Popen` module instead of using
          `Open3.popen3` directly to avoid accidental deadlocks.
          https://docs.gitlab.com/ee/development/utilities.html#popen
        EOL

        def_node_matcher :popen3_node?, <<~PATTERN
          (send nil? :popen3 ...)
        PATTERN

        def_node_matcher :open3_popen3_node?, <<~PATTERN
          (send (const nil? :Open3) :popen3 ...)
        PATTERN

        def on_send(node)
          return if in_spec?(node)

          if popen3_node?(node) || open3_popen3_node?(node)
            add_offense(node, location: :expression)
          end
        end
      end
    end
  end
end
