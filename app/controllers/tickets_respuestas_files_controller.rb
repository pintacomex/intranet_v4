class TicketsRespuestasFilesController < ApplicationController
  include TicketsHelper
  before_filter :authenticate_user!
  before_filter :obtiene_catalogos
  before_filter :parametros_validos

  include ActionView::Helpers::TextHelper

  def create
    @todos_respuestas_file = TodosRespuestasFile.create( todos_respuestas_file_params )
    id = params[:IdHTodo].to_i
    if @todos_respuestas_file.save
      id_respuesta = params[:IdRespuesta].to_i
      sql = "INSERT INTO TodosRespuestas (IdHTodo, IdRespuesta, Usuario, Texto, File, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{id_respuesta}, #{User.sanitize(current_user.id)}, '', #{@todos_respuestas_file.id}, now(), now())"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/tickets_show?id=#{id}", alert: "No se ha podido guardar la respuesta del Ticket"
      end
      logTxt = "Ticket actualizado por #{getUser(current_user.id)}. Ha subido un nuevo archivo: http://#{request.host_with_port}#{@todos_respuestas_file.file.url}"
      sql = "INSERT INTO TodosLogs (IdHTodo, Texto, FechaCreacion, FechaActualizacion) VALUES ( #{id}, #{User.sanitize(logTxt)}, now(), now() )"
      begin
        @dbEsta.connection.execute(sql)
      rescue Exception => exc
        return redirect_to "/tickets_show?id=#{id}", alert: "No se ha podido guardar el log del Ticket"
      end
      @logTxtMail = "Ticket actualizado por #{getUser(current_user.id)}. Ha subido <a href='http://#{request.host_with_port}#{@todos_respuestas_file.file.url}'>un nuevo archivo</a>."
      enviar_emails(id)
    	return redirect_to "/tickets_show?id=#{id}", notice: "Archivo agregado correctamente"
    else
    	return redirect_to "/tickets_show?id=#{id}", alert: "Error al agregar al archivo"
    end
  end

  private

    def todos_respuestas_file_params
      params.require(:todos_respuestas_file).permit(:IdHTodo, :IdRespuesta, :Usuario, :file)
    end

    def parametros_validos
      unless params[:todos_respuestas_file].present?
        return redirect_to '/tickets', alert: 'Archivo no encontrado'
      end
    end

    def getUser(i)
      @users      = User.order(:name).map{|u| [u.name.to_s.gsub(" - ", " "), "#{u.id}"]}
      return @users.select { |item|  item[1] == "#{i}" }.first[0] rescue "No encontrado"
    end

    def obtiene_catalogos
      # @areas = [ [ "Administración", 1 ], [ "Sistemas", 2 ], [ "Ventas", 3 ] ]
      @prioridades = [ [ "Normal", 2 ], [ "Baja", 1 ],  [ "Alta", 3 ], [ "Urgente", 4 ] ]
      # @tipos = [ [ "Tarea", 1 ], [ "Recordatorio", 2 ], [ "Otro", 3 ] ]
      @tipos = [ ['Soporte Técnico', 1], ['Soporte Acapulco', 3], ['Soporte Chilpo', 4], ['Soporte Coatza', 5], ['Soporte Taxco', 6], ['Soporte Sistemas', 2] ]
      @status = [ [ "Abierto", 1 ], [ "En Progreso", 2 ], [ "Esperando Respuesta", 3 ],  [ "En Espera", 4 ], [ "Cerrado", 5 ], [ "Desechado", 6 ] ]
      # Aqui debería seleccionar sólo a los que tienen acceso al modulo (y otro de sólo staff)
      @users      = User.order(:name).map{|u| [u.name.to_s.gsub(" - ", " "), "#{u.id}"]}
      @emails     = User.order(:name).map{|u| [u.email.downcase, "#{u.id}"]}
      @dest_users = User.joins("LEFT JOIN permisos ON users.id = permisos.idUsuario").where("permisos.id > 0").order(:name).map{|u| ["Usuario: #{u.name.to_s.gsub(" - ", " ")}", "u#{u.id}"]}.uniq
      @sucursales = @dbComun.connection.select_all("SELECT * FROM sucursal WHERE TipoSuc = 'S' ORDER BY Num_suc").map{|u| ["- Sucursal: #{u['Num_suc']} - #{u['Nombre']}", "s#{u['Num_suc']}"]}.uniq rescue []
      @grupos =  @dbEsta.connection.select_all("SELECT * FROM GruposHGrupos ORDER BY IdGrupo").map{|u| ["#{u['Nombre']}", "#{u['IdGrupo']}"]}.uniq rescue []
      @involucrados = []
    end

    def get_emails_from_ticket(id)
      emails = []
      users = []
      sql = "SELECT TodosHTodos.*, TodosRespuestas.Usuario, TodosRespuestas.Texto, TodosRespuestas.IdRespuesta, TodosRespuestas.FechaCreacion as RFechaCreacion, TodosRespuestas.File FROM TodosHTodos LEFT JOIN TodosRespuestas ON TodosHTodos.IdHTodo = TodosRespuestas.IdHTodo WHERE TodosHTodos.IdHTodo = #{id.to_i} ORDER BY TodosRespuestas.IdHTodo DESC LIMIT 100"
      todo = @dbEsta.connection.select_all(sql)
      return [] if todo.count < 1
      @mail_subject = "Ticket: #{todo.first['Asunto']} <#{getUser(todo.first['CreadoPor'])}> [#{getTipoGrupo(todo.first['Tipo'])}]"
      todo.each do |u|
        users.push(u['CreadoPor'])
        users.push(u['Responsable'])
        users.push(u['Usuario'])
      end
      sql = "SELECT GruposDGrupos.* FROM GruposDGrupos LEFT JOIN GruposHGrupos ON GruposHGrupos.IdGrupo = GruposDGrupos.IdGrupo WHERE GruposHGrupos.IdGrupo = #{User.sanitize(todo.first['Tipo'])} ORDER BY GruposDGrupos.IdUser DESC"
      dgrupo = @dbEsta.connection.select_all(sql)
      dgrupo.each do |u|
        users.push(u['IdUser'])
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
      mail_to = get_emails_from_ticket(id)
      mail_subject = @mail_subject
      mail_body    = "#{@logTxtMail}<br /><br /><a href='http://#{request.host_with_port}/tickets_show?id=#{id}'>Consultar el ticket</a><br /><br /><STRONG>Contenido:</STRONG><br />#{@logTxtMail}<br /><br /><a href='http://#{request.host_with_port}/tickets_show?id=#{id}'>Consultar el ticket</a><br /><br />"
      mail_body = simple_format(mail_body, {}, sanitize: false, wrapper_tag: "div")
      mail_body = "<HTML><HEAD></HEAD><BODY><DIV style=\"FONT-SIZE: 12pt; FONT-FAMILY: 'Calibri'; COLOR: #000000\">#{mail_body}</DIV></BODY></HTML>"
      if modo_local?
        puts "Se iba a enviar el siguiente email pero manda localmente a la consola:\n  mail_to: #{mail_to}\n  mail_subject: #{mail_subject}\n  mail_body: #{mail_body}\n"
      else
        JustMailer.email_something_html(mail_to, mail_subject, mail_body).deliver_later if mail_to != ""
      end
    end

    def modo_local?
      sending_host = request.host.gsub("www.","").gsub(".com","").gsub(".mx","").gsub(".dyndns.org","").gsub(".dyndns.biz","").gsub("intranet","").gsub("comex","").gsub("bajapaint","").gsub("pintacomex","")
      return true if sending_host == "localhost"
      false
    end
end
