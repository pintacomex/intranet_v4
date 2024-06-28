class ObrasController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app
  before_filter :get_puede_editar, only: [:obras, :obra, :obra_edit_status, :obra_porc_desc_script]
  before_filter :set_filters, only: [:obras]

  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper

  def obras
    sql = "SELECT obras.*, s.Nombre as sNombre FROM #{@nomDbPdv}obras LEFT JOIN #{@nomDbComun}sucursal as s ON s.Num_suc = Sucursal WHERE ( ( #{@filtros.join(" ) AND ( ")} ) ) ORDER BY obras.sucursal, obras.IdObra"
    @obras = @dbEsta.connection.select_all(sql)
  end

  def obra
    @sucursal = params[:sucursal].to_i if params.has_key?(:sucursal)
    @idobra = params[:idobra].to_i if params.has_key?(:idobra)
    if @sucursal && @sucursal > 0 && @idobra && @idobra > 0
      @filtros.push("obras.Sucursal = #{@sucursal}")
      @filtros.push("obras.IdObra = #{@idobra}")
      sql = "SELECT obras.*, s.Nombre as sNombre FROM #{@nomDbPdv}obras LEFT JOIN #{@nomDbComun}sucursal as s ON s.Num_suc = Sucursal WHERE ( ( #{@filtros.join(" ) AND ( ")} ) ) ORDER BY obras.sucursal, obras.IdObra"
      @obra = @dbEsta.connection.select_all(sql)
      return redirect_to obras_path, alert: "Obra no encontrada" if @obra.count != 1
      @obra = @obra.first
      @GTotalVendido = 0.0
      @GTotalValuado = 0.0
      @GDescuentoEquivalente = 0.0
      sql = "SELECT Fecha, Nummov, Controlfac, Tipo_subt, Total, Totvaluado, Observac, tipomov.NomTipoSubTipo, clientes.Nombre as cNombre, 0 as TotalVendido, 0 as TotalValuado, '' as Mano FROM #{@nomDbPdv}hmovpdv LEFT JOIN #{@nomDbPdv}tipomov ON Tipo_subt = TipoSubTipo LEFT JOIN #{@nomDbPdv}clientes ON hmovpdv.Sucursal = clientes.Sucursal AND hmovpdv.Idcliente = clientes.Idcliente WHERE ( ( Tipo_subt = '#{["V$", "v$", "VC", "vC", "fC", "f$", "B", "K$", "IE", "IS"].join("' ) OR ( Tipo_subt = '")}' ) ) AND hmovpdv.Sucursal = #{@sucursal} AND hmovpdv.IdObra = '#{@idobra}' AND Status2 = 'T' ORDER BY hmovpdv.sucursal, hmovpdv.fecha, hmovpdv.nummov"
      @movs = @dbEsta.connection.select_all(sql)
      @movs.each do |m|

        sql = "SELECT * FROM #{@nomDbPdv}dmovpdv WHERE dmovpdv.Sucursal = #{@sucursal} AND dmovpdv.Fecha = '#{m['Fecha']}' AND dmovpdv.Nummov = '#{m['Nummov']}' AND Idrenglon > 0 AND Status2 = 'T'"
        dmovs = @dbEsta.connection.select_all(sql)
        total_vendido = 0.0
        total_valuado = 0.0
        mano = ""
        dmovs.each do |dm|
          if m['Tipo_subt'] == "V$" || m['Tipo_subt'] == "VC"
            total_vendido = total_vendido + dm['Preciofin'].to_f rescue 0
            total_valuado = total_valuado + (dm['Preciolp'].to_f * dm['Cantidad'].to_f) rescue 0
            mano = "Si" if dm['Cveasoc'] == "MANO"
          elsif m['Tipo_subt'] == "v$" || m['Tipo_subt'] == "vC"
            total_vendido = total_vendido + (dm['Preciofin'].to_f * -1) rescue 0
            total_valuado = total_valuado + (dm['Preciolp'].to_f * dm['Cantidad'].to_f * -1) rescue 0
            mano = "Si" if dm['Cveasoc'] == "MANO"
          elsif m['Tipo_subt'] == "B"
            total_valuado = total_valuado + (dm['Preciolp'].to_f * dm['Cantidad'].to_f) rescue 0
            mano = "Si" if dm['Cveasoc'] == "MANO"
          end
        end
        m['TotalVendido'] = total_vendido
        m['TotalValuado'] = total_valuado
        m['Mano'] = mano
        @GTotalVendido = @GTotalVendido + total_vendido rescue 0
        @GTotalValuado = @GTotalValuado + total_valuado rescue 0
      end
      @GDescuentoEquivalente = ( ( 1 - ( @GTotalVendido / @GTotalValuado ) ) * 100 ) rescue 0 if @GTotalValuado > 0
      sql = "SELECT ObrasChat.*, '' as userEmail, '' as userName FROM ObrasChat WHERE Sucursal = #{@sucursal} and IdObra = #{@idobra} ORDER BY FechaHora"
      @chat_comments = @dbEsta.connection.select_all(sql)
      @chat_comments.each do |a|
        if a['IdUser'].to_i > 0
          u = User.where("id = #{a['IdUser']}").first
          a['userEmail'] = u.email rescue ''
          a['userName']  = u.name rescue ''
        end
      end

    else
      return redirect_to obras_path
    end
  end

  def obra_detalle
    @sucursal = params[:sucursal].to_i if params.has_key?(:sucursal)
    @idobra = params[:idobra].to_i if params.has_key?(:idobra)
    @fecha = params[:fecha].to_i if params.has_key?(:fecha)
    @nummov = params[:nummov].to_i if params.has_key?(:nummov)
    if @sucursal && @sucursal > 0 && @idobra && @idobra > 0 && @fecha && @fecha > 0 && @nummov && @nummov > 0
      get_filtros_from_user
      @filtros.push("obras.Sucursal = #{@sucursal}")
      @filtros.push("obras.IdObra = #{@idobra}")
      sql = "SELECT obras.*, s.Nombre as sNombre FROM #{@nomDbPdv}obras LEFT JOIN #{@nomDbComun}sucursal as s ON s.Num_suc = Sucursal WHERE ( ( #{@filtros.join(" ) AND ( ")} ) ) ORDER BY obras.sucursal, obras.IdObra"
      @obra = @dbEsta.connection.select_all(sql)
      return redirect_to obras_path, alert: "Obra no encontrada" if @obra.count != 1
      @obra = @obra.first
      sql = "SELECT Fecha, Nummov, Controlfac, Tipo_subt, Total, Totvaluado, Observac, tipomov.NomTipoSubTipo FROM #{@nomDbPdv}hmovpdv LEFT JOIN #{@nomDbPdv}tipomov ON Tipo_subt = TipoSubTipo WHERE hmovpdv.Sucursal = #{@sucursal} AND hmovpdv.Fecha = '#{@fecha}' AND hmovpdv.Nummov = '#{@nummov}' AND Status2 = 'T' ORDER BY sucursal, fecha, nummov"
      @movs = @dbEsta.connection.select_all(sql)
      sql = "SELECT * FROM #{@nomDbPdv}dmovpdv WHERE dmovpdv.Sucursal = #{@sucursal} AND dmovpdv.Fecha = '#{@fecha}' AND dmovpdv.Nummov = '#{@nummov}' AND Idrenglon > 0 AND Status2 = 'T'"
      @dmov = @dbEsta.connection.select_all(sql)
    else
      return redirect_to obras_path
    end
  end

  def obra_new_comment
    @sucursal = params[:sucursal].to_i if params.has_key?(:sucursal)
    @idobra   = params[:idobra].to_i if params.has_key?(:idobra)
    url = "/obras"
    if @sucursal && @sucursal > 0 && @idobra && @idobra > 0
        url = "/obra?sucursal=#{@sucursal}&idobra=#{@idobra}"
        # Aqui se ve si se mando un nuevo comentario al Chat
        @nuevo_comentario = params[:nuevo_comentario] if params.has_key?(:nuevo_comentario)
        if @nuevo_comentario && @nuevo_comentario.to_s.length > 0
            sql = "INSERT INTO ObrasChat ( Sucursal, IdObra, FechaHora, IdUser, Comentario ) VALUES ( #{ User.sanitize(@sucursal) }, #{ User.sanitize(@idobra) }, now(), #{ User.sanitize(current_user.id) }, #{ User.sanitize(@nuevo_comentario) } )"
            begin
              @dbEsta.connection.execute(sql)
            rescue Exception => exc 
              return redirect_to url, alert: "No se ha podido guardar el comentario"
            end
            # Se escribe por duplicado en Esta y Pdv
            begin
              @dbPdv.connection.execute(sql)
            rescue Exception => exc 
              return redirect_to url, alert: "No se ha podido guardar el comentario en PDV"
            end            
            return redirect_to url, notice: "Comentario guardado exitosamente"
        end
    end
    return redirect_to url, alert: "Ha habido un error al guardar el comentario"
  end

  def obra_edit_status
    @sucursal = params[:sucursal].to_i if params.has_key?(:sucursal)
    @idobra   = params[:idobra].to_i if params.has_key?(:idobra)
    url = "/obras"
    if @sucursal && @sucursal > 0 && @idobra && @idobra > 0
        url = "/obra?sucursal=#{@sucursal}&idobra=#{@idobra}"
        if @puede_editar
          @descuento_negociado = params[:descuento_negociado].gsub(",","") if params.has_key?(:descuento_negociado)
          @status = params[:status] if params.has_key?(:status)
          extra_sql = ""
          extra_sql = ", Activa = 0, FecUltMovCierre = '#{Date.today.to_s.gsub("-","")}'" if @status.to_i == 1
          sql = "UPDATE #{@nomDbPdv}obras SET PorcDescNegociado = #{User.sanitize(@descuento_negociado)}, Cerrada = #{User.sanitize(@status)} #{extra_sql} WHERE Sucursal = #{User.sanitize(@sucursal)} AND IdObra = #{User.sanitize(@idobra)}"
          begin
              @dbEsta.connection.execute(sql)
          rescue Exception => exc 
              return redirect_to url, alert: "No se ha podido guardar la obra"
          end
          # Se escribe por duplicado en Esta y Pdv
          begin
            @dbPdv.connection.execute(sql)
          rescue Exception => exc 
            return redirect_to url, alert: "No se ha podido guardar la obra en PDV"
          end
          @nuevo_comentario = "Obra editada por Contralor: Nuevo Descuento Negociado: #{number_to_currency(@descuento_negociado, :locale => :mx, :precision => 2).gsub("$","")}%, Nuevo Status: #{@status.to_i > 0 ? "Cerrada" : "Abierta"}"
          sql = "INSERT INTO ObrasChat ( Sucursal, IdObra, FechaHora, IdUser, Comentario ) VALUES ( #{User.sanitize(@sucursal)}, #{User.sanitize(@idobra)}, now(), #{User.sanitize(current_user.id)}, #{User.sanitize(@nuevo_comentario)} )"
          begin
              @dbEsta.connection.execute(sql)
          rescue Exception => exc 
              return redirect_to url, alert: "No se ha podido guardar el comentario de la obra"
          end
          # Se escribe por duplicado en Esta y Pdv
          begin
              @dbPdv.connection.execute(sql)
          rescue Exception => exc 
              return redirect_to url, alert: "No se ha podido guardar el comentario de la obra en PDV"
          end            
          return redirect_to url, notice: "Obra guardada exitosamente"
        end
    end
    return redirect_to url, alert: "Ha habido un error al guardar la obra"    
  end

  def obra_porc_desc_script
    url = "/obras"
    if @puede_editar
      sqls = [ 
        "update #{@nomDbPdv}obras as o set FechaIni=coalesce((select min(fecha) from #{@nomDbPdv}hmovpdv as h where sucursal=o.sucursal and idobra=o.idobra),\"\") , FechaUltMov=coalesce((select max(fecha) from #{@nomDbPdv}hmovpdv as h where sucursal=o.sucursal and idobra=o.idobra),\"\")",
        "update #{@nomDbPdv}obras as o set TotalVentas=round(coalesce((select sum(if (d.tipo_subt=\"V$\" or d.tipo_subt=\"VC\", preciofin, if (d.tipo_subt=\"v$\" or d.tipo_subt=\"vC\", -preciofin,0.00))) from #{@nomDbPdv}hmovpdv as h left join #{@nomDbPdv}dmovpdv as d using (sucursal,fecha,nummov,status2) where h.sucursal = o.sucursal and h.idobra=o.idobra    and h.status2=\"T\"),0),2),TotalValuado=round(coalesce((select sum(if (d.tipo_subt=\"V$\" or d.tipo_subt=\"VC\", cantidad*preciolp, if (d.tipo_subt=\"v$\" or d.tipo_subt=\"vC\", -cantidad*preciolp, if (d.tipo_subt=\"B\", cantidad*preciolp, 0.00)))) from #{@nomDbPdv}hmovpdv as h left join #{@nomDbPdv}dmovpdv as d using (sucursal,fecha,nummov,status2) where h.sucursal = o.sucursal and h.idobra=o.idobra and h.status2=\"T\"),0),2)",
        "update #{@nomDbPdv}obras as o set PorcDescCalculado=round((1-(TotalVentas/TotalValuado))*100,2) where TotalValuado<>0"
      ]
      sqls.each do |sql|
        begin
          @dbEsta.connection.execute(sql)
        rescue Exception => exc 
            return redirect_to url, alert: "No se ha podido ejecutar el query: #{sql.truncate(40)}"
        end
        begin
          @dbPdv.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to url, alert: "No se ha podido ejecutar el query en PDV: #{sql.truncate(40)}"
        end
      end
      return redirect_to url, notice: "El Porcentaje de Descuento Calculado se ha ejecutado exitosamente"
    else
      return redirect_to url, alert: "No autorizado"
    end
  end

  private 

    def set_filters
      @ver_activas_abiertas = "1"
      @ver_activas_abiertas = false if params.has_key?(:ver_activas_abiertas) && params[:ver_activas_abiertas].to_i == 2
      @ver_activas_abiertas = "0"   if params.has_key?(:ver_activas_abiertas) && params[:ver_activas_abiertas].to_i == 0
      @ver_activas_abiertas = "3"   if params.has_key?(:ver_activas_abiertas) && params[:ver_activas_abiertas].to_i == 3
      @ver_activas_abiertas = "4"   if params.has_key?(:ver_activas_abiertas) && params[:ver_activas_abiertas].to_i == 4
      get_filtros_from_user
      @filtros.push("obras.Activa = #{@ver_activas_abiertas}") if @ver_activas_abiertas == "0" || @ver_activas_abiertas == "1"
      @filtros.push("obras.Cerrada = #{@ver_activas_abiertas.to_i - 3}") if @ver_activas_abiertas == "3" || @ver_activas_abiertas == "4"      
    end

    def get_filtros_from_user
      @filtros = [] if !@filtros
      @filtros.push("1")
      @permiso = Permiso.joins("LEFT JOIN cat_roles ON permisos.permiso = cat_roles.nomPermiso").where("idUsuario = #{current_user.id} AND p1 = #{@sitio[0].idEmpresa.to_i}").order("cat_roles.nivel").limit(1)
      if @permiso && @permiso.count == 1
          if @permiso[0].p2 != "" && @permiso[0].p2 != "0"
              @zonas = @permiso[0].p2.to_s.split(',').map{|i| i.to_i}.sort
              @filtros.push("s.ZonaAsig = #{@zonas.join(" OR s.ZonaAsig = ")}") if @zonas.count > 0
          end
          if @permiso[0].p3 != "" && @permiso[0].p3 != "0"
              @sucursales = @permiso[0].p3.to_s.split(',').map{|i| i.to_i}.sort
              @filtros.push("obras.Sucursal = #{@sucursales.join(" OR obras.Sucursal = ")}") if @sucursales.count > 0
          end
      else
          return redirect_to "/", alert: "No autorizado"
      end
      return @filtros
    end

    def get_puede_editar
      @puede_editar = false
      get_filtros_from_user
      @puede_editar = true if @user_permisos[:nivel] == 5
    end

end
