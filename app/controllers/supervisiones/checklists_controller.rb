class Supervisiones::ChecklistsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app
  before_filter :get_id, only: [:edit, :update, :destroy]

  def index
    sql = "SELECT SupChecklists.*, SupCategorias.IdCatChecklist, count(*) AS CatCount FROM SupChecklists LEFT JOIN SupCategorias ON SupChecklists.IdChecklist = SupCategorias.IdChecklist GROUP BY SupChecklists.IdChecklist ORDER BY SupChecklists.Nombre DESC LIMIT 100"
    @checklists = @dbEsta.connection.select_all(sql)
    @subtiposucs = @dbComun.connection.select_all("SELECT * FROM subtiposuc ORDER BY Nombre").map{|u| ["#{u['SubTipoSuc']} - #{u['Nombre']}", "#{u['SubTipoSuc']}"]}.uniq rescue []
  end

  def new
    @form_url = "/supervisiones/checklist_create"
    @subtiposucs = @dbComun.connection.select_all("SELECT * FROM subtiposuc ORDER BY Nombre").map{|u| ["#{u['SubTipoSuc']} - #{u['Nombre']}", "#{u['SubTipoSuc']}"]}.uniq rescue []
    @dbComun.connection.select_all("SELECT * FROM sucursal WHERE TipoSuc = 'S' ORDER BY Num_suc").map{|u| ["- Sucursal: #{u['Num_suc']} - #{u['Nombre']}", "#{u['Num_suc']}"]}.uniq rescue []
  end

  def create
    nombre = params[:nombre] if params.has_key?(:nombre)
    subtiposuc = params[:subtiposuc] if params.has_key?(:subtiposuc)
    return redirect_to "/supervisiones/checklist_new", alert: "Ingresa Nombre válido" if nombre.length < 2

    id = 1
    sql = "SELECT max(IdChecklist) as maxIdChecklist FROM SupChecklists"
    checklists = @dbEsta.connection.select_all(sql)
    if checklists.count == 1
      id = checklists[0]['maxIdChecklist'].to_i + 1 rescue 1
    end
    sql = "INSERT INTO SupChecklists (IdChecklist, Nombre, SubTipoSuc) VALUES ( #{id}, #{User.sanitize(nombre)}, #{User.sanitize(subtiposuc)})"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/supervisiones/checklist_new", alert: "No se ha podido crear el checklist"
    end
    redirect_to "/supervisiones/checklists", notice: "Checklist creado exitosamente"    
  end

  def edit
    sql = "SELECT * FROM SupChecklists WHERE IdChecklist = #{@id}"
    @checklist = @dbEsta.connection.select_all(sql)
    @subtiposucs = @dbComun.connection.select_all("SELECT * FROM subtiposuc ORDER BY Nombre").map{|u| ["#{u['SubTipoSuc']} - #{u['Nombre']}", "#{u['SubTipoSuc']}"]}.uniq rescue []
    @form_url = "/supervisiones/checklist_update"
  end

  def update
    nombre = params[:nombre] if params.has_key?(:nombre)
    subtiposuc = params[:subtiposuc] if params.has_key?(:subtiposuc)
    return redirect_to "/supervisiones/checklist_edit", alert: "Ingresa Nombre válido" if nombre.length < 2

    sql = "UPDATE SupChecklists SET Nombre = #{User.sanitize(nombre)}, SubTipoSuc = #{User.sanitize(subtiposuc)} WHERE IdChecklist = #{@id}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/supervisiones/categories?id=#{@id}", alert: "No se ha podido editar el Checklist"
    end 
    redirect_to "/supervisiones/categories?id=#{@id}", notice: "Checklist editado exitosamente"    
  end

  def destroy
    sql = "DELETE FROM SupCampos WHERE IdChecklist = #{@id}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/supervisiones/checklists", alert: "No se han podido borrar los Campos del Checklist"
    end
    sql = "DELETE FROM SupCategorias WHERE IdChecklist = #{@id}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/supervisiones/checklists", alert: "No se han podido borrar las Categorías del Checklist"
    end
    sql = "DELETE FROM SupChecklists WHERE IdChecklist = #{@id}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/supervisiones/checklists", alert: "No se han podido borrar el Checklist"
    end    
    redirect_to "/supervisiones/checklists", notice: "Checklist borrado exitosamente"    
  end

  private

    def get_id
      @id = params[:id].to_i if params.has_key?(:id)
      return redirect_to "/supervisiones/checklists", notice: "Checklist no encontrado" if !@id or @id < 1
    end
end
