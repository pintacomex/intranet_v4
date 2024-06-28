class Auths::FlujosController < ApplicationController
  before_filter :authenticate_user!
  before_filter :admin_only
  before_filter :find_flujo, only: [:show, :destroy]
  before_filter :obtiene_catalogos

  def index
    sql = "SELECT AuthsFlujos.*, '' as NombreUsuario FROM AuthsFlujos ORDER BY IdTipoSolicitud, NivelActual, IdUsuario"
    @flujos = @dbEsta.connection.select_all(sql)
    @flujos.each do |a|
      if a['IdUsuario'].to_i > 0
        u = User.where("id = #{User.sanitize(a['IdUsuario'])}").first
        a['NombreUsuario'] = u.name rescue ''
      end
    end
  end

  def new
    @new = true
    @flujo = {}
    @flujo['IdTipoSolicitud'] = 1
    @flujo['NivelActual'] = 0
    @flujo['IdUsuario'] = 2
    @flujo['DebeAutorizar'] = 0
    @flujo['NivelFuturo'] = 80
  end

  def create
    create_or_update
  end

  def show
  end

  def destroy
    sql = "DELETE FROM AuthsFlujos WHERE IdTipoSolicitud = #{User.sanitize(@id.first)} AND NivelActual = #{User.sanitize(@id[1])} AND IdUsuario = #{User.sanitize(@id.last)}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      redirect_to "/auths/flujos", alert: "No se ha podido borrar el flujo. Error: #{exc.message}"
    end
    redirect_to "/auths/flujos", notice: "Flujo borrado exitosamente"
  end

  private

    def find_flujo
      @id = params[:id].to_s.split("-")
      sql = "SELECT AuthsFlujos.*, '' as NombreUsuario FROM AuthsFlujos WHERE IdTipoSolicitud = #{User.sanitize(@id.first)} AND NivelActual = #{User.sanitize(@id[1])} AND IdUsuario = #{User.sanitize(@id.last)} LIMIT 1"
      @flujo = @dbEsta.connection.select_all(sql).first rescue false
      redirect_to '/' unless @flujo
      if @flujo['IdUsuario'].to_i > 0
        u = User.where("id = #{User.sanitize(@flujo['IdUsuario'])}").first
        @flujo['NombreUsuario'] = u.name rescue 'Usuario No Encontrado'
      end
    end

    def obtiene_catalogos
      @tipo_solicitudes = @dbEsta.connection.select_all("SELECT AuthsTipoSolicitudes.* FROM AuthsTipoSolicitudes ORDER BY IdTipoSolicitud").map{|u| ["#{u['IdTipoSolicitud']} - #{u['Nombre'].to_s}", "#{u['IdTipoSolicitud']}"]}.uniq
      @niveles = [["00 - Creada", "0"]]
      @niveles = @niveles.concat((1..20).map{|i| ["#{format('%02d', i)} - En Proceso Nivel #{i}", "#{i}"]})
      @niveles = @niveles.concat((59..69).map{|i| ["#{i} - Rechazada", "#{i}"]})
      @niveles = @niveles.concat((80..99).map{|i| ["#{i} - Aprobada", "#{i}"]})
      @usuarios = User.joins("LEFT JOIN permisos ON users.id = permisos.idUsuario").where("permisos.id > 0").order(:name).map{|u| ["#{u.name.to_s.gsub(" - ", " ")}", "#{u.id}"]}.uniq
    end

    def create_or_update
      @new = params[:new] == "true"
      @id_tipo_solicitud = params[:idtiposolicitud].to_i
      @nivel_actual = params[:nivelactual].to_i
      @id_usuario = params[:idusuario].to_i
      @debe_autorizar = params[:debeautorizar].to_i
      @nivel_futuro = params[:nivelfuturo].to_i
      @flujo = {}
      @flujo['IdTipoSolicitud'] = @id_tipo_solicitud
      @flujo['NivelActual'] = @nivel_actual
      @flujo['IdUsuario'] = @id_usuario
      @flujo['DebeAutorizar'] = @debe_autorizar
      @flujo['NivelFuturo'] = @nivel_futuro
      sql = "INSERT INTO AuthsFlujos (IdTipoSolicitud, NivelActual, IdUsuario, DebeAutorizar, NivelFuturo) VALUES ( #{User.sanitize(@id_tipo_solicitud)}, #{User.sanitize(@nivel_actual)}, #{User.sanitize(@id_usuario)}, #{User.sanitize(@debe_autorizar)}, #{User.sanitize(@nivel_futuro)} ) ON DUPLICATE KEY UPDATE DebeAutorizar = #{User.sanitize(@debe_autorizar)}, NivelFuturo = #{User.sanitize(@nivel_futuro)}"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        flash[:alert] = "No se ha podido #{@new ? "crear" : "editar"} el flujo. Error: #{exc.message}"
        return render 'edit'
      end
      redirect_to "/auths/flujos/#{@id_tipo_solicitud}-#{@nivel_actual}-#{@id_usuario}", notice: "Flujo #{@new ? "creado" : "editado"} exitosamente"
    end
end

