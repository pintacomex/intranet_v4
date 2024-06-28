class Api::V1::NotificacionesController < Api::V1::BaseController
  acts_as_token_authentication_handler_for User

  def index
    @deviceId = params[:deviceId] if params.has_key?(:deviceId)
    @notificaciones = Notificacione.where(destinatario: current_user.email)
    @notificaciones = @notificaciones.where(deviceId: @deviceId) if @deviceId
    @notificaciones = @notificaciones.order("created_at DESC").limit(20)
    render(
      json: { notificaciones: @notificaciones }.to_json,
      status: 200
    )
  end

end
