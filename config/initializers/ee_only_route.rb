# frozen_string_literal: true

Rails.application.config.middleware.insert_after(
  ::Gitlab::Middleware::CorrelationId,
  ::Gitlab::Middleware::EeOnlyRoute
)
