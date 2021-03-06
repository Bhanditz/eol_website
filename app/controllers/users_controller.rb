class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
    redirect_if_user_is_inactive
  end

  def index
    @dummy = "HOME"
    @users = User.all
  end

  def delete_user
    @user = User.find(params[:id])
    authenticate @user, :destroy?
    @user.soft_delete
    Devise.sign_out_all_scopes ? sign_out : sign_out(User)
    flash[:notice] = I18n.t(:destroyed, scope: 'devise.registrations')
    respond_to do |format|
      format.html { redirect_to root_path }
      format.json { render json: true }
    end
  end

  def autocomplete
    render json: User.autocomplete(params[:query])
  end

  private

  def redirect_if_user_is_inactive
    unless @user.active
      flash[:notice] = I18n.t(:user_not_active)
      redirect_to new_user_session_path
    end
  end
end
