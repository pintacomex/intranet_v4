class AuthsRespuestasFilesController < ApplicationController
  include ::Auths::SolicitudesHelper
  before_filter :authenticate_user!
  before_filter :obtiene_catalogos
  before_filter :parametros_validos

  include ActionView::Helpers::TextHelper

  def create
    @respuestas_file = AuthsRespuestasFile.create(auths_respuestas_file_params)
    id = params[:IdSolicitud].to_i
    if @respuestas_file.save
      id_respuesta = params[:IdRespuesta].to_i
      sql = "INSERT INTO AuthsRespuestas (IdSolicitud, IdRespuesta, Usuario, Texto, File, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{id_respuesta}, #{User.sanitize(current_user.id)}, '', #{@respuestas_file.id}, now(), now())"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/auths/solicitudes/#{id}", alert: "No se ha podido guardar la respuesta de la Solicitud"
      end
      logTxt = "Solicitud actualizada por #{getUser(current_user.id)}. Ha subido un nuevo archivo: http://#{request.host_with_port}#{@respuestas_file.file.url}"
      sql = "INSERT INTO AuthsLogs (IdSolicitud, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{User.sanitize(logTxt)}, now(), now() )"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/auths/solicitudes/#{id}", alert: "No se ha podido guardar el log de la Solicitud"
      end
      @logTxt = "Solicitud actualizada por #{getUser(current_user.id)}. Ha subido <a href='http://#{request.host_with_port}#{@respuestas_file.file.url}'>un nuevo archivo</a>."
      enviar_emails(id)
      return redirect_to "/auths/solicitudes/#{id}", notice: "Archivo agregado correctamente"
    else
      return redirect_to "/auths/solicitudes/#{id}", alert: "Error al agregar al archivo"
    end
  end

  private

    def auths_respuestas_file_params
      params.require(:auths_respuestas_file).permit(:IdSolicitud, :IdRespuesta, :Usuario, :file)
    end

    def parametros_validos
      unless params[:auths_respuestas_file].present?
        return redirect_to '/auths', alert: 'Archivo no encontrado'
      end
    end

    def getUser(i)
      @users      = User.order(:name).map{|u| [u.name.to_s.gsub(" - ", " "), "#{u.id}"]}
      return @users.select { |item|  item[1] == "#{i}" }.first[0] rescue "No encontrado"
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

    def get_solicitud(id)
      sql = "SELECT AuthsSolicitudes.*, AuthsRespuestas.Texto AS Texto FROM AuthsSolicitudes LEFT JOIN AuthsRespuestas ON AuthsSolicitudes.IdSolicitud = AuthsRespuestas.IdSolicitud WHERE AuthsSolicitudes.IdSolicitud = #{id.to_i} LIMIT 1"
      @solicitud = @dbEsta.connection.select_all(sql)
      return false if @solicitud.count < 1
      @solicitud = @solicitud.first
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
      mail_body    = "Solicitud actualizada por: #{get_usuario(current_user.id)}.<br /><br /><a href='http://#{request.host_with_port}/auths/solicitud/#{id}'>Consultar la solicitud</a><br /><br /><STRONG>Contenido:</STRONG><br />#{@logTxt}<br /><br /><a href='http://#{request.host_with_port}/auths/solicitud/#{id}'>Consultar la solicitud</a><br /><br />"
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
