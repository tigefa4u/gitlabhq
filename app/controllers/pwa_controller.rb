# frozen_string_literal: true

class PwaController < ApplicationController
  skip_before_action :authenticate_user!
  protect_from_forgery except: :service_worker

  def offline
    render 'offline', layout: 'errors'
  end

  def service_worker
  end
end
