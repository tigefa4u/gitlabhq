# frozen_string_literal: true

class PrometheusQuery < ActiveRecord::Base
  belongs_to :prometheus_metric, validate: true

  validates :query, presence: true
  validates :unit, presence: true

  def to_query_hash
    {
      query_range: query,
      unit: unit,
      label: legend,
      series: query_series
    }.compact
  end

  private

  def query_series
    case legend
    when 'Status Code'
      [{
        label: 'status_code',
        when: [
          { value: '2xx', color: 'green' },
          { value: '4xx', color: 'orange' },
          { value: '5xx', color: 'red' }
        ]
      }]
    end
  end
end
