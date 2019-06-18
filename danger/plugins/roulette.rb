# frozen_string_literal: true

require_relative '../../lib/gitlab/danger/roulette'

module Danger
  class Roulette < Plugin
    ROULETTE_DATA_URL = 'https://about.gitlab.com/roulette.json'
    # Put the helper code somewhere it can be tested
    include Gitlab::Danger::Roulette

    def roulette_data
      http_get_json(ROULETTE_DATA_URL)
    end
  end
end
