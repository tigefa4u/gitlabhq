# frozen_string_literal: true

module Gitlab
  module AcmeClient
    PRODUCTION_DIRECTORY_URL = 'https://acme-v02.api.letsencrypt.org/directory'
    STAGING_DIRECTORY_URL = 'https://acme-staging-v02.api.letsencrypt.org/directory'

    class << self
      def create
        raise 'Acme integration is disabled' unless acme_integration_enabled?

        acme_client = Acme::Client.new(private_key: private_key,
                                       directory: directory,
                                       kid: acme_account_kid)

        # account wasn't yet registered in Let's Encrypt
        # if it was calling new_account will just return the same id
        # we save kid to avoid making new_account call every time
        unless acme_account_kid
          account = acme_client.new_account(contact: contact, terms_of_service_agreed: true)
          ApplicationSetting.current.update(acme_account_kid: account.kid)
        end

        acme_client
      end

      private

      def acme_integration_enabled?
        admin_email
      end

      # gets acme private key from application settings
      # generates and saves one if it doesn't exist
      def private_key
        private_key_string = ApplicationSetting.current.acme_private_key
        return OpenSSL::PKey::RSA.new(private_key_string) if private_key_string

        private_key = OpenSSL::PKey::RSA.new(4096)

        application_setting = ApplicationSetting.current

        application_setting.with_lock do
          application_setting.reload
          raise "Acme private key already created" if application_setting.acme_private_key

          ApplicationSetting.current.update(acme_private_key: private_key.to_s)
        end

        private_key
      end

      def acme_account_kid
        ApplicationSetting.current.acme_account_kid
      end

      def admin_email
        ApplicationSetting.current.admin_notification_email
      end

      def contact
        "mailto:#{admin_email}"
      end

      def directory
        if Rails.env.production?
          PRODUCTION_DIRECTORY_URL
        else
          STAGING_DIRECTORY_URL
        end
      end
    end
  end
end
