class Auths::SolicitudesController < ApplicationController
  include ::Auths::SolicitudesHelper
  include ActionView::Helpers::TextHelper
  before_filter :authenticate_user!
  before_filter :admin_only
  before_filter :find_solicitud, only: [:edit, :update, :show, :destroy]
  before_filter :obtiene_catalogos

  def index
    get_base_filtros
    sql = "SELECT AuthsSolicitudes.*, AuthsRespuestas.Texto AS Texto, count(*) AS RCount FROM AuthsSolicitudes LEFT JOIN AuthsRespuestas ON AuthsSolicitudes.IdSolicitud = AuthsRespuestas.IdSolicitud WHERE ( ( #{@filtros.join(" ) OR ( ")} ) ) AND ( ( #{@filtros_and.join(" ) AND ( ")} ) ) GROUP BY AuthsSolicitudes.IdSolicitud ORDER BY AuthsSolicitudes.FechaActualizacion DESC LIMIT 100"
    @solicitudes = @dbEsta.connection.select_all(sql)
  end

  def new
    @new = true
    @solicitud = {}
    @solicitud['IdTipoSolicitud'] = 1
    @solicitud['Texto'] = ''
  end

  def edit
    @new = false
  end

  def create
    create_solicitud
  end

  def update
    get_base_filtros
    get_solicitud_y_puede_editar
    autorizar_rechazar_solicitud
  end

  def show
    get_base_filtros
    get_solicitud_y_puede_editar
    sql = "SELECT * FROM AuthsLogs WHERE IdSolicitud = #{User.sanitize(@id)} ORDER BY FechaCreacion DESC"
    @solicitud_logs = @dbEsta.connection.select_all(sql)
    @solicitudRespuestasFile = AuthsRespuestasFile.new
  end

  def destroy
    redirect_to "/auths/solicitudes", alert: "No se puede borrar una solicitud"
  end

  def respuesta_create
    id    = params[:id].to_i  if params.has_key?(:id)
    texto = params[:texto]    if params.has_key?(:texto)
    return redirect_to "/auths/solicitudes", alert: "Datos inválidos" if id < 1
    return redirect_to "/auths/solicitudes/#{id}", alert: "Favor de ingresar texto válido" if texto.to_s.length < 1
    get_solicitud(id)
    return redirect_to "/auths/solicitudes", alert: "Datos inválidos" unless @solicitud
    sql = "INSERT INTO AuthsRespuestas (IdSolicitud, IdRespuesta, Usuario, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{Time.now.to_i}, #{current_user.id}, #{User.sanitize(texto)}, now(), now())"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      return redirect_to "/auths/solicitudes/#{id}", alert: "No se ha podido guardar la respuesta de la Solicitud"
    end
    @logTxt = "Solicitud con nueva respuesta por #{get_usuario(current_user.id)}: #{params[:texto].to_s.strip}.".gsub("..", ".")
    sql = "INSERT INTO AuthsLogs (IdSolicitud, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{User.sanitize(@logTxt)}, now(), now() )"
    begin
      @dbEsta.connection.execute(sql)
    rescue Exception => exc
      return redirect_to "/auths/solicitudes/#{id}", alert: "No se ha podido guardar el log de la respuesta"
    end
    enviar_emails(id)
    redirect_to "/auths/solicitudes/#{id}"
  end

  private

    def get_base_filtros
      get_flujos_for_current_user
      @filtros = [0]
      @filtros_and = [1]
      @filtros.push("AuthsSolicitudes.IdUsuarioSolicitante = #{current_user.id}")
      @flujos.each do |a|
        @filtros.push("( AuthsSolicitudes.IdTipoSolicitud = #{a['IdTipoSolicitud']} AND AuthsSolicitudes.NivelActual = #{a['NivelActual']} )")
      end
    end

    def get_solicitud(id)
      sql = "SELECT AuthsSolicitudes.*, AuthsRespuestas.Texto AS Texto FROM AuthsSolicitudes LEFT JOIN AuthsRespuestas ON AuthsSolicitudes.IdSolicitud = AuthsRespuestas.IdSolicitud WHERE AuthsSolicitudes.IdSolicitud = #{id.to_i} LIMIT 1"
      @solicitud = @dbEsta.connection.select_all(sql)
      return false if @solicitud.count < 1
      @solicitud = @solicitud.first
    end

    def get_solicitud_y_puede_editar
      @filtros_and.push("AuthsSolicitudes.IdSolicitud = #{User.sanitize(@id)}")
      sql = "SELECT AuthsSolicitudes.*, AuthsRespuestas.Usuario, AuthsRespuestas.Texto, AuthsRespuestas.IdRespuesta, AuthsRespuestas.FechaCreacion as RFechaCreacion, AuthsRespuestas.File FROM AuthsSolicitudes LEFT JOIN AuthsRespuestas ON AuthsSolicitudes.IdSolicitud = AuthsRespuestas.IdSolicitud WHERE ( ( #{@filtros.join(" ) OR ( ")} ) ) AND ( ( #{@filtros_and.join(" ) AND ( ")} ) ) ORDER BY AuthsRespuestas.IdSolicitud DESC LIMIT 100"
      @solicitud = @dbEsta.connection.select_all(sql) rescue []
      return redirect_to "/auths/solicitudes", alert: "Solicitud no encontrada" if @solicitud.count < 1
      @flujo = @flujos.detect{ |i| i['IdTipoSolicitud'] == @solicitud[0]['IdTipoSolicitud'] && i['NivelActual'] == @solicitud[0]['NivelActual'] && i['IdUsuario'] == current_user.id }
      @puede_editar = @flujo && @flujo['DebeAutorizar'] == 1
    end

    def find_solicitud
      @id = params[:id].to_i
      sql = "SELECT AuthsSolicitudes.*, '' as NombreUsuario, '' as NombreUsuarioAuth FROM AuthsSolicitudes WHERE IdSolicitud = #{User.sanitize(@id)} LIMIT 1"
      @solicitud = @dbEsta.connection.select_all(sql).first rescue false
      redirect_to '/' unless @solicitud
    end

    def obtiene_catalogos
      @tipo_solicitudes = @dbEsta.connection.select_all("SELECT AuthsTipoSolicitudes.* FROM AuthsTipoSolicitudes ORDER BY IdTipoSolicitud").map{|u| ["#{u['IdTipoSolicitud']} - #{u['Nombre'].to_s}", "#{u['IdTipoSolicitud']}"]}.uniq
      @niveles = [["00 - Creada", "0"]]
      @niveles = @niveles.concat((1..20).map{|i| ["#{format('%02d', i)} - En Proceso Nivel #{i}", "#{i}"]})
      @niveles = @niveles.concat((59..69).map{|i| ["#{i} - Rechazada", "#{i}"]})
      @niveles = @niveles.concat((80..99).map{|i| ["#{i} - Aprobada", "#{i}"]})
      @usuarios = User.joins("LEFT JOIN permisos ON users.id = permisos.idUsuario").where("permisos.id > 0").order(:name).map{|u| ["#{u.name.to_s.gsub(" - ", " ")}", "#{u.id}"]}.uniq
      @emails = User.order(:name).map{|u| [u.email.downcase, "#{u.id}"]}
    end

    def create_solicitud
      @new = params[:new] == "true"
      @id_solicitud = params[:idsolicitud].to_i
      @id_solicitud = get_id if @new && @id_solicitud == 0
      @id_tipo_solicitud = params[:idtiposolicitud].to_i
      @id_usuario_solicitante = current_user.id
      @nivel_actual = 0
      @id_usuario_autorizador = 0 # Parece q este field no se va a usar
      @subtipo = 0
      @ultima_respuesta = current_user.id
      @texto = params[:texto]
      @solicitud = {}
      @solicitud['IdTipoSolicitud'] = @id_tipo_solicitud
      @solicitud['texto'] = @texto
      if @texto == ''
        return redirect_to "/auths/solicitudes", alert: "Mensaje inválido"
      end
      @id_respuesta = Time.now.to_i
      sql = "INSERT INTO AuthsRespuestas (IdSolicitud, IdRespuesta, Usuario, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{User.sanitize(@id_solicitud)}, #{@id_respuesta}, #{current_user.id}, #{User.sanitize(@texto)}, now(), now())"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/auths/solicitudes", alert: "No se ha podido crear la Respuesta de la Solicitud. Error: #{exc.message}"
      end
      sql = "INSERT INTO AuthsSolicitudes (IdSolicitud, IdTipoSolicitud, IdUsuarioSolicitante, IdUsuarioAutorizador, NivelActual, Subtipo, UltimaRespuesta, FechaCreacion, FechaActualizacion) VALUES ( #{User.sanitize(@id_solicitud)}, #{User.sanitize(@id_tipo_solicitud)}, #{User.sanitize(@id_usuario_solicitante)}, #{User.sanitize(@id_usuario_autorizador)}, #{User.sanitize(@nivel_actual)}, #{User.sanitize(@subtipo)}, #{User.sanitize(current_user.id)}, now(), now())"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/auths/solicitudes", alert: "No se ha podido crear la Solicitud. Error: #{exc.message}"
      end
      asunto = "##{@id_solicitud} #{@texto.to_s.gsub("\n", "").titleize.truncate(20)}"
      file_log = ""
      file_log_mail = ""
      if params.has_key?(:file)
        @respuestas_file = AuthsRespuestasFile.create(
          IdSolicitud: @id_solicitud, IdRespuesta: @id_respuesta, Usuario: current_user.id, file: params[:file]
        )
        if @respuestas_file.save
          sql = "INSERT INTO AuthsRespuestas (IdSolicitud, IdRespuesta, Usuario, Texto, File, FechaCreacion, FechaActualizacion) VALUES ( #{User.sanitize(@id_solicitud)}, #{@id_respuesta + 1}, #{current_user.id}, '', #{@respuestas_file.id}, now(), now())"
          begin
            @dbEsta.connection.execute(sql)
          rescue Exception => exc
            return redirect_to "/auths/solicitudes", alert: "No se ha podido guardar el archivo al crear la Solicitud. Error: #{exc.message}"
          end
          file_log = " con archivo #{@respuestas_file.file.url}"
          file_log_mail = "Con <a href='http://#{request.host_with_port}#{@respuestas_file.file.url}'>archivo adjunto</a>."
        else
          return redirect_to "/auths/solicitudes", alert: "Error al agregar al archivo"
        end
      end
      logTxt = "Solicitud creada por usuario: #{get_usuario(current_user.id)}. Tipo de Solicitud: #{get_tipo_solicitud(@id_tipo_solicitud)}. Solicitud: #{asunto}#{file_log}"
      sql = "INSERT INTO AuthsLogs (IdSolicitud, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{@id_solicitud}, #{User.sanitize(logTxt)}, now(), now() )"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/auths/solicitudes", alert: "No se ha podido guardar el log de la Solicitud. Error: #{exc.message}"
      end
      mail_to = get_emails_from_solicitud(@id_solicitud)
      mail_subject = @mail_subject
      mail_body    = "Solicitud creada por: #{get_usuario(current_user.id)}: #{asunto}<br /><br /><a href='http://#{request.host_with_port}/auths/solicitudes/#{@id_solicitud}'>Consultar la solicitud</a><br /><br /><STRONG>Contenido:</STRONG><br />#{@texto}<br />#{file_log_mail}<br /><br /><a href='http://#{request.host_with_port}/auths/solicitudes/#{@id_solicitud}'>Consultar la solicitud</a><br /><br />"
      mail_body = simple_format(mail_body, {}, sanitize: false, wrapper_tag: "div")
      mail_body = "<HTML><HEAD></HEAD><BODY><DIV style=\"FONT-SIZE: 12pt; FONT-FAMILY: 'Calibri'; COLOR: #000000\">#{mail_body}</DIV></BODY></HTML>"
      if modo_local?
        puts "Se iba a enviar el siguiente email pero manda localmente a la consola:\n  mail_to: #{mail_to}\n  mail_subject: #{mail_subject}\n  mail_body: #{mail_body}\n"
      else
        TicketsMailer.email_something_html(mail_to, mail_subject, mail_body).deliver_later if mail_to != ""
      end
      redirect_to "/auths/solicitudes/#{@id_solicitud}", notice: "Solicitud #{@new ? "creada" : "editada"} exitosamente"
    end

    def autorizar_rechazar_solicitud
      @autorizar = params[:autorizar].to_i if params.has_key?(:autorizar)
      # raise @autorizar.inspect
      @id_solicitud = @solicitud.first['IdSolicitud'].to_i
      @accion = @autorizar == 1 ? "Autorizada" : "Rechazada"
      asunto = "##{@id_solicitud} #{@texto.to_s.gsub("\n", "").titleize.truncate(20)}"
      @nivel_actual = @flujo['NivelFuturo'].to_i
      @nivel_actual = 60 if @autorizar != 1
      @texto = "Solicitud #{@accion} por usuario: #{get_usuario(current_user.id)}. Solicitud: #{asunto}. Nivel Actual: #{get_nivel(@nivel_actual)}"
      @id_respuesta = Time.now.to_i
      sql = "INSERT INTO AuthsRespuestas (IdSolicitud, IdRespuesta, Usuario, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{User.sanitize(@id_solicitud)}, #{@id_respuesta}, #{current_user.id}, #{User.sanitize(@texto)}, now(), now())"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/auths/solicitudes", alert: "No se ha podido crear la Respuesta de la Solicitud. Error: #{exc.message}"
      end
      sql = "INSERT INTO AuthsSolicitudes (IdSolicitud, NivelActual, FechaCreacion, FechaActualizacion) VALUES ( #{User.sanitize(@id_solicitud)}, #{User.sanitize(@nivel_actual)}, now(), now()) ON DUPLICATE KEY UPDATE NivelActual = #{User.sanitize(@nivel_actual)}, FechaActualizacion = now()"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/auths/solicitudes", alert: "No se ha podido editar la Solicitud. Error: #{exc.message}"
      end
      sql = "INSERT INTO AuthsLogs (IdSolicitud, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{@id_solicitud}, #{User.sanitize(@texto)}, now(), now() )"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/auths/solicitudes", alert: "No se ha podido guardar el log de la Solicitud. Error: #{exc.message}"
      end
      mail_to = get_emails_from_solicitud(@id_solicitud)
      mail_subject = @mail_subject
      mail_body    = "Solicitud #{@accion} por: #{get_usuario(current_user.id)}: #{asunto}<br /><br /><a href='http://#{request.host_with_port}/auths/solicitudes/#{@id_solicitud}'>Consultar la solicitud</a><br /><br /><STRONG>Contenido:</STRONG><br />#{@texto}<br /><a href='http://#{request.host_with_port}/auths/solicitudes/#{@id_solicitud}'>Consultar la solicitud</a><br /><br />"
      mail_body = simple_format(mail_body, {}, sanitize: false, wrapper_tag: "div")
      mail_body = "<HTML><HEAD></HEAD><BODY><DIV style=\"FONT-SIZE: 12pt; FONT-FAMILY: 'Calibri'; COLOR: #000000\">#{mail_body}</DIV></BODY></HTML>"
      if modo_local?
        puts "Se iba a enviar el siguiente email pero manda localmente a la consola:\n  mail_to: #{mail_to}\n  mail_subject: #{mail_subject}\n  mail_body: #{mail_body}\n"
      else
        TicketsMailer.email_something_html(mail_to, mail_subject, mail_body).deliver_later if mail_to != ""
      end
      redirect_to "/auths/solicitudes/", notice: "Solicitud #{@accion} exitosamente"
    end

    def get_id
      id = 1
      ids = @dbEsta.connection.select_all("SELECT max(IdSolicitud) as mid FROM AuthsSolicitudes")
      id = ids.first['mid'].to_i + 1 if ids.count == 1
      id
    end

    def borrar_solicitud_anterior(id)
      return if id < 1
      sql = "DELETE FROM AuthsRespuestas WHERE IdSolicitud = #{User.sanitize(id)}"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/auths/solicitudes", alert: "No se han podido borrar las respuestas de las Solicitudes anteriores"
      end
      sql = "DELETE FROM AuthsSolicitudes WHERE IdSolicitud = #{User.sanitize(id)}"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/auths/solicitudes", alert: "No se han podido borrar los encabezados de las Solicitudes anteriores"
      end
      sql = "DELETE FROM AuthsLogs WHERE IdSolicitud = #{User.sanitize(id)}"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/auths/solicitudes", alert: "No se ha podido borrar los logs de las Solicitudes anteriores"
      end
    end

    def get_flujos_for_current_user
      sql = "SELECT AuthsFlujos.* FROM AuthsFlujos WHERE IdUsuario = #{User.sanitize(current_user.id)}"
      @flujos = @dbEsta.connection.select_all(sql) rescue []
    end

    def find_flujos(id_tipo_solicitud, nivel_actual)
      sql = "SELECT AuthsFlujos.* FROM AuthsFlujos WHERE IdTipoSolicitud = #{User.sanitize(id_tipo_solicitud)} AND NivelActual = #{User.sanitize(nivel_actual)} ORDER BY IdUsuario"
      @flujos = @dbEsta.connection.select_all(sql).first rescue false
      redirect_to '/', alert: 'Flujos no encontrados' unless @flujos
    end

    def get_emails_from_solicitud(id)
      emails = []
      users = []
      get_solicitud(id)
      return [] unless @solicitud
      @mail_subject = "Solicitud: #{@solicitud['Texto'].to_s.truncate(30)} <#{get_usuario(@solicitud['IdUsuarioSolicitante'])}> [#{get_tipo_solicitud(@solicitud['IdTipoSolicitud'])}]"
      users.push(@solicitud['IdUsuarioSolicitante'])
      users.push(@solicitud['Responsable']) if @solicitud['IdUsuarioAutorizador'].to_i > 0
      users.push(current_user.id) if user_signed_in?
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
      mail_to = get_emails_from_solicitud(id)
      mail_subject = @mail_subject
      mail_body    = "Solicitud actualizada por: #{get_usuario(current_user.id)}.<br /><br /><a href='http://#{request.host_with_port}/auths/solicitudes/#{id}'>Consultar la solicitud</a><br /><br /><STRONG>Contenido:</STRONG><br />#{@logTxt}<br /><br /><a href='http://#{request.host_with_port}/auths/solicitudes/#{id}'>Consultar la solicitud</a><br /><br />"
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
end

