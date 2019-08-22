# frozen_string_literal: true

class RunningWebServer
  def self.unicorn?
    !!defined?(::Unicorn)
  end

  def self.puma?
    !!defined?(::Puma)
  end
end
