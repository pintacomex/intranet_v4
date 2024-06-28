class Notificaciones::MailsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app

  def mails
    sql = "SELECT NotificacionesMail.*, '' as nomTipoMail, '' as nomEmpresa, '' as nomZona, '' as nomSucursal from NotificacionesMail order by Email"
    @notificaciones_mails = @dbEsta.connection.select_all(sql)
    @notificaciones_mails.each do |a|
        a['nomTipoMail'] = "Todas"
        a['nomEmpresa'] = "Todas"
        a['nomEmpresa'] = Sitio.where(idEmpresa: a['Empresa']).first.nombre rescue 'Sin Empresa' if a['Empresa'] != -1
        a['nomZona'] = "Todas"
        baseComun = "none."
        baseComun = "comun."        if Sitio.where(idEmpresa: a['Empresa']).first.basePdv == "pdv"        rescue "none."
        baseComun = "comunpaint."   if Sitio.where(idEmpresa: a['Empresa']).first.basePdv == "pdvpaint"   rescue "none."
        baseComun = "comunadrahca." if Sitio.where(idEmpresa: a['Empresa']).first.basePdv == "pdvadrahca" rescue "none."
        a['nomZona'] = @dbComun.connection.select_all("SELECT * FROM #{baseComun}zonas WHERE NumZona = #{a['Zona']} LIMIT 1")[0]['NomZona'] rescue 'Sin Zona' if a['Zona'].to_i != -1
        a['nomSucursal'] = "Todas"
        a['nomSucursal'] = @dbComun.connection.select_all("SELECT * FROM #{baseComun}sucursal WHERE Num_suc = #{a['Sucursal']} LIMIT 1")[0]['Nombre'] rescue 'Sin Sucursal' if a['Sucursal'].to_i != -1
    end
  end

  def mails_new
    @new = true
    render 'mails_new'
  end

  def mails_edit
    @new = false
    render 'mails_edit'
  end

  def mails_create
    # Aqui se crea o actualiza el notificaciones_mail
    url = '/notificaciones/mails'
    if params.has_key?(:Email) && params.has_key?(:Zona) && params.has_key?(:Sucursal) && params.has_key?(:TipoNotificacion) && params.has_key?(:PdvPrueba)
        nivel_escritura = params[:NivelEscritura].join(",") rescue ""
        nivel_lectura = params[:NivelLectura].join(",") rescue ""
        return redirect_to url, alert: "Favor de seleccionar al menos un nivel" if "#{nivel_escritura}#{nivel_lectura}" == "" 
        sql = "DELETE FROM NotificacionesMail WHERE TipoNotificacion = #{User.sanitize(params[:TipoNotificacion].to_i)} AND Email = #{User.sanitize(params[:Email])} AND Empresa = #{User.sanitize(@sitio[0].idEmpresa)} AND  Zona = #{User.sanitize(params[:Zona].to_i)} AND Sucursal = #{User.sanitize(params[:Sucursal].to_i)}"
        begin
            @dbEsta.connection.execute(sql)
        rescue Exception => exc 
            return redirect_to url, alert: "Ha ocurrido un error al borrar registros anteriores: #{exc.message}"
        end   
        begin
            @dbPdv.connection.execute(sql)
        rescue Exception => exc 
            return redirect_to url, alert: "Ha ocurrido un error al borrar registros anteriores en Pdv: #{exc.message}"
        end 
        sql = "INSERT IGNORE INTO NotificacionesMail (TipoNotificacion, Email, Empresa, Zona, Sucursal, NivelEscritura, NivelLectura, PdvPrueba) VALUES (#{User.sanitize(params[:TipoNotificacion].to_i)}, #{User.sanitize(params[:Email])}, #{User.sanitize(@sitio[0].idEmpresa)}, #{User.sanitize(params[:Zona].to_i)}, #{User.sanitize(params[:Sucursal].to_i)}, #{User.sanitize(nivel_escritura)}, #{User.sanitize(nivel_lectura)}, #{User.sanitize(params[:PdvPrueba])})"
        begin
            @dbEsta.connection.execute(sql)
        rescue Exception => exc 
            return redirect_to url, alert: "Ha ocurrido un error: #{exc.message}"
        end   
        begin
            @dbPdv.connection.execute(sql)
        rescue Exception => exc 
            return redirect_to url, alert: "Ha ocurrido un error al escribir en Pdv: #{exc.message}"
        end    
        return redirect_to url, notice: "Usuario guardado exitosamente"
    end
    return redirect_to url, alert: "Favor de revisar sus datos"
  end

  def mails_delete
    # Aqui se crea o actualiza el notificaciones_mail
    url = '/notificaciones/mails'
    if params.has_key?(:Email) && params.has_key?(:Zona) && params.has_key?(:Sucursal) && params.has_key?(:TipoNotificacion)
        sql = "DELETE FROM NotificacionesMail WHERE TipoNotificacion = #{User.sanitize(params[:TipoNotificacion].to_i)} and Email = #{User.sanitize(params[:Email])} and Zona = #{User.sanitize(params[:Zona].to_i)} and Sucursal = #{User.sanitize(params[:Sucursal].to_i)}"
        begin
            @dbEsta.connection.execute(sql)
        rescue Exception => exc 
            return redirect_to url, alert: "Ha ocurrido un error: #{exc.message}"
        end
        begin
            @dbPdv.connection.execute(sql)
        rescue Exception => exc 
            return redirect_to url, alert: "Ha ocurrido un error: #{exc.message}"
        end
        return redirect_to url, notice: "Email borrado exitosamente"
    end
    return redirect_to url
  end

end
