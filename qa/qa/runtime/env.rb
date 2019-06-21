# frozen_string_literal: true

module QA
  module Runtime
    module Env
      extend self

      attr_writer :personal_access_token, :ldap_username, :ldap_password

      ENV_VARIABLES = {
        'QA_REMOTE_GRID' => :remote_grid,
        'QA_REMOTE_GRID_USERNAME' => :remote_grid_username,
        'QA_REMOTE_GRID_ACCESS_KEY' => :remote_grid_access_key,
        'QA_REMOTE_GRID_PROTOCOL' => :remote_grid_protocol,
        'QA_BROWSER' => :browser,
        'GITLAB_ADMIN_USERNAME' => :admin_username,
        'GITLAB_ADMIN_PASSWORD' => :admin_password,
        'GITLAB_USERNAME' => :user_username,
        'GITLAB_PASSWORD' => :user_password,
        'GITLAB_LDAP_USERNAME' => :ldap_username,
        'GITLAB_LDAP_PASSWORD' => :ldap_password,
        'GITLAB_FORKER_USERNAME' => :forker_username,
        'GITLAB_FORKER_PASSWORD' => :forker_password,
        'GITLAB_USER_TYPE' => :user_type,
        'GITLAB_SANDBOX_NAME' => :gitlab_sandbox_name,
        'GITLAB_QA_ACCESS_TOKEN' => :qa_access_token,
        'GITLAB_QA_ADMIN_ACCESS_TOKEN' => :qa_admin_access_token,
        'GITHUB_ACCESS_TOKEN' => :github_access_token,
        'GITLAB_URL' => :gitlab_url,
        'SIMPLE_SAML_HOSTNAME' => :simple_saml_hostname,
        'ACCEPT_INSECURE_CERTS' => :accept_insecure_certs,
        'EE_LICENSE' => :ee_license,
        'GCLOUD_ACCOUNT_EMAIL' => :gcloud_account_email,
        'GCLOUD_ACCOUNT_KEY' => :gcloud_account_key,
        'CLOUDSDK_CORE_PROJECT' => :cloudsdk_core_project,
        'GCLOUD_ZONE' => :gcloud_zone,
        'SIGNUP_DISABLED' => :signup_disabled,
        'QA_COOKIES' => :qa_cookie,
        'QA_DEBUG' => :qa_debug,
        'QA_LOG_PATH' => :qa_log_path,
        'QA_CAN_TEST_GIT_PROTOCOL_V2' => :qa_can_test_git_protocol_v2,
        'GITLAB_QA_USERNAME_1' => :gitlab_qa_username_1,
        'GITLAB_QA_PASSWORD_1' => :gitlab_qa_password_1,
        'GITLAB_QA_USERNAME_2' => :gitlab_qa_username_2,
        'GITLAB_QA_PASSWORD_2' => :gitlab_qa_password_2,
        'GITHUB_OAUTH_APP_ID' => :github_oauth_app_id,
        'GITHUB_OAUTH_APP_SECRET' => :github_oauth_app_secret,
        'GITHUB_USERNAME' => :github_username,
        'GITHUB_PASSWORD' => :github_password,
        'KNAPSACK_GENERATE_REPORT' => :knapsack_generate_report,
        'KNAPSACK_REPORT_PATH' => :knapsack_report_path,
        'KNAPSACK_TEST_FILE_PATTERN' => :knapsack_test_file_pattern,
        'KNAPSACK_TEST_DIR' => :knapsack_test_dir,
        'CI' => :ci,
        'CI_NODE_INDEX' => :ci_node_index,
        'CI_NODE_TOTAL' => :ci_node_total,
        'GITLAB_CI' => :gitlab_ci,
        'QA_SKIP_PULL' => :qa_skip_pull
      }.freeze

      # The environment variables used to indicate if the environment under test
      # supports the given feature
      SUPPORTED_FEATURES = {
        git_protocol_v2: 'QA_CAN_TEST_GIT_PROTOCOL_V2',
        admin: 'QA_CAN_TEST_ADMIN_FEATURES'
      }.freeze

      def supported_features
        SUPPORTED_FEATURES
      end

      def admin_password
        ENV['GITLAB_ADMIN_PASSWORD']
      end

      def admin_username
        ENV['GITLAB_ADMIN_USERNAME']
      end

      def admin_personal_access_token
        ENV['GITLAB_QA_ADMIN_ACCESS_TOKEN']
      end

      def debug?
        enabled?(ENV['QA_DEBUG'], default: false)
      end

      def log_destination
        ENV['QA_LOG_PATH'] || $stdout
      end

      # set to 'false' to have Chrome run visibly instead of headless
      def chrome_headless?
        enabled?(ENV['CHROME_HEADLESS'])
      end

      # set to 'true' to have Chrome use a fixed profile directory
      def reuse_chrome_profile?
        enabled?(ENV['CHROME_REUSE_PROFILE'], default: false)
      end

      def accept_insecure_certs?
        enabled?(ENV['ACCEPT_INSECURE_CERTS'])
      end

      def running_in_ci?
        ENV['CI'] || ENV['CI_SERVER']
      end

      def qa_cookies
        ENV['QA_COOKIES'] && ENV['QA_COOKIES'].split(';')
      end

      def signup_disabled?
        enabled?(ENV['SIGNUP_DISABLED'], default: false)
      end

      # specifies token that can be used for the api
      def personal_access_token
        @personal_access_token ||= ENV['GITLAB_QA_ACCESS_TOKEN']
      end

      def remote_grid
        # if username specified, password/auth token is required
        # can be
        # - "http://user:pass@somehost.com/wd/hub"
        # - "https://user:pass@somehost.com:443/wd/hub"
        # - "http://localhost:4444/wd/hub"

        return if (ENV['QA_REMOTE_GRID'] || '').empty?

        "#{remote_grid_protocol}://#{remote_grid_credentials}#{ENV['QA_REMOTE_GRID']}/wd/hub"
      end

      def remote_grid_username
        ENV['QA_REMOTE_GRID_USERNAME']
      end

      def remote_grid_access_key
        ENV['QA_REMOTE_GRID_ACCESS_KEY']
      end

      def remote_grid_protocol
        ENV['QA_REMOTE_GRID_PROTOCOL'] || 'http'
      end

      def browser
        ENV['QA_BROWSER'].nil? ? :chrome : ENV['QA_BROWSER'].to_sym
      end

      def user_username
        ENV['GITLAB_USERNAME']
      end

      def user_password
        ENV['GITLAB_PASSWORD']
      end

      def github_username
        ENV['GITHUB_USERNAME']
      end

      def github_password
        ENV['GITHUB_PASSWORD']
      end

      def forker?
        !!(forker_username && forker_password)
      end

      def forker_username
        ENV['GITLAB_FORKER_USERNAME']
      end

      def forker_password
        ENV['GITLAB_FORKER_PASSWORD']
      end

      def gitlab_qa_username_1
        ENV['GITLAB_QA_USERNAME_1'] || 'gitlab-qa-user1'
      end

      def gitlab_qa_password_1
        ENV['GITLAB_QA_PASSWORD_1']
      end

      def gitlab_qa_username_2
        ENV['GITLAB_QA_USERNAME_2'] || 'gitlab-qa-user2'
      end

      def gitlab_qa_password_2
        ENV['GITLAB_QA_PASSWORD_2']
      end

      def knapsack?
        !!(ENV['KNAPSACK_GENERATE_REPORT'] || ENV['KNAPSACK_REPORT_PATH'] || ENV['KNAPSACK_TEST_FILE_PATTERN'])
      end

      def ldap_username
        @ldap_username ||= ENV['GITLAB_LDAP_USERNAME']
      end

      def ldap_password
        @ldap_password ||= ENV['GITLAB_LDAP_PASSWORD']
      end

      def sandbox_name
        ENV['GITLAB_SANDBOX_NAME']
      end

      def namespace_name
        ENV['GITLAB_NAMESPACE_NAME']
      end

      def auto_devops_project_name
        ENV['GITLAB_AUTO_DEVOPS_PROJECT_NAME']
      end

      def gcloud_account_key
        ENV.fetch("GCLOUD_ACCOUNT_KEY")
      end

      def gcloud_account_email
        ENV.fetch("GCLOUD_ACCOUNT_EMAIL")
      end

      def gcloud_zone
        ENV.fetch('GCLOUD_ZONE')
      end

      def has_gcloud_credentials?
        %w[GCLOUD_ACCOUNT_KEY GCLOUD_ACCOUNT_EMAIL].none? { |var| ENV[var].to_s.empty? }
      end

      # Specifies the token that can be used for the GitHub API
      def github_access_token
        ENV['GITHUB_ACCESS_TOKEN'].to_s.strip
      end

      def require_github_access_token!
        return unless github_access_token.empty?

        raise ArgumentError, "Please provide GITHUB_ACCESS_TOKEN"
      end

      # Returns true if there is an environment variable that indicates that
      # the feature is supported in the environment under test.
      # All features are supported by default.
      def can_test?(feature)
        raise ArgumentError, %Q(Unknown feature "#{feature}") unless SUPPORTED_FEATURES.include? feature

        enabled?(ENV[SUPPORTED_FEATURES[feature]], default: true)
      end

      def runtime_scenario_attributes
        ENV['QA_RUNTIME_SCENARIO_ATTRIBUTES']
      end

      private

      def remote_grid_credentials
        if remote_grid_username
          raise ArgumentError, %Q(Please provide an access key for user "#{remote_grid_username}") unless remote_grid_access_key

          return "#{remote_grid_username}:#{remote_grid_access_key}@"
        end

        ''
      end

      def enabled?(value, default: true)
        return default if value.nil?

        (value =~ /^(false|no|0)$/i) != 0
      end
    end
  end
end
