class Notificaciones::AutorizacionesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app
  before_filter :obtiene_catalogos

  def index
    @auths = WebservicesAuth.order("created_at DESC").page params[:page]
  end

  def show
    @auth = WebservicesAuth.where("id = #{User.sanitize(params[:id])}").first rescue nil
    redirect_to "/notificaciones/autorizaciones", alert: "No encontrado" if !@auth
  end

  private

  	def obtiene_catalogos
      #  0: Solicitud Autoriza recibida
      #  1: Solicitud Autoriza aprobada
      #  2: Solicitud Autoriza negada
      #  3: Solicitud Autoriza cancelada
      #  4: Solicitud Autoriza expirada
  		@status = [ [ "Recibida", 0 ], [ "Aprobada", 1 ], [ "Negada", 2 ],  [ "Cancelada", 3 ], [ "Expirada", 4 ] ]
  	end
end
