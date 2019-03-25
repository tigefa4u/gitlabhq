# frozen_string_literal: true

module Ci
  class TriggerRequest < ActiveRecord::Base
    extend Gitlab::Ci::Model
    include IgnorableColumn

    # We switched to Ci::PipelineVariable from Ci::TriggerRequest.variables.
    # Ci::TriggerRequest doesn't save variables anymore.
    ignore_column :variables

    belongs_to :trigger
    belongs_to :pipeline, foreign_key: :commit_id
    has_many :builds

    delegate :short_token, to: :trigger, prefix: true, allow_nil: true
  end
end
