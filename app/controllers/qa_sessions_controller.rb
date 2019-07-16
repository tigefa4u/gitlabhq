# frozen_string_literal: true

class QaSessionsController < Devise::SessionsController
  before_action :ensure_qa_running!

  def create
    user = warden.authenticate!(scope: :user)
    
    sign_in(user)

    redirect_to after_sign_in_path_for(user)
  end

  def ensure_qa_running!
    #head :403 unless ENV['QA']
  end
end
