class Notificaciones::NotificacionesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app

  def index
    @notificaciones = Notificacione.order("created_at DESC").page params[:page]
  end

end
