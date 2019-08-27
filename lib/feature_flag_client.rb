# frozen_string_literal: true

class FeatureFlagClient
  def self.enabled?(key, user: nil, thing: nil, default_enabled: false)
    if client
      key_string = key.to_s
      unleash_context = Unleash::Context.new
      unleash_context.user_id = user.email if user

      client.is_enabled?(key_string, unleash_context)
    else
      Feature.enabled?(key, thing, default_enabled: default_enabled)
    end
  end

  private

  def self.client
    server_url = ENV['GITLAB_FEATURE_FLAG_SERVER_URL']
    instance_id = ENV['GITLAB_FEATURE_FLAG_INSTANCE_ID']

    if server_url && instance_id
      @client ||= Unleash::Client.new(
        url: server_url,
        instance_id: instance_id,
        app_name: Rails.env
      )
    end
  end
end
