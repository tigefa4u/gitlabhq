# frozen_string_literal: true

module CycleAnalytics
  class ProjectLevel
    include LevelBase
    attr_reader :project, :options

    def initialize(project, options:)
      @project = project
      @options = options.merge(project: project)
    end

    def all_medians_by_stage
      stages.each_with_object({}) do |stage, medians_per_stage|
        medians_per_stage[stage.name.to_sym] = stage.project_median
      end
    end

    def stats
      stages.map(&:as_json)
    end

    def summary
      @summary ||= ::Gitlab::CycleAnalytics::StageSummary.new(project,
                                                              from: options[:from],
                                                              current_user: options[:current_user]).data
    end

    def permissions(user:)
      Gitlab::CycleAnalytics::Permissions.get(user: user, project: project)
    end

    def [](identifier)
      stages.find { |s| s.name.to_s.eql?(identifier.to_s) }
    end

    def stages
      @stages ||= Gitlab::Analytics::CycleAnalytics::DefaultStages.all.map do |params|
        Gitlab::CycleAnalytics::LegacyStageAdapter.new(project.cycle_analytics_stages.build(params), options)
      end
    end
  end
end
