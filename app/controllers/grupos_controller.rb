class GruposController < ApplicationController
  before_filter :authenticate_user!
  before_filter :admin_only

  def grupos
    sql = "SELECT GruposHGrupos.*, GruposDGrupos.IdUser, count(*) AS GCount FROM GruposHGrupos LEFT JOIN GruposDGrupos ON GruposHGrupos.IdGrupo = GruposDGrupos.IdGrupo GROUP BY GruposHGrupos.IdGrupo ORDER BY GruposHGrupos.Nombre DESC LIMIT 100"
    @grupos = @dbEsta.connection.select_all(sql)
    sql = "SELECT GruposHGrupos.IdGrupo, GruposHGrupos.Nombre, GruposDGrupos.IdUser, GruposDGrupos.RolUser, '' as userEmail, '' as userName FROM GruposDGrupos LEFT JOIN GruposHGrupos ON GruposHGrupos.IdGrupo = GruposDGrupos.IdGrupo ORDER BY GruposHGrupos.Nombre DESC, GruposDGrupos.RolUser DESC, GruposDGrupos.IdUser ASC LIMIT 100"
    @grupos_det = @dbEsta.connection.select_all(sql)
    @grupos_det.each do |a|
      if a['IdUser'].to_i > 0
        u = User.where("id = #{a['IdUser']}").first
        a['userEmail'] = u.email rescue ''
        a['userName']  = u.name rescue ''
      end
    end
  end

  def grupos_new
  end

  def grupos_create
    nombre = params[:nombre] if params.has_key?(:nombre)
    return redirect_to "/grupos_new", alert: "Ingresa Nombre válido" if nombre.length < 2

    id = 1
    sql = "SELECT max(IdGrupo) as maxIdGrupo FROM GruposHGrupos"
    grupos = @dbEsta.connection.select_all(sql)
    if grupos.count == 1
      id = grupos[0]['maxIdGrupo'].to_i + 1 rescue 1
    end
    sql = "INSERT INTO GruposHGrupos (IdGrupo, Nombre) VALUES ( #{id}, #{User.sanitize(nombre)})"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/grupos_new", alert: "No se ha podido crear el grupo"
    end
    redirect_to "/grupos", notice: "Grupo generado exitosamente"    
  end

  def grupos_edit
    id = params[:id].to_i if params.has_key?(:id)
    return redirect_to "/grupos", notice: "Grupo no encontrado" if !id or id < 1

    sql = "SELECT GruposHGrupos.* FROM GruposHGrupos WHERE IdGrupo = #{id}"
    @grupo = @dbEsta.connection.select_all(sql)
    sql = "SELECT GruposDGrupos.*, GruposHGrupos.Nombre FROM GruposDGrupos LEFT JOIN GruposHGrupos ON GruposHGrupos.IdGrupo = GruposDGrupos.IdGrupo WHERE GruposDGrupos.IdGrupo = #{User.sanitize(id)} ORDER BY GruposDGrupos.IdUser DESC"
    @dgrupo = @dbEsta.connection.select_all(sql)
    @grupo_users = @dgrupo.map{|u| u['IdUser']}.reject{ |u| u.to_i < 1 }
    @users = User.order(:name).map{|u| ["#{u.name.to_s.gsub(" - ", " ")}", u.id]}
    @users = User.joins("LEFT JOIN permisos ON users.id = permisos.idUsuario").where("permisos.id > 0").order(:name).map{|u| ["Usuario: #{u.name.to_s.gsub(" - ", " ")}", u.id]}.uniq

  end

  def grupos_update
    id = params[:id].to_i if params.has_key?(:id)
    nombre = params[:nombre] if params.has_key?(:nombre)
    return redirect_to "/grupos", notice: "Grupo no encontrado" if !id or id < 1
    return redirect_to "/grupos_edit", alert: "Ingresa Nombre válido" if nombre.length < 2
    sql = "INSERT INTO GruposHGrupos (IdGrupo, Nombre) VALUES ( #{id}, #{User.sanitize(nombre)}) ON DUPLICATE KEY UPDATE Nombre = #{User.sanitize(nombre)}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/grupos_edit?id=#{id}", alert: "No se ha podido guardar el grupo"
    end
    sql = "DELETE FROM GruposDGrupos WHERE IdGrupo = #{id}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/grupos_edit?id=#{id}", alert: "No se han podido borrar los integrantes del grupo"
    end
    users = []
    users = params[:users] if params.has_key?(:users)
    users = users.select{ |u| u.to_s.to_i > 0 }
    if users.count > 0
      sql = "INSERT INTO GruposDGrupos (IdGrupo, IdUser) VALUES (#{id},#{users.join("),(#{id},")})"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/grupos_edit?id=#{id}", alert: "No se han podido guardar los integrantes del grupo"
      end
    end
    redirect_to "/grupos", notice: "Grupo editado exitosamente"    
  end

  def grupos_destroy
    id = params[:id].to_i if params.has_key?(:id)
    return redirect_to "/grupos", notice: "Grupo no encontrado" if !id or id < 1
    sql = "DELETE FROM GruposDGrupos WHERE IdGrupo = #{id}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/grupos_edit?id=#{id}", alert: "No se han podido borrar los integrantes del grupo"
    end
    sql = "DELETE FROM GruposHGrupos WHERE IdGrupo = #{id}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/grupos_edit?id=#{id}", alert: "No se ha podido borrar el grupo"
    end
    redirect_to "/grupos", notice: "Grupo borrado exitosamente"    
  end

  def grupos_update_rol
    id_grupo = params[:IdGrupo].to_i if params.has_key?(:IdGrupo)
    id_user = params[:IdUser].to_i if params.has_key?(:IdUser)
    rol_user = params[:RolUser].to_i if params.has_key?(:RolUser)
    sql = "UPDATE GruposDGrupos SET RolUser = #{rol_user} WHERE IdGrupo = #{id_grupo} AND IdUser = #{id_user}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/grupos", alert: "No se ha podido cambiar el rol"
    end
    return redirect_to "/grupos", notice: "Nuevo rol realizado exitosamente"
  end
end







