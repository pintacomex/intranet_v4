class Supervisiones::SupervisionesController < ApplicationController
  include TodosHelper
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app
  before_filter :get_id, only: [:edit, :update, :destroy]
  before_filter :get_checklists, only: [:load_sucs, :load_cats]
  before_filter :get_checklists_cats_sucs, only: [:nueva_supervision, :programar_supervisiones, :supervisiones_por_programar]

  def root
    return redirect_to "/supervisiones/programadas"
  end

  def programadas
    @puede_supervisar = false
    @puede_supervisar = true if get_current_user_app_nivel >= 3
    get_filtros
  	@filtros.push("SupCalendarios.FechaProgramada > '#{(Date.today - 1.month).to_s}'")
  	@filtros.push("SupCalendarios.FechaProgramada < '#{(Date.today + 3.month).to_s}'")
    get_filtros_from_user_for_supcalendarios
  	@supervisiones = @dbEsta.connection.select_all("SELECT SupCalendarios.*, s.Nombre, ck.Nombre as ckNombre, cat.Nombre as catNombre, '' as nomUser FROM SupCalendarios LEFT JOIN #{@nomDbComun}sucursal as s ON s.Num_suc = SupCalendarios.Sucursal LEFT JOIN SupChecklists as ck ON ck.IdChecklist = SupCalendarios.IdChecklist LEFT JOIN SupCategorias as cat ON cat.IdChecklist = SupCalendarios.IdChecklist AND cat.IdCatChecklist = SupCalendarios.IdCatChecklist LEFT JOIN Supervisiones as sup ON SupCalendarios.Sucursal = sup.IdCalendario WHERE ( ( #{@filtros.join(" ) AND ( ")} ) ) GROUP BY Sucursal, FechaProgramada, IdChecklist, IdCatChecklist, IdUser, Tipo ORDER BY SupCalendarios.FechaProgramada ASC LIMIT 50") rescue []
  	@supervisiones.each do |a|
      if a['IdUser'].to_i > 0
        u = User.where("id = #{a['IdUser']}").first
        a['nomUser'] = u.name.to_s.gsub(" - ", " ") rescue 'No encontrado'
      end
    end
  end

  def terminadas
  	get_filtros
    get_filtros_from_user_for_supervisiones
    @supervisiones = @dbEsta.connection.select_all("SELECT Supervisiones.*, s.Nombre, ck.Nombre as ckNombre, cat.Nombre as catNombre, '' as nomUser FROM Supervisiones LEFT JOIN #{@nomDbComun}sucursal as s ON s.Num_suc = Supervisiones.Sucursal LEFT JOIN SupChecklists as ck ON ck.IdChecklist = Supervisiones.IdChecklist LEFT JOIN SupCategorias as cat ON cat.IdChecklist = Supervisiones.IdChecklist AND cat.IdCatChecklist = Supervisiones.IdCatChecklists WHERE ( #{@filtros.join(" ) AND ( ")} ) AND Status = 2 ORDER BY FechaTerminacion DESC, IdVisita DESC LIMIT 50") rescue []
  	@supervisiones.each do |a|
      if a['IdUser'].to_i > 0
        u = User.where("id = #{a['IdUser']}").first
        a['nomUser'] = u.name.to_s.gsub(" - ", " ") rescue 'No encontrado'
      end
    end   	
  end

  def supervision_terminada
  	@sucursal  = params[:sucursal].to_i  if params.has_key?(:sucursal)
  	@id_visita = params[:id_visita].to_i if params.has_key?(:id_visita)
  	url = "/supervisiones/programadas"
  	get_filtros
  	return redirect_to url, alert: "Datos incorrectos" if !@sucursal or @sucursal < 1 or !@id_visita or @id_visita < 1
    @supervision = @dbEsta.connection.select_all("SELECT Supervisiones.*, s.Nombre, ck.Nombre as ckNombre FROM Supervisiones LEFT JOIN #{@nomDbComun}sucursal as s ON s.Num_suc = Supervisiones.Sucursal LEFT JOIN SupChecklists as ck ON ck.IdChecklist = Supervisiones.IdChecklist WHERE Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)} AND ( #{@filtros.join(" ) AND ( ")} ) AND Status = 2 LIMIT 1") rescue []
    return redirect_to url, alert: "Supervisión no encontrada" if @supervision.count != 1
    @supervision = @supervision.first
    @dsupervisiones = @dbEsta.connection.select_all("SELECT SupDSupervisiones.*, cat.Nombre as catNombre, fld.Nombre as fldNombre, fld.Descripcion as fldDescripcion, fld.OpcionNA as fldOpcionNA, fld.PuntosSi as fldPuntosSi, fld.ToDoSi as fldToDoSi, fld.PuntosNo as fldPuntosNo, fld.ToDoNo as fldToDoNo FROM SupDSupervisiones LEFT JOIN SupCategorias as cat ON cat.IdChecklist = SupDSupervisiones.IdChecklist AND cat.IdCatChecklist = SupDSupervisiones.IdCatChecklist LEFT JOIN SupCampos as fld ON fld.IdChecklist = SupDSupervisiones.IdChecklist AND fld.IdCatChecklist = SupDSupervisiones.IdCatChecklist AND fld.IdFldChecklist = SupDSupervisiones.IdCampo WHERE Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)}") rescue []
    return redirect_to url, alert: "Detalle de Supervisión no encontrada" if @dsupervisiones.count < 1
    obtiene_catalogos
    @imgs = {}
    @chat_comments = {}
  	@dsupervisiones.each do |d| 
      @chat_comments["#{d['IdChecklist']}-#{d['IdCatChecklist']}-#{d['IdCampo']}"] = @dbEsta.connection.select_all("SELECT SupComentarios.*, '' as userEmail, '' as userName FROM SupComentarios WHERE Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)} AND IdChecklist = #{User.sanitize(d['IdChecklist'])} AND IdCatChecklist = #{User.sanitize(d['IdCatChecklist'])} AND IdCampo = #{User.sanitize(d['IdCampo'])} ORDER BY FechaHora")
      @chat_comments["#{d['IdChecklist']}-#{d['IdCatChecklist']}-#{d['IdCampo']}"].each do |a|
        if a['IdUser'].to_i > 0
            u = User.where("id = #{a['IdUser']}").first
            a['userEmail'] = u.email rescue ''
            a['userName']  = u.name rescue ''
        end
      end
      @imgs["#{d['IdChecklist']}-#{d['IdCatChecklist']}-#{d['IdCampo']}"] = SupImagen.where("Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)} AND IdChecklist = #{User.sanitize(d['IdChecklist'])} AND IdCatChecklist = #{User.sanitize(d['IdCatChecklist'])} AND IdCampo = #{User.sanitize(d['IdCampo'])}")
    end  
  end

  def nueva_supervision
    return redirect_to "/", alert: "No Autorizado" if get_current_user_app_nivel < 3
  end

  def nueva_supervision_create
  	@sucursal  = params[:sucursal].to_i  if params.has_key?(:sucursal)
  	@checklist = params[:checklist].to_i if params.has_key?(:checklist)
  	@categoria = params[:categoria].to_i if params.has_key?(:categoria)
  	url = "/supervisiones/nueva_supervision"
  	if @sucursal and @checklist and @categoria and @sucursal > 0 and @checklist > 0 and @categoria > 0
  	  return redirect_to "/supervisiones/crear_supervision?s=#{@sucursal}_2000-01-01_#{@checklist}_#{@categoria}&tipo=nueva"
  	else
  	  return redirect_to url, alert: "Datos incorrectos"
  	end  	
  end

  def crear_supervision
  	# Crea una supervision nueva, ya sea programada o no
    return redirect_to "/", alert: "No Autorizado" if get_current_user_app_nivel < 3
  	url = "/supervisiones/programadas"
  	@s = params[:s] if params.has_key?(:s)
  	return redirect_to url, alert: "Supervisión no encontrada" if !@s
  	@sucursal = @s.split("_")[0].to_i rescue 0
  	@fecha_programada  = @s.split("_")[1] rescue ""
  	@id_checklist      = @s.split("_")[2].to_i rescue 0
  	@id_cat_checklists = @s.split("_")[3].to_s rescue ""
  	return redirect_to url, alert: "Datos incorrectos" if @sucursal < 1 or @fecha_programada == "" or @id_checklist < 1 or @id_cat_checklists == ""
  	@tipo = params[:tipo] if params.has_key?(:tipo)
  	if @tipo == "nueva" or @tipo == "programada"
  	  # Aqui debe crearse la supervision y tal vez tambien los detalles de la supervision
      @checklists = @dbEsta.connection.select_all("SELECT SupChecklists.* FROM SupChecklists WHERE IdChecklist = #{User.sanitize(@id_checklist)}") rescue []
      return redirect_to url, alert: "Checklist No Encontrado" if @checklists.count != 1
      where_cats = ""
      where_cats = "AND IdCatChecklist = #{User.sanitize(@id_cat_checklists.to_i)}" if @id_cat_checklists.to_i > 0
      if @id_cat_checklists.split(",").count > 1
      	where_cats = "AND ( ( IdCatChecklist = #{@id_cat_checklists.split(",").map{ |c| User.sanitize(c.to_i) }.join(" ) OR ( IdCatChecklist = ")} ) )"
      end
      @categorias = @dbEsta.connection.select_all("SELECT SupCategorias.* FROM SupCategorias WHERE IdChecklist = #{User.sanitize(@id_checklist)} AND SupCategorias.Activo = 1 #{where_cats}") rescue []
      return redirect_to url, alert: "No se han encontrado SupCategorias para ese Checklist" if @categorias.count < 1

      @id_visita = 1
      @supervisiones = @dbEsta.connection.select_all("SELECT Supervisiones.* FROM Supervisiones WHERE Sucursal = #{User.sanitize(@sucursal)} ORDER BY IdVisita DESC LIMIT 1") rescue []
      if @supervisiones.count == 1
	    @id_visita = @supervisiones.first['IdVisita'].to_i + 1
	  end
	  sql = "DELETE FROM SupDSupervisiones WHERE Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{@id_visita}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to url, alert: "No se han podido borrar las SupDSupervisiones previas"
    end
    @categorias.each do |cat|
    	campos = @dbEsta.connection.select_all("SELECT * FROM SupCampos WHERE IdChecklist = #{User.sanitize(@id_checklist)} AND IdCatChecklist = #{cat['IdCatChecklist']} AND SupCampos.Activo = 1 ORDER BY Orden ASC, IdFldChecklist ASC") rescue []
    	campos.each do |campo|
    	  sql = "INSERT INTO SupDSupervisiones (Sucursal, IdVisita, IdChecklist, IdCatChecklist, IdCampo) VALUES (#{User.sanitize(@sucursal)}, #{@id_visita}, #{User.sanitize(@id_checklist)}, #{cat['IdCatChecklist']}, #{campo['IdFldChecklist']})"
        begin
          @dbEsta.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to url, alert: "No se ha podido hacer un insert de SupDSupervisiones"
        end
    	end
    end
    id_calendario = ""
    id_calendario = @s if @tipo == "programada"
    sql = "INSERT INTO Supervisiones (Sucursal, IdVisita, IdChecklist, IdCatChecklists, FechaInicio, IdUser, IdCalendario ) VALUES (#{User.sanitize(@sucursal)}, #{@id_visita}, #{User.sanitize(@id_checklist)}, #{User.sanitize(@id_cat_checklists)}, '#{Date.today.to_s}', #{current_user.id}, #{User.sanitize(id_calendario)} )"
	  begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to url, alert: "No se ha podido hacer el insert en Supervisiones"
      end
      if @tipo == "programada"
	    sql = "DELETE FROM SupCalendarios WHERE Sucursal = #{User.sanitize(@sucursal)} AND FechaProgramada = #{User.sanitize(@fecha_programada)} AND IdChecklist = #{User.sanitize(@id_checklist)} AND IdCatCheckList = #{User.sanitize(@id_cat_checklists)}"
        begin
          @dbEsta.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to url, alert: "No se ha podido borrar de SupCalendario"
        end      
      end
      # Todo bien! Se redirecciona a la Supervision
      return redirect_to "/supervisiones/supervision_en_curso?sucursal=#{@sucursal}&id_visita=#{@id_visita}"
  	end
  end

  def supervisiones_en_curso
    return redirect_to "/", alert: "No Autorizado" if get_current_user_app_nivel < 3
  	get_filtros
    # El usuario solo puede ver las supervisiones hechas por el mismo
    @filtros.push("Supervisiones.IdUser = #{current_user.id}")
    @supervisiones = @dbEsta.connection.select_all("SELECT Supervisiones.*, s.Nombre, ck.Nombre as ckNombre, cat.Nombre as catNombre, '' as nomUser FROM Supervisiones LEFT JOIN #{@nomDbComun}sucursal as s ON s.Num_suc = Supervisiones.Sucursal LEFT JOIN SupChecklists as ck ON ck.IdChecklist = Supervisiones.IdChecklist LEFT JOIN SupCategorias as cat ON cat.IdChecklist = Supervisiones.IdChecklist AND cat.IdCatChecklist = Supervisiones.IdCatChecklists WHERE ( #{@filtros.join(" ) AND ( ")} ) AND Status = 0 ORDER BY FechaTerminacion DESC, IdVisita DESC LIMIT 50") rescue []
  	@supervisiones.each do |a|
      if a['IdUser'].to_i > 0
        u = User.where("id = #{a['IdUser']}").first
        a['nomUser'] = u.name.to_s.gsub(" - ", " ") rescue 'No encontrado'
      end
    end    
  end

  def supervision_en_curso
    return redirect_to "/", alert: "No Autorizado" if get_current_user_app_nivel < 3
  	@sucursal  = params[:sucursal].to_i  if params.has_key?(:sucursal)
  	@id_visita = params[:id_visita].to_i if params.has_key?(:id_visita)
  	url = "/supervisiones/programadas"
  	get_filtros
    @filtros.push("Supervisiones.IdUser = #{current_user.id}")
  	return redirect_to url, alert: "Datos incorrectos" if !@sucursal or @sucursal < 1 or !@id_visita or @id_visita < 1
    @supervision = @dbEsta.connection.select_all("SELECT Supervisiones.*, s.Nombre, ck.Nombre as ckNombre FROM Supervisiones LEFT JOIN #{@nomDbComun}sucursal as s ON s.Num_suc = Supervisiones.Sucursal LEFT JOIN SupChecklists as ck ON ck.IdChecklist = Supervisiones.IdChecklist WHERE Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)} AND ( #{@filtros.join(" ) AND ( ")} ) AND Status = 0 LIMIT 1") rescue []
    return redirect_to url, alert: "Supervisión no encontrada" if @supervision.count != 1
    @supervision = @supervision.first
    @dsupervisiones = @dbEsta.connection.select_all("SELECT SupDSupervisiones.*, cat.Nombre as catNombre, fld.Nombre as fldNombre, fld.Descripcion as fldDescripcion, fld.OpcionNA as fldOpcionNA, fld.PuntosSi as fldPuntosSi, fld.ToDoSi as fldToDoSi, fld.PuntosNo as fldPuntosNo, fld.ToDoNo as fldToDoNo FROM SupDSupervisiones LEFT JOIN SupCategorias as cat ON cat.IdChecklist = SupDSupervisiones.IdChecklist AND cat.IdCatChecklist = SupDSupervisiones.IdCatChecklist LEFT JOIN SupCampos as fld ON fld.IdChecklist = SupDSupervisiones.IdChecklist AND fld.IdCatChecklist = SupDSupervisiones.IdCatChecklist AND fld.IdFldChecklist = SupDSupervisiones.IdCampo WHERE Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)}") rescue []
    return redirect_to url, alert: "Detalle de Supervisión no encontrada" if @dsupervisiones.count < 1
    @chat_comments = {}
    @imgs = {}
    obtiene_catalogos
  	@dsupervisiones.each do |d| 
      @chat_comments["#{d['IdChecklist']}-#{d['IdCatChecklist']}-#{d['IdCampo']}"] = @dbEsta.connection.select_all("SELECT SupComentarios.*, '' as userEmail, '' as userName FROM SupComentarios WHERE Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)} AND IdChecklist = #{User.sanitize(d['IdChecklist'])} AND IdCatChecklist = #{User.sanitize(d['IdCatChecklist'])} AND IdCampo = #{User.sanitize(d['IdCampo'])} ORDER BY FechaHora")
      @chat_comments["#{d['IdChecklist']}-#{d['IdCatChecklist']}-#{d['IdCampo']}"].each do |a|
        if a['IdUser'].to_i > 0
            u = User.where("id = #{a['IdUser']}").first
            a['userEmail'] = u.email rescue ''
            a['userName']  = u.name rescue ''
        end
      end
      @imgs["#{d['IdChecklist']}-#{d['IdCatChecklist']}-#{d['IdCampo']}"] = SupImagen.where("Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)} AND IdChecklist = #{User.sanitize(d['IdChecklist'])} AND IdCatChecklist = #{User.sanitize(d['IdCatChecklist'])} AND IdCampo = #{User.sanitize(d['IdCampo'])}")
    end      
  end

  def supervision_en_curso_update
  	@sucursal         = params[:sucursal].to_i         if params.has_key?(:sucursal)
  	@id_visita        = params[:id_visita].to_i        if params.has_key?(:id_visita)
  	url = "/supervisiones/programadas"
  	get_filtros
  	return redirect_to url, alert: "Datos incorrectos" if !@sucursal or @sucursal < 1 or !@id_visita or @id_visita < 1
    @supervision = @dbEsta.connection.select_all("SELECT Supervisiones.*, s.Nombre, ck.Nombre as ckNombre FROM Supervisiones LEFT JOIN #{@nomDbComun}sucursal as s ON s.Num_suc = Supervisiones.Sucursal LEFT JOIN SupChecklists as ck ON ck.IdChecklist = Supervisiones.IdChecklist WHERE Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)} AND ( #{@filtros.join(" ) AND ( ")} ) AND Status = 0 LIMIT 1") rescue []
    return redirect_to url, alert: "Supervisión no encontrada" if @supervision.count != 1
    @supervision = @supervision.first  	
    @dsupervisiones = @dbEsta.connection.select_all("SELECT SupDSupervisiones.*, cat.Nombre as catNombre, fld.Nombre as fldNombre, fld.Descripcion as fldDescripcion, fld.OpcionNA as fldOpcionNA, fld.PuntosSi as fldPuntosSi, fld.ToDoSi as fldToDoSi, fld.PuntosNo as fldPuntosNo, fld.ToDoNo as fldToDoNo FROM SupDSupervisiones LEFT JOIN SupCategorias as cat ON cat.IdChecklist = SupDSupervisiones.IdChecklist AND cat.IdCatChecklist = SupDSupervisiones.IdCatChecklist LEFT JOIN SupCampos as fld ON fld.IdChecklist = SupDSupervisiones.IdChecklist AND fld.IdCatChecklist = SupDSupervisiones.IdCatChecklist AND fld.IdFldChecklist = SupDSupervisiones.IdCampo WHERE Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)}") rescue []
    return redirect_to url, alert: "Detalle de Supervisión no encontrada" if @dsupervisiones.count < 1
  	url = "/supervisiones/supervision_en_curso?sucursal=#{@sucursal}&id_visita=#{@id_visita}"
    zona = @dbPdv.connection.select_all("SELECT ZonaAsig FROM #{@nomDbComun}sucursal where Num_suc = #{@sucursal}").first['ZonaAsig'].to_i rescue 0
  	do_todos = []
  	calificacion = 0
    calificacion_posible = 0
  	@dsupervisiones.each do |d|
      respuesta = ""
  		respuesta = params["#{d['IdChecklist']}-#{d['IdCatChecklist']}-#{d['IdCampo']}"].to_i if params["#{d['IdChecklist']}-#{d['IdCatChecklist']}-#{d['IdCampo']}"] != ""
  		puntos = 0
  		if respuesta == 0
  		  puntos = puntos + d['fldPuntosNo']
        do_todos.push(get_todo_row("No", @supervision, d, zona)) if d['fldToDoNo'] != ""
  		elsif respuesta == 1
  		  puntos = puntos + d['fldPuntosSi']
        do_todos.push(get_todo_row("Sí", @supervision, d, zona)) if d['fldToDoSi'] != ""
  		end
      calificacion_posible = calificacion_posible + d['fldPuntosSi'].to_i if d['fldOpcionNA'].to_i < 1
  		calificacion = calificacion + puntos
	    sql = "UPDATE SupDSupervisiones SET Respuesta = #{User.sanitize(respuesta)}, Puntos = #{User.sanitize(puntos)} WHERE Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)} AND IdChecklist = #{User.sanitize(d['IdChecklist'])} AND IdCatChecklist = #{User.sanitize(d['IdCatChecklist'])} AND IdCampo = #{User.sanitize(d['IdCampo'])}"
	    begin
	      @dbEsta.connection.execute(sql)
	    rescue Exception => exc 
	      return redirect_to url, alert: "No se ha podido guardar el detalle de la supervisión"
	    end
    end
    @commit = params[:commit]
    if @commit.to_s.downcase.include?("finalizar")
      calificacion_final = 0.0
      calificacion_final = (calificacion.to_f * 10.to_f / calificacion_posible.to_f).to_i rescue 0.0
	    sql = "UPDATE Supervisiones SET FechaTerminacion = '#{Date.today.to_s}', Calificacion = #{User.sanitize(calificacion_final.to_i)}, Status = 1 WHERE Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)}"
	    begin
	      @dbEsta.connection.execute(sql)
	    rescue Exception => exc 
	      return redirect_to url, alert: "No se ha podido guardar la supervisión"
	    end
      return redirect_to "/supervisiones/supervisiones_por_aprobar", notice: "Supervisión finalizada exitosamente y en espera de aprobación"		
    end
    return redirect_to url, notice: "Supervisión guardada exitosamente"		
  end

  def supervision_en_curso_aci
  	@sucursal         = params[:sucursal].to_i         if params.has_key?(:sucursal)
  	@id_visita        = params[:id_visita].to_i        if params.has_key?(:id_visita)
  	@id_checklist     = params[:id_checklist].to_i     if params.has_key?(:id_checklist)
  	@id_cat_checklist = params[:id_cat_checklist].to_i if params.has_key?(:id_cat_checklist)
  	@id_campo         = params[:id_campo].to_i         if params.has_key?(:id_campo)

  	url = "/supervisiones/programadas"
  	get_filtros
  	return redirect_to url, alert: "Datos incorrectos" if !@sucursal or @sucursal < 1 or !@id_visita or @id_visita < 1 or !@id_checklist or @id_checklist < 1 or !@id_cat_checklist or @id_cat_checklist < 1 or !@id_campo or @id_campo < 1
    @supervision = @dbEsta.connection.select_all("SELECT Supervisiones.*, s.Nombre, ck.Nombre as ckNombre FROM Supervisiones LEFT JOIN #{@nomDbComun}sucursal as s ON s.Num_suc = Supervisiones.Sucursal LEFT JOIN SupChecklists as ck ON ck.IdChecklist = Supervisiones.IdChecklist WHERE Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)} AND ( #{@filtros.join(" ) AND ( ")} ) AND Status = 0 LIMIT 1") rescue []
    return redirect_to url, alert: "Supervisión no encontrada" if @supervision.count != 1
  	url = "/supervisiones/supervision_en_curso?sucursal=#{@sucursal}&id_visita=#{@id_visita}"
    @supervision = @supervision.first
    @dsupervisiones = @dbEsta.connection.select_all("SELECT SupDSupervisiones.*, cat.Nombre as catNombre, fld.Nombre as fldNombre, fld.Descripcion as fldDescripcion, fld.OpcionNA as fldOpcionNA, fld.PuntosSi as fldPuntosSi, fld.ToDoSi as fldToDoSi, fld.PuntosNo as fldPuntosNo, fld.ToDoNo as fldToDoNo FROM SupDSupervisiones LEFT JOIN SupCategorias as cat ON cat.IdChecklist = SupDSupervisiones.IdChecklist AND cat.IdCatChecklist = SupDSupervisiones.IdCatChecklist LEFT JOIN SupCampos as fld ON fld.IdChecklist = SupDSupervisiones.IdChecklist AND fld.IdCatChecklist = SupDSupervisiones.IdCatChecklist AND fld.IdFldChecklist = SupDSupervisiones.IdCampo WHERE Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)} AND SupDSupervisiones.IdChecklist = #{User.sanitize(@id_checklist)} AND SupDSupervisiones.IdCatChecklist = #{User.sanitize(@id_cat_checklist)} AND SupDSupervisiones.IdCampo = #{User.sanitize(@id_campo)}") rescue []
    return redirect_to url, alert: "Detalle de Supervisión no encontrada" if @dsupervisiones.count != 1
    @chat_comments = @dbEsta.connection.select_all("SELECT SupComentarios.*, '' as userEmail, '' as userName FROM SupComentarios WHERE Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)} AND IdChecklist = #{User.sanitize(@id_checklist)} AND IdCatChecklist = #{User.sanitize(@id_cat_checklist)} AND IdCampo = #{User.sanitize(@id_campo)} ORDER BY FechaHora")
    @chat_comments.each do |a|
      if a['IdUser'].to_i > 0
        u = User.where("id = #{a['IdUser']}").first
        a['userEmail'] = u.email rescue ''
        a['userName']  = u.name rescue ''
      end
    end
  	obtiene_catalogos
    @imgs = SupImagen.where("Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)} AND IdChecklist = #{User.sanitize(@id_checklist)} AND IdCatChecklist = #{User.sanitize(@id_cat_checklist)} AND IdCampo = #{User.sanitize(@id_campo)}")
  	@sup_imagen = SupImagen.new
  end

  def supervision_en_curso_aci_create
  	@sucursal         = params[:sucursal].to_i         if params.has_key?(:sucursal)
  	@id_visita        = params[:id_visita].to_i        if params.has_key?(:id_visita)
  	@id_checklist     = params[:id_checklist].to_i     if params.has_key?(:id_checklist)
  	@id_cat_checklist = params[:id_cat_checklist].to_i if params.has_key?(:id_cat_checklist)
  	@id_campo         = params[:id_campo].to_i         if params.has_key?(:id_campo)
  	@tipo             = params[:tipo]      if params.has_key?(:tipo)
  	@nuevo_comentario = params[:nuevo_comentario]      if params.has_key?(:nuevo_comentario)

  	url = "/supervisiones/programadas"
  	get_filtros
  	return redirect_to url, alert: "Datos incorrectos" if !@sucursal or @sucursal < 1 or !@id_visita or @id_visita < 1 or !@id_checklist or @id_checklist < 1 or !@id_cat_checklist or @id_cat_checklist < 1 or !@id_campo or @id_campo < 1
  	url = "/supervisiones/supervision_en_curso_aci?sucursal=#{@sucursal}&id_visita=#{@id_visita}&id_checklist=#{@id_checklist}&id_cat_checklist=#{@id_cat_checklist}&id_campo=#{@id_campo}"
  	if @tipo == "comentario"
	  	return redirect_to url, alert: "Favor de ingresar el comentario" if !@nuevo_comentario or @nuevo_comentario.to_s.strip.length < 1
	    sql = "INSERT INTO SupComentarios ( Sucursal, IdVisita, IdChecklist, IdCatChecklist, IdCampo, FechaHora, IdUser, Comentario ) VALUES ( #{User.sanitize(@sucursal)}, #{User.sanitize(@id_visita)}, #{User.sanitize(@id_checklist)}, #{User.sanitize(@id_cat_checklist)}, #{User.sanitize(@id_campo)}, now(), #{User.sanitize(current_user.id)}, #{User.sanitize(@nuevo_comentario)} )"
	    begin
	      @dbEsta.connection.execute(sql)
	    rescue Exception => exc 
	      return redirect_to url, alert: "No se ha podido guardar el comentario"
	    end
	    return redirect_to url, notice: "Comentario guardado exitosamente"
    end
  	return redirect_to url, alert: "Ha habido un error"
  end

  def supervisiones_por_aprobar
    get_filtros
    get_filtros_from_user_for_supervisiones
    @supervisiones = @dbEsta.connection.select_all("SELECT Supervisiones.*, s.Nombre, ck.Nombre as ckNombre, cat.Nombre as catNombre, '' as nomUser FROM Supervisiones LEFT JOIN #{@nomDbComun}sucursal as s ON s.Num_suc = Supervisiones.Sucursal LEFT JOIN SupChecklists as ck ON ck.IdChecklist = Supervisiones.IdChecklist LEFT JOIN SupCategorias as cat ON cat.IdChecklist = Supervisiones.IdChecklist AND cat.IdCatChecklist = Supervisiones.IdCatChecklists WHERE ( #{@filtros.join(" ) AND ( ")} ) AND Status = 1 ORDER BY FechaTerminacion DESC, IdVisita DESC LIMIT 50") rescue []
    @supervisiones.each do |a|
      if a['IdUser'].to_i > 0
        u = User.where("id = #{a['IdUser']}").first
        a['nomUser'] = u.name.to_s.gsub(" - ", " ") rescue 'No encontrado'
      end
    end  
  end

  def supervision_por_aprobar
  	@sucursal  = params[:sucursal].to_i  if params.has_key?(:sucursal)
  	@id_visita = params[:id_visita].to_i if params.has_key?(:id_visita)
  	url = "/supervisiones/programadas"
  	return redirect_to url, alert: "Datos incorrectos" if !@sucursal or @sucursal < 1 or !@id_visita or @id_visita < 1
    get_filtros
    get_filtros_from_user_for_supervisiones
    @es_encargado = @user_permisos[:nivel].to_i == 50
    @supervision = @dbEsta.connection.select_all("SELECT Supervisiones.*, s.Nombre, ck.Nombre as ckNombre FROM Supervisiones LEFT JOIN #{@nomDbComun}sucursal as s ON s.Num_suc = Supervisiones.Sucursal LEFT JOIN SupChecklists as ck ON ck.IdChecklist = Supervisiones.IdChecklist WHERE Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)} AND ( #{@filtros.join(" ) AND ( ")} ) AND Status = 1 LIMIT 1") rescue []
    return redirect_to url, alert: "Supervisión no encontrada" if @supervision.count != 1
    @supervision = @supervision.first
    @dsupervisiones = @dbEsta.connection.select_all("SELECT SupDSupervisiones.*, cat.Nombre as catNombre, fld.Nombre as fldNombre, fld.Descripcion as fldDescripcion, fld.OpcionNA as fldOpcionNA, fld.PuntosSi as fldPuntosSi, fld.ToDoSi as fldToDoSi, fld.PuntosNo as fldPuntosNo, fld.ToDoNo as fldToDoNo FROM SupDSupervisiones LEFT JOIN SupCategorias as cat ON cat.IdChecklist = SupDSupervisiones.IdChecklist AND cat.IdCatChecklist = SupDSupervisiones.IdCatChecklist LEFT JOIN SupCampos as fld ON fld.IdChecklist = SupDSupervisiones.IdChecklist AND fld.IdCatChecklist = SupDSupervisiones.IdCatChecklist AND fld.IdFldChecklist = SupDSupervisiones.IdCampo WHERE Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)}") rescue []
    return redirect_to url, alert: "Detalle de Supervisión no encontrada" if @dsupervisiones.count < 1
    obtiene_catalogos
    @imgs = {}
    @chat_comments = {}
  	@dsupervisiones.each do |d| 
      @chat_comments["#{d['IdChecklist']}-#{d['IdCatChecklist']}-#{d['IdCampo']}"] = @dbEsta.connection.select_all("SELECT SupComentarios.*, '' as userEmail, '' as userName FROM SupComentarios WHERE Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)} AND IdChecklist = #{User.sanitize(d['IdChecklist'])} AND IdCatChecklist = #{User.sanitize(d['IdCatChecklist'])} AND IdCampo = #{User.sanitize(d['IdCampo'])} ORDER BY FechaHora")
      @chat_comments["#{d['IdChecklist']}-#{d['IdCatChecklist']}-#{d['IdCampo']}"].each do |a|
        if a['IdUser'].to_i > 0
            u = User.where("id = #{a['IdUser']}").first
            a['userEmail'] = u.email rescue ''
            a['userName']  = u.name rescue ''
        end
      end      
      @imgs["#{d['IdChecklist']}-#{d['IdCatChecklist']}-#{d['IdCampo']}"] = SupImagen.where("Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)} AND IdChecklist = #{User.sanitize(d['IdChecklist'])} AND IdCatChecklist = #{User.sanitize(d['IdCatChecklist'])} AND IdCampo = #{User.sanitize(d['IdCampo'])}")
    end 
  end

  def supervision_por_aprobar_update
  	@sucursal         = params[:sucursal].to_i         if params.has_key?(:sucursal)
  	@id_visita        = params[:id_visita].to_i        if params.has_key?(:id_visita)
  	url = "/supervisiones/programadas"
  	get_filtros
  	return redirect_to url, alert: "Datos incorrectos" if !@sucursal or @sucursal < 1 or !@id_visita or @id_visita < 1
    @supervision = @dbEsta.connection.select_all("SELECT Supervisiones.*, s.Nombre, ck.Nombre as ckNombre FROM Supervisiones LEFT JOIN #{@nomDbComun}sucursal as s ON s.Num_suc = Supervisiones.Sucursal LEFT JOIN SupChecklists as ck ON ck.IdChecklist = Supervisiones.IdChecklist WHERE Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)} AND ( #{@filtros.join(" ) AND ( ")} ) AND Status = 1 LIMIT 1") rescue []
    return redirect_to url, alert: "Supervisión no encontrada" if @supervision.count != 1
    @supervision = @supervision.first  	
    @dsupervisiones = @dbEsta.connection.select_all("SELECT SupDSupervisiones.*, cat.Nombre as catNombre, fld.Nombre as fldNombre, fld.Descripcion as fldDescripcion, fld.OpcionNA as fldOpcionNA, fld.PuntosSi as fldPuntosSi, fld.ToDoSi as fldToDoSi, fld.PuntosNo as fldPuntosNo, fld.ToDoNo as fldToDoNo FROM SupDSupervisiones LEFT JOIN SupCategorias as cat ON cat.IdChecklist = SupDSupervisiones.IdChecklist AND cat.IdCatChecklist = SupDSupervisiones.IdCatChecklist LEFT JOIN SupCampos as fld ON fld.IdChecklist = SupDSupervisiones.IdChecklist AND fld.IdCatChecklist = SupDSupervisiones.IdCatChecklist AND fld.IdFldChecklist = SupDSupervisiones.IdCampo WHERE Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)}") rescue []
    return redirect_to url, alert: "Detalle de Supervisión no encontrada" if @dsupervisiones.count < 1
    @commit = params[:commit]
    if @commit.to_s.downcase == "no aprobar"
      	# Aqui limpia la fecha de finalizacion y calificacion y status
	    sql = "UPDATE Supervisiones SET Calificacion = 0, Status = 0 WHERE Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)}"
	    begin
	      @dbEsta.connection.execute(sql)
	    rescue Exception => exc 
	      return redirect_to url, alert: "No se ha podido guardar la supervisión"
	    end
    	return redirect_to url, notice: "Supervisión no aprobada exitosamente y en espera de nueva revisión"		
    end
  	url = "/supervisiones/supervision_por_aprobar?sucursal=#{@sucursal}&id_visita=#{@id_visita}"
    zona = @dbPdv.connection.select_all("SELECT ZonaAsig FROM #{@nomDbComun}sucursal where Num_suc = #{@sucursal}").first['ZonaAsig'].to_i rescue 0
  	do_todos = []
  	calificacion = 0
    calificacion_posible = 0
  	@dsupervisiones.each do |d| 
  		respuesta = params["#{d['IdChecklist']}-#{d['IdCatChecklist']}-#{d['IdCampo']}"].to_i rescue 0
  		puntos = 0
  		if respuesta == 0
  		  puntos = puntos + d['fldPuntosNo']
  		  do_todos.push(get_todo_row("No", @supervision, d, zona)) if d['fldToDoNo'] != ""
  		elsif respuesta == 1
  		  puntos = puntos + d['fldPuntosSi']
        do_todos.push(get_todo_row("Sí", @supervision, d, zona)) if d['fldToDoSi'] != ""
  		end
      calificacion_posible = calificacion_posible + d['fldPuntosSi'].to_i if d['fldOpcionNA'].to_i < 0
  		calificacion = calificacion + puntos
    end
    p "do_todos #{do_todos.inspect}"
  	# Se debe finalizar la supervision, o pasar su status de 0 a 1 y escribir la calificacion creando ToDos
  	obtiene_catalogos
    ids_todos_generados = []
    if do_todos.count > 0
      sql = "SELECT Nombre FROM #{@nomDbComun}sucursal where Num_suc = #{@sucursal}"
      nomsuc = @dbEsta.connection.select_all("SELECT Nombre FROM #{@nomDbComun}sucursal where Num_suc = #{@sucursal}").first['Nombre'] rescue "No Encontrada"
      do_todos.each do |i|
      	# Se crean los ToDos
        id = get_todo_id
        ids_todos_generados.push(id)
        involucrados = get_involucrados(i)
        asunto = "Suc #{@sucursal} #{nomsuc} - #{i[:desc]} - #{i[:respuesta]} Aprobado"
        sql = "INSERT INTO TodosRespuestas (IdHTodo, IdRespuesta, Usuario, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{Time.now.to_i}, #{current_user.id}, #{User.sanitize(asunto)}, now(), now())"
        begin
          @dbEsta.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to url, alert: "No se ha podido guardar la respuesta del To-Do"
        end
        sql = "INSERT INTO TodosHTodos (IdHTodo, Tipo, Involucrados, Prioridad, Status, CreadoPor, Responsable, Asunto, UltimaRespuesta, FechaCreacion, FechaActualizacion) VALUES ( #{id}, 3, #{User.sanitize(involucrados)}, 2, 1, #{User.sanitize(current_user.id)}, 0, #{User.sanitize(asunto)}, #{User.sanitize(current_user.id)}, now(), now())"
        begin
          @dbEsta.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to url, alert: "No se ha podido guardar el To-Do"
        end
        logTxt = "To-Do creado por Sistema de Supervisiones. Usuario: #{getUser(current_user.id)} con involucrados: #{involucrados}, prioridad: #{getPrioridad(2)}, tipo: #{getTipo(3)} y asunto: #{asunto}"
        sql = "INSERT INTO TodosLogs (IdHTodo, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{User.sanitize(logTxt)}, now(), now() )"
        begin
          @dbEsta.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to url, alert: "No se ha podido guardar el log del To-Do"
        end        
      end
    end
    calificacion_final = 0.0
    calificacion_final = (calificacion.to_f * 10.to_f / calificacion_posible.to_f).to_i rescue 0.0
    sql = "UPDATE Supervisiones SET FechaTerminacion = '#{Date.today.to_s}', Calificacion = #{User.sanitize(calificacion_final.to_i)}, Status = 2, ToDosCreados = #{User.sanitize(ids_todos_generados.join(","))} WHERE Sucursal = #{User.sanitize(@sucursal)} AND IdVisita = #{User.sanitize(@id_visita)}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to url, alert: "No se ha podido guardar la supervisión"
    end

    return redirect_to "/supervisiones/terminadas", notice: "Supervisión aprobada exitosamente. To-Dos generados: #{do_todos.count}"		
  end

  def supervisiones_por_programar
    return redirect_to "/", alert: "No Autorizado" if get_current_user_app_nivel < 3
    @sucursal  = params[:sucursal]  if params.has_key?(:sucursal)
    @supervisiones = []
    url = "/supervisiones/supervisiones_por_programar"
    if @sucursal
      # Tal vez se tenga que agregar el checklist en el formulario otra vez, para escoger el subtiposuc correcto
      subtiposuc = @dbEsta.connection.select_all("SELECT SupChecklists.* FROM SupChecklists WHERE IdChecklist = #{User.sanitize(1)} ORDER BY SupChecklists.Nombre DESC LIMIT 1").first['SubTipoSuc'] rescue 'S'
      where_suc = "SubTipoSuc = #{User.sanitize(subtiposuc)} "
      where_suc = "#{where_suc} AND Num_suc = #{User.sanitize(@sucursal.to_i)}" if @sucursal.to_i > 0
      @sucs = @dbComun.connection.select_all("SELECT * FROM sucursal WHERE #{where_suc} ORDER BY Num_suc").map{|u| ["#{u['Num_suc']} - #{u['Nombre']}", "#{u['Num_suc']}"]}.uniq rescue []
      @checklists = @dbEsta.connection.select_all("SELECT SupChecklists.* FROM SupChecklists ORDER BY SupChecklists.Nombre DESC")
      @sucs.each do |s| 
        @checklists.each do |ck| 
          @cats = @dbEsta.connection.select_all("SELECT SupCategorias.*, SupChecklists.Nombre as clNombre, SupCampos.IdFldChecklist, count(*) AS CamCount FROM SupCategorias LEFT JOIN SupChecklists ON SupChecklists.IdChecklist = SupCategorias.IdChecklist LEFT JOIN SupCampos ON SupCategorias.IdCatChecklist = SupCampos.IdCatChecklist WHERE SupCategorias.IdChecklist = #{ck['IdChecklist'].to_i} and SupCategorias.Activo = 1 GROUP BY SupCategorias.IdChecklist, IdCatChecklist ORDER BY SupCategorias.Orden ASC, SupCategorias.IdCatChecklist ASC")
          @cats.each do |c| 
            if @supervisiones.count < 100
              # Se revisa que no se haya programado o hecho esa revision
              programadas = @dbEsta.connection.select_all("SELECT * from SupCalendarios WHERE Sucursal = #{s.last} AND IdChecklist = #{c['IdChecklist']} AND ( IdCatChecklist = 0 OR IdCatChecklist = #{c['IdCatChecklist']} ) AND FechaProgramada > '#{(Date.today - c['Frecuencia'].to_i.days).to_s}' AND FechaProgramada < '#{(Date.today + c['Frecuencia'].to_i.days).to_s}'").count
              hechas = @dbEsta.connection.select_all("SELECT * from Supervisiones WHERE Sucursal = #{s.last} AND IdChecklist = #{c['IdChecklist']} AND ( IdCatChecklists = 0 OR IdCatChecklists LIKE '%#{c['IdCatChecklist']}%') AND FechaInicio > '#{(Date.today - c['Frecuencia'].to_i.days).to_s}' AND FechaInicio < '#{(Date.today + c['Frecuencia'].to_i.days).to_s}'").count
              if programadas < 1 and hechas < 1
                @supervisiones.push({ suc: s.last, sucNom: s.first, ck: c['IdChecklist'], ckNom: c['clNombre'], cat: c['IdCatChecklist'], catNom: c['Nombre'], frecuencia: c['Frecuencia'] })
              end
            else
              break
            end
          end
        end
      end
    end
  end

  def programar_supervisiones
    return redirect_to "/", alert: "No Autorizado" if get_current_user_app_nivel < 3
    @categorias = @categorias.unshift(["Todas",0]) if @categorias.count > 1
    @supervisores = User.joins("LEFT JOIN permisos ON users.id = permisos.idUsuario").where("permisos.id > 0 AND permisos.p1 = #{@sitio[0].idEmpresa} AND ( permisos.permiso = 'Supervisor' OR permisos.permiso = 'Auditor')").order(:name)
    @supervisores = User.where("id = #{current_user.id}") if get_current_user_app_nivel == 3
    #if @user_permisos[:nivel].to_i.between?(20, 30)
    @supervisores = @supervisores.map{|u| ["#{u.name.to_s.gsub(" - ", " ")} - #{u.email}", "#{u.id}"]}.uniq rescue []
  end

  def programar_supervisiones_create
    return redirect_to "/", alert: "No Autorizado" if get_current_user_app_nivel < 3
  	@sucursal  = params[:sucursal]  if params.has_key?(:sucursal)
  	@usuario   = params[:usuario]   if params.has_key?(:usuario)
  	@fecha     = params[:fecha]     if params.has_key?(:fecha)
  	@tipo      = params[:tipo]      if params.has_key?(:tipo)
  	@checklist = params[:checklist] if params.has_key?(:checklist)
  	@categoria = params[:categoria] if params.has_key?(:categoria)
  	url = "/supervisiones/programar_supervisiones"
  	if @sucursal and @usuario and @fecha and @tipo and @checklist
      @fecha = Date.strptime(@fecha, "%m/%d/%Y") rescue 0
      @cats = []
      @cats.push(@categoria.to_i) if @categoria.to_i > 0
      if @categoria.to_i == 0
        cats_activas = @dbEsta.connection.select_all("SELECT SupCampos.IdCatChecklist FROM SupCampos LEFT JOIN SupCategorias ON SupCategorias.IdChecklist = SupCampos.IdChecklist WHERE SupCampos.IdChecklist = #{User.sanitize(@checklist)} AND SupCampos.Activo = 1 AND SupCategorias.Activo = 1 GROUP BY SupCampos.IdCatChecklist") rescue []
        if cats_activas.count < 1
          return redirect_to url, alert: "Lo sentimos, no se han encontrado Categorías Activas con Campos Activos para el Checklist seleccionado"
        end
        cats_activas.each do |c|
          @cats.push(c['IdCatChecklist'].to_i)
        end
      end
      @cats.each do |c|
        sup_cals = @dbEsta.connection.select_all("SELECT * FROM SupCalendarios WHERE Sucursal = #{User.sanitize(@sucursal)} AND FechaProgramada = #{User.sanitize(@fecha)} AND IdChecklist = #{User.sanitize(@checklist)} AND IdCatChecklist = #{User.sanitize(c)} LIMIT 1") rescue [1]
        if sup_cals.count > 0
          return redirect_to url, alert: "Lo sentimos, ya existe una Supervisión Programada para esa Sucursal, Fecha y Categorias"
        end
      end
      @cats.each do |c|
    	  sql = "INSERT INTO SupCalendarios (Sucursal, FechaProgramada, IdChecklist, IdCatChecklist, IdUser, Tipo) VALUES ( #{User.sanitize(@sucursal)}, #{User.sanitize(@fecha)}, #{User.sanitize(@checklist)}, #{User.sanitize(c)}, #{User.sanitize(@usuario)}, #{User.sanitize(@tipo)} )"
        begin
          @dbEsta.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to url, alert: "No se ha podido guardar la supervision. Error: #{exc}"
        end
      end
      return redirect_to url, notice: "Programación exitosa. Supervisiones programadas: #{@cats.count}"
  	else
  	  return redirect_to url, alert: "Datos incorrectos"
  	end
  end

  def programar_supervisiones_destroy
    @sucursal  = params[:sucursal]  if params.has_key?(:sucursal)
    @fecha     = params[:fecha]     if params.has_key?(:fecha)
    @checklist = params[:checklist] if params.has_key?(:checklist)
    @categoria = params[:categoria] if params.has_key?(:categoria)
    url = "/supervisiones/programadas"
    if @sucursal and @fecha and @checklist and @categoria
      sql = "DELETE FROM SupCalendarios WHERE Sucursal = #{User.sanitize(@sucursal)} AND FechaProgramada = #{User.sanitize(@fecha)} AND IdChecklist = #{User.sanitize(@checklist)} AND IdCatChecklist = #{User.sanitize(@categoria)}"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to url, alert: "No se ha podido borrar la Supervisión Programada"
      end      
      return redirect_to url, notice: "La Supervisión Programada se ha borrado exitosamente"
    else
      return redirect_to url, alert: "Datos incorrectos"
    end
  end

  def load_sucs
    @subtiposuc = @checklists.first['SubTipoSuc'] rescue 'S'
    get_filtros
    get_filtros_from_user_for_sucursales
    @sucursales = @dbComun.connection.select_all("SELECT * FROM sucursal WHERE SubTipoSuc = #{User.sanitize(@subtiposuc)} AND ( ( #{@filtros.join(" ) AND ( ")} ) ) ORDER BY Num_suc").map{|u| ["Sucursal: #{u['Num_suc']} - #{u['Nombre']}", "#{u['Num_suc']}"]}.uniq rescue []
  end

  def load_cats
    @categorias = get_categorias_activas(@checklist)
    @checklists = @checklists.map{|u| ["Checklist: #{u['Nombre']}", "#{u['IdChecklist']}"]}.uniq rescue []
    @categorias = @categorias.unshift(["Todas",0]) if params.has_key?(:todas) && @categorias.count > 0
  end

  def sup_test
    raise "sup_test"
  end

  private 

  	def get_filtros
  	  @filtros = ["1"]
  	end

    def get_filtros_from_user_for(t, f = "Sucursal")
      # El contralor (5) para arriba ve a todos
      # El regional (10), auditor (20) supervisor (30) ven su zona
      # El promotor (40) y encargado (50) ver solo su sucursal
      # Nota: Esto cambia por los nuevos Niveles Especiales en App_rol_nivel:
      # Niveles:
      # 1: No puede ver nada
      # 2: Sólo Sucursales Propias
      # 3: Sólo Zonas Propias
      # 4: Toda la Empresa
      # 5: Todo y Checklists
      return if get_current_user_app_nivel >= 4
      if get_current_user_app_nivel < 2
        @filtros.push("0")
        return
      end
      @permiso = Permiso.joins("LEFT JOIN cat_roles ON permisos.permiso = cat_roles.nomPermiso").where("idUsuario = #{current_user.id} AND p1 = #{@sitio[0].idEmpresa.to_i}").order("cat_roles.nivel").limit(1)
      if @permiso && @permiso.count == 1
        if get_current_user_app_nivel == 3
          if @permiso[0].p2 != ""
            zonas = @permiso[0].p2.to_s.split(',').map{|i| i.to_i}.sort
            if zonas.count > 0
              sucs = @dbComun.connection.select_all("SELECT * FROM sucursal WHERE ZonaAsig = #{zonas.join(" OR ZonaAsig = ")}").map{|i| i['Num_suc'].to_i}.sort rescue []
              @filtros.push("#{t}.#{f} = #{sucs.join(" OR #{t}.#{f} = ")}") if sucs.count > 0
            end
          end
        elsif get_current_user_app_nivel == 2
          if @permiso[0].p3 != ""
            sucs = @permiso[0].p3.to_s.split(',').map{|i| i.to_i}.sort
            @filtros.push("#{t}.#{f} = #{sucs.join(" OR #{t}.#{f} = ")}") if sucs.count > 0
          end
        else
          @filtros.push("0")
        end
      else
        return redirect_to "/", alert: "No autorizado"
      end      
    end

    def get_filtros_from_user_for_supervisiones
      get_filtros_from_user_for("Supervisiones")
    end

    def get_filtros_from_user_for_supcalendarios
      get_filtros_from_user_for("SupCalendarios")
    end

    def get_filtros_from_user_for_sucursales
      get_filtros_from_user_for("sucursal", "Num_suc")
    end    

    def obtiene_catalogos
      @users      = User.order(:name).map{|u| [u.name.to_s.gsub(" - ", " "), "#{u.id}"]}
      @emails     = User.order(:name).map{|u| [u.email, "#{u.id}"]}
      @sucursales = @dbComun.connection.select_all("SELECT * FROM sucursal WHERE TipoSuc = 'S' ORDER BY Num_suc").map{|u| ["- Sucursal: #{u['Num_suc']} - #{u['Nombre']}", "#{u['Num_suc']}"]}.uniq rescue []
      @prioridades = [ [ "Normal", 2 ], [ "Baja", 1 ],  [ "Alta", 3 ], [ "Urgente", 4 ] ]
      @tipos = [ [ "Tarea", 1 ], [ "Recordatorio", 2 ], [ "Otro", 3 ] ]
      @status = [ [ "Abierto", 1 ], [ "En Progreso", 2 ], [ "Esperando Respuesta", 3 ],  [ "En Espera", 4 ], [ "Cerrado", 5 ], [ "Desechado", 6 ] ]
    end  	

    def get_todo_row(respuesta, supervision, d, zona)
      return { respuesta: respuesta, id: "#{d['IdChecklist']}-#{d['IdCatChecklist']}-#{d['IdCampo']}", desc: "#{supervision['ckNombre']} - #{d['catNombre']} - #{d['fldNombre']} - #{d['fldDescripcion']}", catNombre: d['catNombre'], fldNombre: d['fldNombre'], fldDescripcion: d['fldDescripcion'], fldPuntosSi: d['fldPuntosSi'], fldToDoSi: d['fldToDoSi'], fldPuntosNo: d['fldPuntosNo'], fldToDoNo: d['fldToDoNo'], zona: zona, idUser: supervision['IdUser'] }      
    end

    def get_categorias_activas(id, buscada = 0)
      #ToDo Hacer esto en solo un query
      ret = []
      c_where = ""
      c_where = "AND SupCampos.IdCatChecklist = #{buscada}" if buscada.to_i > 0
      cats_activas = @dbEsta.connection.select_all("SELECT SupCampos.IdCatChecklist FROM SupCampos LEFT JOIN SupCategorias ON SupCategorias.IdChecklist = SupCampos.IdChecklist WHERE SupCampos.IdChecklist = #{User.sanitize(id)} #{c_where} AND SupCampos.Activo = 1 AND SupCategorias.Activo = 1 GROUP BY SupCampos.IdCatChecklist") rescue []
      cats_activas.each do |c|
        cat_nom = @dbEsta.connection.select_all("SELECT * FROM SupCategorias WHERE SupCategorias.IdChecklist = #{User.sanitize(id)} AND SupCategorias.IdCatChecklist = #{c['IdCatChecklist'].to_i}").first['Nombre'] rescue ""
        ret.push([cat_nom, c['IdCatChecklist'].to_i])
      end
      return ret
    end

    def get_checklists
      @checklist = params[:idChecklist].to_i if params.has_key?(:idChecklist)
      @checklists = @dbEsta.connection.select_all("SELECT SupChecklists.* FROM SupChecklists WHERE IdChecklist = #{User.sanitize(@checklist)} ORDER BY SupChecklists.Nombre DESC LIMIT 100") rescue []  
    end

    def get_checklists_cats_sucs
      c_where = "WHERE 1"
      c_where = "#{c_where} AND SupChecklists.IdChecklist = #{params[:checklist]}" if params.has_key?(:checklist)
      @checklists = @dbEsta.connection.select_all("SELECT SupChecklists.* FROM SupChecklists #{c_where} ORDER BY SupChecklists.Nombre DESC LIMIT 100") rescue []
      @subtiposuc = @checklists.first['SubTipoSuc'] 
      get_filtros
      get_filtros_from_user_for_sucursales
      @sucursales = @dbComun.connection.select_all("SELECT * FROM sucursal WHERE SubTipoSuc = #{User.sanitize(@subtiposuc)} AND ( ( #{@filtros.join(" ) AND ( ")} ) ) ORDER BY Num_suc").map{|u| ["Sucursal: #{u['Num_suc']} - #{u['Nombre']}", "#{u['Num_suc']}"]}.uniq rescue []
      buscada = 0
      buscada = params[:categoria].to_i if params.has_key?(:categoria)
      @categorias = get_categorias_activas(@checklists.first['IdChecklist'].to_i, buscada)
      @checklists = @checklists.map{|u| ["Checklist: #{u['Nombre']}", "#{u['IdChecklist']}"]}.uniq rescue []
    end

    def get_involucrados(d)
      # Aqui debe buscar si el d[todosi o todono] tiene a que nivel se añadan como involucrados. Es decir, que si esta un encargado, que agregue al encargado de esa sucursal, y un supervisor que agregue al supervisor de esa zona o sucursal, y asi. y solo para ellos
      involucrados = []
      involucrados_a_hacer = []
      involucrados_a_hacer = d[:fldToDoSi].to_s.split(",").map{|i| i.to_i} if d[:respuesta] == "Sí"
      involucrados_a_hacer = d[:fldToDoNo].to_s.split(",").map{|i| i.to_i} if d[:respuesta] == "No"
      cat_roles = CatRole.order(:nivel).collect{ |c| [c.nomPermiso, c.nivel] }
      involucrados_a_hacer.each do |i|
        where_permisos = "0"
        if i.between?(0, 5)
          # Si es director/contralor, se buscan todos los directores/contralores
          where_permisos = "permiso = '#{cat_roles.select{|c| c.last == i }.map{|c| c.first }.join("' OR permiso = '")}'"
          where_permisos = "p1 = #{@sitio[0].idEmpresa.to_i} AND (#{where_permisos})"
        elsif i.between?(10, 30)
          # Si es Regional a Supervisor, se buscan la zona a la que pertenece la sucursal y despues se buscan los regionales, auditores o supervisores de esa zona en permisos
          where_permisos = "permiso = '#{cat_roles.select{|c| c.last == i }.map{|c| c.first }.join("' OR permiso = '")}'"
          where_permisos = "p1 = #{@sitio[0].idEmpresa.to_i} AND (#{where_permisos}) AND p2 LIKE '%#{d[:zona]}%'"
        elsif i.between?(40, 60)
          # Si es Promotor, Encargado o Vendedor, se buscan los usuarios que tengan esa sucursal
          where_permisos = "permiso = '#{cat_roles.select{|c| c.last == i }.map{|c| c.first }.join("' OR permiso = '")}'"
          where_permisos = "p1 = #{@sitio[0].idEmpresa.to_i} AND (#{where_permisos}) AND p3 LIKE '%#{@sucursal}%'"
        end
        users = Permiso.where(where_permisos).order(:idUsuario)
        users.each do |u|
          involucrados.push("u#{u.idUsuario}")
        end        
      end
      # Si no se ha encontrado un usuario, se pone por default el supervisor
      involucrados = ["u#{d[:idUser]}"] if involucrados.count < 1
      involucrados = involucrados.uniq.sort.join(",")
      return involucrados
    end

    def dump_to_file(filename,txt,modo="w")
      File.open(filename, modo) {|f| f.write(txt) }
    end

end
