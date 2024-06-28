class Notificaciones::AuthLogsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app

  def index
    @auths = AuthLog.order("created_at DESC").page(params[:page]).per(100)
  end

  def show
    @auth = AuthLog.where("id = #{User.sanitize(params[:id])}").first rescue nil
    redirect_to "/notificaciones/auth_logs", alert: "No encontrado" if !@auth
  end

end
