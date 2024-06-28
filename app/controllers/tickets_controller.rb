class TicketsController < ApplicationController
  include TicketsHelper
  before_filter :authenticate_user!, except: [:tickets_programados_robot]
  before_filter :tiene_permiso_de_ver_app, except: [:tickets_programados_robot]
  before_filter :obtiene_catalogos
  before_filter :admin_only, only: [:tickets_programados, :tickets_programados_new, :tickets_programados_create, :tickets_programados_edit, :tickets_programados_update, :tickets_programados_destroy]

  include ActionView::Helpers::TextHelper

  def tickets
    @filtros_responsable = { 0 => "Creados por mí, Asignados a mí o Sin asignar", 1 => "Nuevos sin asignar", 2 => "Asignados a mí", 3 => "Asignados a otros", 4 => "Ver Todos" }
    @filtro_responsable = 0
    @filtro_responsable = params[:responsable].to_i if params.has_key?(:responsable) && params[:responsable].to_i > 0 && params[:responsable].to_i < @filtros_responsable.keys.count
    @filtros_status = { 0 => "Status Activo", 1 => "Abierto", 2 => "En Progreso", 3 => "Esperando Respuesta", 4 => "En Espera", 5 => "Cerrado", 6 => "Desechado", 7 => "Ver Todos" }
    @filtro_status = 0
    @filtro_status = params[:status].to_i if params.has_key?(:status) && params[:status].to_i > 0 && params[:status].to_i < @filtros_status.keys.count
    @filtros_dias = { 0 => "Actualización: Cualquier día", 1 => "Último día", 7 => "Última semana", 30 => "Último mes", 365 => "Último año" }
    @filtro_dias = 0
    @filtro_dias = params[:dias].to_i if params.has_key?(:dias) && params[:dias].to_i > 0 && @filtros_dias.has_key?(params[:dias].to_i)

    @filtros = [0]
    @filtros.push(1) if @es_director
    @filtros_and = [1]
    get_filtros_for_user(current_user.id) # unless @es_director
    @es_agente = parte_de_algun_grupo?(current_user.id)
    @grupos_del_que_es_parte = grupos_del_que_es_parte(current_user.id)
    get_filtros_for_filtro(current_user.id)
    @filtros_grupos = { 0 => "Grupos: Todos" }
    @filtro_grupo = 0
    if @grupos_del_que_es_parte.count > 1 && @es_director
      adicionales = @grupos.map{|grupo| { grupo.last => "Grupo: #{grupo.first}" } }
      @filtros_grupos =  ([@filtros_grupos] + adicionales).reduce(Hash.new, :merge)
      @filtro_grupo = params[:grupo].to_i if params.has_key?(:grupo) && params[:grupo].to_i > 0 && @filtros_grupos.has_key?(params[:grupo].to_i)
    elsif @grupos_del_que_es_parte.count > 1
      adicionales = @grupos.select{ |grupo| @grupos_del_que_es_parte.include?(grupo.last) }.map{|grupo| { grupo.last => "Grupo: #{grupo.first}" } }
      @filtros_grupos =  ([@filtros_grupos] + adicionales).reduce(Hash.new, :merge)
      @filtro_grupo = params[:grupo].to_i if params.has_key?(:grupo) && params[:grupo].to_i > 0 && @filtros_grupos.has_key?(params[:grupo].to_i)
    end
    @filtros_and.push("Tipo = #{@filtro_grupo}") if @filtro_grupo > 0
    @filtros_and.push("TodosHTodos.FechaActualizacion >= '#{(Date.today -  @filtro_dias).to_time.to_s}'") if @filtro_dias > 0
    # get_filtros_for_busqueda
    sql = "SELECT TodosHTodos.*, count(*) AS RCount FROM TodosHTodos LEFT JOIN TodosRespuestas ON TodosHTodos.IdHTodo = TodosRespuestas.IdHTodo WHERE ( ( #{@filtros.join(" ) OR ( ")} ) ) AND ( ( #{@filtros_and.join(" ) AND ( ")} ) ) GROUP BY TodosHTodos.IdHTodo ORDER BY TodosHTodos.FechaActualizacion DESC LIMIT 100"
    @tickets = @dbEsta.connection.select_all(sql)
  end

  def tickets_new
  end

  def tickets_create
    texto  = params[:texto]  if params.has_key?(:texto)
    if texto.to_s.length < 1
      return redirect_to "/tickets_new", alert: "Ingrese Mensaje válido"
    end
    id = get_todo_id
    id_respuesta = Time.now.to_i
    borrar_ticket_anterior(id)
    sql = "INSERT INTO TodosRespuestas (IdHTodo, IdRespuesta, Usuario, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{id_respuesta}, #{current_user.id}, #{User.sanitize(texto)}, now(), now())"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      return redirect_to "/tickets_new", alert: "No se ha podido guardar la respuesta del Ticket"
    end
    file_log = ""
    file_log_mail = ""
    if params.has_key?(:file)
      @todos_respuestas_file = TodosRespuestasFile.create(
        IdHTodo: id, IdRespuesta: id_respuesta, Usuario: current_user.id, file: params[:file]
      )
      if @todos_respuestas_file.save
        sql = "INSERT INTO TodosRespuestas (IdHTodo, IdRespuesta, Usuario, Texto, File, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{id_respuesta + 1}, #{User.sanitize(current_user.id)}, '', #{@todos_respuestas_file.id}, now(), now())"
        begin
          @dbEsta.connection.execute(sql)
        rescue Exception => exc
          return redirect_to "/tickets", alert: "No se ha podido guardar el archivo al crear el Ticket"
        end
        file_log = " con archivo #{@todos_respuestas_file.file.url}"
        file_log_mail = "Con <a href='http://#{request.host_with_port}#{@todos_respuestas_file.file.url}'>archivo adjunto</a>."
      else
        return redirect_to "/tickets", alert: "Error al agregar al archivo"
      end
    end
    asunto = "##{id} #{texto.to_s.gsub("\n", "").titleize.truncate(20)}"
    sql = "INSERT INTO TodosHTodos (IdHTodo, Tipo, Involucrados, Prioridad, Status, CreadoPor, Responsable, Asunto, UltimaRespuesta, Porcentaje, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{User.sanitize(params[:tipo].to_i)}, '', 2,  1, #{User.sanitize(current_user.id)}, 0, #{User.sanitize(asunto)}, #{User.sanitize(current_user.id)}, 0, now(), now())"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      return redirect_to "/tickets_new", alert: "No se ha podido guardar el Ticket"
    end
    logTxt = "Ticket creado por usuario: #{getUser(current_user.id)}, grupo: #{getTipoGrupo(params[:tipo].to_i)} y asunto: #{asunto}#{file_log}"
    sql = "INSERT INTO TodosLogs (IdHTodo, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{User.sanitize(logTxt)}, now(), now() )"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      return redirect_to "/tickets_new", alert: "No se ha podido guardar el log del Ticket"
    end
    mail_to = get_emails_from_ticket(id, true)
    mail_subject = @mail_subject
    mail_body    = "Ticket creado por: #{getUser(current_user.id)}, grupo: #{getTipoGrupo(params[:tipo].to_i)} y asunto: #{asunto}<br /><br /><a href='http://#{request.host_with_port}/tickets_show?id=#{id}'>Consultar el ticket</a><br /><br /><STRONG>Contenido:</STRONG><br />#{texto}<br />#{file_log_mail}<br /><br /><a href='http://#{request.host_with_port}/tickets_show?id=#{id}'>Consultar el ticket</a><br /><br />"
    mail_body = simple_format(mail_body, {}, sanitize: false, wrapper_tag: "div")
    mail_body = "<HTML><HEAD></HEAD><BODY><DIV style=\"FONT-SIZE: 12pt; FONT-FAMILY: 'Calibri'; COLOR: #000000\">#{mail_body}</DIV></BODY></HTML>"
    if modo_local?
      puts "Se iba a enviar el siguiente email pero manda localmente a la consola:\n  mail_to: #{mail_to}\n  mail_subject: #{mail_subject}\n  mail_body: #{mail_body}\n"
    else
      TicketsMailer.email_something_html(mail_to, mail_subject, mail_body).deliver_later if mail_to != ""
    end
    redirect_to "/tickets", notice: "Ticket generado exitosamente"
  end

  def tickets_update
    id    = params[:id].to_i  if params.has_key?(:id)
    return redirect_to "/tickets", alert: "Datos inválidos" if id < 1
    get_h_todo(id)
    return redirect_to "/tickets", alert: "Datos inválidos" unless @todo
    sql = get_update_todos_h_todo(id, true)
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      return redirect_to "/tickets_show?id=#{id}", alert: "No se ha podido actualizar el Ticket"
    end
    sql = get_update_todos_log(id)
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      return redirect_to "/tickets_show?id=#{id}", alert: "No se ha podido guardar el log del Ticket"
    end
    sql = "INSERT INTO TodosRespuestas (IdHTodo, IdRespuesta, Usuario, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{Time.now.to_i}, #{current_user.id}, #{User.sanitize(@logTxt)}, now(), now())"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      return redirect_to "/tickets_show?id=#{id}", alert: "No se ha podido guardar la respuesta del Ticket"
    end
    enviar_emails(id)
    redirect_to "/tickets_show?id=#{id}"
  end

  def tickets_respuesta_create
    id    = params[:id].to_i  if params.has_key?(:id)
    texto = params[:texto]    if params.has_key?(:texto)
    return redirect_to "/tickets", alert: "Datos inválidos" if id < 1
    return redirect_to "/tickets_show?id=#{id}", alert: "Favor de ingresar texto válido" if texto.to_s.length < 1
    get_h_todo(id)
    return redirect_to "/tickets", alert: "Datos inválidos" unless @todo
    sql = get_update_todos_h_todo(id, true)
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      return redirect_to "/tickets_show?id=#{id}", alert: "No se ha podido actualizar el Ticket"
    end
    sql = "INSERT INTO TodosRespuestas (IdHTodo, IdRespuesta, Usuario, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{Time.now.to_i}, #{current_user.id}, #{User.sanitize(texto)}, now(), now())"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      return redirect_to "/tickets_show?id=#{id}", alert: "No se ha podido guardar la respuesta del Ticket"
    end
    sql = get_update_todos_log_con_texto(id)
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      return redirect_to "/tickets_show?id=#{id}", alert: "No se ha podido guardar el log del Ticket"
    end
    enviar_emails(id)
    redirect_to "/tickets_show?id=#{id}"
  end

  def tickets_show
    id = params[:id].to_i if params.has_key?(:id)
    return redirect_to "/tickets", alert: "Ticket no valido" if !id
    @filtros = [1]
    @filtros_and = [1]
    @es_agente = parte_de_algun_grupo?(current_user.id)
    @grupos_del_que_es_parte = grupos_del_que_es_parte(current_user.id)
    get_filtros_for_filtro(current_user.id)
    sql = "SELECT TodosHTodos.*, TodosRespuestas.Usuario, TodosRespuestas.Texto, TodosRespuestas.IdRespuesta, TodosRespuestas.FechaCreacion as RFechaCreacion, TodosRespuestas.File FROM TodosHTodos LEFT JOIN TodosRespuestas ON TodosHTodos.IdHTodo = TodosRespuestas.IdHTodo WHERE ( ( #{@filtros.join(" ) OR ( ")} ) ) AND ( ( #{@filtros_and.join(" ) AND ( ")} ) ) AND TodosHTodos.IdHTodo = #{User.sanitize(params[:id].to_i)} ORDER BY TodosRespuestas.IdHTodo DESC LIMIT 100"
    @todo = @dbEsta.connection.select_all(sql)
    return redirect_to "/tickets", alert: "Ticket no encontrado" if @todo.count < 1
    @puede_editar = parte_de_grupo?(current_user, @todo.first['Tipo']) || @todo.first['CreadoPor'] == current_user.id
    @admin_de_grupo = admin_de_grupo?(current_user, @todo.first['Tipo'])
    @es_responsable = @todo.first['Responsable'].to_i == current_user.id
    @tiene_responsable = @todo.first['Responsable'].to_i > 0
    obtiene_responsables(@todo.first['Tipo'])
    get_fechas_limites(@todo.first['FechaLimite'])
    sql = "SELECT * FROM TodosLogs WHERE IdHTodo = #{User.sanitize(params[:id].to_i)} ORDER BY FechaCreacion DESC"
    @todo_logs = @dbEsta.connection.select_all(sql)
    @todosRespuestasFile = TodosRespuestasFile.new
  end

  def tickets_involucrados_edit
    editar_involucrados
  end

  def tickets_involucrados_edit_post
    editar_involucrados
  end

  def tickets_programados
    sql = "SELECT TodosTodoProgramado.*, '' as userEmail, '' as userName FROM TodosTodoProgramado WHERE DiaDeMes > 0 ORDER BY TodosTodoProgramado.DiaDeMes ASC LIMIT 100"
    @tickets_programados_dia = @dbEsta.connection.select_all(sql)
    sql = "SELECT TodosTodoProgramado.*, '' as userEmail, '' as userName FROM TodosTodoProgramado WHERE DiaDeMes < 1 AND FechaProgramada >= #{User.sanitize(Date.tomorrow.to_s[0..10])} AND FechaProgramada <= #{User.sanitize(1.year.from_now.to_date.to_s[0..10])} ORDER BY TodosTodoProgramado.FechaProgramada ASC LIMIT 100"
    @tickets_programados_fecha = @dbEsta.connection.select_all(sql)
  end

  def tickets_programados_new
    @url = "/tickets_programados_create"
  end

  def tickets_programados_create
    texto  = params[:Texto] if params.has_key?(:Texto)
    if texto.to_s.length < 1
      return redirect_to "/tickets_programados_new", alert: "Ingrese Mensaje válido"
    end
    id = get_ticket_programado_id
    fecha_o_dia = params[:fecha_o_dia]
    dia_de_mes = params[:DiaDeMes].to_i
    fecha_programada = params[:FechaProgramada]
    if fecha_o_dia == "FECHA"
      dia_de_mes = 0
    else
      fecha_programada = "2000-01-01"
    end
    sql = "INSERT INTO TodosTodoProgramado (IdTodoProgramado, DiaDeMes, FechaProgramada, Tipo, Status, Responsable, Texto, DiasFechaLimite, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{User.sanitize(dia_de_mes)}, #{User.sanitize(fecha_programada)}, #{User.sanitize(params[:Tipo].to_i)}, #{User.sanitize(params[:Status].to_i)}, 0, #{User.sanitize(params[:Texto])}, #{User.sanitize(params[:DiasFechaLimite].to_i)}, now(), now())"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      return redirect_to "/tickets_programados_new", alert: "No se ha podido guardar la Programación del Ticket"
    end
    redirect_to "/tickets_programados", notice: "Ticket programado exitosamente"
  end

  def tickets_programados_edit
    id = params[:id].to_i  if params.has_key?(:id)
    sql = "SELECT TodosTodoProgramado.* FROM TodosTodoProgramado WHERE TodosTodoProgramado.IdTodoProgramado = #{User.sanitize(id)} LIMIT 1"
    @todo_programado = @dbEsta.connection.select_all(sql)
    return redirect_to "/tickets_programados", alert: "No se ha podido encontrar la Programación del Ticket" if @todo_programado.count < 1
    @todo_programado = @todo_programado.first
    @url = "/tickets_programados_update"
  end

  def tickets_programados_update
    id = params[:id].to_i  if params.has_key?(:id)
    sql = "SELECT TodosTodoProgramado.* FROM TodosTodoProgramado WHERE TodosTodoProgramado.IdTodoProgramado = #{User.sanitize(id)} LIMIT 1"
    @todo_programado = @dbEsta.connection.select_all(sql)
    return redirect_to "/tickets_programados", alert: "No se ha podido encontrar la Programación del Ticket" if @todo_programado.count < 1
    texto  = params[:Texto] if params.has_key?(:Texto)
    if texto.to_s.length < 1
      return redirect_to "/tickets_programados_edit?id=#{id}", alert: "Ingrese Mensaje válido"
    end
    fecha_o_dia = params[:fecha_o_dia]
    dia_de_mes = params[:DiaDeMes].to_i
    fecha_programada = params[:FechaProgramada]
    if fecha_o_dia == "FECHA"
      dia_de_mes = 0
    else
      fecha_programada = "2000-01-01"
    end
    sql = "UPDATE TodosTodoProgramado SET DiaDeMes = #{User.sanitize(dia_de_mes)}, FechaProgramada = #{User.sanitize(fecha_programada)}, Tipo = #{User.sanitize(params[:Tipo].to_i)}, Status = #{User.sanitize(params[:Status].to_i)}, Texto = #{User.sanitize(params[:Texto])}, DiasFechaLimite = #{User.sanitize(params[:DiasFechaLimite].to_i)}, FechaActualizacion = now() WHERE IdTodoProgramado = #{User.sanitize(id)}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      return redirect_to "/tickets_programados_edit?id=#{id}", alert: "No se ha podido actualizar la Programación del Ticket"
    end
    redirect_to "/tickets_programados", notice: "Ticket programado exitosamente"
  end

  def tickets_programados_destroy
    id = params[:id].to_i  if params.has_key?(:id)
    sql = "SELECT TodosTodoProgramado.* FROM TodosTodoProgramado WHERE TodosTodoProgramado.IdTodoProgramado = #{User.sanitize(id)} LIMIT 1"
    @todo_programado = @dbEsta.connection.select_all(sql)
    return redirect_to "/tickets_programados", alert: "No se ha podido encontrar la Programación del Ticket" if @todo_programado.count < 1
    sql = "DELETE FROM TodosTodoProgramado WHERE IdTodoProgramado = #{User.sanitize(id)}"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      return redirect_to "/tickets_programados", alert: "No se ha podido borrar la Programación del Ticket"
    end
    redirect_to "/tickets_programados", notice: "Programación borrada exitosamente"
  end

  def tickets_programados_robot
    # Si el robot tiene id significa q una programacion es la q se busca solamente, y si dice un parametro force significa q lo haga aunque la fecha no sea la de Hoy. Si no tiene nada significa q busque todos los del dia
    id_p = 0
    id_p = params[:id].to_i if params.has_key?(:id) && params[:id].to_i > 0
    force = false
    force = true if id_p > 0 && params.has_key?(:force) && params[:force].to_i == 1
    tickets_generados = 0
    errores = []
    filtros = []
    filtros.push("1")
    filtros.push("IdTodoProgramado = #{id_p}") if id_p > 0
    filtros.push("( DiaDeMes = #{Date.today.day} OR FechaProgramada = #{User.sanitize(Date.today.to_s[0..10])} )") unless force
    sql = "SELECT TodosTodoProgramado.* FROM TodosTodoProgramado WHERE ( ( #{filtros.join(" ) AND ( ")} ) ) LIMIT 100"
    @tickets_programados = @dbEsta.connection.select_all(sql)
    @tickets_programados.each do |programacion|
      id = get_todo_id
      id_respuesta = Time.now.to_i
      texto = programacion['Texto']
      sql = "INSERT INTO TodosRespuestas (IdHTodo, IdRespuesta, Usuario, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{id_respuesta}, 999999, #{User.sanitize(texto)}, now(), now())"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        p "No se ha podido guardar la respuesta del ticket de la programacion: #{programacion['IdTodoProgramado']}: #{exc}"
        errores.push("No se ha podido guardar la respuesta del ticket de la programacion: #{programacion['IdTodoProgramado']}")
        next
      end
      asunto = "##{id} #{texto.to_s.gsub("\n", "").titleize.truncate(20)}"
      # TODO ARREGLAR ESTE QUERY
      fecha_limite = ''
      fecha_limite = (Date.today + programacion['DiasFechaLimite'].to_i).to_s if programacion['DiasFechaLimite'].to_i > 0 && programacion['DiasFechaLimite'].to_i <= 45
      sql = "INSERT INTO TodosHTodos (IdHTodo, Tipo, Involucrados, Prioridad, Status, CreadoPor, Responsable, Asunto, UltimaRespuesta, FechaLimite, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{User.sanitize(programacion['Tipo'].to_i)}, '', 2,  #{User.sanitize(programacion['Status'].to_i)}, 999999, 0, #{User.sanitize(asunto)}, 999999, #{User.sanitize(fecha_limite)}, now(), now())"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        p "No se ha podido guardar el ticket de la programacion: #{programacion['IdTodoProgramado']}: #{exc}"
        errores.push("No se ha podido guardar el ticket de la programacion: #{programacion['IdTodoProgramado']}")
        next
      end
      logTxt = "Ticket creado por usuario: #{getUser(999999)}, grupo: #{getTipoGrupo(programacion['Tipo'].to_i)} y asunto: #{asunto}"
      sql = "INSERT INTO TodosLogs (IdHTodo, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{User.sanitize(logTxt)}, now(), now() )"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        p "No se ha podido guardar el log del ticket de la programacion: #{programacion['IdTodoProgramado']}: #{exc}"
        errores.push("No se ha podido guardar el log del ticket de la programacion: #{programacion['IdTodoProgramado']}")
        next
      end
      mail_to = get_emails_from_ticket(id, true)
      mail_subject = @mail_subject
      mail_body    = "Ticket creado por: #{getUser(999999)}, grupo: #{getTipoGrupo(programacion['Tipo'].to_i)} y asunto: #{asunto}<br /><br /><a href='http://#{request.host_with_port}/tickets_show?id=#{id}'>Consultar el ticket</a><br /><br /><STRONG>Contenido:</STRONG><br />#{texto}<br /><br /><br /><a href='http://#{request.host_with_port}/tickets_show?id=#{id}'>Consultar el ticket</a><br /><br />"
      mail_body = simple_format(mail_body, {}, sanitize: false, wrapper_tag: "div")
      mail_body = "<HTML><HEAD></HEAD><BODY><DIV style=\"FONT-SIZE: 12pt; FONT-FAMILY: 'Calibri'; COLOR: #000000\">#{mail_body}</DIV></BODY></HTML>"
      if modo_local?
        puts "Se iba a enviar el siguiente email pero manda localmente a la consola:\n  mail_to: #{mail_to}\n  mail_subject: #{mail_subject}\n  mail_body: #{mail_body}\n"
      else
        TicketsMailer.email_something_html(mail_to, mail_subject, mail_body).deliver_later if mail_to != ""
      end
      tickets_generados = tickets_generados + 1
    end
    render status: 200, json: { info: "Tarea ejecutada exitosamente. Tickets generados: #{tickets_generados}.#{errores.count > 0 ? "Errores: #{errores.join(". ")}." : ""}" }
  end

  private

    def obtiene_catalogos
      @prioridades = [ [ "Normal", 2 ], [ "Baja", 1 ],  [ "Alta", 3 ], [ "Urgente", 4 ] ]
      # @tipos = [ ['Soporte Técnico', 1], ['Soporte Acapulco', 3], ['Soporte Chilpo', 4], ['Soporte Coatza', 5], ['Soporte Taxco', 6], ['Soporte Sistemas', 2] ]
      @status = [ [ "Abierto", 1 ], [ "En Progreso", 2 ], [ "Esperando Respuesta", 3 ],  [ "En Espera", 4 ], [ "Cerrado", 5 ], [ "Desechado", 6 ] ]
      @porcentajes = (0..100).step(10).map{|i| ["#{i}%", i] }
      # Aqui debería seleccionar sólo a los que tienen acceso al modulo (y otro de sólo staff)
      @users      = User.order(:name).map{|u| [u.name.to_s.gsub(" - ", " "), "#{u.id}"]}.push(["Sistema", "999999"])
      @emails     = User.order(:name).map{|u| [u.email.downcase, "#{u.id}"]}
      @dest_users = User.joins("LEFT JOIN permisos ON users.id = permisos.idUsuario").where("permisos.id > 0").order(:name).map{|u| ["Usuario: #{u.name.to_s.gsub(" - ", " ")}", "u#{u.id}"]}.uniq
      @sucursales = @dbComun.connection.select_all("SELECT * FROM sucursal WHERE TipoSuc = 'S' ORDER BY Num_suc").map{|u| ["- Sucursal: #{u['Num_suc']} - #{u['Nombre']}", "s#{u['Num_suc']}"]}.uniq rescue []
      @grupos =  @dbEsta.connection.select_all("SELECT * FROM GruposHGrupos ORDER BY IdGrupo").map{|u| ["#{u['Nombre']}", u['IdGrupo']]}.uniq rescue []
      @involucrados = []
      @es_director = false
      @es_director = true if Permiso.where("idUsuario = #{current_user.id} and permiso = 'Director'").length > 0
    end

    def arreglar_involucrados(ds,grupos_individuales)
      nds = []
      if grupos_individuales == 1 && ds
        # Aqui se crean los todos uno por cada integrante de grupo mas el current user
        ds.each do |d|
          if d.include?("g")
            # Create an entry for each member of the group
            sql = "SELECT GruposDGrupos.*, GruposHGrupos.Nombre FROM GruposDGrupos LEFT JOIN GruposHGrupos ON GruposHGrupos.IdGrupo = GruposDGrupos.IdGrupo WHERE GruposDGrupos.IdGrupo = #{User.sanitize(d.gsub("g",""))} ORDER BY GruposDGrupos.IdUser DESC"
            dgrupo = @dbEsta.connection.select_all(sql)
            nds.concat(dgrupo.map{|u| "u#{u['IdUser']}"}.reject{ |u| u.gsub("u","").to_i < 1 })
          else
            nds.push(d)
          end
        end
        nnds = []
        nds.each do |d|
          nnds.push([d].push("u#{current_user.id}").uniq.join(","))
        end
        return nnds
      end
      # Aqui se agregan los campos con "Todos los Grupos", "Usuarios" o "Sucursales"
      ds = [] if ds.nil?
      ds.push("u#{current_user.id}")
      ds.each do |d|
        # If a - is in the name, it means "All the Groups", etc.
        if d.include?("-")
          if d.include?("g")
            nds.concat(@grupos.map{|u| u[1]})
          elsif d.include?("u")
            nds.concat(@dest_users.map{|u| u[1]})
          elsif d.include?("s")
            nds.concat(@sucursales.map{|u| u[1]})
          end
        else
          nds.push(d)
        end
      end
      return [nds.uniq.join(",")]
    end

    def get_update_todos_h_todo(id, nuevaRespuesta = false)
      sql = "SELECT TodosHTodos.* FROM TodosHTodos  WHERE TodosHTodos.IdHTodo = #{id.to_i} LIMIT 1"
      todo = @dbEsta.connection.select_all(sql)
      redirect_to '/tickets', alert: "Ticket no encontrado" if todo.count < 1
      tipo_anterior = todo.first['Tipo'].to_i
      status_anterior = todo.first['Status'].to_i
      porcentaje_anterior = todo.first['Porcentaje'].to_i
      q = []
      q.push("Involucrados = #{User.sanitize(params[:involucrados].join(","))}") if params.has_key?(:involucrados) and params[:involucrados].join(",") != ""
      q.push("Tipo = #{User.sanitize(params[:tipo].to_i)}") if params.has_key?(:tipo)
      q.push("Prioridad = #{User.sanitize(params[:prioridad].to_i)}") if params.has_key?(:prioridad)
      if params.has_key?(:porcentaje) && params[:porcentaje].to_i == 100 && porcentaje_anterior < 100
        q.push("Status = 5") # (por cambio de Porcentaje a 100)
      elsif params.has_key?(:status)
        q.push("Status = #{User.sanitize(params[:status].to_i)}")
      end
      if params.has_key?(:status) && params[:status].to_i == 5 && status_anterior < 5
        q.push("Porcentaje = 100") # (por cambio de Status a Cerrado)
      elsif params.has_key?(:status) && params[:status].to_i == 1 && status_anterior >= 5
        q.push("Porcentaje = 0") # (por cambio de Status a Abierto)
      elsif params.has_key?(:porcentaje)
        q.push("Porcentaje = #{User.sanitize(params[:porcentaje].to_i)}")
      end
      q.push("Responsable = #{User.sanitize(params[:responsable].to_i)}") if params.has_key?(:responsable)
      q.push("FechaLimite = #{User.sanitize(sanitiza_fecha_limite(params[:fecha_limite]))}") if params.has_key?(:fecha_limite)
      if params.has_key?(:tipo) && params[:tipo].to_i != tipo_anterior
        q.push("Responsable = 0")
        params[:responsable] = 0
      end
      q.push("UltimaRespuesta = #{User.sanitize(current_user.id)}") if nuevaRespuesta
      return "UPDATE TodosHTodos SET #{q.join(", ")}, FechaActualizacion = now() WHERE IdHTodo = #{id}"
    end

    def get_update_todos_log(id)
      cambios = []
      cambios.push("Grupo: #{getTipoGrupo(params[:tipo].to_i)}") if params.has_key?(:tipo) && params[:tipo].to_i != @todo['Tipo'].to_i
      if params.has_key?(:porcentaje) && params[:porcentaje].to_i == 100
        cambios.push("Status: Cerrado (por cambio de Porcentaje a 100%)")
      elsif params.has_key?(:status) && params[:status].to_i != @todo['Status'].to_i
        cambios.push("Status: #{getStatus(params[:status].to_i)}")
      end
      if params[:status].to_i == 5 && @todo['Status'].to_i < 5
        cambios.push("Porcentaje: 100% (por cambio de Status a Cerrado)")
      elsif params[:status].to_i == 1 && @todo['Status'].to_i >= 5
        cambios.push("Porcentaje: 0% (por cambio de Status a Abierto)")
      else
        cambios.push("Porcentaje: #{params[:porcentaje].to_i}%") if params.has_key?(:porcentaje) && params[:porcentaje].to_i != @todo['Porcentaje'].to_i
      end
      cambios.push("Responsable: #{params[:responsable].to_i > 0 ? getUser(params[:responsable].to_i) : 'Ninguno'}") if params.has_key?(:responsable) && params[:responsable].to_i > -1 && params[:responsable].to_i != @todo['Responsable'].to_i
      cambios.push("Fecha Límite: #{sanitiza_fecha_limite(params[:fecha_limite], 'Ninguna')}") if params.has_key?(:fecha_limite) && params[:fecha_limite].to_s != @todo['FechaLimite'].to_s
      cambiosStr = cambios.count > 0 ? ": #{cambios.join(", ")}" : ""
      @logTxt = "Ticket actualizado por #{getUser(current_user.id)}#{cambiosStr}."
      return "INSERT INTO TodosLogs (IdHTodo, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{User.sanitize(@logTxt)}, now(), now() )"
    end

    def get_update_todos_log_con_texto(id)
      @logTxt = "Ticket con nueva respuesta por #{getUser(current_user.id)}: #{params[:texto].to_s.strip}.".gsub("..", ".")
      return "INSERT INTO TodosLogs (IdHTodo, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{User.sanitize(@logTxt)}, now(), now() )"
    end

    def get_filtros_for_user(u)
      @filtros.push("TodosHTodos.Responsable = #{u}") if @filtro_responsable == 0
      @filtros.push("TodosHTodos.CreadoPor = #{u}") if @filtro_responsable == 0
      @filtros.push("TodosHTodos.Responsable = 0") if @filtro_responsable == 0
      @filtros.push("TodosHTodos.Responsable = 0 AND TodosHTodos.FechaCreacion >= #{User.sanitize((Date.today - 15.days).to_s[0..10])} ") if @filtro_responsable == 1
      @filtros.push("TodosHTodos.Responsable = #{u}") if @filtro_responsable == 2
      @filtros.push("TodosHTodos.Responsable != #{u} AND TodosHTodos.Responsable != 0") if @filtro_responsable == 3
      @filtros.push("1") if @filtro_responsable == 4

      @filtros_and.push("TodosHTodos.Status < 5") if @filtro_status == 0
      @filtros_and.push("TodosHTodos.Status = 1") if @filtro_status == 1
      @filtros_and.push("TodosHTodos.Status = 2") if @filtro_status == 2
      @filtros_and.push("TodosHTodos.Status = 3") if @filtro_status == 3
      @filtros_and.push("TodosHTodos.Status = 4") if @filtro_status == 4
      @filtros_and.push("TodosHTodos.Status = 5") if @filtro_status == 5
      @filtros_and.push("TodosHTodos.Status = 6") if @filtro_status == 6
    end

    def get_filtros_for_user_old(u)
      @filtros.push("TodosHTodos.Responsable = #{u}")
      @filtros.push("TodosHTodos.Involucrados like '%u#{u}%'")
      sql = "SELECT GruposDGrupos.* FROM GruposDGrupos LEFT JOIN GruposHGrupos ON GruposHGrupos.IdGrupo = GruposDGrupos.IdGrupo WHERE GruposDGrupos.IdUser = #{User.sanitize(u)} ORDER BY GruposDGrupos.IdGrupo DESC"
      dgrupo = @dbEsta.connection.select_all(sql)
      @filtros.concat(dgrupo.map{|u| "TodosHTodos.Involucrados = 'g#{u['IdGrupo']}'"})
    end

    def get_filtros_for_filtro(u)
      return if @es_director
      if @es_agente
        @filtros_and.push("TodosHTodos.Tipo IN (#{@grupos_del_que_es_parte.join(",")})")
      else
        @filtros_and.push("TodosHTodos.CreadoPor = #{u}")
      end
    end

    def get_filtros_for_filtro_old(u)
      filtro = params[:filtro] if params.has_key?(:filtro)
      tipo   = params[:tipo]   if params.has_key?(:tipo)
      status = params[:status] if params.has_key?(:status)
      @filtros_and.push("TodosHTodos.Responsable = #{User.sanitize(u)}") if filtro == "mis-to-dos"
      @filtros_and.push("TodosHTodos.Responsable = 0")    if filtro == "sin-asignar"
      @filtros_and.push("TodosHTodos.Status = 6")         if filtro == "desechados"
      tipo   = @tipos.detect  { |t| t.first.downcase.gsub(" ", "_") == tipo }.last.to_i   rescue 0
      status = @status.detect { |t| t.first.downcase.gsub(" ", "_") == status }.last.to_i rescue 0
      @filtros_and.push("TodosHTodos.Tipo   = #{User.sanitize(tipo)}")   if tipo > 0
      @filtros_and.push("TodosHTodos.Status = #{User.sanitize(status)}") if status > 0
      @filtros_and.push("TodosHTodos.Status != 6") if filtro != "desechados" and status != 6
    end

    def get_filtros_for_busqueda
      s = params[:s] if params.has_key?(:s)
      if s.to_s.length > 0
        @filtros_and.push("( TodosHTodos.Asunto like '%#{User.sanitize(s)[1..-2]}%' OR TodosRespuestas.Texto like '%#{User.sanitize(s)[1..-2]}%' )")
      end
    end

    def editar_involucrados
      sql = "SELECT TodosHTodos.* FROM TodosHTodos WHERE TodosHTodos.IdHTodo = #{User.sanitize(params[:id].to_i)} LIMIT 1"
      @todo = @dbEsta.connection.select_all(sql)
      return redirect_to "/tickets", alert: "Ticket no encontrado" if @todo.count < 0
      id = @todo[0]['IdHTodo'].to_i
      return redirect_to "/tickets", alert: "Id del Ticket no encontrado" if id < 1
      @involucrados = @todo[0]['Involucrados'].to_s.split(",") rescue []
      return redirect_to "/tickets", alert: "Involucrados no encontrados" if @involucrados.count < 0
      remove_me = params[:remove_me].to_i if params.has_key?(:remove_me)
      if remove_me
        @involucrados = @involucrados - ["u#{current_user.id}"]
      else
        @nuevos_involucrados = params[:involucrados] if params.has_key?(:involucrados) and params[:involucrados].join(",") != ""
        return redirect_to "/tickets_show?id=#{id}", alert: "Favor de seleccionar los nuevos involucrados" if !@nuevos_involucrados
        @involucrados = @involucrados.concat(@nuevos_involucrados).uniq
      end
      sql = "UPDATE TodosHTodos SET Involucrados = #{User.sanitize(@involucrados.join(","))}, FechaActualizacion = now() WHERE IdHTodo = #{id}"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/tickets_show?id=#{id}", alert: "No se han podido guardar los nuevos involucrados del Ticket"
      end
      logTxt = "Ticket actualizado por usuario: #{getUser(current_user.id)}. Nuevos Involucrados: #{@involucrados.join(",")}"
      logTxt = "Ticket actualizado por usuario: #{getUser(current_user.id)}. Se ha removido a sí mismo de los Involucrados. Nuevos Involucrados: #{@involucrados.join(",")}" if remove_me
      sql = "INSERT INTO TodosLogs (IdHTodo, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{User.sanitize(logTxt)}, now(), now() )"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/tickets_show?id=#{id}", alert: "No se han podido guardar los nuevos involucrados del Ticket en el Log"
      end
      return redirect_to "/tickets", notice: "Se ha removido del Ticket exitosamente" if remove_me
      return redirect_to "/tickets_show?id=#{id}", notice: "Involucrados del Ticket editados exitosamente"
    end

    def grupos_del_que_es_parte(usuario)
      resultado = []
      sql = "SELECT GruposDGrupos.* FROM GruposDGrupos WHERE IdUser = #{User.sanitize(usuario)}"
      dgrupo = @dbEsta.connection.select_all(sql) rescue []
      dgrupo.each do |grupo|
        resultado.push(grupo['IdGrupo'].to_i)
      end
      return resultado
    end

    def parte_de_algun_grupo?(usuario)
      sql = "SELECT GruposDGrupos.* FROM GruposDGrupos WHERE IdUser = #{User.sanitize(usuario)} LIMIT 1"
      dgrupo = @dbEsta.connection.select_all(sql) rescue []
      return true if dgrupo.count == 1
      false
    end

    def parte_de_grupo?(usuario, ticket_tipo_grupo)
      sql = "SELECT GruposDGrupos.* FROM GruposDGrupos WHERE IdGrupo = #{User.sanitize(ticket_tipo_grupo)} AND IdUser = #{User.sanitize(usuario)} LIMIT 1"
      dgrupo = @dbEsta.connection.select_all(sql) rescue []
      return true if dgrupo.count == 1
      false
    end

    def admin_de_grupo?(usuario, ticket_tipo_grupo)
      sql = "SELECT GruposDGrupos.* FROM GruposDGrupos WHERE IdGrupo = #{User.sanitize(ticket_tipo_grupo)} AND IdUser = #{User.sanitize(usuario)} and RolUser = 1 LIMIT 1"
      dgrupo = @dbEsta.connection.select_all(sql) rescue []
      return true if dgrupo.count == 1
      false
    end

    def obtiene_responsables(ticket_tipo_grupo)
      sql = "SELECT GruposDGrupos.* FROM GruposDGrupos WHERE IdGrupo = #{User.sanitize(ticket_tipo_grupo)}"
      dgrupo = @dbEsta.connection.select_all(sql) rescue []
      @resp_users = []
      return if dgrupo.count < 1
      @resp_users = User.where("id in (?)", dgrupo.map{|dg| dg['IdUser'] }).order(:name).map{|u| ["#{u.name.to_s.gsub(" - ", " ")}", "#{u.id}"]}.uniq
    end

    def get_h_todo(id)
      sql = "SELECT TodosHTodos.* FROM TodosHTodos WHERE TodosHTodos.IdHTodo = #{id.to_i} LIMIT 1"
      @todo = @dbEsta.connection.select_all(sql)
      return false if @todo.count < 1
      @todo = @todo.first
    end

    def get_emails_from_ticket(id, incluir_al_grupo = false, incluir_al_admin = false)
      emails = []
      users = []
      get_h_todo(id)
      return [] unless @todo
      @mail_subject = "Ticket: #{@todo['Asunto']} <#{getUser(@todo['CreadoPor'])}> [#{getTipoGrupo(@todo['Tipo'])}]"
      # Los q reciben un mail son: El Creador del Ticket, al Responsable y el ultimo q lo movio y ya
      users.push(@todo['CreadoPor'])
      users.push(@todo['Responsable']) if @todo['Responsable'].to_i > 0
      users.push(current_user.id) if user_signed_in?
      # Excepto cuando
      if incluir_al_grupo
        sql = "SELECT GruposDGrupos.* FROM GruposDGrupos WHERE IdGrupo = #{User.sanitize(@todo['Tipo'])}"
        sql = "#{sql} AND RolUser = 0" unless incluir_al_admin
        dgrupo = @dbEsta.connection.select_all(sql) rescue []
        dgrupo.each do |u|
          users.push(u['IdUser'])
        end
      end
      users.uniq.each do |u|
        user = User.where("id = #{u}").first rescue ""
        if user && user != ""
          user_email = user.email
          user_email = "#{user_email}@pintacomex.mx" unless user_email.include?("@")
          emails.push(user_email)
        end
      end
      emails.join(";")
    end

    def enviar_emails(id)
      mail_to = get_emails_from_ticket(id, true)
      mail_subject = @mail_subject
      mail_body    = "Ticket actualizado por: #{getUser(current_user.id)}.<br /><br /><a href='http://#{request.host_with_port}/tickets_show?id=#{id}'>Consultar el ticket</a><br /><br /><STRONG>Contenido:</STRONG><br />#{@logTxt}<br /><br /><a href='http://#{request.host_with_port}/tickets_show?id=#{id}'>Consultar el ticket</a><br /><br />"
      mail_body = simple_format(mail_body, {}, sanitize: false, wrapper_tag: "div")
      mail_body = "<HTML><HEAD></HEAD><BODY><DIV style=\"FONT-SIZE: 12pt; FONT-FAMILY: 'Calibri'; COLOR: #000000\">#{mail_body}</DIV></BODY></HTML>"
      if modo_local?
        puts "Se iba a enviar el siguiente email pero manda localmente a la consola:\n  mail_to: #{mail_to}\n  mail_subject: #{mail_subject}\n  mail_body: #{mail_body}\n"
      else
        TicketsMailer.email_something_html(mail_to, mail_subject, mail_body).deliver_later if mail_to != ""
      end
    end

    def modo_local?
      sending_host = request.host.gsub("www.","").gsub(".com","").gsub(".mx","").gsub(".dyndns.org","").gsub(".dyndns.biz","").gsub("intranet","").gsub("comex","").gsub("bajapaint","").gsub("pintacomex","")
      return true if sending_host == "localhost"
      false
    end

    def get_fechas_limites(fecha)
      @fecha_limite = Date.parse(fecha) rescue ''
      @fechas_limite = (30.days.ago.to_date..(Date.today + 45.days)).map{ |date| [date.strftime("%Y-%m-%d"), date.strftime("%Y-%m-%d")] }.unshift(["Sin Fecha Límite", ''])
      unless @fecha_limite != '' && @fecha_limite >= 30.days.ago.to_date && @fecha_limite <= Date.today + 45.days
        @fecha_limite = ''
      end
    end

    def sanitiza_fecha_limite(fecha, regresar = '')
      fecha_limite = Date.parse(fecha) rescue ''
      if fecha_limite != '' && fecha_limite >= 30.days.ago.to_date && fecha_limite <= Date.today + 45.days
        return fecha_limite.strftime("%Y-%m-%d")
      else
        return regresar
      end
    end

    def get_ticket_programado_id
      id = 1
      sql = "SELECT max(IdTodoProgramado) as mid FROM TodosTodoProgramado"
      ids = @dbEsta.connection.select_all(sql)
      if ids.count == 1
        id = ids.first['mid'].to_i + 1
      end
      return id
    end

    def borrar_ticket_anterior(id)
      return if id < 1
      sql = "DELETE FROM TodosRespuestas WHERE IdHTodo = #{User.sanitize(id)}"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/tickets", alert: "No se han podido borrar las respuestas de los Tickets anteriores"
      end
      sql = "DELETE FROM TodosHTodos WHERE IdHTodo = #{User.sanitize(id)}"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/tickets", alert: "No se han podido borrar los encabezados de los Tickets anteriores"
      end
      sql = "DELETE FROM TodosLogs WHERE IdHTodo = #{User.sanitize(id)}"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/tickets_programados", alert: "No se ha podido borrar los logs de los Tickets anteriores"
      end
    end
end