# frozen_string_literal: true

class Admin::AuditLogsController < Admin::ApplicationController
  before_action :check_license_admin_audit_log_available!
  PER_PAGE = 25

  def index
    @events = LogFinder.new(audit_logs_params).execute.page(params[:page]).per(PER_PAGE)
    @entity = case audit_logs_params[:entity_type]
              when 'User'
                User.find_by_id(audit_logs_params[:entity_id])
              when 'Project'
                Project.find_by_id(audit_logs_params[:entity_id])
              when 'Group'
                Namespace.find_by_id(audit_logs_params[:entity_id])
              else
                nil
              end
  end

  def audit_logs_params
    params.permit(:entity_type, :entity_id)
  end

  def check_license_admin_audit_log_available!
    render_404 unless License.feature_available?(:admin_audit_log)
  end
end