class UserSessionsController < ApplicationController
  skip_before_filter :require_login
  def new
    @user = User.new
  end

  def create
    _remember_me = true
    if @user = login(params[:username], params[:password], _remember_me)
      redirect_back_or_to(:users, notice: "Добро пожаловать, #{@user.username}!")
    else
      flash.now[:alert] = "Неправильный логин или пароль"
      render action: 'new'
    end
  end

  def destroy
    uname = current_user.username
    logout
    redirect_to(:users, notice: "До свидания, #{uname}")
  end
end
