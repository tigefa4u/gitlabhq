server_url = ENV['GITLAB_FEATURE_FLAG_SERVER_URL']
instance_id = ENV['GITLAB_FEATURE_FLAG_INSTANCE_ID']

if RunningWebServer.unicorn? && server_url && instance_id
  Unleash.configure do |config|
    config.url = server_url
    config.instance_id = instance_id
    config.app_name = Rails.env
    config.logger = Gitlab::UnleashClient::Logger.build
  end
end
