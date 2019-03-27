# frozen_string_literal: true

module AcmeHelpers
  DIRECTORY = 'https://acme-staging-v02.api.letsencrypt.org/directory'
  NEW_NONCE_URL = 'https://acme-staging-v02.api.letsencrypt.org/acme/new-nonce'

  def stub_directory
    response = <<-EOF
{
  "eQ3fEKjOSxE": "https://community.letsencrypt.org/t/adding-random-entries-to-the-directory/33417",
  "keyChange": "https://acme-staging-v02.api.letsencrypt.org/acme/key-change",
  "meta": {
    "caaIdentities": [
      "letsencrypt.org"
    ],
    "termsOfService": "https://letsencrypt.org/documents/LE-SA-v1.2-November-15-2017.pdf",
    "website": "https://letsencrypt.org/docs/staging-environment/"
  },
  "newAccount": "https://acme-staging-v02.api.letsencrypt.org/acme/new-acct",
  "newNonce": "https://acme-staging-v02.api.letsencrypt.org/acme/new-nonce",
  "newOrder": "https://acme-staging-v02.api.letsencrypt.org/acme/new-order",
  "revokeCert": "https://acme-staging-v02.api.letsencrypt.org/acme/revoke-cert"
}
EOF
    stub_request(:get, Gitlab::AcmeClient::STAGING_DIRECTORY_URL)
      .to_return(status: 200, body: response, headers: {})

    stub_request(:head, NEW_NONCE_URL)
      .to_return(status: 200, body: "", headers: {})
  end
end
