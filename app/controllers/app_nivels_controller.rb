class AppNivelsController < InheritedResources::Base
  before_filter :authenticate_user!
  before_filter :admin_only
  before_filter :get_catalogos

  def index
    @app_nivels = AppNivel.select("app_nivels.*, apps.nombre").joins("LEFT JOIN apps ON app_nivels.app = apps.id").order("nombre ASC, nivel ASC").page(params[:page]).per(50)
  end

  def show
  	flash.keep
  	redirect_to "/app_nivels"
  end

  private

    def app_nivel_params
      params.require(:app_nivel).permit(:app, :nivel, :descripcion)
    end

    def get_catalogos
      @apps = App.order(:nombre).collect{ |c| ["#{c.nombre}", c.id] }
    end
end

