# frozen_string_literal: true

module API
  module Internals
    class Pages < Grape::API
      before { authenticate_by_gitlab_pages_token! }

      namespace 'internals' do
        params do
          requires :host, type: String, desc: 'The Pages host'
        end
        get 'pages/query' do
          if namespace = find_namespace(params[:host])
            render namespace,
              using: API::Entities::Pages::NamespaceDomain,
              prefix: namespace.full_path
          elsif domain = find_pages_domain(params[:host])
            render domain,
              using: API::Entities::Pages::PagesDomain,
              prefix: domain.project.full_path
          else
            status :not_found
          end
        end
      end

      helpers do
        def find_namespace_name(host)
          host = host.downcase
          gitlab_host = "." + ::Settings.pages.host.downcase
          host.delete_suffix(gitlab_host) if host.ends_with?(gitlab_host)
        end

        def find_namespace(host)
          namespace_name = find_namespace_name(host)
          Namespace.find_by_full_path(namespace_name) if namespace_name
        end

        def find_pages_domain(host)
          PagesDomain.find_by(domain: host.downcase)
        end
      end
    end
  end
end
