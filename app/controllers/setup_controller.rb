class SetupController < ApplicationController
  skip_before_action :require_setup
  skip_before_action :cloudflare_access_autologin
  skip_before_action :authenticate_user!
  before_action :redirect_if_configured

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      sign_in(@user)
      redirect_to root_path
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def redirect_if_configured
    redirect_to new_user_session_path if User.exists?
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
