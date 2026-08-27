class Users::SessionsController < Devise::SessionsController
  def create
    session.delete(:cart_id)
    super
  end

  def destroy
    session.delete(:cart_id)
    super
  end

  protected

  def respond_to_on_destroy(non_navigational_status: :no_content)
    logout_url = HostedInstanceConfig.cloudflare_access_logout_url

    if request.headers["Cf-Access-Jwt-Assertion"].present? && logout_url
      redirect_to logout_url,
                  allow_other_host: true, status: :see_other
    else
      super
    end
  end
end
