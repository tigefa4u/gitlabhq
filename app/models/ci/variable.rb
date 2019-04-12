# frozen_string_literal: true

module Ci
  class Variable < ApplicationRecord
    extend Gitlab::Ci::Model
    include HasVariable
    include Presentable
    include Maskable

    belongs_to :project

    alias_attribute :secret_value, :value

    enum variable_type: {
      env_var: 1,
      file: 2
    }

    validates :key, uniqueness: {
      scope: [:project_id, :environment_scope],
      message: "(%{value}) has already been taken"
    }

    scope :unprotected, -> { where(protected: false) }

    def self.variable_type_options
      [
        %w(Variable env_var),
        %w(File file)
      ]
    end

    def to_runner_variable
      super.merge(file: file?)
    end
  end
end
