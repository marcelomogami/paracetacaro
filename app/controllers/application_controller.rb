class ApplicationController < ActionController::Base
  allow_browser versions: :modern unless Rails.env.test?
  stale_when_importmap_changes

  before_action :require_setup
  before_action :cloudflare_access_autologin
  before_action :authenticate_user!

  helper_method :current_cart, :admin?

  private

  def current_cart
    @current_cart ||= Cart.find_by(id: session[:cart_id])
  end

  def require_setup
    redirect_to setup_path unless User.exists?
  end

  def cloudflare_access_autologin
    return if current_user

    token = request.headers["Cf-Access-Jwt-Assertion"]
    return if token.blank?

    payload = CloudflareAccessVerifier.call(token)
    return unless payload

    user = User.find_by(email: payload["email"])
    sign_in(user, store: true) if user
  end

  def admin?
    current_user&.id == User.minimum(:id)
  end

  def after_sign_in_path_for(_resource)
    root_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    new_user_session_path
  end
end
