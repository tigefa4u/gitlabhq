# frozen_string_literal: true

class ClusterWaitForIngressIpAddressWorker < ClusterApplicationBaseWorker
  include Gitlab::Utils::StrongMemoize

  Error = Class.new(StandardError)

  LEASE_TIMEOUT = 15.seconds.to_i

  def perform(app_name, app_id)
    super
    execute
  end

  def execute
    return if app.external_ip
    return unless try_obtain_lease

    app.update!(external_ip: ingress_ip) if ingress_ip
  end

  private

  def try_obtain_lease
    Gitlab::ExclusiveLease
      .new("check_ingress_ip_address_service:#{app.id}", timeout: LEASE_TIMEOUT)
      .try_obtain
  end

  def ingress_ip
    service.status.loadBalancer.ingress&.first&.ip
  end

  def service
    strong_memoize(:ingress_service) do
      app.ingress_service
    end
  end
end
