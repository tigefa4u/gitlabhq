# frozen_string_literal: true

FactoryBot.define do
  factory :prometheus_query, class: PrometheusQuery do
    query 'avg(metric)'
    unit 'm/s'
    legend 'legend'
    association :prometheus_metric
  end
end
