# frozen_string_literal: true

module AutoDevopsHelper
  def show_auto_devops_callout?(project)
    Feature.get(:auto_devops_banner_disabled).off? &&
      show_callout?('auto_devops_settings_dismissed') &&
      can?(current_user, :admin_pipeline, project) &&
      project.has_auto_devops_implicitly_disabled? &&
      !project.repository.gitlab_ci_yml &&
      !project.ci_service
  end

  def auto_devops_badge_for_project(project)
    return unless project.auto_devops_enabled? && !project.auto_devops&.enabled

    badge_for_namespace_or_instance(project.namespace)
  end

  def auto_devops_badge_for_group(group)
    return unless group.auto_devops_enabled?

    badge_for_namespace_or_instance(group)
  end

  private

  def badge_for_namespace_or_instance(namespace)
    namespace.self_and_ancestors.each do |parent_group|
      return s_('CICD|group enabled') if parent_group.auto_devops_enabled
    end

    s_('CICD|instance enabled')
  end
end
