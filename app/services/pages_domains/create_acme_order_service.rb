# frozen_string_literal: true

module PagesDomains
  class CreateAcmeOrderService
    attr_reader :pages_domain

    def initialize(pages_domain)
      @pages_domain = pages_domain
    end

    def execute
      acme_client = Gitlab::AcmeClient.create
      order = acme_client.new_order(identifiers: [pages_domain.domain])

      authorization = order.authorizations.first
      challenge = authorization.http

      acme_order = pages_domain.acme_orders.create!(
        url: order.url,
        finalize_url: order.finalize_url,
        expires: order.expires,

        challenge_token: challenge.token,
        challenge_file_content: challenge.file_content
      )

      challenge.request_validation
      ObtainAcmeSslCertWorker.perform_in(1.minute, acme_order.id)
    end
  end
end
