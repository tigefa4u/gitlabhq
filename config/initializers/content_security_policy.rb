Rails.application.config.content_security_policy do |policy|
  policy.default_src :self
  policy.object_src  :none
  policy.worker_src  *%w(https://assets.gitlab-static.net https://gl-canary.freetls.fastly.net https://gitlab.com blob:)
  policy.script_src  *%w('self' http://localhost:3808 'unsafe-inline' 'unsafe-eval' https://assets.gitlab-static.net https://gl-canary.freetls.fastly.net https://www.google.com/recaptcha/ https://www.recaptcha.net/ https://www.gstatic.com/recaptcha/ https://apis.google.com https://localhost:45537/)
  policy.style_src   *%w('self' 'unsafe-inline' https://assets.gitlab-static.net https://gl-canary.freetls.fastly.net)
  policy.img_src     *%w(* data: blob)
  policy.frame_src   *%w('self' https://www.google.com/recaptcha/ https://www.recaptcha.net/ https://content.googleapis.com https://content-compute.googleapis.com https://content-cloudbilling.googleapis.com https://content-cloudresourcemanager.googleapis.com https://*.codesandbox.io)
  policy.frame_ancestors *%w('self')
  policy.connect_src   *%w('self' http://localhost:3808 ws://localhost:3808 https://assets.gitlab-static.net https://gl-canary.freetls.fastly.net wss://gitlab.com https://sentry.gitlab.net https://customers.gitlab.com https://snowplow.trx.gitlab.net)
end

Rails.application.config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }
