# frozen_string_literal: true

class FeatureFlagClient
  def self.enabled?(key)
    server_url = ENV['GITLAB_FEATURE_FLAG_SERVER_URL']
    instance_id = ENV['GITLAB_FEATURE_FLAG_INSTANCE_ID']

    if server_url && instance_id
      @client ||= Unleash::Client.new(
        url: server_url,
        instance_id: instance_id,
        app_name: Rails.env
      )
    end

    # TODO: Implement call to server to check feature flag
    false
  end
end
