# frozen_string_literal: true

module PagesDomains
  class CreateAcmeChallengeService
    attr_reader :pages_domain

    def initialize(pages_domain)
      @pages_domain = pages_domain
    end

    def execute
      acme_client = Gitlab::AcmeClient.create
      order = acme_client.new_order(identifiers: [pages_domain.domain])

      authorization = order.authorizations.first
      challenge = authorization.http

      pages_domain.acme_challenges.create!(
        url: challenge.url,
        token: challenge.token,
        file_content: challenge.file_content
      )

      challenge.request_validation
    end
  end
end
