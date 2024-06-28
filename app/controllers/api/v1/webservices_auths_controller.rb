class Api::V1::WebservicesAuthsController < Api::V1::BaseController
  acts_as_token_authentication_handler_for User
  before_filter :tiene_permiso_de_ver_auths
  before_filter :get_niveles_de_usuario_de_notificaciones_mail, only: [:index]
  before_filter :get_empresa

  def index
    @auths = WebservicesAuth.where("#{@where_empresa} (nivel = #{@niveles.join(" OR nivel = ")})").order("fechaHora DESC").limit(20)
    render(
      json: { webservices_auths: @auths.map{|i| i.as_json.merge( { 
          final_status: get_final_status(i)
        } ) }.map{|i| i.as_json.merge( { 
          nom_empresa: get_nom_empresa(i)
        } ) } }.to_json,
      status: 200
    )
  end

  def update
    id          = params[:id].to_i rescue nil
    sucursal    = params[:sucursal].to_i rescue nil
    pc          = params[:pc].to_i       rescue nil
    numAuth     = params[:numAuth].to_i  rescue nil
    ok_no       = params[:ok_no]         rescue nil

    if id.nil? or sucursal.nil? or pc.nil? or numAuth.nil? or ok_no.nil? or
       id < 1 or sucursal < 1 or pc < 1 or numAuth < 1 or ok_no.to_s.length < 0
      render status: 200, json: { descripcion: "Error en autorizacion", status: 0 }
      return
    end

    auths = WebservicesAuth.where("#{@where_empresa} id = #{User.sanitize(id)} and empresa = #{@sitio[0].idEmpresa.to_i} and sucursal = #{User.sanitize(sucursal)} and pc = #{User.sanitize(pc)} and numAuth = #{User.sanitize(numAuth)} and fechaHora > '#{DateTime.now - 10.minutes}'").order("fechaHora DESC")

    app_text = ""
    app_status = 0

    if auths.count > 0
      auth = auths.first

      if ok_no == "ok"

        auth.update(respuesta: "Solicitud autorizada por #{current_user.email}.", status: 1)

        if auth.save
          app_text = "Solicitud autorizada exitosamente."
          app_status = 1

          auth_log = AuthLog.where("numAuth = '#{User.sanitize(numAuth)}'").first rescue nil
          if auth_log
            auth_log.update(respuesta: "Solicitud autorizada por #{current_user.email}", status: "Aprobada")
            auth_log.save
          end

        else
          app_text = "Lo sentimos, ha habido un error al escribir la autorización."
        end

      elsif ok_no == "no"

        auth.update(respuesta: "Solicitud rechazada por #{current_user.email}.", status: 2)

        if auth.save
          app_text = "Solicitud rechazada exitosamente."
          app_status = 1

          auth_log = AuthLog.where("numAuth = '#{User.sanitize(numAuth)}'").first rescue nil
          if auth_log
            auth_log.update(respuesta: "Solicitud rechazada por #{current_user.email}", status: "Rechazada")
            auth_log.save
          end

        else
          app_text = "Lo sentimos, ha habido un error al escribir la autorización."
        end

      else
        app_text = "Lo sentimos, el comando no se ha reconocido."
      end

    else
      app_text = "Lo sentimos, no se han encontrado autorizaciones pendientes en los últimos 10 minutos con los datos solicitados."
    end

    render status: 200, json: { info: app_text, status: app_status }
  end

  private 

    def tiene_permiso_de_ver_auths
      # Esto deberia funcionar solo si el usuario es Nivel Supervisor
      get_modulos_app_rol_nivel
      @nivel = @user_permisos[:nivel] rescue 100
      if @nivel > 30 # Si es de Supervisor para arriba, puede ver el modulo
        render(
          json: { webservices_auths: [{
            "id" => "",
            "sucursal" => "",
            "descripcion" => "Sin acceso a solicitudes",
            "respuesta" => "",
            "status" => "",
            "fechaHora" => "",
            "created_at" => "",
            "updated_at" => "",
            "pc" => "",
            "numAuth" => "",
            "final_status" => ""
          }], info: "Validacion Nivel Supervisor No Autorizada" }.to_json,
          status: 200
        )
        return
      end
    end

    def get_niveles_de_usuario_de_notificaciones_mail
      @niveles = [0]
      @niveles_escritura = []
      @bases = []
      @bases.push(@nomDbEsta)
      if current_user.has_role? :admin
        # Los admins pueden ver las auths de todas las empresas
        @bases.push("estaadrahca.") if @nomDbEsta == "estapinta."
        @bases.push("estapinta.")   if @nomDbEsta == "estaadrahca."
      end
      @bases.each do |b|
        @notificaciones_mails = @dbEsta.connection.select_all("SELECT NotificacionesMail.* from #{b}NotificacionesMail WHERE Email = #{User.sanitize(current_user.email)}")
        @notificaciones_mails.each do |row|
          niv_esc = row['NivelEscritura'].to_s.split(",").map{|i| i.to_i} rescue []
          niv_lec = row['NivelLectura'].to_s.split(",").map{|i| i.to_i} rescue []
          @niveles.concat(niv_esc).concat(niv_lec)
          @niveles_escritura.concat(niv_esc)
        end
      end
    end

    def get_final_status(row)
      ret = "Solicitud Expirada"
      if row.status == 0        
        if row.fechaHora > DateTime.now - 10.minutes
          if @niveles_escritura.include?(row.nivel)
            ret = "Esperando respuesta" # Esto significa que puede aprobar/desaprobar desde la app
          else
            ret = "En espera de respuesta" # Esto significa que NO puede aprobar/desaprobar desde la app
          end
        end
      elsif row.status == 1 or row.status == 2
        ret = row.respuesta
      elsif row.status == 3
        ret = "Solicitud Cancelada"
      end
      return ret
    end

    def get_empresa
      # Los admins pueden ver las auths de todas las empresas
      @where_empresa = "empresa = #{@sitio[0].idEmpresa.to_i} and "
      @where_empresa = "" if current_user.has_role? :admin
    end

    def get_nom_empresa(e)
      ret = "Sin Empresa"
      ret = Empresa.where("idEmpresa = #{e['empresa'].to_i}").first.nombre.to_s.split(",").first rescue "Empresa no encontrada"
      return ret
    end
end
