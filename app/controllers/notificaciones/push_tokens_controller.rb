class Notificaciones::PushTokensController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app

  def index
    @push_tokens = PushToken.includes(:user).where("user_id > 0").order("users.email ASC")
  end

  def push_token_test
    @push_token = PushToken.includes(:user).where(id: params[:id]).first rescue nil
    if @push_token
      texto = "Notificación de prueba\nNotificación de prueba2 Notificación de prueba3\n\nNotificación de prueba4 Notificación de prueba5 Notificación de prueba6 Notificación de prueba7 Notificación de prueba8 Notificación de prueba9 Notificación de prueba10 Notificación de prueba11 Notificación de prueba12."
      notificacion = Notificacione.new
      notificacion.tipo = "PUSH_TOKEN_TEST"
      notificacion.destinatario = @push_token.user.email
      notificacion.deviceId = @push_token.deviceId
      notificacion.texto = texto
      notificacion.status = 0
      notificacion.save
      exponent.publish(
        exponentPushToken: @push_token.push_token,
        sound: 'default',
        title: texto.truncate(30),
        message: texto,
        ttl: 600,
        priority: 'high',
        badge: 1,
        data: { a: 'b' }
      )
      notificacion.status = 1
      notificacion.save
      redirect_to notificaciones_push_tokens_path, notice: "Notificación solicitada exitosamente"
    else
      redirect_to notificaciones_push_tokens_path, alert: "Push Token no encontrado"
    end
  end

  private

    def exponent
      @exponent ||= Exponent::Push::Client.new
    end

end
