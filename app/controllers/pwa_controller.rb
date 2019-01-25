# frozen_string_literal: true

class PwaController < ApplicationController
  skip_before_action :authenticate_user!
  protect_from_forgery except: :service_worker

  def offline
    render 'offline', layout: 'errors'
  end

  def service_worker
    respond_to do |format|
      format.js do
        render file: "public/assets/webpack/service_worker.js", layout: nil, content_type: 'text/javascript'
      end
    end
  end
end
