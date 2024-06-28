class Notificaciones::WebhooksController < InheritedResources::Base
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app

  def index
    @webhooks = Webhook.order("name ASC").page(params[:page]).per(50)
  end

  def show
  	flash.keep
  	redirect_to "/notificaciones/webhooks"
  end

  private

    def webhook_params
      params.require(:webhook).permit(:name, :value)
    end
end

