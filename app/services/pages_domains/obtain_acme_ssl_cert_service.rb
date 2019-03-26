# frozen_string_literal: true

module PagesDomains
  class ObtainAcmeSslCertService
    attr_reader :acme_order

    def initialize(acme_order)
      @acme_order = acme_order
    end

    def execute
      acme_client = Gitlab::AcmeClient.create

      private_key = OpenSSL::PKey::RSA.new(4096)
      csr = Acme::Client::CertificateRequest.new(
        private_key: private_key,
        subject: { common_name: acme_order.pages_domain.domain }
      )

      # rubocop: disable CodeReuse/ActiveRecord
      order = acme_client.order(url: acme_order.url)
      # rubocop: enable CodeReuse/ActiveRecord

      order.finalize(csr: csr)
      sleep(20) # FIXME: make it async

      certificate = order.certificate
      acme_order.pages_domain.assign_attributes(key: private_key, certificate: certificate)
      acme_order.pages_domain.save!
    end
  end
end
