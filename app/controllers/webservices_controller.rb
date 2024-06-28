#!/bin/env ruby
# encoding: utf-8
class WebservicesController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_filter :authenticate_user!, only: [:index]
  before_filter :tiene_permiso_de_ver_app, only: [:index]

  include ActionView::Helpers::NumberHelper

  def index
  end

  def pdv
    comando = params[:comando] if params.has_key?(:comando)
    param   = params[:param]   if params.has_key?(:param)

    if comando == "descMes"
      # ejemplo /webservices/pdv?comando=descMes&param=78,201605

      sucursal = param.split(",")[0].to_i rescue nil
      fecha    = param.split(",")[1].to_i rescue nil

      if sucursal.nil? or fecha.nil? or sucursal < 1 or fecha < 1
        render status: 400, json: { codigoError: 101, error: "Parametros incorrectos", status: 1 }
        return
      end

      sql = "SELECT * FROM htotalmes WHERE sucursal = #{User.sanitize(sucursal)} and fecha = #{User.sanitize(fecha)}"

      begin
        @pdv = @dbEsta.connection.select_all(sql)
      rescue Exception => exc
        render status: 500, json: { codigoError: 102, error: "Ha habido un error al ejecutar el query. #{exc}", status: 1 }
        return
      end

      descuento = @pdv[0]['vtaStock'] - @pdv[0]['vtaNeta'] rescue nil

      if descuento.nil?
        render status: 500, json: { codigoError: 103, error: "Datos no encontrados.", status: 1 }
        return
      end

      render status: 200, json: { respuesta: { descuento: descuento }, status: 0 }
      return

    elsif comando == "enviarNotificacion"
      # ejemplo /webservices/pdv?comando=enviarNotificacion&param=78,3&texto=TestDeNotificacion

      sucursal = param.split(",")[0].to_i rescue nil
      nivel    = param.split(",")[1].to_i rescue nil
      texto    = params[:texto]   if params.has_key?(:texto)

      if sucursal.nil? or nivel.nil? or texto.nil? or sucursal < 1 or nivel < 1 or texto.to_s == ""
        render status: 400, json: { codigoError: 201, error: "Parametros incorrectos", status: 1 }
        return
      end

      res = procesa_enviar_notificacion(sucursal, nivel, texto)

      res_status   = res[:status]   rescue 401
      res_obj      = res[:obj]      rescue { codigoError: 202, error: "Error al Procesar", status: 1 }

      render status: res_status, json: res_obj
      return

    end

    render status: 400, json: { codigoError: 100, error: "Parametros incorrectos", status: 1 }
  end

  def pdv_autoriza
    # Este comando es para las autorizaciones nivel 4 del PDV
    # Ejemplo: /webservices/pdv?comando=autoriza&param=97,1,348,3,0&texto=DESCRIPCION_DE_DESCUENTO
    # Ejemplo de cancelacion: /webservices/pdv?comando=autoriza&param=97,1,348,3,0&texto=SOLICITUD_CANCELADA
    # Ejemplo de autorizacion desde la tienda: /webservices/pdv?comando=autoriza&param=97,1,348,3,0&texto=SOLICITUD_AUTORIZADA xxx

    comando = params[:comando] if params.has_key?(:comando)
    param   = params[:param]   if params.has_key?(:param)

    if comando == "autoriza"

      sucursal    = param.split(",")[0].to_i rescue nil
      pc          = param.split(",")[1].to_i rescue nil
      numAuth     = param.split(",")[2].to_i rescue nil
      nivel       = param.split(",")[3].to_i rescue nil
      pdvPrueba   = param.split(",")[4].to_i rescue 0
      texto       = params[:texto]     rescue nil

      if sucursal.nil? or pc.nil? or numAuth.nil? or nivel.nil? or texto.nil? or
         sucursal < 1 or pc < 1 or numAuth < 1 or nivel < 1 or texto.to_s.length < 1
        render status: 400, json: { codigoError: 201, error: "Parametros incorrectos", status: 1 }
        return
      end

      res = procesa_autoriza(sucursal, pc, numAuth, nivel, pdvPrueba, texto)

      res_status   = res[:status]   rescue 401
      res_obj      = res[:obj]      rescue { codigoError: 202, error: "Error al Procesar", status: 1 }

      render status: res_status, json: res_obj
      return

    end

    render status: 400, json: { codigoError: 100, error: "Parametros incorrectos", status: 1 }
  end

  def ecommerce_pedido
    # Este comando es para notificar que hay un pedido nuevo en
    # uno de los canales de Ecommerce
    # Ejemplo: /webservices/ecommerce/pedido?comando=pedido_nuevo&param=123,1
    # curl 'http://localhost:3001/webservices/ecommerce/pedido' -H 'Content-Type: application/json' --data-binary '{ "id": 5, "comando": "pedido_nuevo", "param": "123,1" }'

    res = procesa_pedido_nuevo(0)

    res_status   = res[:status]   rescue 401
    res_obj      = res[:obj]      rescue { codigoError: 202, error: "Error al Procesar", status: 1 }

    render status: res_status, json: res_obj
    return

    # comando = params[:comando] if params.has_key?(:comando)
    # param   = params[:param]   if params.has_key?(:param)

    # if comando == "pedido_nuevo"
    #   pedido    = param.split(",")[0].to_i rescue nil
    #   prueba   = param.split(",")[1].to_i rescue 0

    #   if pedido.nil? or pedido < 1
    #     render status: 400, json: { codigoError: 201, error: "Parametros incorrectos", status: 1 }
    #     return
    #   end

    #   res = procesa_pedido_nuevo(pedido, prueba)

    #   res_status   = res[:status]   rescue 401
    #   res_obj      = res[:obj]      rescue { codigoError: 202, error: "Error al Procesar", status: 1 }

    #   render status: res_status, json: res_obj
    #   return
    # end

    # render status: 400, json: { codigoError: 100, error: "Parametros incorrectos", status: 1 }

  end

  private

    def procesa_autoriza(sucursal, pc, numAuth, nivel, pdvPrueba, descripcion)

      puts "procesa_autoriza(sucursal: #{sucursal}, pc: #{pc}, numAuth: #{numAuth}, nivel: #{nivel}, descripcion: #{descripcion})"

      auths = WebservicesAuth.where("empresa = #{@sitio[0].idEmpresa.to_i} and sucursal = #{User.sanitize(sucursal)} and pc = #{User.sanitize(pc)} and numAuth = '#{User.sanitize(numAuth)}' and fechaHora > '#{DateTime.now - 10.minutes}'").order("fechaHora DESC")

      data = { pantalla: 'solicitudes', sucursal: sucursal, numAuth: numAuth }

      # Los status son los siguientes:
      #  0: Solicitud Autoriza recibida
      #  1: Solicitud Autoriza aprobada
      #  2: Solicitud Autoriza negada
      #  3: Solicitud Autoriza cancelada
      #  4: Solicitud Autoriza expirada

      if auths.count > 0

        auth = auths.first

        if auth.status == 0

          if auth.fechaHora > DateTime.now - 10.minutes

            if descripcion == "SOLICITUD_CANCELADA"

              auth.update(respuesta: descripcion, status: 3)
              app_text = ""
              store_text = ""
              if auth.save
                app_text = "La siguiente solicitud ha sido cancelada por la tienda: Sucursal: #{sucursal}, Descripción: #{auth.descripcion}, Respuesta: #{descripcion}"
                store_text = "Solicitud cancelada exitosamente"

                auth_log = AuthLog.where("numAuth = '#{User.sanitize(numAuth)}'").first rescue nil
                if auth_log
                  auth_log.update(respuesta: "Solicitud cancelada", status: "Cancelada")
                  auth_log.save
                end

              else
                store_text = "Lo sentimos, ha habido un error al escribir la cancelación"
              end

              notificar_slack_auth(sucursal, nivel, app_text) if app_text != ""

              res = procesa_enviar_notificacion(sucursal, nivel, app_text, "WS_AUTORIZA", data, pdvPrueba) if app_text != ""
              return { status: 200, obj: { status: 3, descripcion: store_text } }

            elsif descripcion.start_with?("SOLICITUD_AUTORIZADA")

              auth.update(respuesta: descripcion, status: 1)
              app_text = ""
              store_text = ""
              if auth.save
                app_text = "La siguiente solicitud ha sido autorizada desde la tienda: Sucursal: #{sucursal}, Descripción: #{auth.descripcion}, Respuesta: #{descripcion}"
                store_text = "Solicitud autorizada desde la tienda exitosamente"

                auth_log = AuthLog.where("numAuth = '#{User.sanitize(numAuth)}'").first rescue nil
                if auth_log
                  auth_log.update(respuesta: descripcion.gsub("SOLICITUD_AUTORIZADA", "Solicitud aprobada"), status: "Aprobada")
                  auth_log.save
                end

              else
                store_text = "Lo sentimos, ha habido un error al escribir la autorización"
              end

              notificar_slack_auth(sucursal, nivel, app_text) if app_text != ""

              res = procesa_enviar_notificacion(sucursal, nivel, app_text, "WS_AUTORIZA", data, pdvPrueba) if app_text != ""
              return { status: 200, obj: { status: 1, descripcion: store_text } }

            else

              return { status: 200, obj: { status: 0, descripcion: "Esperando autorización" } }

            end

          else

            auth.update(respuesta: "Solicitud Expirada", status: 4)
            store_text = ""
            if auth.save
              store_text = "Solicitud Expirada"

              auth_log = AuthLog.where("numAuth = '#{User.sanitize(numAuth)}'").first rescue nil
              if auth_log
                auth_log.update(respuesta: "Solicitud Expirada", status: "Expirada")
                auth_log.save
              end

            else
              store_text = "Lo sentimos, ha habido un error al escribir que la solicitud ha expirado"
            end
            return { status: 200, obj: { status: 4, descripcion: store_text } }

          end

        elsif auth.status == 1 || auth.status == 2 || auth.status == 3 || auth.status == 4
          return { status: 200, obj: { status: auth.status, descripcion: auth.respuesta } }
        else
          return { status: 200, obj: { status: 0, descripcion: "Error en autorizacion" } }
        end

      else

        # Antes de crearse, debe revisarse si hay usuarios asignados a esa sucursal para notificaciones
        texto = "Solicitud de Autorización: Sucursal: #{sucursal} - #{descripcion}. 10 minutos para autorizar o rechazar."
        res = procesa_enviar_notificacion(sucursal, nivel, texto, "WS_AUTORIZA", data, pdvPrueba)
        res_usuarios_notificados = res[:usuarios_notificados]   rescue 0

        if res_usuarios_notificados < 1

          return { status: 200, obj: { status: 0, descripcion: "No se han encontrado usuarios para enviar la solicitud. Favor de contactarlos por otros medios." } }

        else

          notificar_slack_auth(sucursal, nivel, texto)

          WebservicesAuth.create(empresa: @sitio[0].idEmpresa.to_i, sucursal: sucursal, pc: pc, numAuth: numAuth, descripcion: descripcion.gsub("|", "\n"), respuesta: "", status: 0, fechaHora: DateTime.now, nivel: nivel)
          AuthLog.create(empresa: @sitio[0].idEmpresa.to_i, sucursal: sucursal, pc: pc, numAuth: numAuth, nivel: nivel, fechaHora: DateTime.now, descripcion: descripcion.gsub("|", "\n"), status: "Pendiente",respuesta: "En espera de autorización", pdvPrueba: pdvPrueba.to_i)

          return { status: 200, obj: { status: 0, descripcion: "Solicitud recibida exitosamente. Usuarios notificados: #{res_usuarios_notificados}" } }

        end

      end

    end

    def procesa_enviar_notificacion(sucursal, nivel, texto, tipo = "WS_ENVIAR_NOTIFICACION", data = { a: 'b' }, pdvPrueba = 0)

      # Se ve a cuantos se le va a enviar la notificacion
      usuarios_notificados = 0
      a_enviar = []
      where_pdv = ""
      where_pdv = "WHERE pdvPrueba = 1" if pdvPrueba == 1
      sql = "SELECT NotificacionesMail.* from NotificacionesMail #{where_pdv} order by Email"
      @notificaciones_mails = @dbEsta.connection.select_all(sql)
      @notificaciones_mails.each do |a|

        next if a['TipoNotificacion'] != 0 && a['TipoNotificacion'] != 1
        next if a['Sucursal'].to_i != -1 && a['Sucursal'].to_i != sucursal
        next if !( a['NivelEscritura'].include?("#{nivel}") || a['NivelLectura'].include?("#{nivel}") )

        user = User.where(email: a['Email']).first rescue 0
        push_tokens = PushToken.includes(:user).where(user_id: user.id)
        usuarios_notificados = usuarios_notificados + 1 if push_tokens.count > 0

        push_tokens.each do |push_token|
          # Se crea un arreglo de notificaciones a enviar para no duplicar/triplicar notificaciones
          a_enviar.push({ destinatario: push_token.user.email, deviceId: push_token.deviceId, token: push_token.push_token, data: data })
        end
      end

      a_enviar.uniq.each do |a|
          notificacion = Notificacione.new
          notificacion.tipo = tipo
          notificacion.destinatario = a[:destinatario]
          notificacion.deviceId = a[:deviceId]
          notificacion.texto = texto.gsub("|", "\n")
          notificacion.status = 0
          notificacion.save
          no_enviar_notificaciones = params[:no_enviar_notificaciones] if params.has_key?(:no_enviar_notificaciones)
          sending_host = request.host.gsub("www.","").gsub(".com","").gsub(".mx","").gsub(".dyndns.org","").gsub(".dyndns.biz","").gsub("intranet","").gsub("comex","")
          if no_enviar_notificaciones.nil? and sending_host != "localhost"
            exponent.publish(
              exponentPushToken: a[:token],
              title: texto.truncate(30),
              message: texto.gsub("|", "\n"),
              ttl: 600,
              sound: 'default',
              priority: 'high',
              badge: 1,
              data: a[:data]
            )
          end
          notificacion.status = 1
          notificacion.save
      end

      return { status: 200, obj: { descripcion: "Usuarios Notificados: #{usuarios_notificados}", status: 0 }, usuarios_notificados: usuarios_notificados }

    end

    def notificar_slack_auth(sucursal, nivel, texto)
      # Aqui se ve a que zona pertenece la sucursal, crea el string 0102 (donde 01 es la zona y 02 es el nivel) y busca el webhook correspondiente para notificar
      suc = @dbEsta.connection.select_all("SELECT * FROM #{@nomDbComun}sucursal where Num_suc = #{sucursal}") rescue []

      if suc.count != 1
        p "Error en Webservices.notificar_slack_auth: Sucursal no encontrada: #{sucursal}"
        return
      end

      zona = -1
      zona = suc.first['ZonaAsig'].to_i rescue -1

      if zona < 0
        p "Error en Webservices.notificar_slack_auth: Zona no encontrada: #{sucursal} #{suc.inspect}"
        return
      end

      slack_channel = "#{max_rjust(zona, 2)}#{max_rjust(nivel, 2)}"
      webhook = Webhook.where("name = #{User.sanitize(slack_channel)}")

      if webhook.count == 1
        slack_channel = "auth#{slack_channel}"

        webhook_val = webhook.first.value rescue ""

        if webhook_val == "" || !webhook_val.start_with?("https://hooks.slack.com/services/")
          p "Error en Webservices.notificar_slack_auth: Webhook no valido: #{slack_channel} #{webhook_val} #{webhook.inspect}"
          return
        end

        no_enviar_notificaciones = params[:no_enviar_notificaciones] if params.has_key?(:no_enviar_notificaciones)
        sending_host = request.host.gsub("www.","").gsub(".com","").gsub(".mx","").gsub(".dyndns.org","").gsub(".dyndns.biz","").gsub("intranet","").gsub("comex","")
        if no_enviar_notificaciones.nil? and sending_host != "localhost"
          notificar_slack(webhook_val, slack_channel, texto)
        else
          p "No enviando notificacion por ser localhost o parametro: notificar_slack(webhook_val, slack_channel, texto) webhook_val: #{webhook_val}, slack_channel: #{slack_channel}, texto: #{texto.truncate(20)}"
        end
      end

    end

    def notificar_slack(webhook, canal, texto, usuario = "authbot")
      notifier = Slack::Notifier.new webhook
      notifier.channel  = canal
      notifier.username = usuario
      notifier.ping texto
    end

    def max_rjust(num, limit)
      # Esta funcion regresa rjust pero si se pasa el numero de tamano deja los ultimos n digitos
      num.to_s.split(//).last(limit).join.rjust(limit,"0")
    end

    def exponent
      @exponent ||= Exponent::Push::Client.new
    end

    def procesa_pedido_nuevo(prueba)
      id_pedido = JSON.parse(request.raw_post)['id'] rescue 0

      sql = "INSERT INTO wsContextusPedidos ( operacion, idPedido, request, status, created_at, updated_at ) VALUES ( 'pedido_nuevo_raw', #{User.sanitize(id_pedido)}, #{User.sanitize(request.raw_post)}, 1, now(), now() )"
      begin
        @dbVentasonline.connection.execute(sql)
      rescue Exception => exc
        return { status: 500, json: { codigoError: 200, error: "Error al ejecutar el query: #{exc}", status: 1 } }
      end

      return { status: 200, obj: { status: 0, descripcion: "Llamada recibida exitosamente." } }
    end
end
