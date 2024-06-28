class Auths::TipoSolicitudesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :admin_only
  before_filter :find_solicitud, only: [:edit, :update, :show, :destroy]
  before_filter :obtiene_catalogos, only: [:new, :create, :edit, :update]

  def index
    sql = "SELECT AuthsTipoSolicitudes.* FROM AuthsTipoSolicitudes ORDER BY IdTipoSolicitud"
    @solicitudes = @dbEsta.connection.select_all(sql)
  end

  def new
    @new = true
    @solicitud = {}
    @solicitud['IdTipoSolicitud'] = 1
    @solicitud['Nombre'] = ''
  end

  def edit
    @new = false
  end

  def create
    create_or_update
  end

  def update
    create_or_update
  end

  def show
  end

  def destroy
    sql = "DELETE FROM AuthsTipoSolicitudes WHERE IdTipoSolicitud = #{User.sanitize(@id.first)} AND Nombre = #{User.sanitize(@id.last)}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      redirect_to "/auths/solicitudes", alert: "No se ha podido borrar el solicitud. Error: #{exc.message}"
    end
    redirect_to "/auths/solicitudes", notice: "Tipo de Solicitud borrado exitosamente"
  end

  private

    def find_solicitud
      @id = params[:id].to_i
      sql = "SELECT AuthsTipoSolicitudes.* FROM AuthsTipoSolicitudes WHERE IdTipoSolicitud = #{User.sanitize(@id)} LIMIT 1"
      @solicitud = @dbEsta.connection.select_all(sql).first rescue false
      redirect_to '/' unless @solicitud
    end

    def obtiene_catalogos
    end

    def create_or_update
      @new = params[:new] == "true"
      @id_solicitud = params[:idsolicitud].to_i
      @id_solicitud = get_id if @new && @id_solicitud == 0
      @nombre = params[:nombre].to_s
      @solicitud = {}
      @solicitud['IdTipoSolicitud'] = @id_solicitud
      @solicitud['Nombre'] = @nombre
      if @nombre == ''
        flash[:alert] = "Nombre inválido"
        return render 'edit'
      end
      sql = "INSERT INTO AuthsTipoSolicitudes (IdTipoSolicitud, Nombre) VALUES ( #{User.sanitize(@id_solicitud)}, #{User.sanitize(@nombre)} ) ON DUPLICATE KEY UPDATE Nombre = #{User.sanitize(@nombre)}"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        flash[:alert] = "No se ha podido #{@new ? "crear" : "editar"} el tipo de solicitud. Error: #{exc.message}"
        return render 'edit'
      end
      redirect_to "/auths/tipo_solicitudes/#{@id_solicitud}", notice: "Tipo de Solicitud #{@new ? "creado" : "editado"} exitosamente"
    end

    def get_id
      id = 1
      ids = @dbEsta.connection.select_all("SELECT max(IdTipoSolicitud) as mid FROM AuthsTipoSolicitudes")
      id = ids.first['mid'].to_i + 1 if ids.count == 1
      id
    end
end

