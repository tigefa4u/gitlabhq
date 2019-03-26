# frozen_string_literal: true

class ObtainAcmeSslCertWorker
  include ApplicationWorker

  def perform(acme_order_id)
    PagesDomains::ObtainAcmeSslCertService.new(PagesDomainAcmeOrder.find(acme_order_id)).execute
  end
end
