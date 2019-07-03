# frozen_string_literal: true

module RedirectWhen
  extend ActiveSupport::Concern

  included do
    def self.redirect_when(*syms, &block)
      syms.each do |sym|
        self.define_method("#{sym}!".to_sym) do
          loc, opts = instance_eval(&block)
          redirect_to(loc, opts || {})
        end
      end
    end
  end
end
