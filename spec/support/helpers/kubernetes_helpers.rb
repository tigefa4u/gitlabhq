# frozen_string_literal: true

module KubernetesHelpers
  include Gitlab::Kubernetes

  NODE_NAME = "gke-cluster-applications-default-pool-49b7f225-v527"

  def kube_response(body)
    { body: body.to_json }
  end

  def kube_pods_response
    kube_response(kube_pods_body)
  end

  def nodes_response
    kube_response(nodes_body)
  end

  def nodes_metrics_response
    kube_response(nodes_metrics_body)
  end

  def kube_pod_response
    kube_response(kube_pod)
  end

  def kube_logs_response
    { body: kube_logs_body }
  end

  def kube_deployments_response
    kube_response(kube_deployments_body)
  end

  def kube_ingresses_response(with_canary: false)
    kube_response(kube_ingresses_body(with_canary: with_canary))
  end

  def stub_kubeclient_discover_base(api_url)
    WebMock.stub_request(:get, api_url + '/api/v1').to_return(kube_response(kube_v1_discovery_body))
    WebMock
      .stub_request(:get, api_url + '/apis/apps/v1')
      .to_return(kube_response(kube_apps_v1_discovery_body))
    WebMock
      .stub_request(:get, api_url + '/apis/rbac.authorization.k8s.io/v1')
      .to_return(kube_response(kube_v1_rbac_authorization_discovery_body))
    WebMock
      .stub_request(:get, api_url + '/apis/metrics.k8s.io/v1beta1')
      .to_return(kube_response(kube_metrics_v1beta1_discovery_body))
  end

  def stub_kubeclient_discover_istio(api_url)
    stub_kubeclient_discover_base(api_url)

    WebMock
      .stub_request(:get, api_url + '/apis/networking.istio.io/v1alpha3')
      .to_return(kube_response(kube_istio_discovery_body))
  end

  def stub_kubeclient_discover(api_url)
    stub_kubeclient_discover_base(api_url)

    WebMock
      .stub_request(:get, api_url + '/apis/serving.knative.dev/v1alpha1')
      .to_return(kube_response(kube_v1alpha1_serving_knative_discovery_body))
    WebMock
      .stub_request(:get, api_url + '/apis/networking.k8s.io/v1')
      .to_return(kube_response(kube_v1_networking_discovery_body))
  end

  def stub_kubeclient_discover_knative_not_found(api_url)
    stub_kubeclient_discover_base(api_url)

    WebMock
      .stub_request(:get, api_url + '/apis/serving.knative.dev/v1alpha1')
      .to_return(status: [404, "Resource Not Found"])
  end

  def stub_kubeclient_discover_knative_found(api_url)
    WebMock
      .stub_request(:get, api_url + '/apis/serving.knative.dev/v1alpha1')
      .to_return(kube_response(kube_knative_discovery_body))
  end

  def stub_kubeclient_service_pods(response = nil, options = {})
    stub_kubeclient_discover(service.api_url)

    namespace_path = options[:namespace].present? ? "namespaces/#{options[:namespace]}/" : ""

    pods_url = service.api_url + "/api/v1/#{namespace_path}pods"

    WebMock.stub_request(:get, pods_url).to_return(response || kube_pods_response)
  end

  def stub_kubeclient_nodes(api_url)
    stub_kubeclient_discover_base(api_url)

    nodes_url = api_url + "/api/v1/nodes"

    WebMock.stub_request(:get, nodes_url).to_return(nodes_response)
  end

  def stub_kubeclient_nodes_and_nodes_metrics(api_url)
    stub_kubeclient_nodes(api_url)

    nodes_url = api_url + "/apis/metrics.k8s.io/v1beta1/nodes"

    WebMock.stub_request(:get, nodes_url).to_return(nodes_metrics_response)
  end

  def stub_kubeclient_pods(namespace, status: nil)
    stub_kubeclient_discover(service.api_url)
    pods_url = service.api_url + "/api/v1/namespaces/#{namespace}/pods"
    response = { status: status } if status

    WebMock.stub_request(:get, pods_url).to_return(response || kube_pods_response)
  end

  def stub_kubeclient_pod_details(pod, namespace, status: nil)
    stub_kubeclient_discover(service.api_url)

    pod_url = service.api_url + "/api/v1/namespaces/#{namespace}/pods/#{pod}"
    response = { status: status } if status

    WebMock.stub_request(:get, pod_url).to_return(response || kube_pod_response)
  end

  def stub_kubeclient_deployments(namespace, status: nil)
    stub_kubeclient_discover(service.api_url)
    deployments_url = service.api_url + "/apis/apps/v1/namespaces/#{namespace}/deployments"
    response = { status: status } if status

    WebMock.stub_request(:get, deployments_url).to_return(response || kube_deployments_response)
  end

  def stub_kubeclient_ingresses(namespace, status: nil, method: :get, resource_path: "", response: kube_ingresses_response)
    stub_kubeclient_discover(service.api_url)
    ingresses_url = service.api_url + "/apis/networking.k8s.io/v1/namespaces/#{namespace}/ingresses#{resource_path}"
    response = { status: status } if status

    WebMock.stub_request(method, ingresses_url).to_return(response)
  end

  def stub_server_min_version_failed_request
    WebMock.stub_request(:get, service.api_url + '/version').to_return(
      status: [500, "Internal Server Error"],
      body: {}.to_json)
  end

  def stub_server_min_version(min_version)
    response = kube_response({
      major: "1", # not used, just added here to be a bit more realistic purposes
      minor: min_version.to_s
    })

    WebMock.stub_request(:get, service.api_url + '/version')
      .with(
        headers: {
          'Accept' => '*/*',
          'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Authorization' => 'Bearer aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
          'User-Agent' => 'Ruby'
        })
      .to_return(response)
  end

  def stub_kubeclient_knative_services(options = {})
    namespace_path = options[:namespace].present? ? "namespaces/#{options[:namespace]}/" : ""

    options[:name] ||= "kubetest"
    options[:domain] ||= "example.com"
    options[:response] ||= kube_response(kube_knative_services_body(**options))

    stub_kubeclient_discover(service.api_url)

    knative_url = service.api_url + "/apis/serving.knative.dev/v1alpha1/#{namespace_path}services"

    WebMock.stub_request(:get, knative_url).to_return(options[:response])
  end

  def stub_kubeclient_get_secret(api_url, **options)
    options[:metadata_name] ||= "default-token-1"
    options[:namespace] ||= "default"

    WebMock.stub_request(:get, api_url + "/api/v1/namespaces/#{options[:namespace]}/secrets/#{options[:metadata_name]}")
      .to_return(kube_response(kube_v1_secret_body(options)))
  end

  def stub_kubeclient_get_secret_error(api_url, name, namespace: 'default', status: 404)
    WebMock.stub_request(:get, api_url + "/api/v1/namespaces/#{namespace}/secrets/#{name}")
      .to_return(status: [status, "Internal Server Error"])
  end

  def stub_kubeclient_get_secret_not_found_then_found(api_url, **options)
    options[:metadata_name] ||= "default-token-1"
    options[:namespace] ||= "default"

    WebMock.stub_request(:get, api_url + "/api/v1/namespaces/#{options[:namespace]}/secrets/#{options[:metadata_name]}")
      .to_return(status: [404, "Not Found"])
      .then
      .to_return(kube_response(kube_v1_secret_body(options)))
  end

  def stub_kubeclient_get_secret_missing_token_then_with_token(api_url, **options)
    options[:metadata_name] ||= "default-token-1"
    options[:namespace] ||= "default"

    WebMock.stub_request(:get, api_url + "/api/v1/namespaces/#{options[:namespace]}/secrets/#{options[:metadata_name]}")
      .to_return(kube_response(kube_v1_secret_body(options.merge(token: nil))))
      .then
      .to_return(kube_response(kube_v1_secret_body(options)))
  end

  def stub_kubeclient_get_service_account(api_url, name, namespace: 'default')
    WebMock.stub_request(:get, api_url + "/api/v1/namespaces/#{namespace}/serviceaccounts/#{name}")
      .to_return(kube_response({}))
  end

  def stub_kubeclient_get_service_account_error(api_url, name, namespace: 'default', status: 404)
    WebMock.stub_request(:get, api_url + "/api/v1/namespaces/#{namespace}/serviceaccounts/#{name}")
      .to_return(status: [status, "Internal Server Error"])
  end

  def stub_kubeclient_create_service_account(api_url, namespace: 'default')
    WebMock.stub_request(:post, api_url + "/api/v1/namespaces/#{namespace}/serviceaccounts")
      .to_return(kube_response({}))
  end

  def stub_kubeclient_create_service_account_error(api_url, namespace: 'default')
    WebMock.stub_request(:post, api_url + "/api/v1/namespaces/#{namespace}/serviceaccounts")
      .to_return(status: [500, "Internal Server Error"])
  end

  def stub_kubeclient_put_service_account(api_url, name, namespace: 'default')
    WebMock.stub_request(:put, api_url + "/api/v1/namespaces/#{namespace}/serviceaccounts/#{name}")
      .to_return(kube_response({}))
  end

  def stub_kubeclient_create_secret(api_url, namespace: 'default')
    WebMock.stub_request(:post, api_url + "/api/v1/namespaces/#{namespace}/secrets")
      .to_return(kube_response({}))
  end

  def stub_kubeclient_put_secret(api_url, name, namespace: 'default')
    WebMock.stub_request(:put, api_url + "/api/v1/namespaces/#{namespace}/secrets/#{name}")
      .to_return(kube_response({}))
  end

  def stub_kubeclient_put_cluster_role_binding(api_url, name)
    WebMock.stub_request(:put, api_url + "/apis/rbac.authorization.k8s.io/v1/clusterrolebindings/#{name}")
      .to_return(kube_response({}))
  end

  def stub_kubeclient_delete_role_binding(api_url, name, namespace: 'default')
    WebMock.stub_request(:delete, api_url + "/apis/rbac.authorization.k8s.io/v1/namespaces/#{namespace}/rolebindings/#{name}")
      .to_return(kube_response({}))
  end

  def stub_kubeclient_put_role_binding(api_url, name, namespace: 'default')
    WebMock.stub_request(:put, api_url + "/apis/rbac.authorization.k8s.io/v1/namespaces/#{namespace}/rolebindings/#{name}")
      .to_return(kube_response({}))
  end

  def stub_kubeclient_create_namespace(api_url)
    WebMock.stub_request(:post, api_url + "/api/v1/namespaces")
      .to_return(kube_response({}))
  end

  def stub_kubeclient_get_namespace(api_url, namespace: 'default')
    WebMock.stub_request(:get, api_url + "/api/v1/namespaces/#{namespace}")
      .to_return(kube_response({}))
  end

  def stub_kubeclient_put_role(api_url, name, namespace: 'default')
    WebMock.stub_request(:put, api_url + "/apis/rbac.authorization.k8s.io/v1/namespaces/#{namespace}/roles/#{name}")
      .to_return(kube_response({}))
  end

  def stub_kubeclient_get_gateway(api_url, name, namespace: 'default')
    WebMock.stub_request(:get, api_url + "/apis/networking.istio.io/v1alpha3/namespaces/#{namespace}/gateways/#{name}")
      .to_return(kube_response(kube_istio_gateway_body(name, namespace)))
  end

  def stub_kubeclient_put_gateway(api_url, name, namespace: 'default')
    WebMock.stub_request(:put, api_url + "/apis/networking.istio.io/v1alpha3/namespaces/#{namespace}/gateways/#{name}")
      .to_return(kube_response({}))
  end

  def kube_v1_secret_body(options)
    {
      "kind" => "SecretList",
      apiVersion: "v1",
      metadata: {
        name: options.fetch(:metadata_name, "default-token-1"),
        namespace: "kube-system"
      },
      data: {
        token: options.fetch(:token, Base64.encode64('token-sample-123'))
      }
    }
  end

  def kube_v1_discovery_body
    {
      "kind" => "APIResourceList",
      "resources" => [
        { "name" => "nodes", "namespaced" => false, "kind" => "Node" },
        { "name" => "pods", "namespaced" => true, "kind" => "Pod" },
        { "name" => "deployments", "namespaced" => true, "kind" => "Deployment" },
        { "name" => "secrets", "namespaced" => true, "kind" => "Secret" },
        { "name" => "serviceaccounts", "namespaced" => true, "kind" => "ServiceAccount" },
        { "name" => "services", "namespaced" => true, "kind" => "Service" },
        { "name" => "namespaces", "namespaced" => true, "kind" => "Namespace" }
      ]
    }
  end

  def kube_knative_discovery_body
    {
      "kind" => "APIResourceList",
      "resources" => []
    }
  end

  def kube_apps_v1_discovery_body
    {
      "kind" => "APIResourceList",
      "resources" => [
        { "name" => "deployments", "namespaced" => true, "kind" => "Deployment" }
      ]
    }
  end

  def kube_v1_rbac_authorization_discovery_body
    {
      "kind" => "APIResourceList",
      "resources" => [
        { "name" => "clusterrolebindings", "namespaced" => false, "kind" => "ClusterRoleBinding" },
        { "name" => "clusterroles", "namespaced" => false, "kind" => "ClusterRole" },
        { "name" => "rolebindings", "namespaced" => true, "kind" => "RoleBinding" },
        { "name" => "roles", "namespaced" => true, "kind" => "Role" }
      ]
    }
  end

  def kube_metrics_v1beta1_discovery_body
    {
      "kind" => "APIResourceList",
      "resources" => [
        { "name" => "nodes", "namespaced" => false, "kind" => "NodeMetrics" },
        { "name" => "pods", "namespaced" => true, "kind" => "PodMetrics" }
      ]
    }
  end

  def kube_istio_discovery_body
    {
      "kind" => "APIResourceList",
      "apiVersion" => "v1",
      "groupVersion" => "networking.istio.io/v1alpha3",
      "resources" => [
        {
          "name" => "gateways",
          "singularName" => "gateway",
          "namespaced" => true,
          "kind" => "Gateway",
          "verbs" => %w[delete deletecollection get list patch create update watch],
          "shortNames" => %w[gw],
          "categories" => %w[istio-io networking-istio-io]
        },
        {
          "name" => "serviceentries",
          "singularName" => "serviceentry",
          "namespaced" => true,
          "kind" => "ServiceEntry",
          "verbs" => %w[delete deletecollection get list patch create update watch],
          "shortNames" => %w[se],
          "categories" => %w[istio-io networking-istio-io]
        },
        {
          "name" => "destinationrules",
          "singularName" => "destinationrule",
          "namespaced" => true,
          "kind" => "DestinationRule",
          "verbs" => %w[delete deletecollection get list patch create update watch],
          "shortNames" => %w[dr],
          "categories" => %w[istio-io networking-istio-io]
        },
        {
          "name" => "envoyfilters",
          "singularName" => "envoyfilter",
          "namespaced" => true,
          "kind" => "EnvoyFilter",
          "verbs" => %w[delete deletecollection get list patch create update watch],
          "categories" => %w[istio-io networking-istio-io]
        },
        {
          "name" => "sidecars",
          "singularName" => "sidecar",
          "namespaced" => true,
          "kind" => "Sidecar",
          "verbs" => %w[delete deletecollection get list patch create update watch],
          "categories" => %w[istio-io networking-istio-io]
        },
        {
          "name" => "virtualservices",
          "singularName" => "virtualservice",
          "namespaced" => true,
          "kind" => "VirtualService",
          "verbs" => %w[delete deletecollection get list patch create update watch],
          "shortNames" => %w[vs],
          "categories" => %w[istio-io networking-istio-io]
        }
      ]
    }
  end

  def kube_v1_networking_discovery_body
    {
      "kind" => "APIResourceList",
      "apiVersion" => "v1",
      "groupVersion" => "networking.k8s.io/v1",
      "resources" => [
        { "name" => "ingresses", "namespaced" => true, "kind" => "Ingress" }
      ]
    }
  end

  def kube_istio_gateway_body(name, namespace)
    {
      "apiVersion" => "networking.istio.io/v1alpha3",
      "kind" => "Gateway",
      "metadata" => {
        "generation" => 1,
        "labels" => {
          "networking.knative.dev/ingress-provider" => "istio",
          "serving.knative.dev/release" => "v0.7.0"
        },
        "name" => name,
        "namespace" => namespace,
        "selfLink" => "/apis/networking.istio.io/v1alpha3/namespaces/#{namespace}/gateways/#{name}"
      },
      "spec" => {
        "selector" => {
          "istio" => "ingressgateway"
        },
        "servers" => [
          {
            "hosts" => [
              "*"
            ],
            "port" => {
              "name" => "http",
              "number" => 80,
              "protocol" => "HTTP"
            }
          },
          {
            "hosts" => [
              "*"
            ],
            "port" => {
              "name" => "https",
              "number" => 443,
              "protocol" => "HTTPS"
            },
            "tls" => {
              "mode" => "PASSTHROUGH"
            }
          }
        ]
      }
    }
  end

  def kube_v1alpha1_serving_knative_discovery_body
    {
      "kind" => "APIResourceList",
      "resources" => [
        { "name" => "revisions", "namespaced" => true, "kind" => "Revision" },
        { "name" => "services", "namespaced" => true, "kind" => "Service" },
        { "name" => "configurations", "namespaced" => true, "kind" => "Configuration" },
        { "name" => "routes", "namespaced" => true, "kind" => "Route" }
      ]
    }
  end

  def kube_pods_body
    {
      "kind" => "PodList",
      "items" => [kube_pod]
    }
  end

  def nodes_body
    {
      "kind" => "NodeList",
      "items" => [kube_node]
    }
  end

  def nodes_metrics_body
    {
      "kind" => "List",
      "items" => [kube_node_metrics]
    }
  end

  def kube_logs_body
    "2019-12-13T14:04:22.123456Z Log 1\n2019-12-13T14:04:23.123456Z Log 2\n2019-12-13T14:04:24.123456Z Log 3"
  end

  def kube_deployments_body
    {
      "kind" => "DeploymentList",
      "items" => [kube_deployment]
    }
  end

  def kube_ingresses_body(with_canary: false)
    items = with_canary ? [kube_ingress, kube_ingress(track: :canary)] : [kube_ingress]

    {
      "kind" => "List",
      "items" => items
    }
  end

  def kube_knative_pods_body(name, namespace)
    {
      "kind" => "PodList",
      "items" => [kube_knative_pod(name: name, namespace: namespace)]
    }
  end

  def kube_knative_services_body(...)
    {
      "kind" => "List",
      "items" => [knative_09_service(...)]
    }
  end

  # This is a partial response, it will have many more elements in reality but
  # these are the ones we care about at the moment
  def kube_pod(name: "kube-pod", container_name: "container-0", environment_slug: "production", namespace: "project-namespace", project_slug: "project-path-slug", status: "Running", track: nil)
    {
      "metadata" => {
        "name" => name,
        "namespace" => namespace,
        "generateName" => "generated-name-with-suffix",
        "creationTimestamp" => "2016-11-25T19:55:19Z",
        "annotations" => {
          "app.gitlab.com/env" => environment_slug,
          "app.gitlab.com/app" => project_slug
        },
        "labels" => {
          "track" => track
        }.compact
      },
      "spec" => {
        "containers" => [
          { "name" => container_name.to_s },
          { "name" => "#{container_name}-1" }
        ]
      },
      "status" => { "phase" => status }
    }
  end

  def kube_ingress(track: :stable)
    additional_annotations =
      if track == :canary
        {
          "nginx.ingress.kubernetes.io/canary" => "true",
          "nginx.ingress.kubernetes.io/canary-by-header" => "canary",
          "nginx.ingress.kubernetes.io/canary-weight" => "50"
        }
      else
        {}
      end

    {
      "metadata" => {
        "name" => "production-auto-deploy",
        "labels" => {
          "app" => "production",
          "app.kubernetes.io/managed-by" => "Helm",
          "chart" => "auto-deploy-app-2.0.0-beta.2",
          "heritage" => "Helm",
          "release" => "production"
        },
        "annotations" => {
          "kubernetes.io/ingress.class" => "nginx",
          "kubernetes.io/tls-acme" => "true",
          "meta.helm.sh/release-name" => "production",
          "meta.helm.sh/release-namespace" => "awesome-app-1-production"
        }.merge(additional_annotations)
      }
    }
  end

  # This is a partial response, it will have many more elements in reality but
  # these are the ones we care about at the moment
  def kube_node
    {
      "metadata" => {
        "name" => NODE_NAME
      },
      "status" => {
        "capacity" => {
          "cpu" => "2",
          "memory" => "7657228Ki"
        },
        "allocatable" => {
          "cpu" => "1930m",
          "memory" => "5777164Ki"
        }
      }
    }
  end

  # This is a partial response, it will have many more elements in reality but
  # these are the ones we care about at the moment
  def kube_node_metrics
    {
      "metadata" => {
        "name" => NODE_NAME
      },
      "usage" => {
        "cpu" => "144208668n",
        "memory" => "1789048Ki"
      }
    }
  end

  # Similar to a kube_pod, but should contain a running service
  def kube_knative_pod(name: "kube-pod", namespace: "default", status: "Running")
    {
      "metadata" => {
        "name" => name,
        "namespace" => namespace,
        "generateName" => "generated-name-with-suffix",
        "creationTimestamp" => "2016-11-25T19:55:19Z",
        "labels" => {
          "serving.knative.dev/service" => name
        }
      },
      "spec" => {
        "containers" => [
          { "name" => "container-0" },
          { "name" => "container-1" }
        ]
      },
      "status" => { "phase" => status }
    }
  end

  def kube_deployment(name: "kube-deployment", environment_slug: "production", project_slug: "project-path-slug", track: nil, replicas: 3)
    {
      "metadata" => {
        "name" => name,
        "generation" => 4,
        "annotations" => {
          "app.gitlab.com/env" => environment_slug,
          "app.gitlab.com/app" => project_slug
        },
        "labels" => {
          "track" => track
        }.compact
      },
      "spec" => { "replicas" => replicas },
      "status" => {
        "observedGeneration" => 4
      }
    }
  end

  def knative_06_service(name: 'kubetest', namespace: 'default', domain: 'example.com', description: 'a knative service', environment: 'production', cluster_id: 9)
    { "apiVersion" => "serving.knative.dev/v1alpha1",
      "kind" => "Service",
      "metadata" =>
        { "annotations" =>
            { "serving.knative.dev/creator" => "system:serviceaccount:#{namespace}:#{namespace}-service-account",
              "serving.knative.dev/lastModifier" => "system:serviceaccount:#{namespace}:#{namespace}-service-account" },
          "creationTimestamp" => "2019-10-22T21:19:20Z",
          "generation" => 1,
          "labels" => { "service" => name },
          "name" => name,
          "namespace" => namespace,
          "resourceVersion" => "6042",
          "selfLink" => "/apis/serving.knative.dev/v1alpha1/namespaces/#{namespace}/services/#{name}",
          "uid" => "9c7f63d0-f511-11e9-8815-42010a80002f" },
      "spec" => {
        "runLatest" => {
          "configuration" => {
            "revisionTemplate" => {
              "metadata" => {
                "annotations" => { "Description" => description },
                "creationTimestamp" => "2019-10-22T21:19:20Z",
                "labels" => { "service" => name }
              },
              "spec" => {
                "container" => {
                  "env" => [{ "name" => "timestamp", "value" => "2019-10-22 21:19:20" }],
                  "image" => "image_name",
                  "name" => "",
                  "resources" => {}
                },
                "timeoutSeconds" => 300
              }
            }
          }
        }
      },
      "status" => {
        "address" => {
          "hostname" => "#{name}.#{namespace}.svc.cluster.local",
          "url" => "http://#{name}.#{namespace}.svc.cluster.local"
        },
        "conditions" =>
          [{ "lastTransitionTime" => "2019-10-22T21:20:25Z", "status" => "True", "type" => "ConfigurationsReady" },
            { "lastTransitionTime" => "2019-10-22T21:20:25Z", "status" => "True", "type" => "Ready" },
            { "lastTransitionTime" => "2019-10-22T21:20:25Z", "status" => "True", "type" => "RoutesReady" }],
        "domain" => "#{name}.#{namespace}.#{domain}",
        "domainInternal" => "#{name}.#{namespace}.svc.cluster.local",
        "latestCreatedRevisionName" => "#{name}-bskx6",
        "latestReadyRevisionName" => "#{name}-bskx6",
        "observedGeneration" => 1,
        "traffic" => [{ "latestRevision" => true, "percent" => 100, "revisionName" => "#{name}-bskx6" }],
        "url" => "http://#{name}.#{namespace}.#{domain}"
      },
      "environment_scope" => environment,
      "cluster_id" => cluster_id,
      "podcount" => 0 }
  end

  def knative_07_service(name: 'kubetest', namespace: 'default', domain: 'example.com', description: 'a knative service', environment: 'production', cluster_id: 5)
    { "apiVersion" => "serving.knative.dev/v1alpha1",
      "kind" => "Service",
      "metadata" =>
        { "annotations" =>
            { "serving.knative.dev/creator" => "system:serviceaccount:#{namespace}:#{namespace}-service-account",
              "serving.knative.dev/lastModifier" => "system:serviceaccount:#{namespace}:#{namespace}-service-account" },
          "creationTimestamp" => "2019-10-22T21:19:13Z",
          "generation" => 1,
          "labels" => { "service" => name },
          "name" => name,
          "namespace" => namespace,
          "resourceVersion" => "289726",
          "selfLink" => "/apis/serving.knative.dev/v1alpha1/namespaces/#{namespace}/services/#{name}",
          "uid" => "988349fa-f511-11e9-9ea1-42010a80005e" },
      "spec" => {
        "template" => {
          "metadata" => {
            "annotations" => { "Description" => description },
            "creationTimestamp" => "2019-10-22T21:19:12Z",
            "labels" => { "service" => name }
          },
          "spec" => {
            "containers" => [{
              "env" =>
              [{ "name" => "timestamp", "value" => "2019-10-22 21:19:12" }],
              "image" => "image_name",
              "name" => "user-container",
              "resources" => {}
            }],
            "timeoutSeconds" => 300
          }
        },
        "traffic" => [{ "latestRevision" => true, "percent" => 100 }]
      },
      "status" =>
        { "address" => { "url" => "http://#{name}.#{namespace}.svc.cluster.local" },
          "conditions" =>
            [{ "lastTransitionTime" => "2019-10-22T21:20:15Z", "status" => "True", "type" => "ConfigurationsReady" },
              { "lastTransitionTime" => "2019-10-22T21:20:15Z", "status" => "True", "type" => "Ready" },
              { "lastTransitionTime" => "2019-10-22T21:20:15Z", "status" => "True", "type" => "RoutesReady" }],
          "latestCreatedRevisionName" => "#{name}-92tsj",
          "latestReadyRevisionName" => "#{name}-92tsj",
          "observedGeneration" => 1,
          "traffic" => [{ "latestRevision" => true, "percent" => 100, "revisionName" => "#{name}-92tsj" }],
          "url" => "http://#{name}.#{namespace}.#{domain}" },
      "environment_scope" => environment,
      "cluster_id" => cluster_id,
      "podcount" => 0 }
  end

  def knative_09_service(name: 'kubetest', namespace: 'default', domain: 'example.com', description: 'a knative service', environment: 'production', cluster_id: 5)
    { "apiVersion" => "serving.knative.dev/v1alpha1",
      "kind" => "Service",
      "metadata" =>
        { "annotations" =>
            { "serving.knative.dev/creator" => "system:serviceaccount:#{namespace}:#{namespace}-service-account",
              "serving.knative.dev/lastModifier" => "system:serviceaccount:#{namespace}:#{namespace}-service-account" },
          "creationTimestamp" => "2019-10-22T21:19:13Z",
          "generation" => 1,
          "labels" => { "service" => name },
          "name" => name,
          "namespace" => namespace,
          "resourceVersion" => "289726",
          "selfLink" => "/apis/serving.knative.dev/v1alpha1/namespaces/#{namespace}/services/#{name}",
          "uid" => "988349fa-f511-11e9-9ea1-42010a80005e" },
      "spec" => {
        "template" => {
          "metadata" => {
            "annotations" => { "Description" => description },
            "creationTimestamp" => "2019-10-22T21:19:12Z",
            "labels" => { "service" => name }
          },
          "spec" => {
            "containers" => [{
              "env" =>
              [{ "name" => "timestamp", "value" => "2019-10-22 21:19:12" }],
              "image" => "image_name",
              "name" => "user-container",
              "resources" => {}
            }],
            "timeoutSeconds" => 300
          }
        },
        "traffic" => [{ "latestRevision" => true, "percent" => 100 }]
      },
      "status" =>
        { "address" => { "url" => "http://#{name}.#{namespace}.svc.cluster.local" },
          "conditions" =>
            [{ "lastTransitionTime" => "2019-10-22T21:20:15Z", "status" => "True", "type" => "ConfigurationsReady" },
              { "lastTransitionTime" => "2019-10-22T21:20:15Z", "status" => "True", "type" => "Ready" },
              { "lastTransitionTime" => "2019-10-22T21:20:15Z", "status" => "True", "type" => "RoutesReady" }],
          "latestCreatedRevisionName" => "#{name}-92tsj",
          "latestReadyRevisionName" => "#{name}-92tsj",
          "observedGeneration" => 1,
          "traffic" => [{ "latestRevision" => true, "percent" => 100, "revisionName" => "#{name}-92tsj" }],
          "url" => "http://#{name}.#{namespace}.#{domain}" },
      "environment_scope" => environment,
      "cluster_id" => cluster_id,
      "podcount" => 0 }
  end

  def knative_05_service(name: 'kubetest', namespace: 'default', domain: 'example.com', description: 'a knative service', environment: 'production', cluster_id: 8)
    { "apiVersion" => "serving.knative.dev/v1alpha1",
      "kind" => "Service",
      "metadata" =>
        { "annotations" =>
            { "serving.knative.dev/creator" => "system:serviceaccount:#{namespace}:#{namespace}-service-account",
              "serving.knative.dev/lastModifier" => "system:serviceaccount:#{namespace}:#{namespace}-service-account" },
          "creationTimestamp" => "2019-10-22T21:19:19Z",
          "generation" => 1,
          "labels" => { "service" => name },
          "name" => name,
          "namespace" => namespace,
          "resourceVersion" => "330390",
          "selfLink" => "/apis/serving.knative.dev/v1alpha1/namespaces/#{namespace}/services/#{name}",
          "uid" => "9c710da6-f511-11e9-9ba0-42010a800161" },
      "spec" => {
        "runLatest" => {
          "configuration" => {
            "revisionTemplate" => {
              "metadata" => {
                "annotations" => { "Description" => description },
                "creationTimestamp" => "2019-10-22T21:19:19Z",
                "labels" => { "service" => name }
              },
              "spec" => {
                "container" => {
                  "env" => [{ "name" => "timestamp", "value" => "2019-10-22 21:19:19" }],
                  "image" => "image_name",
                  "name" => "",
                  "resources" => { "requests" => { "cpu" => "400m" } }
                },
                "timeoutSeconds" => 300
              }
            }
          }
        }
      },
      "status" =>
        { "address" => { "hostname" => "#{name}.#{namespace}.svc.cluster.local" },
          "conditions" =>
            [{ "lastTransitionTime" => "2019-10-22T21:20:24Z", "status" => "True", "type" => "ConfigurationsReady" },
              { "lastTransitionTime" => "2019-10-22T21:20:24Z", "status" => "True", "type" => "Ready" },
              { "lastTransitionTime" => "2019-10-22T21:20:24Z", "status" => "True", "type" => "RoutesReady" }],
          "domain" => "#{name}.#{namespace}.#{domain}",
          "domainInternal" => "#{name}.#{namespace}.svc.cluster.local",
          "latestCreatedRevisionName" => "#{name}-58qgr",
          "latestReadyRevisionName" => "#{name}-58qgr",
          "observedGeneration" => 1,
          "traffic" => [{ "percent" => 100, "revisionName" => "#{name}-58qgr" }] },
      "environment_scope" => environment,
      "cluster_id" => cluster_id,
      "podcount" => 0 }
  end

  def kube_terminals(service, pod)
    pod_name = pod['metadata']['name']
    pod_namespace = pod['metadata']['namespace']
    containers = pod['spec']['containers']

    containers.map do |container|
      terminal = {
        selectors: { pod: pod_name, container: container['name'] },
        url: container_exec_url(service.api_url, pod_namespace, pod_name, container['name']),
        subprotocols: ['channel.k8s.io'],
        headers: { 'Authorization' => ["Bearer #{service.token}"] },
        created_at: DateTime.parse(pod['metadata']['creationTimestamp']),
        max_session_time: 0
      }
      terminal[:ca_pem] = service.ca_pem if service.ca_pem.present?
      terminal
    end
  end

  def kube_deployment_rollout_status(ingresses: [])
    ::Gitlab::Kubernetes::RolloutStatus.from_deployments(kube_deployment, ingresses: ingresses)
  end

  def empty_deployment_rollout_status
    ::Gitlab::Kubernetes::RolloutStatus.from_deployments
  end
end
