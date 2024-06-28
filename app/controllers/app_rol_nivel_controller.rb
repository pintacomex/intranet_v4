class AppRolNivelController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app

  def index
    @apps = App.order(:nombre)
    @apps = App.where("id = #{params[:qapp].to_i}") if params.has_key?(:qapp) and params[:qapp].to_i > 0
    @roles = CatRole.order(:nivel)
    @niveles_default = [ [ "Sin Acceso", 0 ], [ "Lectura", 1 ], [ "Escritura", 2 ] ]
    get_app_nivels
    # raise @app_nivels[11].inspect
  end

  def app_rol_nivel_acceso
    @app = params[:app].to_i if params.has_key?(:app)
    @rol = params[:rol].to_i if params.has_key?(:rol)
    @nivel = params[:nivel].to_i if params.has_key?(:nivel)
    url = app_rol_nivel_path
    url = app_rol_nivel_path(qapp: params[:qapp]) if params.has_key?(:qapp) and params[:qapp].to_i > 0
    return redirect_to url, alert: "Los datos son incorrectos" if @app < 1
    AppRolNivel.where("app = #{@app} AND rol = #{@rol}").destroy_all
    return redirect_to url, notice: "Acceso removido exitosamente" if @nivel == 0
    arn = AppRolNivel.create(app: @app, rol: @rol, nivel: @nivel)
    if arn.save
      return redirect_to url, notice: "Acceso guardado exitosamente"
    else
      return redirect_to url, alert: "Ha habido un error guardando el acceso"
    end
  end

  private

    def get_app_nivels
      @app_nivels = {}
      AppNivel.order("app ASC, nivel ASC").each do |an|
        @app_nivels[an.app] = [] if !@app_nivels[an.app]
        @app_nivels[an.app].push([an.descripcion, an.nivel])
      end
    end

end
