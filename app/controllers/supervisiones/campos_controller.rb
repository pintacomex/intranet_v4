class Supervisiones::CamposController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app
  before_filter :get_id_idcat
  before_filter :get_idcampo, only: [:edit, :destroy]
  before_filter :get_niveles, only: [:index, :new, :create, :edit, :update]

  def index
    sql = "SELECT * FROM SupChecklists WHERE IdChecklist = #{@id}"
    @checklist = @dbEsta.connection.select_all(sql)
    sql = "SELECT * FROM SupCategorias WHERE IdChecklist = #{@id} AND IdCatChecklist = #{@idcat}"
    @category = @dbEsta.connection.select_all(sql)
    sql = "SELECT * FROM SupCampos WHERE IdChecklist = #{@id} AND IdCatChecklist = #{@idcat} ORDER BY Orden ASC, IdFldChecklist ASC"
    @campos = @dbEsta.connection.select_all(sql)  
  end

  def new
    @form_url = "/supervisiones/campo_create"
  end

  def create
    nombre, descripcion = params[:nombre], params[:descripcion] if params.has_key?(:nombre) && params.has_key?(:descripcion)
    return redirect_to "/supervisiones/campo_new?id=#{@id}-{@idcat}", alert: "Ingresa Nombre y Descripcion válidos" if nombre.length < 2 || descripcion.length < 2

    idcampo = 1
    sql = "SELECT max(IdFldChecklist) as maxIdFldChecklist FROM SupCampos WHERE IdChecklist = #{@id} AND IdCatChecklist = #{@idcat}"
    checklists = @dbEsta.connection.select_all(sql)
    if checklists.count == 1
      idcampo = checklists[0]['maxIdFldChecklist'].to_i + 1 rescue 1
    end
    todosi = params[:todosi].join(",") rescue ""
    todono = params[:todono].join(",") rescue ""
    sql = "INSERT INTO SupCampos (IdChecklist, IdCatChecklist, IdFldChecklist, Orden, Nombre, Descripcion, OpcionNA, PuntosSi, ToDoSi, PuntosNo, ToDoNo, Activo) VALUES ( #{@id}, #{@idcat}, #{idcampo}, #{params[:orden].to_i}, #{User.sanitize(nombre)}, #{User.sanitize(descripcion)}, #{params[:opcionna].to_i}, #{params[:puntossi].to_i}, #{User.sanitize(todosi)}, #{params[:puntosno].to_i}, #{User.sanitize(todono)}, #{params[:activo].to_i})"   
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/supervisiones/campo_new?id=#{@id}-#{@idcat}", alert: "No se ha podido crear el campo"
    end 
    redirect_to "/supervisiones/campos?id=#{@id}-#{@idcat}", notice: "Campo generado exitosamente"    
  end

  def edit
    sql = "SELECT * FROM SupCampos WHERE IdChecklist = #{@id} AND IdCatChecklist = #{@idcat} AND IdFldChecklist = #{@idcampo}"
    @campo = @dbEsta.connection.select_all(sql)
    @form_url = "/supervisiones/campo_update"
  end

  def update
    nombre, descripcion = params[:nombre], params[:descripcion] if params.has_key?(:nombre) && params.has_key?(:descripcion)
    return redirect_to "/supervisiones/campo_new?id=#{@id}-{@idcat}", alert: "Ingresa Nombre y Descripcion válidos" if nombre.length < 2 || descripcion.length < 2

    todosi = params[:todosi].join(",") rescue ""
    todono = params[:todono].join(",") rescue ""
    sql = "UPDATE SupCampos SET Orden = #{params[:orden].to_i}, Nombre = #{User.sanitize(nombre)}, Descripcion = #{User.sanitize(descripcion)}, OpcionNA = #{params[:opcionna].to_i}, PuntosSi = #{params[:puntossi].to_i}, ToDoSi = #{User.sanitize(todosi)}, PuntosNo = #{params[:puntosno].to_i}, ToDoNo = #{User.sanitize(todono)}, Activo = #{params[:activo].to_i} WHERE IdChecklist = #{params[:IdChecklist].to_i} AND IdCatChecklist = #{params[:IdCatChecklist].to_i} AND IdFldChecklist = #{params[:IdFldChecklist].to_i}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/supervisiones/campo_new?id=#{@id}-#{@idcat}", alert: "No se ha podido editar el campo"
    end 
    redirect_to "/supervisiones/campos?id=#{@id}-#{@idcat}", notice: "Campo editado exitosamente"    
  end  

  def destroy
    sql = "DELETE FROM SupCampos WHERE IdChecklist = #{@id} and IdCatChecklist = #{@idcat} and IdFldChecklist = #{@idcampo}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/supervisiones/checklists", alert: "No se han podido borrar los SupCampos del Checklist"
    end
    redirect_to "/supervisiones/campos?id=#{@id}-#{@idcat}", notice: "Campo borrado exitosamente"    
  end

  private

    def get_id_idcat
      @id, @idcat = params[:id].split("-").first.to_i, params[:id].split("-")[1].to_i if params.has_key?(:id)
      return redirect_to "/supervisiones/checklists", notice: "Checklist no encontrado" if !@id or @id < 1 or !@idcat or @idcat < 1
    end

    def get_idcampo
      @idcampo = params[:id].split("-")[2].to_i if params.has_key?(:id)
      return redirect_to "/supervisiones/checklists", notice: "Checklist no encontrado" if !@idcampo or @idcampo < 1
    end

    def get_niveles
      # @niveles = [["Vendedor de Sucursal", 1],
      #             ["Encargado", 2],
      #             ["Supervisor", 3],
      #             ["Gerente Regional", 5],
      #             ["Director de Operaciones", 4],
      #             ["Director", 7],
      #             ["CXC", 6],
      #             ["Auditor", 9],
      #             ["Gerente de Auditoría", 10],
      #             ["Ventas", 11],
      #             ["Gerente de Ventas", 12],
      #             ["Normatividad", 15],
      #             ["Director de Normatividad", 16],
      #             ["Administración", 19],
      #             ["Director de Administración", 20],
      #             ["Sistemas", 23],
      #             ["Director de Sistemas", 24],
      #             ["Recursos Humanos", 27],
      #             ["Director de Recursos Humanos", 28]]
      @niveles = CatRole.order(:nivel).collect{ |c| [c.nomPermiso, c.nivel] }
    end

end
