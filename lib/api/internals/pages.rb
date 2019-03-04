# frozen_string_literal: true

module API
  module Internals
    class Pages < Grape::API
      namespace 'internals' do
        params do
          requires :host, type: String, desc: 'The Pages host'
        end
        get 'pages/query' do
          if namespace_name = find_namespace_name(params[:host])
            namespace_domain(namespace_name, params[:host].downcase)
          elsif domain = find_user_domain(params[:host])
            user_domain(domain)
          else
            status :not_found
          end
        end
      end

      helpers do
        def namespace_domain(namespace_name, host)
          lookup_paths = []

          if namespace = Namespace.find_by_full_path(namespace_name)
            namespace.all_projects.with_pages.each do |project|
              prefix = project.full_path.delete_prefix(namespace.full_path)
              lookup_paths << project_params(project, prefix)
            end

            lookup_paths << namespace_project_params(namespace, host, "")
          end

          status :ok

          { lookup_paths: lookup_paths.compact }
        end

        def user_domain(domain)
          lookup_paths = []
          lookup_paths << project_params(domain.project, "")

          status :ok

          {
            certificate: domain.certificate,
            key: domain.certificate_key,
            lookup_paths: lookup_paths.compact
          }
        end

        def find_namespace_name(host)
          host = host.downcase
          gitlab_host = "." + ::Settings.pages.host.downcase
          host.delete_suffix(gitlab_host) if host.ends_with?(gitlab_host)
        end

        def find_user_domain(host)
          PagesDomain.find_by(domain: host.downcase)
        end

        def namespace_project_params(namespace, project_name, prefix)
          project = namespace.projects.with_pages.find_by(path: project_name)
          project_params(project, prefix)
        end

        def project_params(project, prefix)
          return unless project
          return unless project.pages_deployed?

          {
            https_only: project.pages_https_only?,
            project_id: project.project_id,
            access_control: !project.public_pages?,
            prefix: "#{prefix}/",
            path: "#{project.public_pages_path}/"
          }
        end
      end
    end
  end
end
