class TodosController < ApplicationController
  # ESTE ES EL CONTROLADOR VIEJO NO SE USA
  include TodosHelper
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app
  before_filter :obtiene_catalogos
  before_filter :only_me

  def todos
    @filtros = [0]
    get_filtros_for_user(current_user.id)
    @filtros_and = [1]
    get_filtros_for_filtro(current_user.id)
    get_filtros_for_busqueda
    sql = "SELECT TodosHTodos.*, count(*) AS RCount FROM TodosHTodos LEFT JOIN TodosRespuestas ON TodosHTodos.IdHTodo = TodosRespuestas.IdHTodo WHERE ( ( #{@filtros.join(" ) OR ( ")} ) ) AND ( ( #{@filtros_and.join(" ) AND ( ")} ) ) GROUP BY TodosHTodos.IdHTodo ORDER BY TodosHTodos.FechaActualizacion DESC LIMIT 100"
    @todos = @dbEsta.connection.select_all(sql)
  end

  def todos_new
  end

  def todos_create
    asunto = params[:asunto] if params.has_key?(:asunto)
    texto  = params[:texto]  if params.has_key?(:texto)
    grupos_individuales = params[:grupos_individuales] if params.has_key?(:grupos_individuales)
    involucrados = params[:involucrados] if params.has_key?(:involucrados)
    if asunto.length < 1 or texto.length < 1
      return redirect_to "/todos_new", alert: "Ingrese Asunto y Texto válidos"
    end
    involucrados = arreglar_involucrados(involucrados,grupos_individuales.to_i)
    involucrados.each do |involucrado|
      id = get_todo_id
      sql = "INSERT INTO TodosRespuestas (IdHTodo, IdRespuesta, Usuario, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{Time.now.to_i}, #{current_user.id}, #{User.sanitize(texto)}, now(), now())"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/todos_new", alert: "No se ha podido guardar la respuesta del To-Do"
      end
      sql = "INSERT INTO TodosHTodos (IdHTodo, Tipo, Involucrados, Prioridad, Status, CreadoPor, Responsable, Asunto, UltimaRespuesta, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{User.sanitize(params[:tipo].to_i)}, #{User.sanitize(involucrado)}, #{User.sanitize(params[:prioridad].to_i)},  1, #{User.sanitize(current_user.id)}, 0, #{User.sanitize(asunto)}, #{User.sanitize(current_user.id)}, now(), now())"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/todos_new", alert: "No se ha podido guardar el To-Do"
      end
      logTxt = "To-Do creado por usuario: #{getUser(current_user.id)} con involucrados: #{involucrado}, prioridad: #{getPrioridad(params[:prioridad].to_i)}, tipo: #{getTipo(params[:tipo].to_i)} y asunto: #{asunto}"
      sql = "INSERT INTO TodosLogs (IdHTodo, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{User.sanitize(logTxt)}, now(), now() )"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/todos_new", alert: "No se ha podido guardar el log del To-Do"
      end
    end
    redirect_to "/todos", notice: "To-Do generado exitosamente"
  end

  def todos_update
    id    = params[:id].to_i  if params.has_key?(:id)
    if id < 1
      return redirect_to "/todos", alert: "Datos inválidos"
    end
    sql = get_update_todos_h_todo(id, true)
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      return redirect_to "/todos_show?id=#{id}", alert: "No se ha podido actualizar el To-Do"
    end
    sql = get_update_todos_log(id)
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      return redirect_to "/todos_show?id=#{id}", alert: "No se ha podido guardar el log del To-Do"
    end
    redirect_to "/todos_show?id=#{id}"
  end

  def todos_respuesta_create
    id    = params[:id].to_i  if params.has_key?(:id)
    texto = params[:texto]    if params.has_key?(:texto)
    if id < 1
      return redirect_to "/todos", alert: "Datos inválidos"
    end
    if texto.length < 1
      return redirect_to "/todos_show?id=#{id}", alert: "Favor de ingresar texto válido"
    end
    sql = get_update_todos_h_todo(id, true)
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      return redirect_to "/todos_show?id=#{id}", alert: "No se ha podido actualizar el To-Do"
    end
    sql = "INSERT INTO TodosRespuestas (IdHTodo, IdRespuesta, Usuario, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{Time.now.to_i}, #{current_user.id}, #{User.sanitize(texto)}, now(), now())"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      return redirect_to "/todos_show?id=#{id}", alert: "No se ha podido guardar la respuesta del To-Do"
    end
    sql = get_update_todos_log_con_texto(id)
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      return redirect_to "/todos_show?id=#{id}", alert: "No se ha podido guardar el log del To-Do"
    end
    redirect_to "/todos_show?id=#{id}"
  end

  def todos_show
    id = params[:id].to_i if params.has_key?(:id)
    return redirect_to "/todos", alert: "To-Do no valido" if !id
    sql = "SELECT TodosHTodos.*, TodosRespuestas.Usuario, TodosRespuestas.Texto, TodosRespuestas.IdRespuesta, TodosRespuestas.FechaCreacion as RFechaCreacion, TodosRespuestas.File FROM TodosHTodos LEFT JOIN TodosRespuestas ON TodosHTodos.IdHTodo = TodosRespuestas.IdHTodo WHERE TodosHTodos.IdHTodo = #{User.sanitize(params[:id].to_i)} ORDER BY TodosRespuestas.IdHTodo DESC LIMIT 100"
    @todo = @dbEsta.connection.select_all(sql)
    return redirect_to "/todos", alert: "To-Do no encontrado" if @todo.count < 0
    sql = "SELECT * FROM TodosLogs WHERE IdHTodo = #{User.sanitize(params[:id].to_i)} ORDER BY FechaCreacion DESC"
    @todo_logs = @dbEsta.connection.select_all(sql)
    @todosRespuestasFile  = TodosRespuestasFile.new
  end

  def todos_involucrados_edit
    editar_involucrados
  end

  def todos_involucrados_edit_post
    editar_involucrados
  end

  private

    def obtiene_catalogos
      # @areas = [ [ "Administración", 1 ], [ "Sistemas", 2 ], [ "Ventas", 3 ] ]
      @prioridades = [ [ "Normal", 2 ], [ "Baja", 1 ],  [ "Alta", 3 ], [ "Urgente", 4 ] ]
      @tipos = [ [ "Tarea", 1 ], [ "Recordatorio", 2 ], [ "Otro", 3 ] ]
      @status = [ [ "Abierto", 1 ], [ "En Progreso", 2 ], [ "Esperando Respuesta", 3 ],  [ "En Espera", 4 ], [ "Cerrado", 5 ], [ "Desechado", 6 ] ]
      # Aqui debería seleccionar sólo a los que tienen acceso al modulo (y otro de sólo staff)
      @users      = User.order(:name).map{|u| [u.name.to_s.gsub(" - ", " "), "#{u.id}"]}
      @emails     = User.order(:name).map{|u| [u.email.downcase, "#{u.id}"]}
      @dest_users = User.joins("LEFT JOIN permisos ON users.id = permisos.idUsuario").where("permisos.id > 0").order(:name).map{|u| ["Usuario: #{u.name.to_s.gsub(" - ", " ")}", "u#{u.id}"]}.uniq
      @resp_users = User.joins("LEFT JOIN permisos ON users.id = permisos.idUsuario").where("permisos.id > 0").order(:name).map{|u| ["#{u.name.to_s.gsub(" - ", " ")}", "#{u.id}"]}.uniq
      @sucursales = @dbComun.connection.select_all("SELECT * FROM sucursal WHERE TipoSuc = 'S' ORDER BY Num_suc").map{|u| ["- Sucursal: #{u['Num_suc']} - #{u['Nombre']}", "s#{u['Num_suc']}"]}.uniq rescue []
      @grupos =  @dbEsta.connection.select_all("SELECT * FROM GruposHGrupos ORDER BY Nombre").map{|u| ["- Grupo: #{u['Nombre']}", "g#{u['IdGrupo']}"]}.uniq rescue []
      @involucrados = []
      @involucrados.push(["> Todos los Grupos", "g-1"])
      @involucrados.concat(@grupos)
      @involucrados.push(["> Todos los Usuarios", "u-1"])
      @involucrados.concat(@dest_users)
      @involucrados.push(["> Todas las Sucursales", "s-1"])
      @involucrados.concat(@sucursales)
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
      # He puesto aquí esto para DRY Dont Repeat Yourself
      q = []
      q.push("Involucrados = #{User.sanitize(params[:involucrados].join(","))}") if params.has_key?(:involucrados) and params[:involucrados].join(",") != ""
      q.push("Tipo = #{User.sanitize(params[:tipo].to_i)}") if params.has_key?(:tipo)
      q.push("Prioridad = #{User.sanitize(params[:prioridad].to_i)}") if params.has_key?(:prioridad)
      q.push("Status = #{User.sanitize(params[:status].to_i)}") if params.has_key?(:status)
      q.push("Responsable = #{User.sanitize(params[:responsable].to_i)}") if params.has_key?(:responsable)
      q.push("UltimaRespuesta = #{User.sanitize(current_user.id)}") if nuevaRespuesta
      return "UPDATE TodosHTodos SET #{q.join(", ")}, FechaActualizacion = now() WHERE IdHTodo = #{id}"
    end

    def get_update_todos_log(id, nuevaRespuesta = false)
      involucrados = "Sin Cambios"
      involucrados = params[:involucrados].join(",") if params.has_key?(:involucrados) and params[:involucrados].join(",") != ""
      respuesta = "Sin Nueva Respuesta"
      respuesta = "Con Nueva Respuesta" if nuevaRespuesta
      logTxt = "To-Do actualizado por usuario: #{getUser(current_user.id)}. Involucrados: #{involucrados}. Prioridad: #{getPrioridad(params[:prioridad].to_i)}. Tipo: #{getTipo(params[:tipo].to_i)}. Status: #{getStatus(params[:status].to_i)}. Responsable: #{getUser(params[:responsable].to_i)}. Respuesta: #{respuesta}"
      return "INSERT INTO TodosLogs (IdHTodo, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{User.sanitize(logTxt)}, now(), now() )"
    end

    def get_update_todos_log_con_texto(id)
      logTxt = "To-Do con nueva respuesta por usuario: #{getUser(current_user.id)}. Respuesta: #{params[:texto]}"
      return "INSERT INTO TodosLogs (IdHTodo, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{User.sanitize(logTxt)}, now(), now() )"
    end

    def get_filtros_for_user(u)
      @filtros.push("TodosHTodos.Responsable = #{u}")
      @filtros.push("TodosHTodos.Involucrados like '%u#{u}%'")
      sql = "SELECT GruposDGrupos.* FROM GruposDGrupos LEFT JOIN GruposHGrupos ON GruposHGrupos.IdGrupo = GruposDGrupos.IdGrupo WHERE GruposDGrupos.IdUser = #{User.sanitize(u)} ORDER BY GruposDGrupos.IdGrupo DESC"
      dgrupo = @dbEsta.connection.select_all(sql)
      @filtros.concat(dgrupo.map{|u| "TodosHTodos.Involucrados = 'g#{u['IdGrupo']}'"})
    end

    def get_filtros_for_filtro(u)
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
      return redirect_to "/todos", alert: "To-Do no encontrado" if @todo.count < 0
      id = @todo[0]['IdHTodo'].to_i
      return redirect_to "/todos", alert: "Id del To-Do no encontrado" if id < 1
      @involucrados = @todo[0]['Involucrados'].to_s.split(",") rescue []
      return redirect_to "/todos", alert: "Involucrados no encontrados" if @involucrados.count < 0
      remove_me = params[:remove_me].to_i if params.has_key?(:remove_me)
      if remove_me
        @involucrados = @involucrados - ["u#{current_user.id}"]
      else
        @nuevos_involucrados = params[:involucrados] if params.has_key?(:involucrados) and params[:involucrados].join(",") != ""
        return redirect_to "/todos_show?id=#{id}", alert: "Favor de seleccionar los nuevos involucrados" if !@nuevos_involucrados
        @involucrados = @involucrados.concat(@nuevos_involucrados).uniq
      end
      sql = "UPDATE TodosHTodos SET Involucrados = #{User.sanitize(@involucrados.join(","))}, FechaActualizacion = now() WHERE IdHTodo = #{id}"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/todos_show?id=#{id}", alert: "No se han podido guardar los nuevos involucrados del To-Do"
      end
      logTxt = "To-Do actualizado por usuario: #{getUser(current_user.id)}. Nuevos Involucrados: #{@involucrados.join(",")}"
      logTxt = "To-Do actualizado por usuario: #{getUser(current_user.id)}. Se ha removido a sí mismo de los Involucrados. Nuevos Involucrados: #{@involucrados.join(",")}" if remove_me
      sql = "INSERT INTO TodosLogs (IdHTodo, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{User.sanitize(logTxt)}, now(), now() )"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/todos_show?id=#{id}", alert: "No se han podido guardar los nuevos involucrados del To-Do en el Log"
      end
      return redirect_to "/todos", notice: "Se ha removido del To-Do exitosamente" if remove_me
      return redirect_to "/todos_show?id=#{id}", notice: "Involucrados del To-Do editados exitosamente"
    end

    def only_me
      if current_user.id != 1
        redirect_to '/'
      end
    end
end
