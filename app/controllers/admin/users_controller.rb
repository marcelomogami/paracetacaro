class Admin::UsersController < ApplicationController
  before_action :require_admin
  before_action :set_user, only: [ :edit, :update, :destroy ]

  def index
    @users = User.order(:created_at)
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to root_path, notice: "Usuário #{@user.email} cadastrado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @user.update(edit_params)
      redirect_to admin_users_path, notice: "Usuário atualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @user.destroy
    redirect_to admin_users_path, notice: "Usuário removido."
  end

  private

  def require_admin
    redirect_to root_path unless admin?
  end

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def edit_params
    params.require(:user).permit(:name, :email, :beta_tester)
  end
end
