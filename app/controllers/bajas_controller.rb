class BajasController < ApplicationController
  before_filter :authenticate_user!, except: [:bajas_enviar_mails_robot, :bajas_enviar_mails_robot_index]
  before_filter :tiene_permiso_de_ver_app, except: [:bajas_enviar_mails_robot, :bajas_enviar_mails_robot_index]

  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper

  def index
    get_filtros_from_user
    @ver_autorizadas = false
    @ver_autorizadas = params[:ver_autorizadas] if params.has_key?(:ver_autorizadas)
    if ['nn', 'an', 'na', 'aa', 'nx'].include? @ver_autorizadas 
        @filtros.push("(RegAutorizacion = 0  or RegAutorizacion IS NULL) and (CtlAutorizacion = 0  or CtlAutorizacion IS NULL)") if @ver_autorizadas == 'nn'
        @filtros.push("(RegAutorizacion = 0 or RegAutorizacion IS NULL)") if @ver_autorizadas == 'nx'
        @filtros.push("(CtlAutorizacion = 0 or CtlAutorizacion IS NULL)") if @ver_autorizadas == 'an'
        @filtros.push("RegAutorizacion = 1 and CtlAutorizacion = 1") if @ver_autorizadas == 'aa'
    end
    @fecha = (Date.today - 90.days).to_s.gsub("-","")
    sql = "SELECT BajasHmov.*, sucursal.Nombre, sucursal.ZonaAsig, catbajas.Descrip, BajasAuth.RegAutorizacion as baRegAutorizacion, BajasAuth.CtlAutorizacion as baCtlAutorizacion FROM BajasHmov LEFT JOIN #{@nomDbComun}sucursal ON Num_suc = Sucursal LEFT JOIN #{@nomDbPdv}catbajas ON Folioinfo = Categoria LEFT JOIN BajasAuth ON BajasAuth.Sucursal = BajasHmov.Sucursal AND BajasAuth.Fecha = BajasHmov.Fecha AND BajasAuth.Nummov = BajasHmov.Nummov WHERE BajasHmov.fecha > '#{@fecha}' AND tipo_subt = 'B' AND status2 = 'T' AND abs(total) >= 100 AND ( ( #{@filtros.join(" ) AND ( ")} ) ) ORDER BY BajasHmov.fecha DESC, Sucursal ASC, Nummov ASC"
    @bajas = @dbEsta.connection.select_all(sql)
    @bajas.each do |b|
      if b['Total'] < 10.0 || "#{b['Tipo_subt']}#{b['Folioinfo']}" == "B20"
        sql = "SELECT * from BajasAuth where Sucursal = #{b['Sucursal']} and Nummov = #{b['Nummov']} and Fecha = #{b['Fecha']}"
        baja = @dbEsta.connection.select_all(sql)
        if baja.length < 1
          sql = "INSERT INTO BajasAuth ( Sucursal, Fecha, Nummov, RegFechaHora, CtlFechaHora, RegIdUser, CtlIdUser, RegAutorizacion, CtlAutorizacion, RegComentario, CtlComentario ) VALUES ( #{User.sanitize(b['Sucursal'])}, #{User.sanitize(b['Fecha'])}, #{User.sanitize(b['Nummov'])}, now(), now(), #{User.sanitize(0)}, #{User.sanitize(0)}, 1, 1, #{ User.sanitize('Autorizado por el Robot') }, #{ User.sanitize('Autorizado por el Robot') } )"
          @dbEsta.connection.execute(sql)
        end
      end
    end
    sql = "SELECT BajasHmov.*, sucursal.Nombre, sucursal.ZonaAsig, catbajas.Descrip, BajasAuth.RegAutorizacion as baRegAutorizacion, BajasAuth.CtlAutorizacion as baCtlAutorizacion FROM BajasHmov LEFT JOIN #{@nomDbComun}sucursal ON Num_suc = Sucursal LEFT JOIN #{@nomDbPdv}catbajas ON Folioinfo = Categoria LEFT JOIN BajasAuth ON BajasAuth.Sucursal = BajasHmov.Sucursal AND BajasAuth.Fecha = BajasHmov.Fecha AND BajasAuth.Nummov = BajasHmov.Nummov WHERE BajasHmov.fecha > '#{@fecha}' AND tipo_subt = 'B' AND status2 = 'T' AND abs(total) >= 100 AND ( ( #{@filtros.join(" ) AND ( ")} ) ) ORDER BY BajasHmov.fecha DESC, Sucursal ASC, Nummov ASC"
    @bajas = @dbEsta.connection.select_all(sql)
    respond_to do |format|
        format.html
    end        
  end

  def bajas_obra
    get_filtros_from_user
    @idobra = params[:idobra].to_i if params.has_key?(:idobra)
    if @idobra > 0
        @filtros.push("IdObra = #{@idobra}")
        sql = "SELECT BajasHmov.*, sucursal.Nombre, sucursal.ZonaAsig, catbajas.Descrip, tipomov.NomTipoSubTipo, BajasAuth.RegAutorizacion as baRegAutorizacion, BajasAuth.CtlAutorizacion as baCtlAutorizacion FROM BajasHmov LEFT JOIN #{@nomDbComun}sucursal ON Num_suc = Sucursal LEFT JOIN #{@nomDbPdv}catbajas ON Folioinfo = Categoria LEFT JOIN #{@nomDbPdv}tipomov ON Tipo_subt = TipoSubTipo LEFT JOIN BajasAuth ON BajasAuth.Sucursal = BajasHmov.Sucursal AND BajasAuth.Fecha = BajasHmov.Fecha AND BajasAuth.Nummov = BajasHmov.Nummov WHERE status2 = 'T' AND ( ( #{@filtros.join(" ) AND ( ")} ) ) ORDER BY BajasHmov.fecha DESC, Sucursal ASC, Nummov ASC limit 1000"
        @bajas = @dbEsta.connection.select_all(sql)
        return redirect_to bajas_path, alert: "No Encontrado" if @bajas.count < 1
        respond_to do |format|
            format.html
        end
    else
        return redirect_to bajas_path, alert: "No Authorizado"
    end
  end

  def bajas_detalle
    get_filtros_from_user
    @sucursal = params[:sucursal].to_i if params.has_key?(:sucursal)
    @fecha    = params[:fecha].to_i if params.has_key?(:fecha)
    @nummov   = params[:nummov].to_i if params.has_key?(:nummov)
    if @sucursal > 0 and @fecha > 20000000 and @nummov > 0
        @filtros_hmov = []
        @filtros_hmov.push("Sucursal = #{@sucursal.to_i}")
        @filtros_hmov.push("Fecha = #{@fecha.to_i}")
        @filtros_hmov.push("Nummov = #{@nummov.to_i}")
        get_modulos_usuario
        @es_regional  = false
        @es_regional  = true if @user_permisos[:nivel] == 10
        @es_contralor = false
        @es_contralor = true if @user_permisos[:nivel] == 5
        #Aqui ve si se mando una Auth y Comentario para guardarlos
        if @es_regional or @es_contralor
            prefix = "Reg"
            prefix = "Ctl" if @es_contralor
            auth       = params[:auth].to_i  if params.has_key?(:auth)
            comentario = params[:comentario] if params.has_key?(:comentario)
            if auth != 0 && comentario.to_s.length > 0
                sql = "INSERT INTO BajasAuth ( Sucursal, Fecha, Nummov, #{prefix}FechaHora, #{prefix}IdUser, #{prefix}Autorizacion, #{prefix}Comentario ) VALUES ( #{User.sanitize(@sucursal)}, #{User.sanitize(@fecha)}, #{User.sanitize(@nummov)}, now(), #{User.sanitize(current_user.id)}, 1, #{ User.sanitize(comentario) } ) ON DUPLICATE KEY UPDATE #{prefix}FechaHora = now(), #{prefix}IdUser = #{User.sanitize(current_user.id)}, #{prefix}Autorizacion = 1, #{prefix}Comentario = #{User.sanitize(comentario)}"
                begin
                  @dbEsta.connection.execute(sql)
                rescue Exception => exc 
                  return redirect_to "/bajas_detalle?sucursal=#{@sucursal}&fecha=#{@fecha}&nummov=#{@nummov}", alert: "No se ha podido guardar la autorización"
                end
                begin
                  @dbPdv.connection.execute(sql)
                rescue Exception => exc 
                  return redirect_to "/bajas_detalle?sucursal=#{@sucursal}&fecha=#{@fecha}&nummov=#{@nummov}", alert: "No se ha podido guardar la autorización"
                end             
                # AQUI DEBE GENERARSE UN COMENTARIO CON LA AUTORIZACION
                nuevo_comentario = "Nueva Autorización del #{prefix == "Reg" ? "Regional" : "Contralor"}: #{comentario}"
                sql = "INSERT INTO BajasChat ( Sucursal, Fecha, Nummov, FechaHora, IdUser, Comentario ) VALUES ( #{User.sanitize(@sucursal)}, #{User.sanitize(@fecha)}, #{User.sanitize(@nummov)}, now(), #{User.sanitize(current_user.id)}, #{User.sanitize(nuevo_comentario)} )"
                begin
                  @dbEsta.connection.execute(sql)
                rescue Exception => exc 
                  return redirect_to "/bajas_detalle?sucursal=#{@sucursal}&fecha=#{@fecha}&nummov=#{@nummov}", alert: "No se ha podido guardar el comentario despues de agregar la autorización"
                end
                # Se escribe por duplicado en Esta y Pdv
                begin
                  @dbPdv.connection.execute(sql)
                rescue Exception => exc 
                  return redirect_to "/bajas_detalle?sucursal=#{@sucursal}&fecha=#{@fecha}&nummov=#{@nummov}", alert: "No se ha podido guardar el comentario en PDV despues de agregar autorización"
                end            
                # Aqui se manda un mail de los comentarios
                # enviar_mails_comentarios(@suc_origen, @control_fac, current_user.id, @nuevo_comentario)
                return redirect_to "/bajas_detalle?sucursal=#{@sucursal}&fecha=#{@fecha}&nummov=#{@nummov}", notice: "Autorización guardada exitosamente"
            end
            # Aqui se ve si se mando un borrar_auth para borrarlo
            @borrar_auth = params[:borrar_auth].to_i if params.has_key?(:borrar_auth)
            if @borrar_auth == 0
                prefix = ""
                prefix = "Reg" if params[:borrar_auth] == "reg"
                prefix = "Ctl" if params[:borrar_auth] == "ctl"
                # El Contralor puede borrar la auth de Regional pero no al reves
                if ( prefix == "" or ( @es_regional and prefix == "ctl" ) ) 
                  return redirect_to "/bajas_detalle?sucursal=#{@sucursal}&fecha=#{@fecha}&nummov=#{@nummov}", alert: "No autorizado"
                end
                sql = "UPDATE BajasAuth SET #{prefix}FechaHora = NULL, #{prefix}IdUser = 0, #{prefix}Autorizacion = 0, #{prefix}Comentario = '' WHERE Sucursal = #{ User.sanitize(@sucursal) } AND Fecha = #{ User.sanitize(@fecha) } AND Nummov = #{ User.sanitize(@nummov)}"
                begin
                  @dbEsta.connection.execute(sql)
                rescue Exception => exc 
                  return redirect_to "/bajas_detalle?sucursal=#{@sucursal}&fecha=#{@fecha}&nummov=#{@nummov}", alert: "No se ha podido borrar la Autorizacion"
                end
                begin
                  @dbPdv.connection.execute(sql)
                rescue Exception => exc 
                  return redirect_to "/bajas_detalle?sucursal=#{@sucursal}&fecha=#{@fecha}&nummov=#{@nummov}", alert: "No se ha podido borrar la Autorización"
                end
                # AQUI DEBE GENERARSE UN COMENTARIO CON LA AUTORIZACION BORRADA
                nuevo_comentario = "Autorización Removida por el #{prefix == "Reg" ? "Regional" : "Contralor"}"
                sql = "INSERT INTO BajasChat ( Sucursal, Fecha, Nummov, FechaHora, IdUser, Comentario ) VALUES ( #{User.sanitize(@sucursal)}, #{User.sanitize(@fecha)}, #{User.sanitize(@nummov)}, now(), #{User.sanitize(current_user.id)}, #{User.sanitize(nuevo_comentario)} )"
                begin
                  @dbEsta.connection.execute(sql)
                rescue Exception => exc 
                  return redirect_to "/bajas_detalle?sucursal=#{@sucursal}&fecha=#{@fecha}&nummov=#{@nummov}", alert: "No se ha podido guardar el comentario despues de borrar la autorización"
                end
                # Se escribe por duplicado en Esta y Pdv
                begin
                  @dbPdv.connection.execute(sql)
                rescue Exception => exc 
                  return redirect_to "/bajas_detalle?sucursal=#{@sucursal}&fecha=#{@fecha}&nummov=#{@nummov}", alert: "No se ha podido guardar el comentario en PDV despues de borrar la autorización"
                end                
                return redirect_to "/bajas_detalle?sucursal=#{@sucursal}&fecha=#{@fecha}&nummov=#{@nummov}", notice: "Autorización borrada exitosamente"
            end            
        end        
        # Aqui se ve si se mando un nuevo comentario al Chat
        @nuevo_comentario = params[:nuevo_comentario] if params.has_key?(:nuevo_comentario)        
        if @nuevo_comentario && @nuevo_comentario.to_s.length > 0
            sql = "INSERT INTO BajasChat ( Sucursal, Fecha, Nummov, FechaHora, IdUser, Comentario ) VALUES ( #{ User.sanitize(@sucursal) }, #{ User.sanitize(@fecha) }, #{ User.sanitize(@nummov) }, now(), #{ User.sanitize(current_user.id) }, #{ User.sanitize(@nuevo_comentario) } )"
            begin
              @dbEsta.connection.execute(sql)
            rescue Exception => exc 
              return redirect_to "/bajas_detalle?sucursal=#{@sucursal}&fecha=#{@fecha}&nummov=#{@nummov}", alert: "No se ha podido guardar el comentario"
            end
            # Se escribe por duplicado en Esta y Pdv
            begin
              @dbPdv.connection.execute(sql)
            rescue Exception => exc 
              return redirect_to "/bajas_detalle?sucursal=#{@sucursal}&fecha=#{@fecha}&nummov=#{@nummov}", alert: "No se ha podido guardar el comentario en PDV"
            end            
            # Aqui se manda un mail de los comentarios
            # enviar_mails_comentarios(@suc_origen, @control_fac, current_user.id, @nuevo_comentario)
            return redirect_to "/bajas_detalle?sucursal=#{@sucursal}&fecha=#{@fecha}&nummov=#{@nummov}", notice: "Comentario guardado exitosamente"
        end
        # Aqui carga los datos de hmovpdv, dmovpdv y los movs ant/pos        
        sql = "SELECT hmovpdv.*, sucursal.Nombre, sucursal.ZonaAsig, catbajas.Descrip, tipomov.NomTipoSubTipo, clientes.Nombre as cliNombre, clientes.Rfc, clientes.Callenum, clientes.NumExt, clientes.Callenum, clientes.NumInt, clientes.Colonia, clientes.Delemuni, BajasAuth.RegFechaHora as baRegFechaHora, BajasAuth.RegIdUser as baRegIdUser, BajasAuth.RegAutorizacion as baRegAutorizacion, BajasAuth.RegComentario as baRegComentario, '' as baRegUserEmail, '' as baRegUserName, BajasAuth.CtlFechaHora as baCtlFechaHora, BajasAuth.CtlIdUser as baCtlIdUser, BajasAuth.CtlAutorizacion as baCtlAutorizacion, BajasAuth.CtlComentario as baCtlComentario, '' as baCtlUserEmail, '' as baCtlUserName FROM #{@nomDbPdv}hmovpdv LEFT JOIN #{@nomDbComun}sucursal ON Num_suc = Sucursal LEFT JOIN #{@nomDbPdv}catbajas ON Folioinfo = Categoria LEFT JOIN #{@nomDbPdv}tipomov ON Tipo_subt = TipoSubTipo LEFT JOIN #{@nomDbPdv}clientes ON clientes.Sucursal = hmovpdv.Sucursal AND clientes.Idcliente = hmovpdv.Idcliente LEFT JOIN BajasAuth ON BajasAuth.Sucursal = hmovpdv.Sucursal AND BajasAuth.Fecha = hmovpdv.Fecha AND BajasAuth.Nummov = hmovpdv.Nummov WHERE ( ( hmovpdv.#{@filtros_hmov.join(" ) AND ( hmovpdv.")} ) ) AND status2 = 'T' AND ( ( #{@filtros.join(" ) AND ( ")} ) ) ORDER BY Fecha DESC, hmovpdv.Sucursal ASC, Nummov ASC limit 1000"
        @bajas = @dbEsta.connection.select_all(sql)
        return redirect_to bajas_path, alert: "No Encontrado" if @bajas.count != 1
        # Populate data from intranet.users as it's in other server
        @bajas.each do |a|
            ['baRegIdUser', 'baCtlIdUser'].each do |field|
                if a[field].to_i > 0
                    u = User.where("id = #{a[field]}").first
                    a["#{field.gsub("IdUser","")}UserEmail'"] = u.email rescue ''
                    a["#{field.gsub("IdUser","")}UserName"]   = u.name  rescue ''
                end
            end
        end
        # raise @bajas.inspect     
        sql = "SELECT * FROM #{@nomDbPdv}dmovpdv WHERE ( #{@filtros_hmov.join(" AND ")} AND Idrenglon > 0 AND Status2 = 'T' )"
        @bajas_dmov = @dbEsta.connection.select_all(sql)
        @filtros_hmov[-1] = "Nummov > #{@nummov.to_i - 10} AND Nummov < #{@nummov.to_i + 10}"
        sql = "SELECT hmovpdv.*, sucursal.Nombre, sucursal.ZonaAsig, catbajas.Descrip, tipomov.NomTipoSubTipo FROM #{@nomDbPdv}hmovpdv LEFT JOIN #{@nomDbComun}sucursal ON Num_suc = Sucursal LEFT JOIN #{@nomDbPdv}catbajas ON Folioinfo = Categoria LEFT JOIN #{@nomDbPdv}tipomov ON Tipo_subt = TipoSubTipo WHERE ( ( #{@filtros_hmov.join(" ) AND ( ")} ) ) AND status2 = 'T' AND ( ( #{@filtros.join(" ) AND ( ")} ) ) ORDER BY Fecha DESC, Sucursal ASC, Nummov ASC limit 1000"
        @bajas_antpos = @dbEsta.connection.select_all(sql)
        # Carga el chat del movimiento
        sql = "SELECT * FROM estapinta.BajasChat where sucursal=#{@sucursal} and fecha=#{@fecha} and nummov= #{@nummov} order by FechaHora"
        @chat_comments = @dbEsta.connection.select_all(sql)
        @chat_comments.each do |a|
            if a['IdUser'].to_i > 0
                u = User.where("id = #{a['IdUser']}").first
                a['userEmail'] = u.email rescue ''
                a['userName']  = u.name rescue ''
            end
        end        
        respond_to do |format|
            format.html
        end
    else
        return redirect_to bajas_path, alert: "No Authorizado"
    end
  end

  def bajas_mails
    # http://rahca.com.mx:3000/bajas_mails?Email=lola%40lola.com&Empresa=4&Sucursal=0&TipoMail=1&Zona=0
    # if params.has_key?(:Email) && params.has_key?(:Sucursal) && params.has_key?(:TipoMail) && params.has_key?(:Zona)
    #     # Editar Renglon
    #     sql = "SELECT * from BajasMails WHERE TipoMail = #{User.sanitize(params[:TipoMail].to_i)} AND Email = #{User.sanitize(params[:Email])} AND Zona = #{User.sanitize(params[:Zona].to_i)} AND Sucursal = #{User.sanitize(params[:Sucursal].to_i)}"
    #     @bajasmails = @dbEsta.connection.select_all(sql)
    #     if @bajasmails and @bajasmails.count == 1
    #         # Se debe mostrar el formulario
    #         @bajasmail = @bajasmails[0]
    #         render 'bajas_mails_edit'
    #         # raise @bajasmails.inspect
    #     end
    # end
    # Ver todo
    sql = "SELECT BajasMails.*, '' as nomTipoMail, '' as nomZona, '' as nomSucursal from BajasMails"
    @bajasmails = @dbEsta.connection.select_all(sql)
    @bajasmails.each do |a|
        a['nomTipoMail'] = "Todos"
        a['nomTipoMail'] = "Fecha Estimada" if a['TipoMail'] == 1
        a['nomTipoMail'] = "Comentarios Nuevos" if a['TipoMail'] == 2
        a['nomZona'] = "Todas"
        a['nomZona'] = @dbComun.connection.select_all("SELECT * FROM zonas WHERE NumZona = #{a['Zona']} LIMIT 1")[0]['NomZona'] rescue 'Sin Zona' if a['Zona'] != -1
        a['nomSucursal'] = "Todas"
        a['nomSucursal'] = @dbComun.connection.select_all("SELECT * FROM sucursal WHERE Num_suc = #{a['Sucursal']} LIMIT 1")[0]['Nombre'] rescue 'Sin Sucursal' if a['Sucursal'] != -1
    end    
  end

  def bajas_mails_new
  end

  def bajas_mails_create
    # Aqui se crea o actualiza el bajasmail
    if params.has_key?(:Email) && params.has_key?(:Sucursal) && params.has_key?(:TipoMail) && params.has_key?(:Zona)
        return redirect_to '/bajas_mails_new', alert: "Favor de ingresar un Email valido" if ! params[:Email].to_s.include?("@")
        sql = "INSERT IGNORE INTO BajasMails (TipoMail, Email, Zona, Sucursal) VALUES (#{User.sanitize(params[:TipoMail].to_i)}, #{User.sanitize(params[:Email])}, #{User.sanitize(params[:Zona].to_i)}, #{User.sanitize(params[:Sucursal].to_i)})"
        begin
            @dbEsta.connection.execute(sql)
        rescue Exception => exc 
            return redirect_to '/bajas_mails', alert: "Ha ocurrido un error: #{exc.message}"
        end   
        begin
            @dbPdv.connection.execute(sql)
        rescue Exception => exc 
            return redirect_to '/bajas_mails', alert: "Ha ocurrido un error al escribir en Pdv: #{exc.message}"
        end    
        return redirect_to '/bajas_mails'
    end
    return redirect_to '/bajas_mails', alert: "Favor de revisar sus datos"
  end

  def bajas_mails_delete
    # Aqui se crea o actualiza el bajasmail
    if params.has_key?(:Email) && params.has_key?(:Sucursal) && params.has_key?(:TipoMail) && params.has_key?(:Zona)
    # raise "hire"
        sql = "DELETE FROM BajasMails WHERE TipoMail = #{User.sanitize(params[:TipoMail].to_i)} and Email = #{User.sanitize(params[:Email])} and Zona = #{User.sanitize(params[:Zona].to_i)} and Sucursal = #{User.sanitize(params[:Sucursal].to_i)}"
        begin
            @dbEsta.connection.execute(sql)
        rescue Exception => exc 
            return redirect_to '/bajas_mails', alert: "Ha ocurrido un error: #{exc.message}"
        end
        begin
            @dbPdv.connection.execute(sql)
        rescue Exception => exc 
            return redirect_to '/bajas_mails', alert: "Ha ocurrido un error: #{exc.message}"
        end
        return redirect_to '/bajas_mails', notice: "Datos modificados"
    end
    return redirect_to '/bajas_mails'
  end  

  def bajas_enviar_mails_robot
    # Esta funcion deberia ejecutarse con un cron para enviar todos los mails de bajas
    # Se puede enviar un mail de prueba agregando el parametro email: /bajas_enviar_mails_robot/?email=altuzzar@gmail.com
    index = -1
    index = params[:index].to_i if params.has_key?(:index)
    sql = "SELECT * from BajasMails"
    sql = "SELECT * from BajasMails WHERE (TipoMail = 0 or TipoMail = 1) and Email = #{User.sanitize(params[:email])}" if params.has_key?(:email)
    @emails_enviados = []
    @emails = @dbEsta.connection.select_all(sql)
    @emails.inspect
    @emails.each_with_index do |e, email_index|
        next if index > -1 && index != email_index
        next if !e['Email'].to_s.include?("@")
        @filtros   = []
        @email_1   = []
        @email_2   = []
        @partes    = [['nx', "No Autorizadas por Regional"], ['nn', "No Autorizadas por Contralor"]]
        @dias      = 90
        @fecha     = (Date.today - @dias.days).to_s.gsub("-","")
        @ultimaAct = Date.today - @dias.days
        @nom_zona  = ""
        @nom_suc   = ""

        @nom_zona = @dbComun.connection.select_all("SELECT * FROM zonas WHERE NumZona = #{e['Zona']} LIMIT 1")[0]['NomZona'] rescue "" if e['Zona'] != -1
        @num_suc  = @dbComun.connection.select_all("SELECT * FROM sucursal WHERE Num_suc = #{e['Sucursal']} LIMIT 1")[0]['Nombre'] rescue "" if e['Sucursal'] != -1

        @filtros.push("1")
        @filtros.push("ZonaAsig = #{e['Zona'].to_i}") if e['Zona'].to_i != -1
        @filtros.push("Sucursal = #{e['Sucursal'].to_i}") if e['Sucursal'].to_i != -1

        @partes.each do |parte|
            @filtros_parte = []
            @filtros_parte.push("RegAutorizacion = 0 or RegAutorizacion IS NULL") if parte[0][0] == 'n'
            @filtros_parte.push("RegAutorizacion = 1") if parte[0][0] == 'a'
            @filtros_parte.push("CtlAutorizacion = 0 or RegAutorizacion IS NULL") if parte[0][1] == 'n'
            @filtros_parte.push("CtlAutorizacion = 1") if parte[0][1] == 'a'
    
            sql = "SELECT BajasHmov.*, sucursal.Nombre, sucursal.ZonaAsig, zonas.NomZona, catbajas.Descrip, BajasAuth.RegAutorizacion as baRegAutorizacion, BajasAuth.CtlAutorizacion as baCtlAutorizacion FROM BajasHmov LEFT JOIN #{@nomDbComun}sucursal ON Num_suc = Sucursal LEFT JOIN #{@nomDbComun}zonas ON NumZona = ZonaAsig LEFT JOIN #{@nomDbPdv}catbajas ON Folioinfo = Categoria LEFT JOIN BajasAuth ON BajasAuth.Sucursal = BajasHmov.Sucursal AND BajasAuth.Fecha = BajasHmov.Fecha AND BajasAuth.Nummov = BajasHmov.Nummov WHERE BajasHmov.fecha > '#{@fecha}' AND tipo_subt = 'B' AND status2 = 'T' AND abs(total) >= 100 AND ( ( #{@filtros.join(" ) AND ( ")} ) AND ( #{@filtros_parte.join(" ) AND ( ")} ) ) ORDER BY Sucursal ASC, BajasHmov.fecha ASC, Nummov ASC"

            @bajas = @dbEsta.connection.select_all(sql)

            @bajas.each do |m|
                fecha = Date.parse(m['Fecha']) rescue ""
                @ultimaAct = fecha if @ultimaAct < fecha

                # AQUI SE AGREGAN LOS COMENTARIOS DE LA FACTURA
                sql = "SELECT BajasChat.*, '' as userEmail, '' as userName FROM BajasChat WHERE Sucursal = '#{m['Sucursal']}' AND Fecha = #{m['Fecha']} AND Nummov = #{m['Nummov']} order by FechaHora"
                @chat_comments = @dbEsta.connection.select_all(sql)
                comentarios = []
                @chat_comments.each do |a|
                    if a['IdUser'].to_i > 0
                        u = User.where("id = #{a['IdUser']}").first
                        a['userName']  = u.name rescue ''
                    end
                    comentarios.push("&nbsp;&nbsp;&nbsp;&nbsp;#{a['Comentario'].to_s.strip.gsub("\n"," ").gsub("\r"," ")} (#{a['userName']} - #{a['FechaHora'].to_s(:db)[0..19]})")
                end

                leyenda_dias = "#{(Date.today - fecha).to_i} DIAS:"
                leyenda_dias = "<FONT style=\"BACKGROUND-COLOR: #DFD400\">#{leyenda_dias}</FONT>" if ( fecha <= Date.today - 1.days and fecha >= Date.today - 30.days )
                leyenda_dias = "<FONT style=\"BACKGROUND-COLOR: #FFA430\">#{leyenda_dias}</FONT>" if ( fecha <= Date.today - 31.days and fecha >= Date.today - 60.days )
                leyenda_dias = "<FONT style=\"BACKGROUND-COLOR: #ED7E7F\">#{leyenda_dias}</FONT>" if ( fecha <= Date.today - 61.days )

                comentarios_str = ''
                if comentarios.length > 0 and e['TipoMail'] != 1
                  comentarios_str = "\n#{comentarios.join("\n")}"
                end

                linea = "<FONT color=#3D00FF>Región: #{m['ZonaAsig']} - #{m['NomZona']} - Sucursal: #{m['Sucursal']} - #{m['Nombre']}</FONT>\n&nbsp;&nbsp;#{leyenda_dias} #{view_context.fix_show_date(m['Fecha'])} Nummov: #{m['Nummov']} Total: #{number_to_currency(m['Total'], :locale => :mx, :precision => 2)} Valuado: #{number_to_currency(m['Totvaluado'], :locale => :mx, :precision => 2)}#{m['IdObra'].to_i > 0 ? " IdObra: #{m['IdObra']}" : ""} #{m['Tipo_subt']}-#{m['Folioinfo']}-#{m['Descrip']} #{m['Observac']}#{comentarios_str}"
              
                @email_1.push(linea) if parte[0] == 'nx'
                @email_2.push(linea) if parte[0] == 'nn'
            end
        end

        if @email_1.count > 0 || @email_2.count > 0
            # Debe enviarse el email
            mail_to      = e['Email'].to_s.gsub(" ", "")
            mail_subject = "Bajas de Mercancía  #{DateTime.now.to_s} #{" Región: #{@nom_zona}" if @nom_zona != ""}#{" Sucursal: #{@nom_suc}" if @nom_suc != ""}#{" al #{@ultimaAct.to_s}" if @ultimaAct}"
            mail_body    = "Estas son las Bajas de Mercancía#{" Región: #{@nom_zona}" if @nom_zona != ""}#{" Sucursal: #{@nom_suc}" if @nom_suc != ""}#{" al #{@ultimaAct.to_s}" if @ultimaAct}:<br />#{hacer_mail_dias( [ ["<STRONG>No Autorizadas por Regional:</STRONG>", @email_1], ["<STRONG>No Autorizadas por Contralor:</STRONG>", @email_2] ] ) }"
            mail_body = simple_format(mail_body, {}, sanitize: false, wrapper_tag: "div")
            mail_body = "<HTML><HEAD></HEAD><BODY><DIV style=\"FONT-SIZE: 12pt; FONT-FAMILY: 'Calibri'; COLOR: #000000\">#{mail_body}</DIV></BODY></HTML>"
            if modo_local?
                puts "Se iba a enviar el siguiente email pero manda localmente a la consola:\n  mail_to: #{mail_to}\n  mail_subject: #{mail_subject}\n  mail_body: #{mail_body}\n"
            else
              JustMailer.email_something_html(mail_to, mail_subject, mail_body).deliver_later
            end
            @emails_enviados.push({ index: index, email: e })
        end
    end 
    render status: 200, json: { info: "Tarea ejecutada exitosamente. Modo Local: #{modo_local?}. Emails enviados: #{@emails_enviados.count}: #{@emails_enviados.to_json}" }
    return  
  end

  def bajas_enviar_mails_robot_index
    sql = "SELECT * from BajasMails"
    @emails = @dbEsta.connection.select_all(sql)
    render status: 200, json: { emails: @emails.to_json }
  end

  def export_excel
    get_filtros_from_user
    @ver_autorizadas = false
    @ver_autorizadas = params[:ver_autorizadas] if params.has_key?(:ver_autorizadas)
    if ['nn', 'an', 'na', 'aa', 'nx'].include? @ver_autorizadas 
        @filtros.push("(RegAutorizacion = 0  or RegAutorizacion IS NULL) and (CtlAutorizacion = 0  or CtlAutorizacion IS NULL)") if @ver_autorizadas == 'nn'
        @filtros.push("(RegAutorizacion = 0 or RegAutorizacion IS NULL)") if @ver_autorizadas == 'nx'
        @filtros.push("(CtlAutorizacion = 0 or CtlAutorizacion IS NULL)") if @ver_autorizadas == 'an'
        @filtros.push("RegAutorizacion = 1 and CtlAutorizacion = 1") if @ver_autorizadas == 'aa'
    end
    sql = "SELECT BajasHmov.*, sucursal.Nombre, sucursal.ZonaAsig, catbajas.Descrip, BajasAuth.RegAutorizacion as baRegAutorizacion, BajasAuth.CtlAutorizacion as baCtlAutorizacion FROM BajasHmov LEFT JOIN #{@nomDbComun}sucursal ON Num_suc = Sucursal LEFT JOIN #{@nomDbPdv}catbajas ON Folioinfo = Categoria LEFT JOIN BajasAuth ON BajasAuth.Sucursal = BajasHmov.Sucursal AND BajasAuth.Fecha = BajasHmov.Fecha AND BajasAuth.Nummov = BajasHmov.Nummov WHERE BajasHmov.fecha > '#{@fecha}' AND tipo_subt = 'B' AND status2 = 'T' AND abs(total) >= 100 AND ( ( #{@filtros.join(" ) AND ( ")} ) ) ORDER BY BajasHmov.fecha DESC, Sucursal ASC, Nummov ASC"
    @bajas = @dbEsta.connection.select_all(sql)
    respond_to do |format|
      format.html
      format.xlsx
    end
  end

  private

    def get_filtros_from_user
        @filtros = []
        @filtros.push("1")
        @permiso = Permiso.joins("LEFT JOIN cat_roles ON permisos.permiso = cat_roles.nomPermiso").where("idUsuario = #{current_user.id} AND p1 = #{@sitio[0].idEmpresa.to_i}").order("cat_roles.nivel").limit(1)
        if @permiso && @permiso.count == 1
            if @permiso[0].p2 != "" && @permiso[0].p2 != "0"
                @zonas = @permiso[0].p2.to_s.split(',').map{|i| i.to_i}.sort
                @filtros.push("ZonaAsig = #{@zonas.join(" OR ZonaAsig = ")}") if @zonas.count > 0
            end
            if @permiso[0].p3 != "" && @permiso[0].p3 != "0"
                @sucursales = @permiso[0].p3.to_s.split(',').map{|i| i.to_i}.sort
                @filtros.push("BajasHmov.Sucursal = #{@sucursales.join(" OR BajasHmov.Sucursal = ")}") if @sucursales.count > 0
            end
        else
            return redirect_to "/", alert: "No autorizado"
        end
        return @filtros
    end

    def revisar_auth
    end

    def hacer_mail_dias(arr)
        ret = []
        arr.each do |a|
            if a[1].count > 0
                ret.push("<br />")
                ret.push("\n#{a[0]}\n")
                # Esto es para hacer un encabezado por sucursal y otro para cliente
                ult_sucursal = ""
                # ult_cliente = ""
                a[1].each do |linea|
                    if ult_sucursal != linea.split("\n")[0]
                        ult_sucursal = linea.split("\n")[0]
                        # ult_cliente  = linea.split("\n")[1]
                        ret.push(" ")
                        ret.push(linea.split("\n")[0]+"\n")
                        ret.push(linea.split("\n")[1..-1])
                    else
                        ret.push(linea.split("\n")[1..-1])
                        # if ult_cliente != linea.split("\n")[1]
                        #     ult_cliente = linea.split("\n")[1]
                        #     ret.push(" ")
                        #     ret.push(linea.split("\n")[1..-1])
                        # else
                        #     ret.push(linea.split("\n")[2..-1])
                        # end
                    end
                end
            end
        end
        return ret.join("\n")
    end

    def modo_local?
        sending_host = request.host.gsub("www.","").gsub(".com","").gsub(".mx","").gsub(".dyndns.org","").gsub(".dyndns.biz","").gsub("intranet","").gsub("comex","").gsub("bajapaint","").gsub("pintacomex","")
        return true if sending_host == "localhost"
        false
    end
end
