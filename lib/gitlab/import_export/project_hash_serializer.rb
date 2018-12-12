# frozen_string_literal: true

# ActiveModel::Serialization (https://github.com/rails/rails/blob/v5.0.7/activemodel/lib/active_model/serialization.rb#L184)
# is simple in that it recursively calls `as_json` on each object to
# serialize everything. However, for a model like a Project, this can
# generate a query for every single association, which can add up to tens
# of thousands of queries and lead to memory bloat.
#
# To improve this, we can do several things:

# 1. Use the option tree in http://api.rubyonrails.org/classes/ActiveModel/Serializers/JSON.html
#    to generate the necessary preload clauses.
#
# 2. We observe that a single project has many issues, merge requests,
#    etc. Instead of serializing everything at once, which could lead to
#    database timeouts and high memory usage, we take each top-level
#    association and serialize the data in batches.
#
#  For example, we serialize the first 1,000 issues and preload all of
#  their associated events, notes, etc. before moving onto the next
#  batch. When we're done, we serialize merge requests in the same way.
#  We repeat this pattern for the remaining associations specified in
#  import_export.yml.
module Gitlab
  module ImportExport
    class ProjectHashSerializer
      attr_reader :project, :tree

      def initialize(project, tree)
        @project = project
        @tree = tree
      end

      # Serializes the project into a Hash for the given option tree
      # (e.g. Project#as_json)
      def execute
        if Feature.enabled?(:import_export_fast_serialize, default_enabled: true)
          fast_serialize
        else
          project.as_json(tree)
        end
      end

      private

      def fast_serialize
        preload_data = extract_preload_clause(tree)
        # Detach the top-level includes so only the project attributes
        # are serialized
        included_tree = tree.delete(:include)
        data = project.as_json(tree)

        # Now serialize each top-level association (e.g. issues, merge requests, etc.)
        # in batches.
        preload_data.each do |key, preload_clause|
          records = project.send(key)
          selection = serialize_options(included_tree, key)

          next unless records

          if records.is_a?(ActiveRecord::Base)
            data[key.to_s] = records
            next
          end

          data[key.to_s] = []

          # Not all models use EachBatch, whereas ActiveRecord guarantees all models can use in_batches.
          records.in_batches do |batch| # rubocop:disable Cop/InBatches
            batch = batch.preload(preload_clause) if preload_clause
            data[key.to_s] += batch.as_json(selection)
          end
        end

        data
      end

      # The `include` tree contains rows of entries that can contain a Hash or a symbol
      # sorted in any particular way:
      #
      # [{:labels=>...,
      #  {:milestones=>...,
      #  :releases,
      #  ...
      # ]
      #
      # This method does a linear search to find the matching association key.
      def serialize_options(included_tree, key)
        selected_include = included_tree.find { |row| row.is_a?(Hash) ? row.keys.first == key : nil }

        selected_include ? selected_include[key] : nil
      end

      def extract_preload_clause(options)
        clause = {}

        return unless options[:include]

        add_includes(options) do |association, opts|
          preload_clause = extract_preload_clause(opts)
          # XXX Hack
          preload_clause.delete(:notes) if association == :ci_pipelines
          preload_clause.merge!({ source_project: nil, target_project: nil }) if association == :merge_requests
          # XXX
          clause[association] = preload_clause
        end

        clause
      end

      # Taken from https://github.com/rails/rails/blob/v5.0.7/activemodel/lib/active_model/serialization.rb#L170
      # but repurposed here.
      #
      # Add associations specified via the <tt>:include</tt> option.
      #
      # Expects a block that takes as arguments:
      #   +association+ - name of the association
      #   +records+     - the association record(s) to be serialized
      #   +opts+        - options for the association records
      def add_includes(options = {})
        return unless includes = options[:include]

        unless includes.is_a?(Hash)
          includes = Hash[Array(includes).map { |n| n.is_a?(Hash) ? n.to_a.first : [n, {}] }]
        end

        includes.each do |association, opts|
          yield association, opts
        end
      end
    end
  end
end
