# frozen_string_literal: true

class AcmeChallengesController < ActionController::Base
  def show
    domain = PagesDomain.find_by!(domain: params[:domain].to_s)
    acme_order = domain.acme_orders.find_by!(challenge_token: params[:token].to_s)

    render plain: acme_order.challenge_file_content, content_type: 'text/plain'
  end
end
