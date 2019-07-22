# frozen_string_literal: true

# Responsible for determining which dashboard service should
# be used to fetch or generate a dashboard hash.
# The services can be considered in two categories - embeds
# and dashboards. Embeds are all portions of dashboards.
module Gitlab
  module Metrics
    module Dashboard
      class ServiceSelector
        SERVICES = ::Metrics::Dashboard

        class << self
          include Gitlab::Utils::StrongMemoize

          # Returns a class which inherits from the BaseService
          # class that can be used to obtain a dashboard.
          # @return [Gitlab::Metrics::Dashboard::Services::BaseService]
          def call(params)
            return SERVICES::CustomMetricEmbedService if custom_metrics_embed?(params)
            return SERVICES::DynamicEmbedService if all_embed_params_present?(params)
            return SERVICES::DefaultEmbedService if params[:embedded]
            return SERVICES::SystemDashboardService if system_dashboard?(params[:dashboard_path])
            return SERVICES::ProjectDashboardService if params[:dashboard_path]

            default_service
          end

          private

          def default_service
            SERVICES::SystemDashboardService
          end

          def system_dashboard?(filepath)
            SERVICES::SystemDashboardService.system_dashboard?(filepath)
          end

          # Custom metrics are added to the system dashboard
          # in ProjectMetricsInserter, so we consider them
          # to be a part of the system dashboard, even though
          # they are exclustely stored in the database.
          def custom_metrics_embed?(params)
            all_embed_params_present?(params) &&
              system_dashboard?(params[:dashboard_path]) &&
              custom_metrics_group?(params[:group])
          end

          def custom_metrics_group?(group)
            custom_metrics_group_titles.include?(group)
          end

          # These are the attributes required to uniquely
          # identify a panel on a dashboard for embedding.
          def all_embed_params_present?(params)
            [
              params[:embedded],
              params[:dashboard_path],
              params[:group],
              params[:title],
              params[:y_label]
            ].all?
          end

          def custom_metrics_group_titles
            strong_memoize(:custom_metrics_group_titles) do
              PrometheusMetricEnums
                .custom_group_details
                .map { |_, details| details[:group_title] }
            end
          end
        end
      end
    end
  end
end
