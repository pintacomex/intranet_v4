class Supervisiones::CategoriesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app
  before_filter :get_id, only: [:index, :new, :create]
  before_filter :get_id_idcat, only: [:edit, :update, :destroy]

  def index
    sql = "SELECT SupChecklists.* FROM SupChecklists WHERE IdChecklist = #{@id}"
    @checklist = @dbEsta.connection.select_all(sql)
    sql = "SELECT SupCategorias.*, SupChecklists.Nombre as clNombre, SupCampos.IdFldChecklist, count(*) AS CamCount FROM SupCategorias LEFT JOIN SupChecklists ON SupChecklists.IdChecklist = SupCategorias.IdChecklist LEFT JOIN SupCampos ON SupCategorias.IdChecklist = SupCampos.IdChecklist AND SupCategorias.IdCatChecklist = SupCampos.IdCatChecklist WHERE SupCategorias.IdChecklist = #{@id} GROUP BY SupCategorias.IdChecklist, IdCatChecklist ORDER BY SupCategorias.Orden ASC, SupCategorias.IdCatChecklist ASC"
    @categorias = @dbEsta.connection.select_all(sql)
  end

  def new
    @form_url = "/supervisiones/category_create"
  end

  def create
    nombre = params[:nombre] if params.has_key?(:nombre)
    return redirect_to "/supervisiones/category_new", alert: "Ingresa Nombre válido" if nombre.length < 2

    @idcat = 1
    sql = "SELECT max(IdCatChecklist) as maxIdCatChecklist FROM SupCategorias WHERE IdChecklist = #{@id}"
    checklists = @dbEsta.connection.select_all(sql)
    if checklists.count == 1
      @idcat = checklists[0]['maxIdCatChecklist'].to_i + 1 rescue 1
    end
    sql = "INSERT INTO SupCategorias (IdChecklist, IdCatChecklist, Orden, Nombre, Frecuencia, Activo) VALUES ( #{@id}, #{@idcat}, #{params[:orden].to_i}, #{User.sanitize(nombre)}, #{params[:frecuencia].to_i}, #{params[:activo].to_i})"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/supervisiones/category_new?id=#{@id}", alert: "No se ha podido crear la categoría"
    end 
    redirect_to "/supervisiones/categories?id=#{@id}", notice: "Categoría generada exitosamente"    
  end

  def edit
    sql = "SELECT * FROM SupCategorias WHERE IdChecklist = #{@id} AND IdCatChecklist = #{@idcat}"
    @category = @dbEsta.connection.select_all(sql)

    @form_url = "/supervisiones/category_update"
  end

  def update
    nombre = params[:nombre] if params.has_key?(:nombre)
    return redirect_to "/supervisiones/category_edit?id=#{@id}-#{@idcat}", alert: "Ingresa Nombre válido" if nombre.length < 2

    sql = "UPDATE SupCategorias SET Orden = #{params[:orden].to_i}, Nombre = #{User.sanitize(nombre)}, Frecuencia = #{params[:frecuencia].to_i}, Activo = #{params[:activo].to_i} WHERE IdChecklist = #{@id} AND IdCatChecklist = #{@idcat}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/supervisiones/category_edit?id=#{@id}-#{@idcat}", alert: "No se ha podido editar la categoría"
    end 
    redirect_to "/supervisiones/campos?id=#{@id}-#{@idcat}", notice: "Categoría editada exitosamente"    
  end

  def destroy
    sql = "DELETE FROM SupCampos WHERE IdChecklist = #{@id} and IdCatChecklist = #{@idcat}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/supervisiones/checklists", alert: "No se han podido borrar los SupCampos del Checklist"
    end
    sql = "DELETE FROM SupCategorias WHERE IdChecklist = #{@id} and IdCatChecklist = #{@idcat}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/supervisiones/checklists", alert: "No se han podido borrar las Categorías del Checklist"
    end
    redirect_to "/supervisiones/categories?id=#{@id}", notice: "Categoría borrada exitosamente"    
  end

  private

    def get_id
      @id = params[:id].split("-").first.to_i if params.has_key?(:id)
      return redirect_to "/supervisiones/checklists", notice: "Checklist no encontrado" if !@id or @id < 1
    end

    def get_id_idcat
      @id, @idcat = params[:id].split("-").first.to_i, params[:id].split("-")[1].to_i if params.has_key?(:id)
      return redirect_to "/supervisiones/checklists", notice: "Checklist no encontrado" if !@id or @id < 1 or !@idcat or @idcat < 1
    end

end
