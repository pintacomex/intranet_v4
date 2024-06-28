class ContenedoresController < ApplicationController
  before_filter :authenticate_user!, except: [:contenedores_enviar_mails_robot, :contenedores_enviar_mails_robot_index]
  before_filter :tiene_permiso_de_ver_app, except: [:contenedores_enviar_mails_robot, :contenedores_enviar_mails_robot_index]

  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper
  include ApplicationHelper

  def index
    @ver_todos = true if params.has_key?(:ver_todos)
    load_cats

    unless @ver_todos
      filtrar_semaforos
    else
      @semaforos = @semaforos_sin_filtrar
    end
  end

  def contenedor
    @ct = params[:ct] if params.has_key?(:ct)
    return redirect_to '/contenedores', alert: "Contenedor no encontrado" if !@ct
    load_cats

    sql = "SELECT * from pdvbelice.contenedor where NumContenedor = #{User.sanitize(@ct)} limit 1"
    @contenedor = @dbPdv.connection.select_all(sql)

    sql = "SELECT * from pdvbelice.contenedorsemaforo3 where NumContenedor = #{User.sanitize(@ct)} limit 1"
    @semaforo = @dbPdv.connection.select_all(sql)
  end

  def contenedores_mails
    # http://rahca.com.mx:3000/contenedores_mails?Email=lola%40lola.com&Empresa=4&Sucursal=0&TipoMail=1&Zona=0
    # if params.has_key?(:Email) && params.has_key?(:Sucursal) && params.has_key?(:TipoMail) && params.has_key?(:Zona)
    sql = "SELECT ContenedoresMails.* from ContenedoresMails order by Email, Frecuencia, IdTarea"
    @contenedoresmails = @dbEsta.connection.select_all(sql)
  end

  def contenedores_mails_new
    load_tareas
  end

  def contenedores_mails_create
    if params.has_key?(:Email) && params.has_key?(:Frecuencia) && params.has_key?(:IdTarea)
        return redirect_to '/contenedores_mails_new', alert: "Favor de ingresar un Email valido" if ! params[:Email].to_s.include?("@")
        sql = "INSERT IGNORE INTO ContenedoresMails (Email, Frecuencia, IdTarea) VALUES (#{User.sanitize(params[:Email])}, #{User.sanitize(params[:Frecuencia].to_i)}, #{User.sanitize(params[:IdTarea].to_i)})"
        begin
            @dbEsta.connection.execute(sql)
        rescue Exception => exc
            return redirect_to '/contenedores_mails', alert: "Ha ocurrido un error: #{exc.message}"
        end
        begin
            @dbPdv.connection.execute(sql)
        rescue Exception => exc
            return redirect_to '/contenedores_mails', alert: "Ha ocurrido un error al escribir en Pdv: #{exc.message}"
        end
        return redirect_to '/contenedores_mails'
    end
    return redirect_to '/contenedores_mails', alert: "Favor de revisar sus datos"
  end

  def contenedores_mails_delete
    if params.has_key?(:Email) && params.has_key?(:Frecuencia) && params.has_key?(:IdTarea)
        sql = "DELETE FROM ContenedoresMails WHERE Email = #{User.sanitize(params[:Email])} and Frecuencia = #{User.sanitize(params[:Frecuencia].to_i)} and IdTarea = #{User.sanitize(params[:IdTarea].to_i)}"
        begin
            @dbEsta.connection.execute(sql)
        rescue Exception => exc
            return redirect_to '/contenedores_mails', alert: "Ha ocurrido un error: #{exc.message}"
        end
        begin
            @dbPdv.connection.execute(sql)
        rescue Exception => exc
            return redirect_to '/contenedores_mails', alert: "Ha ocurrido un error: #{exc.message}"
        end
        return redirect_to '/contenedores_mails', notice: "Datos modificados"
    end
    return redirect_to '/contenedores_mails', alert: "Favor de revisar sus datos"
  end

  def contenedores_enviar_mails_robot
    # Esta funcion deberia ejecutarse con un cron para enviar todos los mails de bajas
    # Se puede enviar un mail de prueba agregando el parametro email: /contenedores_enviar_mails_robot/?email=altuzzar@gmail.com
    index = -1
    index = params[:index].to_i if params.has_key?(:index)
    @emails_enviados = []

    load_cats
    filtrar_semaforos

    @email_contenido = []

    @contenedores.each do |item|
      mexPnm = item['RefContenedor'].to_s.start_with?("PNM") ? "Pnm" : "Mex"
      semaforo = @semaforos.select{ |i| i['NumContenedor'] == item['NumContenedor'] }.first rescue nil
      linea = ""
      if semaforo
        linea = "<STRONG><FONT color=#3D00FF>Contenedor: #{item['RefContenedor']}</FONT></STRONG>"
        i = 0
        ultimoDias = 1
        primera_tarea = true
        @tareas.each do |tarea|
          if tarea["dias#{mexPnm}"].to_i > 0
            i = i + 1
            while i < tarea["IdTarea"].to_i
              # linea += '<span style="color:#D3D3D3" class="glyphicon glyphicon-minus"></span> '
              i = i + 1
            end
            val = semaforo[tarea['tarea']]
            valFec = Date.parse(semaforo["#{tarea['tarea']}Fec"].to_s) rescue "Sin Fecha"
            valFecLim = Date.parse(semaforo["#{tarea['tarea']}Fec"].to_s) + ultimoDias rescue "Sin Fecha"
            tareaDetonadoraVal = semaforo[tarea['tareaDetonadora']]
            tareaDetonadoraValFec = Date.parse(semaforo["#{tarea['tareaDetonadora']}Fec"].to_s) rescue "Sin Fecha"
            tareaDetonadoraValFecLim = Date.parse(semaforo["#{tarea['tareaDetonadora']}Fec"].to_s) + ultimoDias rescue "Sin Fecha"
            diasFaltantes = tareaDetonadoraValFecLim - Date.today rescue -1
            diasVencido = Date.today - tareaDetonadoraValFecLim rescue -1
            ultimoDias = tarea["dias#{mexPnm}"].to_i
            status_checar_si_aplica = @tareasHash[tarea['tarea']]['StatusChecarSiAplica']
            status_checar_si_aplica_val = -1
            if status_checar_si_aplica.to_s != ''
              status_checar_si_aplica_val = semaforo[status_checar_si_aplica]
            end
            if primera_tarea
              primera_tarea = false
              linea += "<STRONG><FONT color=#3D00FF> de fecha #{valFec}</FONT></STRONG>\n"
            end
            if status_checar_si_aplica_val == 0
              # <span style="color:#D3D3D3" class="glyphicon glyphicon-unchecked"></span>
            elsif val == 1
              # linea += "<span class=\"glyphicon glyphicon-ok\"></span>"
            elsif val == 0 and tareaDetonadoraVal == 1 and diasVencido <= 0 # valFecLim != "Sin Fecha" and valFecLim >= Date.today
              linea += "&nbsp;&nbsp;<FONT color=#000>Tarea: #{tarea['Tooltip']}</FONT>\n"
              linea += "&nbsp;&nbsp;<FONT color=#483D8B>Actividad en progreso</FONT>\n"
            elsif val == 0 and tareaDetonadoraVal == 1 and (valFecLim == "Sin Fecha") or (valFecLim != "Sin Fecha" and valFecLim < Date.today)
              linea += "&nbsp;&nbsp;<FONT color=#000>Tarea: #{tarea['Tooltip']}</FONT>\n"
              linea += "&nbsp;&nbsp;<FONT color=red>Actividad retrasada"
              if diasVencido != -1
                linea += " #{diasVencido.to_i} días, fecha esperada: #{tareaDetonadoraValFecLim}"
              end
              linea += "</FONT>\n"
            end
          end
        end
        linea += "<br />"
        @email_contenido << linea
      end
    end

    sql = "SELECT * from ContenedoresMails WHERE IdTarea = 0"
    sql = "SELECT * from ContenedoresMails WHERE IdTarea = 0 AND Email = #{User.sanitize(params[:email])}" if params.has_key?(:email)
    @emails = @dbEsta.connection.select_all(sql)
    @emails.each_with_index do |e, email_index|
      next if index > -1 && index != email_index
      next if !e['Email'].to_s.include?("@")
      next if !debe_enviar_email(e)

      if @email_contenido.count > 0
        # Debe enviarse el email
        mail_to      = e['Email'].to_s.gsub(" ", "")
        mail_subject = "Reporte de Contenedores #{DateTime.now.to_s}"
        mail_body    = "Estos son los Contenedores con Alertas<br /><br />#{@email_contenido.join("\n\n")}"
        mail_body = simple_format(mail_body, {}, sanitize: false, wrapper_tag: "div")
        mail_body = "<HTML><HEAD></HEAD><BODY><DIV style=\"FONT-SIZE: 12pt; FONT-FAMILY: 'Calibri'; COLOR: #000000\">#{mail_body}</DIV></BODY></HTML>"
        if modo_local?
            puts "Se iba a enviar el siguiente email pero manda localmente a la consola:\n  mail_to: #{mail_to}\n mail_subject: #{mail_subject}\n  mail_body: #{mail_body}\n"
        else
          JustMailer.email_something_html(mail_to, mail_subject, mail_body).deliver_later
        end
        @emails_enviados.push({ index: index, email: e })
      end
    end

    # Ahora hay q mandar correos para todos por IdTarea con status En Proceso/Vencida/Terminada
    load_cats
    @semaforos = @semaforos_sin_filtrar

    @contenedores.each do |item|
      mexPnm = item['RefContenedor'].to_s.start_with?("PNM") ? "Pnm" : "Mex"
      semaforo = @semaforos.select{ |i| i['NumContenedor'] == item['NumContenedor'] }.first rescue nil
      if semaforo
        ultimoDias = 1
        @tareas.each do |tarea|
          if tarea["dias#{mexPnm}"].to_i > 0
            status_tarea = 0
            val = semaforo[tarea['tarea']]
            valFec = Date.parse(semaforo["#{tarea['tarea']}Fec"].to_s) rescue "Sin Fecha"
            valFecLim = Date.parse(semaforo["#{tarea['tarea']}Fec"].to_s) + ultimoDias rescue "Sin Fecha"
            tareaDetonadoraVal = semaforo[tarea['tareaDetonadora']]
            tareaDetonadoraValFec = Date.parse(semaforo["#{tarea['tareaDetonadora']}Fec"].to_s) rescue "Sin Fecha"
            tareaDetonadoraValFecLim = Date.parse(semaforo["#{tarea['tareaDetonadora']}Fec"].to_s) + ultimoDias rescue "Sin Fecha"
            diasFaltantes = tareaDetonadoraValFecLim - Date.today rescue -1
            diasVencido = Date.today - tareaDetonadoraValFecLim rescue -1
            ultimoDias = tarea["dias#{mexPnm}"].to_i
            status_checar_si_aplica = @tareasHash[tarea['tarea']]['StatusChecarSiAplica']
            status_checar_si_aplica_val = -1
            if status_checar_si_aplica.to_s != ''
              status_checar_si_aplica_val = semaforo[status_checar_si_aplica]
            end
            if status_checar_si_aplica_val == 0
              # <span style="color:#D3D3D3" class="glyphicon glyphicon-unchecked"></span>
              status_tarea = 1
            elsif val == 1
              status_tarea = 3
              # linea += "<span class=\"glyphicon glyphicon-ok\"></span>"
            elsif val == 0 and tareaDetonadoraVal == 1 and diasVencido <= 0 # valFecLim != "Sin Fecha" and valFecLim >= Date.today
              status_tarea = 2
              # linea += "&nbsp;&nbsp;<FONT color=#000>Tarea: #{tarea['Tooltip']}</FONT>\n"
              # linea += "&nbsp;&nbsp;<FONT color=#483D8B>Actividad en progreso</FONT>\n"
            elsif val == 0 and tareaDetonadoraVal == 1 and (valFecLim == "Sin Fecha") or (valFecLim != "Sin Fecha" and valFecLim < Date.today)
              status_tarea = 4
              # linea += "&nbsp;&nbsp;<FONT color=#000>Tarea: #{tarea['Tooltip']}</FONT>\n"
              # linea += "&nbsp;&nbsp;<FONT color=red>Actividad retrasada"
              # if diasVencido != -1
              #   linea += " #{diasVencido.to_i} días, fecha esperada: #{tareaDetonadoraValFecLim}"
              # end
              # linea += "</FONT>\n"
            end
            if status_tarea >= 2 and status_tarea <= 4
              sql = "INSERT IGNORE INTO ContenedoresStatusCorreos ( NumContenedor, IdTarea, Status, FechaInicio, FechaEsperada, FechaFinalizacion, DiasRestantes, DiasVencido, Notificado ) VALUES ( #{User.sanitize(item['NumContenedor'])}, #{User.sanitize(tarea['IdTarea'])}, #{User.sanitize(status_tarea)}, '#{tareaDetonadoraValFec.to_s}', '#{tareaDetonadoraValFecLim.to_s}', '#{valFec.to_s}', #{val == 0 && diasFaltantes >= 0 ? diasFaltantes.to_i : -1}, #{val == 0 && diasVencido >= 0 ? diasVencido.to_i : -1}, 0 )"
              begin
                @dbEsta.connection.execute(sql)
              rescue Exception => exc
                  return redirect_to '/contenedores_mails', alert: "Ha ocurrido un error: #{exc.message}"
              end
            end
          end
        end
      end
    end

    id_tareas_a_notificar = []
    sql = "SELECT * from ContenedoresMails WHERE IdTarea != 0"
    sql = "SELECT * from ContenedoresMails WHERE IdTarea != 0 AND Email = #{User.sanitize(params[:email])}" if params.has_key?(:email)
    @emails = @dbEsta.connection.select_all(sql)
    @emails.each_with_index do |e, email_index|
      # next if index > -1 && index != email_index # este index ya no funciona a veces
      next if !e['Email'].to_s.include?("@")
      next if !debe_enviar_email(e)
      id_tareas_a_notificar << e['IdTarea'].to_i
      id_tareas_a_notificar.uniq!
    end

    # Este hash va a tener idtarea con un array de email contenido
    email_contenido_por_id_tarea = {}

    id_tareas_a_notificar.each do |idTarea|

      @email_contenido = []

      sql = "SELECT * from ContenedoresStatusCorreos WHERE IdTarea = #{User.sanitize(idTarea)} AND Notificado = 0"
      @cscs = @dbEsta.connection.select_all(sql)
      @cscs.each do |item|

        contenedor = @contenedores.select{ |i| i['NumContenedor'] == item['NumContenedor'] }.first rescue nil
        next if contenedor.nil?
        tarea = @tareasHashPorIdTarea[item['IdTarea']]

        linea = "<STRONG><FONT color=#3D00FF>Contenedor: #{contenedor['RefContenedor']}</FONT></STRONG>"
        linea += "<STRONG><FONT color=#3D00FF> de fecha #{item['FechaFinalizacion']}</FONT></STRONG>\n"

        status_tarea = item['Status'].to_i
        status_texto = if status_tarea == 2
          "<FONT color=#483D8B>Actividad en progreso</FONT>"
        elsif status_tarea == 3
          "<FONT color=green>Actividad terminada</FONT>"
        elsif status_tarea == 4
          "<FONT color=red>Actividad retrasada</FONT>"
        else
          'NO RECONOCIDA'
        end
        linea += "&nbsp;&nbsp;<STRONG><FONT color=#3D00FF>Status de tarea:</FONT>&nbsp;&nbsp;#{status_texto}\n"
        linea += "&nbsp;&nbsp;<FONT color=#000>Tarea No: #{item['IdTarea'].to_i}</FONT>\n"
        linea += "&nbsp;&nbsp;<FONT color=#000>Descripcion: #{tarea['Tooltip']}</FONT>\n"
        linea += "&nbsp;&nbsp;<FONT color=#000>Fecha de inicio: #{item['FechaInicio']}</FONT>\n"
        linea += "&nbsp;&nbsp;<FONT color=#000>Fecha estimada final: #{item['FechaEsperada']}</FONT>\n"
        linea += "&nbsp;&nbsp;<FONT color=#000>Dias restantes: #{item['DiasRestantes'] >= 0 ? item['DiasRestantes'] : ""}</FONT>\n"
        linea += "&nbsp;&nbsp;<FONT color=#000>Dias vencido: #{item['DiasVencido'] >= 0 ? item['DiasVencido'] : ""}</FONT>\n"

        @email_contenido << linea

        sql = "UPDATE ContenedoresStatusCorreos SET Notificado = 1 WHERE NumContenedor = '#{item['NumContenedor']}' AND IdTarea = #{item['IdTarea']} AND Status = #{item['Status']}"
        begin
          @dbEsta.connection.execute(sql)
        rescue Exception => exc
          return redirect_to '/contenedores_mails', alert: "Ha ocurrido un error: #{exc.message}"
        end
      end

      if @email_contenido.count > 0
        email_contenido_por_id_tarea[idTarea] = @email_contenido
      end
    end

    @emails.each_with_index do |e, email_index|
      # next if index > -1 && index != email_index
      next if !e['Email'].to_s.include?("@")
      next if !debe_enviar_email(e)

      # Enviar los emails a cada email_contenido_por_id_tarea

      if email_contenido_por_id_tarea.has_key?(e['IdTarea'].to_i)
        # Debe enviarse el email
        mail_to      = e['Email'].to_s.gsub(" ", "")
        mail_subject = "Reporte de Contenedores con Actividades de Tareas con ID #{e['IdTarea'].to_i} #{DateTime.now.to_s}"
        mail_body    = "Estos son los Contenedores con Actividades de Tareas con ID #{e['IdTarea'].to_i}<br /><br />#{email_contenido_por_id_tarea[e['IdTarea'].to_i].join("\n\n")}"
        mail_body = simple_format(mail_body, {}, sanitize: false, wrapper_tag: "div")
        mail_body = "<HTML><HEAD></HEAD><BODY><DIV style=\"FONT-SIZE: 12pt; FONT-FAMILY: 'Calibri'; COLOR: #000000\">#{mail_body}</DIV></BODY></HTML>"
        if modo_local?
            puts "Se iba a enviar el siguiente email pero manda localmente a la consola:\n  mail_to: #{mail_to}\n mail_subject: #{mail_subject}\n  mail_body: #{mail_body}\n"
        else
          JustMailer.email_something_html(mail_to, mail_subject, mail_body).deliver_later
        end
        @emails_enviados.push({ index: index, email: e })
      end
    end

    render status: 200, json: { info: "Tarea ejecutada exitosamente. Modo Local: #{modo_local?}. Emails enviados: #{@emails_enviados.count}: #{@emails_enviados.to_json}" }
    return
  end

  def contenedores_enviar_mails_robot_index
    sql = "SELECT * from ContenedoresMails"
    @emails = @dbEsta.connection.select_all(sql)
    render status: 200, json: { emails: @emails.to_json }
  end

  private

  def debe_enviar_email(email)
    # Aqui se decide si debe enviar el mail o no, dependiendo si es semanal o mensual
    return true if email['Frecuencia'] == 0
    return true if email['Frecuencia'] == 1 and Date.today.monday? # Lunes
    return true if email['Frecuencia'] == 2 and Date.today.mday == 1 # Primero de mes
    false
  end

  def modo_local?
    sending_host = request.host.gsub("www.","").gsub(".com","").gsub(".mx","").gsub(".dyndns.org","").gsub(".dyndns.biz","").gsub("intranet","").gsub("comex","").gsub("bajapaint","").gsub("pintacomex","")
    return true if sending_host == "localhost"
    false
  end

  def filtrar_semaforos
    if @contenedores.count > 0
      @contenedores.each do |item|
        mexPnm = item['RefContenedor'].to_s.start_with?("PNM") ? "Pnm" : "Mex"
        semaforo = @semaforos_sin_filtrar.select{ |i| i['NumContenedor'] == item['NumContenedor'] }.first rescue nil
        if semaforo
          deberia_agregar = false
          @tareas.each do |tarea|
            if tarea["dias#{mexPnm}"].to_i > 0
              val = semaforo[tarea['tarea']]
              status_checar_si_aplica = @tareasHash[tarea['tarea']]['StatusChecarSiAplica']
              status_checar_si_aplica_val = -1
              status_checar_si_aplica_val = semaforo[status_checar_si_aplica] if status_checar_si_aplica.to_s != ''
              next if status_checar_si_aplica_val == 0
              if val != 1
                deberia_agregar = true
                break
              end
            end
          end
          if deberia_agregar == true
            @semaforos << semaforo
          end
        end
      end
    end
  end

  def load_cats
    load_tareas

    sql = "SELECT * from pdvbelice.contenedor where StatusContenedor = 0 order by NumContenedor limit 1000"
    @contenedores = @dbPdv.connection.select_all(sql)

    sql = "SELECT * from pdvbelice.contenedorsemaforo3 limit 1000"
    @semaforos_sin_filtrar = @dbPdv.connection.select_all(sql)
    @semaforos = []
  end

  def load_tareas
    sql = "SELECT * from pdvbelice.tareasContenedores order by IdTarea limit 1000"
    @tareas = @dbPdv.connection.select_all(sql)

    @tareasHash = {}
    @tareas.each do |tarea|
      @tareasHash[tarea['tarea']] = tarea
    end
    @tareasHashPorIdTarea = {}
    @tareas.each do |tarea|
      @tareasHashPorIdTarea[tarea['IdTarea']] = tarea
    end
  end
end
