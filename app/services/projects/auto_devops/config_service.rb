# frozen_string_literal: true

module Projects
  module AutoDevops
    class ConfigService < BaseService
      def auto_devops_enabled?
        if project.auto_devops&.enabled.nil?
          project.has_auto_devops_implicitly_enabled?
        else
          project.auto_devops.enabled?
        end
      end

      def has_auto_devops_implicitly_enabled?
        auto_devops_config = first_auto_devops_config

        auto_devops_config[:scope] != :project && auto_devops_config[:status]
      end

      def has_auto_devops_implicitly_disabled?
        auto_devops_config = first_auto_devops_config

        auto_devops_config[:scope] != :project && !auto_devops_config[:status]
      end

      private

      def first_auto_devops_config
        return project.namespace.first_auto_devops_config if project.auto_devops&.enabled.nil?

        { scope: :project, status: project.auto_devops&.enabled || force_autodevops_on_by_default? }
      end

      def force_autodevops_on_by_default?
        Feature.enabled?(:force_autodevops_on_by_default, project)
      end
    end
  end
end
