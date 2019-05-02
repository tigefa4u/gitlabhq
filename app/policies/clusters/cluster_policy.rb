# frozen_string_literal: true

module Clusters
  class ClusterPolicy < BasePolicy
    alias_method :cluster, :subject

    delegate { cluster.first_group }
    delegate { cluster.first_project }
    delegate { cluster.instance }
  end
end
