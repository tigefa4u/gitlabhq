FactoryBot.define do
  factory :application_setting do
    default_projects_limit 42

    trait :with_notification_admin_email do
      admin_notification_email { 'vshushlin@gitlab.com' }
    end

    trait :with_acme_integration_set do
    end
  end
end
