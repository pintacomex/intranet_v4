class PdvController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app

  include ActionView::Helpers::NumberHelper

  def pdv
# Navegación y seguridad de la página
    get_filtros_from_user

    @filtro = params[:filtro] if params.has_key?(:filtro)

    sql = "SELECT Date_format(now(),'%m/%d/%Y') as Fecha,Date_format(now(),'%Y%m%d') as FechaMov,Date_format(now(),'%d/%m/%Y') as FechaTitulo"
    @fec_ini = @dbPdv.connection.select_all(sql)
    @fecha = @fec_ini[0]['Fecha']
    @fechamov = @fec_ini[0]['FechaMov']
    @fechatitulo = @fec_ini[0]['FechaTitulo']

    @fecha = params[:fechamov] if params.has_key?(:fechamov)
    @fechamov = (params[:fechamov][6,4]).to_s + (params[:fechamov][0,2]).to_s + (params[:fechamov][3,2]).to_s if params.has_key?(:fechamov)

    case @filtro.to_s
    when "VIG"
      @nomfiltro = "Vigentes"
      sql = "SELECT Fecha,Nummov "
      sql += "from #{@nomDbPdv}#{@hcotiza_wp} as hc inner join #{@nomDbPdv}#{@cotiza_wp} as c "
      sql += "using(sucursal,fecha,nummov) "
      sql += "where "
      sql += "Sucursal = #{@sucursal} "
      sql += "and hc.Idvendedor = #{@vendedor} " if @soloelvendedor.to_i == 1
      sql += "and CURDATE() + 0 between Fecha and (date(Fecha) + interval Vigencia day + 0) "
      sql += "and Controlfac = 0 "
      sql += "and hc.Status2 = 'T' "
      sql += "order by Fecha,Nummov Limit 1"
    when "VEN"
      @nomfiltro = "Vencidas"
      sql = "SELECT Fecha,Nummov "
      sql += "from #{@nomDbPdv}#{@hcotiza_wp} as hc inner join #{@nomDbPdv}#{@cotiza_wp} as c "
      sql += "using(sucursal,fecha,nummov) "
      sql += "where "
      sql += "Sucursal = #{@sucursal} "
      sql += "and hc.Idvendedor = #{@vendedor} " if @soloelvendedor.to_i == 1
      sql += "and (date(Fecha) + interval Vigencia day + 0) < CURDATE() + 0 "
      sql += "and Controlfac = 0 "
      sql += "and hc.Status2 = 'T' "
      sql += "order by Fecha,Nummov Limit 1"
    when "FAC"
      @nomfiltro = "Facturadas"
      sql = "SELECT Fecha,Nummov "
      sql += "from #{@nomDbPdv}#{@hcotiza_wp} as hc inner join #{@nomDbPdv}#{@cotiza_wp} as c "
      sql += "using(sucursal,fecha,nummov) "
      sql += "where "
      sql += "Sucursal = #{@sucursal} "
      sql += "and hc.Idvendedor = #{@vendedor} " if @soloelvendedor.to_i == 1
      #sql += "and CURDATE() + 0 between Fecha and (date(Fecha) + interval Vigencia day + 0) "
      sql += "and Controlfac > 0 "
      sql += "and hc.Status2 = 'T' "
      sql += "order by Fecha,Nummov Limit 1"
    when "CAN"
      @nomfiltro = "Canceladas"
      sql = "SELECT Fecha,Nummov "
      sql += "from #{@nomDbPdv}#{@hcotiza_wp} as hc inner join #{@nomDbPdv}#{@cotiza_wp} as c "
      sql += "using(sucursal,fecha,nummov) "
      sql += "where "
      sql += "Sucursal = #{@sucursal} "
      sql += "and hc.Idvendedor = #{@vendedor} " if @soloelvendedor.to_i == 1
      #sql += "and CURDATE() + 0 between Fecha and (date(Fecha) + interval Vigencia day + 0) "
      #sql += "and Controlfac = 0 "
      sql += "and hc.Status2 = 'C' "
      sql += "order by Fecha,Nummov Limit 1"
    when "TOD"
      @nomfiltro = "Todas"
      sql = "SELECT Fecha,Nummov "
      sql += "from #{@nomDbPdv}#{@hcotiza_wp} as hc inner join #{@nomDbPdv}#{@cotiza_wp} as c "
      sql += "using(sucursal,fecha,nummov) "
      sql += "where "
      sql += "Sucursal = #{@sucursal} "
      sql += "and hc.Idvendedor = #{@vendedor} " if @soloelvendedor.to_i == 1
      #sql += "and CURDATE() + 0 between Fecha and (date(Fecha) + interval Vigencia day + 0) "
      #sql += "and Controlfac = 0 "
      #sql += "and hc.Status2 = 'T' "
      sql += "order by Fecha,Nummov Limit 1"
    end
#raise sql.inspect
#    sql = "SELECT Fecha,Nummov from #{@nomDbPdv}#{@hcotiza_wp} where Sucursal = #{@sucursal} and Status2 = 'T' order by Fecha,Nummov Limit 1"
    @hcotiza = @dbPdv.connection.select_all(sql)

    @fecha = @hcotiza[0]['Fecha'] if @hcotiza.count > 0
    @fecha = params[:fechamov] if params.has_key?(:fechamov)
    @nummov = 0
    @nummov = @hcotiza[0]['Nummov'] if @hcotiza.count > 0
    @nummov = params[:nummov] if params.has_key?(:nummov)

    #Los suguientes dos querys son los movimientos del dia o fecha seleccionada

    case @filtro.to_s
    when "VIG"  #Vigentes
      sql = "SELECT hc.*,Vigencia,(date(Fecha) + interval Vigencia day) as Fechavig "
      sql += "from #{@nomDbPdv}#{@hcotiza_wp} as hc inner join #{@nomDbPdv}#{@cotiza_wp} as c "
      sql += "using(sucursal,fecha,nummov) "
      sql += "where "
      sql += "Sucursal = #{@sucursal} "
      sql += "and hc.Idvendedor = #{@vendedor} " if @soloelvendedor.to_i == 1
      sql += "and CURDATE() + 0 between Fecha and (date(Fecha) + interval Vigencia day + 0) "
      sql += "and Controlfac = 0 "
      sql += "and hc.Status2 = 'T' "
      sql += "order by Fecha,Nummov"
    when "VEN" #Vencidas
      sql = "SELECT hc.*,Vigencia,(date(Fecha) + interval Vigencia day) as Fechavig "
      sql += "from #{@nomDbPdv}#{@hcotiza_wp} as hc inner join #{@nomDbPdv}#{@cotiza_wp} as c "
      sql += "using(sucursal,fecha,nummov) "
      sql += "where "
      sql += "Sucursal = #{@sucursal} "
      sql += "and hc.Idvendedor = #{@vendedor} " if @soloelvendedor.to_i == 1
      sql += "and (date(Fecha) + interval Vigencia day + 0) < CURDATE() + 0 "
      sql += "and Controlfac = 0 "
      sql += "and hc.Status2 = 'T' "
      sql += "order by Fecha,Nummov"
    when "FAC" #Facturadas
      sql = "SELECT hc.*,Vigencia,(date(Fecha) + interval Vigencia day) as Fechavig "
      sql += "from #{@nomDbPdv}#{@hcotiza_wp} as hc inner join #{@nomDbPdv}#{@cotiza_wp} as c "
      sql += "using(sucursal,fecha,nummov) "
      sql += "where "
      sql += "Sucursal = #{@sucursal} "
      sql += "and hc.Idvendedor = #{@vendedor} " if @soloelvendedor.to_i == 1
      #sql += "and CURDATE() + 0 between Fecha and (date(Fecha) + interval Vigencia day + 0) "
      sql += "and Controlfac > 0 "
      sql += "and hc.Status2 = 'T' "
      sql += "order by Fecha,Nummov"
    when "CAN" #Canceladas
      sql = "SELECT hc.*,Vigencia,(date(Fecha) + interval Vigencia day) as Fechavig "
      sql += "from #{@nomDbPdv}#{@hcotiza_wp} as hc inner join #{@nomDbPdv}#{@cotiza_wp} as c "
      sql += "using(sucursal,fecha,nummov) "
      sql += "where "
      sql += "Sucursal = #{@sucursal} "
      sql += "and hc.Idvendedor = #{@vendedor} " if @soloelvendedor.to_i == 1
      #sql += "and CURDATE() + 0 between Fecha and (date(Fecha) + interval Vigencia day + 0) "
      #sql += "and Controlfac = 0 "
      sql += "and hc.Status2 = 'C' "
      sql += "order by Fecha,Nummov"
    when "TOD" #Todas
      sql = "SELECT hc.*,Vigencia,(date(Fecha) + interval Vigencia day) as Fechavig "
      sql += "from #{@nomDbPdv}#{@hcotiza_wp} as hc inner join #{@nomDbPdv}#{@cotiza_wp} as c "
      sql += "using(sucursal,fecha,nummov) "
      sql += "where "
      sql += "Sucursal = #{@sucursal} "
      sql += "and hc.Idvendedor = #{@vendedor} " if @soloelvendedor.to_i == 1
      #sql += "and CURDATE() + 0 between Fecha and (date(Fecha) + interval Vigencia day + 0) "
      #sql += "and Controlfac = 0 "
      #sql += "and hc.Status2 = 'T' "
      sql += "order by Fecha,Nummov"
    end
#raise sql.inspect
    #sql = "SELECT * from #{@nomDbPdv}#{@hcotiza_wp} where Sucursal = #{@sucursal} and Status2 = 'T' order by Fecha,Nummov"
    @hcotiza = @dbPdv.connection.select_all(sql)

    #sql = "SELECT * from #{@nomDbPdv}#{@dcotiza_wp} where Sucursal = #{@sucursal} and Status2 = 'T' and Fecha = #{@fecha} and Nummov = #{@nummov}"
    sql = "SELECT * from #{@nomDbPdv}#{@dcotiza_wp} where Sucursal = #{@sucursal} and Fecha = #{@fecha} and Nummov = #{@nummov}"
#raise sql.inspect
    @dcotiza = @dbPdv.connection.select_all(sql)



    #checamos, si cambio la fecha, actualizamos a la fecha de hoy
    #e inicializamos los consecutivos
    sql = "SELECT max(Fecha) as Fecha from #{@nomDbPdv}#{@hcotiza_wp} where Sucursal = #{@sucursal} Limit 1"
    @hfechamax = @dbPdv.connection.select_all(sql)
    if @hfechamax[0]['Fecha'].to_s != @fechamov.to_s
#      sql = "UPDATE #{@nomDbPdv}#{@hcarrito_wp} set Fecha = CURDATE() + 0 where Sucursal = #{@sucursal} and IdVendedor = #{@vendedor}"
      sql = "UPDATE #{@nomDbPdv}#{@hcarrito_wp} set Fecha = CURDATE() + 0 where Sucursal = #{@sucursal}"
      @dbPdv.connection.execute(sql)

#      sql = "UPDATE #{@nomDbPdv}#{@dcarrito_wp} set Fecha = CURDATE() + 0 where Sucursal = #{@sucursal} and IdVendedor = #{@vendedor}"
      sql = "UPDATE #{@nomDbPdv}#{@dcarrito_wp} set Fecha = CURDATE() + 0 where Sucursal = #{@sucursal}"
      @dbPdv.connection.execute(sql)

#      sql = "UPDATE #{@nomDbPdv}#{@cotizac_wp} set Fecha = CURDATE() + 0 where Sucursal = #{@sucursal} and IdVendedor = #{@vendedor}"
      sql = "UPDATE #{@nomDbPdv}#{@cotizac_wp} set Fecha = CURDATE() + 0 where Sucursal = #{@sucursal}"
      @dbPdv.connection.execute(sql)
    
      sql = "SELECT max(Nummov) as Nummov from #{@nomDbPdv}#{@hcarrito_wp} where Sucursal = #{@sucursal}"
      @hmovmax = @dbPdv.connection.select_all(sql)
    
      sql = "SELECT max(NumCotiza) as NumCotiza from #{@nomDbPdv}#{@cotizac_wp} where Sucursal = #{@sucursal}"
      @cotizamax = @dbPdv.connection.select_all(sql)

      sql = "UPDATE #{@nomDbPdv}#{@consec_wp} set UltMovDia = 0, UltMovDiaC = #{@hmovmax[0]['Nummov'].to_i}, UltCotizac = #{@cotizamax[0]['NumCotiza'].to_i} where Sucursal = #{@sucursal}"
      @dbPdv.connection.execute(sql)
    end

    #Los siguientes dos querys, cuando ya existe en el carrito un movimiento de intercambio con status2 = "?", no pide la sucursal al inicio
    @intienvo = 1
#    sql = "SELECT * from #{@nomDbPdv}#{@hcarrito_wp} where Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and tipo_subt = 'IE' and Status2 = '?'"
#    @intnvo = @dbPdv.connection.select_all(sql)
#    if @intnvo && @intnvo.count > 0
#      @intienvo = 1
#    end

    @intisnvo = 1
#    sql = "SELECT * from #{@nomDbPdv}#{@hcarrito_wp} where Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and tipo_subt = 'IS' and Status2 = '?'"
#    @intnvo = @dbPdv.connection.select_all(sql)
#    if @intnvo && @intnvo.count > 0
#      @intisnvo = 1
#    end

  end

#  def pdv_devolver
#    @vendedor = User.sanitize(params[:q]) if params.has_key?(:q)
#raise @vendedor.inspect
#    if @vendedor && @vendedor[1..-2].to_i > 0
#      sql = "SELECT IdVendedor,Nombre FROM vendedores where Sucursal = 49 and Idvendedor = '#{ @vendedor[1..-2] }'"  
#      @vendedores = @dbComun.connection.select_all(sql)
#    end
#    return redirect_to "/pdv_selvend", alert: "No Existe el Vendedor : " + @vendedor[1..-2].to_s if @vendedores && @vendedores.count == 0
#  end

  def pdv_selvend
    get_filtros_from_user
    @vendedor = params[:q] if params.has_key?(:q)
    @movnvo = params[:movnvo] if params.has_key?(:movnvo)
    titulomov(@movnvo)

    if @vendedor && @vendedor.to_i > 0
      sql = "SELECT IdVend,Nombre FROM vendedor where IdVend = '#{@vendedor}'"  
      @vendedores = @dbPdv.connection.select_all(sql)
    else
      if @vendedor && @vendedor.to_s != ""
        sql = "SELECT IdVend,Nombre FROM vendedor where Nombre like '%#{@vendedor}%'"
        @vendedores = @dbPdv.connection.select_all(sql)
      end
    end
   
    if @vendedor && @vendedor.to_s != "" && (!@vendedores or @vendedores.count == 0 )
      @vendedor = params[:vendedor] if params.has_key?(:vendedor)
      redirect_to "/pdv_selvend?vendedor=#{@vendedor}&movnvo=#{@movnvo}", alert: "No hay vendedores con este Id ó texto"
    end
  end

  def pdv_selcli
    @vendedor = params[:vendedor] if params.has_key?(:vendedor)
    get_filtros_from_user
    @cliente = params[:q] if params.has_key?(:q)
    @movnvo = params[:movnvo] if params.has_key?(:movnvo)
    titulomov(@movnvo)

    if @cliente && @cliente.to_i > 0
      sql = "SELECT IdCliente,Nombre,Rfc,Callenum,NumExt,NumInt,Colonia,Delemuni,Estado,Tipoprecio,Contacto FROM #{@clientes_wp} where Sucursal = #{@sucursal} and Idcliente = '#{@cliente}'"  
      @clientes = @dbPdv.connection.select_all(sql)
    else
      if @cliente && @cliente.to_s != ""
        sql = "SELECT IdCliente,Nombre,Rfc,Callenum,NumExt,NumInt,Colonia,Delemuni,Estado,Tipoprecio,Contacto FROM #{@clientes_wp} where Sucursal = #{@sucursal} and Nombre like '%#{@cliente}%'"
        @clientes = @dbPdv.connection.select_all(sql)
      end
    end
    if @cliente && @cliente.to_s != "" && (!@clientes or @clientes.count == 0 )
      @cliente = params[:cliente] if params.has_key?(:cliente)
      redirect_to "/pdv_selcli?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}", alert: "No hay clientes con este Id ó texto"
    end
  end

  def pdv_selsuc
    @vendedor = params[:vendedor] if params.has_key?(:vendedor)
    get_filtros_from_user
    @todas = 0
    @todas = params[:todas].to_i if params.has_key?(:todas)
    @movnvo = params[:movnvo] if params.has_key?(:movnvo)
    titulomov(@movnvo)

    if @todas && @todas.to_i == 1
      sql = "SELECT Num_suc,Nombre FROM #{@nomDbComun}sucursal where ZonaAsig = #{@zona} and StockCero = 0 and FechaTerm = ''"  
      @sucursales = @dbPdv.connection.select_all(sql)
    else
      sql = "SELECT Num_suc,Nombre FROM #{@nomDbComun}sucursal where Num_suc = #{@sucinter}"
      @sucursales = @dbPdv.connection.select_all(sql)
    end
  end

  def pdv_selobra
    @vendedor = params[:vendedor] if params.has_key?(:vendedor)
    get_filtros_from_user
    @movnvo = params[:movnvo] if params.has_key?(:movnvo)
    titulomov(@movnvo)

    sql = "SELECT IdObra,Nombre FROM #{@nomDbpdv}#{@obras_wp} where Sucursal = #{@sucursal} and Activa = 1"  
    @obras = @dbPdv.connection.select_all(sql)
  end

  def pdv_selprod
    @vendedor = params[:vendedor] if params.has_key?(:vendedor)
    get_filtros_from_user
    @clave = User.sanitize(params[:clave]) if params.has_key?(:clave)
    @cveasoc = User.sanitize(params[:cveasoc]) if params.has_key?(:cveasoc)
    @descrip = User.sanitize(params[:descrip]) if params.has_key?(:descrip)
    @tipoclave = params[:tipoclave] if params.has_key?(:tipoclave)
    @unidmedida = User.sanitize(params[:unidmedida]) if params.has_key?(:unidmedida)
    @preciolp = params[:preciolp] if params.has_key?(:preciolp)
    @costolp = params[:costolp] if params.has_key?(:costolp)
    @precio = params[:precio] if params.has_key?(:precio)
    @cantidad = params[:cantidad] if params.has_key?(:cantidad)
    @cliente = params[:cliente] if params.has_key?(:cliente)
    @tab = "1"
    @tab = params[:tab] if params.has_key?(:tab)
    @seltipodesc = params[:seltipodesc].to_i if params.has_key?(:seltipodesc)
    @descporce = 0
    @descporce = params[:descporce] if params.has_key?(:descporce)
    @descpesos = 0
    @descpesos = params[:descpesos] if params.has_key?(:descpesos)
    @recalcular = 0
    @recalcular = params[:recalcular] if params.has_key?(:recalcular)
    @clienteant = 0
    @clienteant = params[:clienteant] if params.has_key?(:clienteant)
    @movnvo = params[:movnvo] if params.has_key?(:movnvo)
    titulomov(@movnvo)

    cveant = "***"
    @cveant_r = ""
    continua = "1"


# Hay que checar si el tipo de mov que selecciono es del mismo que hay con status2 = ?


    if params.has_key?(:activap) && params[:activap].to_i == 1
      @nummovp = 0
      @nummovp = params[:nummovp] if params.has_key?(:nummovp)
      @tipo_subt = params[:tipo_subt] if params.has_key?(:tipo_subt)

      sql = "UPDATE #{@nomDbPdv}#{@hcarrito_wp} set Status2 = 'P' "
      sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Status2 = '?'"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv?", alert: "No se pudo activar el movimiento pendiente, error: #{exc.message}"
      end

      sql = "UPDATE #{@nomDbPdv}#{@dcarrito_wp} set Status2 = 'P' "
      sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Status2 = '?'"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv", alert: "No se pudo activar el movimiento pendiente, error: #{exc.message}"
      end

      if @movnvo.to_s == "Z"
        sql = "UPDATE #{@nomDbPdv}#{@cotizac_wp} set Status2 = 'P' "
        sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Status2 = '?'"
        begin
          @dbPdv.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to "/pdv_selprod?cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo activar el movimiento pendiente, error: #{exc.message}"
        end
      end
      
      sql = "UPDATE #{@nomDbPdv}#{@hcarrito_wp} set Status2 = '?' "
      sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummovp}"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv", alert: "No se pudo activar el movimiento pendiente, error: #{exc.message}"
      end

      sql = "UPDATE #{@nomDbPdv}#{@dcarrito_wp} set Status2 = '?' "
      sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummovp}"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv", alert: "No se pudo activar el movimiento pendiente, error: #{exc.message}"
      end

      if @movnvo.to_s == "Z"
        sql = "UPDATE #{@nomDbPdv}#{@cotizac_wp} set Status2 = '?' "
        sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummovp}"
        begin
          @dbPdv.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo activar el movimiento pendiente, error: #{exc.message}"
        end
      end
    end

    @nummov = 0
    @fin_sel_prod = 0

    case @movnvo.to_s
    when "V"  
      @tipoventa = "1" #Contado
      @titulotipoventa = "Venta de Contado Comanda"
      @tipo_subt = "V$"
      sql = "SELECT Nummov,fin_sel_prod from #{@nomDbPdv}#{@hcarrito_wp} where Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and tipo_subt like 'V%' and Status2 = '?'"
    when "Z" 
      @tipoventa = "1" #Contado
      @titulotipoventa = "Cotización sin Cliente"
      @tipo_subt = "Z$"
      sql = "SELECT Nummov,fin_sel_prod from #{@nomDbPdv}#{@hcarrito_wp} where Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and tipo_subt like 'Z%' and Status2 = '?'"
    when "IE" 
      @titulotipoventa = "Intercambio de Entrada"
      @tipo_subt = "IE"
      sql = "SELECT Nummov,fin_sel_prod from #{@nomDbPdv}#{@hcarrito_wp} where Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and tipo_subt = 'IE' and Status2 = '?'"
    when "IS" 
      @titulotipoventa = "Intercambio de Salida"
      @tipo_subt = "IS"
      sql = "SELECT Nummov,fin_sel_prod from #{@nomDbPdv}#{@hcarrito_wp} where Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and tipo_subt = 'IS' and Status2 = '?'"
    when "B" 
      @titulotipoventa = "Baja de Mercancía"
      @tipo_subt = "B"
      sql = "SELECT Nummov,fin_sel_prod from #{@nomDbPdv}#{@hcarrito_wp} where Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and tipo_subt = 'B' and Status2 = '?'"
    end
#raise sql.inspect
    @nummovexist = @dbPdv.connection.select_all(sql)
    @nummov = @nummovexist[0]['Nummov'] if @nummovexist.count > 0
    @fin_sel_prod = @nummovexist[0]['fin_sel_prod'] if @nummovexist.count > 0
    #raise @nummov.inspect
    @fin_sel_prod = params[:fin_sel_prod].to_s if params.has_key?(:fin_sel_prod)
    @save_fin_sel_prod = params[:save_fin_sel_prod].to_i if params.has_key?(:save_fin_sel_prod)

    if @movnvo.to_s == "Z"
      sql = "SELECT NumCotiza from #{@nomDbPdv}#{@cotizac_wp} where Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and tipo_subt like 'Z%' and Status2 = '?'"
      @numcotizaexist = @dbPdv.connection.select_all(sql)
      @numcotiza = @numcotizaexist[0]['NumCotiza'] if @numcotizaexist.count > 0
    end

    if params.has_key?(:save_fin_sel_prod) && params[:save_fin_sel_prod].to_i == 1
      sql = "UPDATE #{@nomDbPdv}#{@hcarrito_wp} set fin_sel_prod = #{@fin_sel_prod} where Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo guardar fin selección, error: #{exc.message}"
      end
    end

    #Se da de alta la obra
    if params.has_key?(:nomobra) && params[:nomobra].to_s != ""
      sql = "UPDATE #{@nomDbPdv}#{@consec_wp} set UltObra = UltObra + 1 where Sucursal = #{@sucursal}"
      @dbPdv.connection.execute(sql)

      sql = "SELECT UltObra from #{@nomDbPdv}#{@consec_wp} where Sucursal = #{@sucursal}"
      @ultmov = @dbPdv.connection.select_all(sql)
      idobra = @ultmov[0]['UltObra']
      nomobra = params[:nomobra].to_s

      sql = "INSERT INTO #{@nomDbPdv}#{@obras_wp} set "
      sql +="Sucursal = #{@sucursal},"
      sql +="IdObra = #{idobra},"
      sql +="Nombre = '#{nomobra}',"
      sql +="Activa = 1"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&nomobra=#{nomobra}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo guardar la Obra, error: #{exc.message}"
      end

      sql = "UPDATE #{@nomDbPdv}#{@hcarrito_wp} set IdObra = #{idobra} where Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
      @dbPdv.connection.execute(sql)
    end

    #Se graba la sucursal que surte ó en un Intercambio Suc. que intercambia
    if params.has_key?(:idobra) && params[:idobra].to_i > 0
      idobra = params[:idobra].to_i
      sql = "UPDATE #{@nomDbPdv}#{@hcarrito_wp} set IdObra = #{idobra} where Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
      @dbPdv.connection.execute(sql)
    end

    #Se graba la sucursal que surte ó en un Intercambio Suc. que intercambia
    if @movnvo.to_s == "V" && @nummovexist.count > 0 && @sucinter.to_i > 0
      sql = "UPDATE #{@nomDbPdv}#{@hcarrito_wp} set IdSucursal = #{@sucinter} where Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
      @dbPdv.connection.execute(sql)
    end

    #Los dos querys siguientes son para el titulo de la Obra y la Suc. que surte ó en un Intercambio Suc. que intercambia
    sql = "SELECT IdSucursal,IdObra FROM #{@nomDbPdv}#{@hcarrito_wp} where Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
    @idsucexist = @dbPdv.connection.select_all(sql)

    @idobratitulo = @idsucexist[0]['IdObra'] if @idsucexist && @idsucexist.count > 0
    sql = "SELECT Nombre FROM #{@nomDbPdv}#{@obras_wp} where Sucursal = #{@sucursal}" if @idsucexist && @idsucexist.count > 0
    @nomidobraexist = @dbPdv.connection.select_all(sql) if @idsucexist && @idsucexist.count > 0
    @nomidobratitulo = @nomidobraexist[0]['Nombre'] if @nomidobraexist && @nomidobraexist.count > 0

    sql = "SELECT Num_suc,Nombre FROM #{@nomDbComun}sucursal where Num_suc = #{@idsucexist[0]['IdSucursal']}" if @idsucexist && @idsucexist.count > 0
    @nomidsucexist = @dbPdv.connection.select_all(sql) if @idsucexist && @idsucexist.count > 0
    @idsuctitulo = 0
    @idsuctitulo = @nomidsucexist[0]['Num_suc'] if @nomidsucexist && @nomidsucexist.count > 0
    @nomidsuctitulo = @nomidsucexist[0]['Nombre'] if @nomidsucexist && @nomidsucexist.count > 0

    if params.has_key?(:regreso) && params[:regreso] == "1"
      sql = "SELECT CveAnt,Clave FROM #{@nomDbPub}prodtree where IdCanRefLista = 0 and vendible = 1 and Clave = '#{params[:cveant]}'"
      @regreso = @dbPdv.connection.select_all(sql)
      @cveant_r = @regreso[0]['CveAnt'] if (params[:cveant] != "" or params[:cveant] != "***")
      continua = "0" if @cveant_r == "***" or params[:cveant] == ""
    end

    if params.has_key?(:cveant) && continua == "1"
      cveant = params[:cveant] 
      cveant = @regreso[0]['CveAnt'] if params.has_key?(:regreso) && params[:regreso] == "1"
    end

    sql = "SELECT ColumnaLP from #{@nomDbPub}catlista where NomLista = 'Costo'"
    @precios = @dbPdv.connection.select_all(sql)
    @lcostolp = @precios[0]['ColumnaLP']

    sql = "SELECT ColumnaLP from #{@nomDbPub}catlista where NomLista = 'Publico'"
    @precios = @dbPdv.connection.select_all(sql)
    @lpreciolp = @precios[0]['ColumnaLP']
    @tipodesc = ""
    @tipoprecio = @lpreciolp

    sql = "SELECT Idcliente from #{@nomDbPdv}#{@hcarrito_wp} where Sucursal = #{@sucursal} and fecha = CURDATE() + 0 and IdVendedor = #{@vendedor} and Nummov = #{@nummov}"
    @clienteh = @dbPdv.connection.select_all(sql)
    @cliente = 0 if !@cliente 
    @cliente = @clienteh[0]['Idcliente'] if @cliente == 0 && @clienteh.count > 0

    if @cliente && @cliente.to_i > 0
      sql = "SELECT ColumnaLP,Tipoventa,Nombre,Rfc,Callenum,NumExt,NumInt,Colonia,Delemuni,Estado,Cp,Contacto "
      sql +="from #{@nomDbPub}catlista as l inner join #{@nomDbPdv}#{@clientes_wp} as c "
      sql +="ON c.TipoPrecio = l.IdLista "
      sql +="WHERE Sucursal = #{@sucursal} and IdCliente = #{@cliente}"
      @precios = @dbPdv.connection.select_all(sql)
      @tipoprecio = @precios[0]['ColumnaLP'] if @precios[0]['ColumnaLP'] != @lpreciolp
      @tipodesc = "C" if @precios[0]['ColumnaLP'] != @preciolp
      @tipoventa = "2" if @precios[0]['Tipoventa'].to_i == 2 #Crédito
      if @movnvo.to_s == "V"
        @titulotipoventa = "Venta de Contado por Facturar"
        @titulotipoventa = "Venta de Crédito por Facturar" if @precios[0]['Tipoventa'].to_i == 2 
        @tipo_subt = "VC" if @precios[0]['Tipoventa'].to_i == 2
      else
        @titulotipoventa = "Cotización a Cliente de Contado"
        @titulotipoventa = "Cotización a Cliente de Crédito" if @precios[0]['Tipoventa'].to_i == 2 
        @tipo_subt = "ZC" if @precios[0]['Tipoventa'].to_i == 2
      end
      @nomcli = @precios[0]['Nombre']
      @rfc = @precios[0]['Rfc']
      @callenum = @precios[0]['Callenum']
      @numExt = @precios[0]['NumExt']
      @numInt = @precios[0]['NumInt']
      @colonia = @precios[0]['Colonia']
      @delemuni = @precios[0]['Delemuni']
      @estado = @precios[0]['Estado']
      @cp = @precios[0]['Cp']
      if @cliente.to_i != @clienteh[0]['Idcliente'].to_i
#        @recalcular = 1

        if @movnvo == "Z"
          sql = "SELECT Contacto,NotaSup,NotaInf,DatosVend from #{@nomDbPdv}#{@cotiza_wp} "
          sql +="WHERE Sucursal = #{@sucursal} and IdCliente = #{@cliente} order by NumCotiza DESC limit 1 "
          @cotizaant = @dbPdv.connection.select_all(sql)

          if @cotizaant.count > 0
            contacto = @cotizaant[0]['Contacto']
            notasup = @cotizaant[0]['NotaSup']
            notainf = @cotizaant[0]['NotaInf']
            datosvend = @cotizaant[0]['DatosVend']
          else
            contacto = @precios[0]['Contacto']
            notasup = "Por este medio nos complace presentarle nuestra propuesta Tecnico-Comercial de los productos marca Comex."
            notainf = "Las garantías de los productos son las que ofrece el fabricante y estarán sujetas a que el producto no presente daños, alteraciones o hayan sido utilizados de manera diferente a
las recomendadas por el fabricante.
"
            datosvend = @nomvendedor
          end

          sql = "UPDATE #{@nomDbPdv}#{@cotizac_wp} set Tipo_subt = '#{@tipo_subt}',Idcliente = #{@cliente}, "
          sql +="Contacto = '#{contacto}',NotaSup = '#{notasup}',NotaInf = '#{notainf}',DatosVend = '#{datosvend}' "
          sql +="where Sucursal = #{@sucursal} and fecha = CURDATE() + 0 and idvendedor = #{@vendedor} and NumCotiza = #{@numcotiza} and Nummov = #{@nummov}"
          begin
            @dbPdv.connection.execute(sql)
          rescue Exception => exc 
            return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo guardar el cliente, error: #{exc.message}"
          end
        end

        sql = "UPDATE #{@nomDbPdv}#{@dcarrito_wp} set Tipo_subt = '#{@tipo_subt}',Pordesfac = 0 where Sucursal = #{@sucursal} and fecha = CURDATE() + 0 and idvendedor = #{@vendedor} and Nummov = #{@nummov}"
        begin
          @dbPdv.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to "/pdv_selprod?cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo guardar el cliente, error: #{exc.message}"
        end

        sql = "UPDATE #{@nomDbPdv}#{@hcarrito_wp} set Tipo_subt = '#{@tipo_subt}',Idcliente = #{@cliente},PorDescFac = 0,DescFac = 0 where Sucursal = #{@sucursal} and fecha = CURDATE() + 0 and idvendedor = #{@vendedor} and Nummov = #{@nummov}"
        begin
          @dbPdv.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo guardar el cliente, error: #{exc.message}"
        end
      end
    end 

    if params.has_key?(:clienteant) && @cliente.to_i != @clienteant.to_i
      @recalcular = 1
    end

    if params.has_key?(:cveant) && params[:cveant].to_s.length == 17 
      @lfiltro = "cveant"
      @filtro = params[:cveant]
      cveant = "***"
      @cveant_r = "***"
#      if @stockcero.to_i == 1
        sql = "SELECT Clave,CveAsoc,DescripLar,TipoClave,UnidMedida,#{@lpreciolp} as PrecioLp,#{@lcostolp} as CostoLp,#{@tipoprecio} as PreUniFac, '1' as Cantidad "
        sql += "from #{@nomDbPub}producto "
        sql += "WHERE IdCanRefLista = 0 "
        sql += "and Clave = '#{params[:cveant]}' "
#      else
#        sql = "SELECT Clave,CveAsoc,DescripLar,TipoClave,UnidMedida,#{@lpreciolp} as PrecioLp,#{@lcostolp} as CostoLp,#{@tipoprecio} as PreUniFac,Teorico as Existencia, '1' as Cantidad "
#        sql += "from #{@nomDbPub}producto as p inner join #{@nomDbPdv}stockb as s "
#        sql += "using(Clave) "
#        sql += "WHERE IdCanRefLista = 0 "
#        sql += "and Clave = '#{params[:cveant]}' "
#        sql += "and Sucursal = #{@sucursal} "
#      end
      @productos = @dbPdv.connection.select_all(sql)
      if @productos && @productos.count == 0
        return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}", alert: "No existen productos con esta Clave"
      end
    end
#raise @recalcular.to_i.inspect

    if params.has_key?(:q) && params[:q].to_s.length > 0 
      @lfiltro = "q"
      @filtro = params[:q]
      @sanitized = User.sanitize(params[:q])
#      if @stockcero.to_i == 1
        sql = "SELECT Clave,CveAsoc,DescripLar,TipoClave,UnidMedida,#{@lpreciolp} as PrecioLp,#{@lcostolp} as CostoLp,#{@tipoprecio} as PreUniFac, '1' as Cantidad "
        sql += "from #{@nomDbPub}producto "
        sql += "WHERE IdCanRefLista = 0 "
        sql += "and Clave not like '11%' "
        sql += "and Clave not like '75%' "
        sql += "and Clave not like '80%' "
        sql += "and Vendible = 1 "
        sql += "and CveAsoc = '#{ @sanitized[1..-2] }' LIMIT 100 "
#      else
#        sql = "SELECT Clave,CveAsoc,DescripLar,TipoClave,UnidMedida,#{@lpreciolp} as PrecioLp,#{@lcostolp} as CostoLp,#{@tipoprecio} as PreUniFac,Teorico as Existencia, '1' as Cantidad "
#        sql += "from #{@nomDbPub}producto as p inner join #{@nomDbPdv}stockb as s "
#        sql += "using(Clave) "
#        sql += "WHERE IdCanRefLista = 0 "
#        sql += "and Clave not like '11%' "
#        sql += "and Clave not like '75%' "
#        sql += "and Clave not like '80%' "
#        sql += "and Vendible = 1 "
#        sql += "and CveAsoc = '#{ @sanitized[1..-2] }' "
#        sql += "and Sucursal = #{@sucursal} LIMIT 100 "
#      end
      @productos = @dbPdv.connection.select_all(sql)
      if @productos && @productos.count == 0
#        if @stockcero.to_i == 1
          sql = "SELECT Clave,CveAsoc,DescripLar,TipoClave,UnidMedida,#{@lpreciolp} as PrecioLp,#{@lcostolp} as CostoLp,#{@tipoprecio} as PreUniFac, '1' as Cantidad "
          sql += "from #{@nomDbPub}producto "
          sql += "WHERE IdCanRefLista = 0 "
          sql += "and Clave not like '11%' "
          sql += "and Clave not like '75%' "
          sql += "and Clave not like '80%' "
          sql += "and Vendible = 1 "
          sql += "and DescripLar like '%#{ @sanitized[1..-2] }%' LIMIT 100 "
#        else
#          sql = "SELECT Clave,CveAsoc,DescripLar,TipoClave,UnidMedida,#{@lpreciolp} as PrecioLp,#{@lcostolp} as CostoLp,#{@tipoprecio} as PreUniFac,Teorico as Existencia, '1' as Cantidad "
#          sql += "from #{@nomDbPub}producto as p inner join #{@nomDbPdv}stockb as s "
#          sql += "using(Clave) "
#          sql += "WHERE IdCanRefLista = 0 "
#          sql += "and Clave not like '11%' "
#          sql += "and Clave not like '75%' "
#          sql += "and Clave not like '80%' "
#          sql += "and Vendible = 1 "
#          sql += "and DescripLar like '%#{ @sanitized[1..-2] }%' "
#          sql += "and Sucursal = #{@sucursal} LIMIT 100 "
#        end
        @productos = @dbPdv.connection.select_all(sql)
        if @productos && @productos.count == 0
          return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}", alert: "No existen productos con esta Clave ó Descripción"
        end
      end
    end

    sql = "SELECT CveAnt,Clave,Descp1,Descp2 FROM #{@nomDbPub}prodtree where IdCanRefLista = 0  and vendible = 1 and Clave not like '75%' and Clave not like '80%' and CveAnt = '#{cveant}' order by NumOrd"
    @prodtree = @dbPdv.connection.select_all(sql)

    if @movnvo.to_s == "V" or @movnvo.to_s == "Z"
      if @seltipodesc.to_i == 1 #En porcentaje
        descuentos_en_detalle()
        if @prodcondesc.to_i > 0
          return redirect_to "/pdv_desc_global_edit?vendedor=#{@vendedor}&nummov=#{@nummov}&movnvo=#{@movnvo}&cliente=#{@cliente}&descuento=#{@descporce}&prodcondesc=#{@prodcondesc}&prodsindesc=#{@prodsindesc}&seltipodesc=1&tab=2"
        else
          #Se calcula el descuento en $ a partir del porcentaje
          sql = "SELECT Subtotfac from #{@nomDbPdv}#{@hcarrito_wp} "
          sql +="where "
          sql +="Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} "
          sql +="and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
          @subtot = @dbPdv.connection.select_all(sql)
          @descuentopesos = ((@descporce.to_f * @subtot[0]['Subtotfac'].to_f) / 100).round(2)
          actualiza_desc_global(@descporce,@descuentopesos)
        end
      end

      if @seltipodesc.to_i == 2 #En Pesos
        descuentos_en_detalle()
        @descuentopesos = (@descpesos.to_f / @iva.to_f).round(2)
        #Se calcula el descuento en % a partir del monto en pesos
        sql = "SELECT Subtotfac from #{@nomDbPdv}#{@hcarrito_wp} "
        sql +="where "
        sql +="Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} "
        sql +="and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
        @subtot = @dbPdv.connection.select_all(sql)
        @descuento = (((@descpesos.to_f / @iva.to_f) * 100) / @subtot[0]['Subtotfac'].to_f).round(2)
#  raise @descuento.to_f.inspect
        if @prodcondesc.to_i > 0
          return redirect_to "/pdv_desc_global_edit?vendedor=#{@vendedor}&nummov=#{@nummov}&movnvo=#{@movnvo}&cliente=#{@cliente}&descuento=#{@descuento}&descuentopesos=#{@descuentopesos}&prodcondesc=#{@prodcondesc}&prodsindesc=#{@prodsindesc}&seltipodesc=2&tab=2"
        else
          actualiza_desc_global(@descuento,@descuentopesos)
        end
      end
    end

    if @recalcular.to_i == 1
      sql = "UPDATE #{@nomDbPdv}#{@dcarrito_wp} as d inner join #{@nomDbPub}producto as p "
      sql +="using(clave) "
      sql +="Set "
      sql +="Preciofin = round(#{@tipoprecio} * Cantidad,2), "

      if @cliente.to_i > 0
        if  @rfc.to_s != "" && @rfc.length >= 12
          if @clienteant.to_i == 0
            sql +="Preunifac = round(if(d.CveAsoc = 'MANO',round(Preunifac / #{@iva},2),round(#{@tipoprecio} / #{@iva},2)),2), "
          else
            sql +="Preunifac = round(if(d.CveAsoc = 'MANO',Preunifac,round(#{@tipoprecio} / #{@iva},2)),2), "
          end
          sql +="Totrenfac = round((if(d.CveAsoc = 'MANO',Preunifac,round(#{@tipoprecio} / #{@iva},2)) * Cantidad) - (((if(d.CveAsoc = 'MANO',Preunifac,round(#{@tipoprecio} / #{@iva},2)) * Pordesfac) /100) * Cantidad),2), "
        else
          sql +="Preunifac = round(if(d.CveAsoc = 'MANO',Preunifac,#{@tipoprecio}),2), "
          sql +="Totrenfac = round((if(d.CveAsoc = 'MANO',Preunifac,#{@tipoprecio}) * Cantidad) - (((if(d.CveAsoc = 'MANO',Preunifac,#{@tipoprecio}) * Pordesfac) /100) * Cantidad),2), "
        end
      else
        sql +="Preunifac = round(if(d.CveAsoc = 'MANO',Preunifac,#{@tipoprecio}),2), "
        sql +="Totrenfac = round((if(d.CveAsoc = 'MANO',Preunifac,#{@tipoprecio}) * Cantidad) - (((if(d.CveAsoc = 'MANO',Preunifac,#{@tipoprecio}) * Pordesfac) /100) * Cantidad),2), "
      end      
      sql +="Tipodesc = if('#{@lpreciolp}' != '#{@tipoprecio}','C','') "
      sql +="where "
      sql +="Sucursal = #{@sucursal} "
      sql +="and IdVendedor = #{@vendedor} "
      sql +="and Fecha = CURDATE() + 0 "
      sql +="and Nummov = #{@nummov} "
      sql +="and IdCanRefLista = 0"
  #      raise sql.inspect
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo recalcular el movimiento, error: #{exc.message}"
      end
    end

    if params.has_key?(:agregar) && params[:agregar].to_i == 1
      #return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&movnvo=#{@movnvo}&#{@lfiltro}=#{@filtro}", alert: "No se puede agregar Mano de Obra sin Cliente" if @cliente.to_i == 0 && @cveasoc[1..-2] == "MANO"
      #Alta de la sucursal en consec si no existe
      sql = "INSERT IGNORE INTO #{@nomDbPdv}#{@consec_wp} (Sucursal) values (#{@sucursal}) "
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&#{@lfiltro}=#{@filtro}", alert: "No se pudo agegar el producto, error: #{exc.message}"
      end

      if @nummov.to_i == 0
        #Suma un movimiento al dia
        if @movnvo.to_s == "Z"
          sql = "UPDATE #{@nomDbPdv}#{@consec_wp} set UltMovDiaC = UltMovDiaC + 1,UltCotizaC = UltCotizaC + 1 where Sucursal = #{@sucursal}"
        else
          sql = "UPDATE #{@nomDbPdv}#{@consec_wp} set UltMovDiaC = UltMovDiaC + 1 where Sucursal = #{@sucursal}"
        end
        begin
          @dbPdv.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&#{@lfiltro}=#{@filtro}", alert: "No se pudo agregar el producto, error: #{exc.message}"
        end

        #Obtiene el nuevo nummov
        sql = "SELECT UltMovDiaC,UltCotizaC from #{@nomDbPdv}#{@consec_wp} where Sucursal = #{@sucursal}"
        @ultmov = @dbPdv.connection.select_all(sql)
        @nummov = @ultmov[0]['UltMovDiaC']
        @numcotiza = @ultmov[0]['UltCotizaC']
      end

      if @movnvo.to_s == "Z"
        sql = "INSERT IGNORE INTO #{@nomDbPdv}#{@cotizac_wp} (Sucursal,IdVendedor,Fecha,NumCotiza,Nummov,Tipo_subt,Status,Status2,IdCliente,DatosVend) "
        sql +=" values (#{@sucursal},#{@vendedor},CURDATE() + 0,#{@numcotiza.to_s},#{@nummov.to_s},'#{@tipo_subt}','T','?',#{@cliente},'#{@nomvendedor}')"
        begin
          @dbPdv.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&#{@lfiltro}=#{@filtro}", alert: "No se pudo agregar cotización, error: #{exc.message}"
        end
      end

      sql = "INSERT IGNORE INTO #{@nomDbPdv}#{@hcarrito_wp} (Sucursal,IdVendedor,Fecha,Nummov,Tipo_subt,Status,Status2) "
      sql +=" values (#{@sucursal},#{@vendedor},CURDATE() + 0,#{@nummov.to_s},'#{@tipo_subt}','T','?')"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&#{@lfiltro}=#{@filtro}", alert: "No se pudo agregar el producto, error: #{exc.message}"
      end

      sql = "SELECT * from #{@nomDbPdv}#{@dcarrito_wp} where Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov} and Clave = #{@clave} and CveAsoc != 'MANO' and TipoClave != 5"
      @duplicado = @dbPdv.connection.select_all(sql)
#raise @duplicado.count.inspect

      if @duplicado.count == 0
        #Calcula el nuevo renglón para el nummov en curso
        sql = "SELECT COALESCE(max(IdRenglon),0) + 1 as renglonsig from #{@nomDbPdv}#{@dcarrito_wp} where Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
        @ultmov = @dbPdv.connection.select_all(sql)
        @idrenglon = @ultmov[0]['renglonsig']

        @preciofin = (@precio.to_f * @cantidad.to_f).round(2)
        if @cliente.to_i > 0 && @rfc.to_s != "" && @rfc.length >= 12
          @preunifac = (@precio.to_f / @iva.to_f).round(2)
        else
          @preunifac = @precio.to_f
        end
        @totrenfac = (@preunifac.to_f * @cantidad.to_f).round(2)
        umedida = "Pieza"
        umedida = "NA" if @cveasoc.to_s == "'MANO'"
        sql = "INSERT IGNORE INTO #{@nomDbPdv}#{@dcarrito_wp} (Sucursal,IdVendedor,Fecha,Nummov,IdRenglon,Tipo_subt,Status,Status2,Clave,TipoClave,CveAsoc,Descrip,UMedida,Preciolp,Costolp,Cantidad,PrecioFin,Preunifac,TotRenFac,Tipodesc) "
        sql +=" values (#{@sucursal},#{@vendedor},CURDATE() + 0,#{@nummov},#{@idrenglon},'#{@tipo_subt}','T','?',#{@clave},#{@tipoclave},#{@cveasoc},#{@descrip},'#{umedida}',#{@preciolp},#{@costolp},#{@cantidad},#{@preciofin.to_f},#{@preunifac.to_f},#{@totrenfac.to_f},'#{@tipodesc}')"
        begin
          @dbPdv.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&#{@lfiltro}=#{@filtro}", alert: "No se pudo agregar el producto, error: #{exc.message}"
        end

        return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&#{@lfiltro}=#{@filtro}", notice: "Agregado al Carrito Exitosamente ( '#{@descrip}' )"
      else
        sql = "UPDATE #{@nomDbPdv}#{@dcarrito_wp} set Cantidad = Cantidad + #{@cantidad}, Totrenfac = round(round(Preunifac * Cantidad,2) - round(((Preunifac * Pordesfac)/100) * Cantidad,2),2) where Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov} and Clave = #{@clave}"
#raise sql.inspect
        begin
          @dbPdv.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&#{@lfiltro}=#{@filtro}", alert: "No se pudo agregar el producto, error: #{exc.message}"
        end
        return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&#{@lfiltro}=#{@filtro}", notice: "Se Agrego #{@cantidad} mas al Producto ( #{@descrip} ) Exitosamente"
      end
    end

    sql = "SELECT count(*) as TotDetalle from #{@nomDbPdv}#{@dcarrito_wp} "
    sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
    @haydetalle = @dbPdv.connection.select_all(sql)
    haydetalle = @haydetalle[0]['TotDetalle'].to_i

    if @nummov.to_i > 0 && haydetalle.to_i > 0
      sql = "SELECT sum(Cantidad * Preciolp) as Totalvaluado,sum(TotRenFac) as SubTotal "
      sql +="from #{@nomDbPdv}#{@dcarrito_wp} "
      sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
      @totales = @dbPdv.connection.select_all(sql)

      sql = "UPDATE #{@nomDbPdv}#{@hcarrito_wp} Set "
      if @cliente.to_i > 0
        if  @rfc.to_s != "" && @rfc.length >= 12
          sql +="Total = round((#{@totales[0]['SubTotal']} - Descfac) * #{@iva},2),"
        else
          sql +="Total = round(#{@totales[0]['SubTotal']} - Descfac,2),"
        end
      else
        sql +="Total = #{@totales[0]['SubTotal']},"
      end
      sql +="Totvaluado = #{@totales[0]['Totalvaluado']},"
      sql +="Subtotfac = #{@totales[0]['SubTotal']},"
      if @cliente.to_i > 0
        if @rfc.to_s != "" && @rfc.length >= 12
          sql +="Ivafac = round((#{@totales[0]['SubTotal']} - Descfac) * #{@iva},2) - (#{@totales[0]['SubTotal'].to_f} - Descfac) "
        else
          sql +="Ivafac = 0 "
        end
      else
        sql +="Ivafac = 0 "
      end
      sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo actualizaar hcarrito, error: #{exc.message}"
      end
    else
      sql = "UPDATE #{@nomDbPdv}#{@hcarrito_wp} Set "
      sql +="Total = 0, "
      sql +="Totvaluado = 0,"
      sql +="Subtotfac = 0,"
      sql +="Ivafac = 0 "
      sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo actualizaar hcarrito, error: #{exc.message}"
      end
    end

    sql = "SELECT Sucursal,IdVendedor,Fecha,Nummov,Tipo_subt,Status,Status2,Total,Totvaluado,Idcliente,IdSucursal, "
    sql +="Foliointer,Folioinfo,IdObra,Subtotfac,Pordescfac,Descfac,Ivafac,Observac,Fechasist,fin_sel_prod "
    sql +="from #{@nomDbPdv}#{@hcarrito_wp} "
    sql +="where  Sucursal = #{@sucursal} "
    sql +="and idvendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov} and Status2 = '?'"
#raise sql.inspect
    @hcarrito = @dbPdv.connection.select_all(sql)

    sql = "SELECT Sucursal,IdVendedor,Fecha,Nummov,Idrenglon,Tipo_subt,Status,Status2,Clave,Cveasoc,Descrip, "
    sql +="UMedida,Preciolp,Costolp,Cantidad,Preciofin,Preunifac,Pordesfac,(round((Preunifac * Pordesfac)/100,2) * Cantidad) * -1 as PordesfacP,Totrenfac,Tipodesc "
    sql +="from #{@nomDbPdv}#{@dcarrito_wp} "
    sql +="where  Sucursal = #{@sucursal} "
    sql +="and idvendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov} and Status2 = '?'"
    @dcarrito = @dbPdv.connection.select_all(sql)


    if params.has_key?(:finalizar) && params[:finalizar].to_i == 1
      sql = "SELECT count(*) as haycodmano from #{@nomDbPdv}#{@dcarrito_wp} "
      sql +="where  "
      sql +="Sucursal = #{@sucursal} and idvendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov} "
      sql +="and Cveasoc = 'MANO'"
      @codigomano = @dbPdv.connection.select_all(sql)
      @asignarobra = 0
      @asignarobra = 1 if @codigomano[0]['haycodmano'].to_i > 0

      if @movnvo == "Z"
        sql = "SELECT Vigencia from #{@nomDbPdv}#{@cotizac_wp} "
        sql +="where  "
        sql +="Sucursal = #{@sucursal} and idvendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov} "
        @vigenciamov = @dbPdv.connection.select_all(sql)
        @vigencia = 0
        @vigencia = @vigenciamov[0]['Vigencia'].to_i
      end

      return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&movnvo=#{@movnvo}", alert: "Necesita seleccionar un cliente, ya que existe Código Mano en el detalle" if @cliente.to_i == 0 && @codigomano[0]['haycodmano'].to_i > 0
      return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&asignarobra=1&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "Necesita asignar una obra" if @codigomano[0]['haycodmano'].to_i > 0 and @hcarrito[0]['IdObra'].to_i == 0 && @movnvo == "V"
      return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&asignarsuc=1&movnvo=#{@movnvo}&tab=2", alert: "Necesita seleccionar la Sucursal que Surte" if @hcarrito[0]['IdSucursal'].to_i == 0 && @movnvo == "V"
      return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&movnvo=#{@movnvo}&tab=2", alert: "Necesita seleccionar un cliente a la Cotización" if @movnvo == "Z" && @cliente.to_i == 0 
      #return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&movnvo=#{@movnvo}&tab=2", alert: "Necesita indicar los dias de vigencia en Datos Cotización" if @movnvo == "Z" && @vigencia.to_i == 0 

      if @movnvo == "Z" or @movnvo == "B" or @movnvo == "IS"
        sql = "UPDATE #{@nomDbPdv}#{@consec_wp} set UltMovDia = UltMovDia + 1 where Sucursal = #{@sucursal}"
      else
        sql = "UPDATE #{@nomDbPdv}#{@consec_wp} set UltMovDia = UltMovDia + 2 where Sucursal = #{@sucursal}"
      end
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo finalizar el movimiento, error: #{exc.message}"
      end

      #Obtiene el nuevo nummov
      sql = "SELECT UltMovDia, UltObra from #{@nomDbPdv}#{@consec_wp} where Sucursal = #{@sucursal}"
      @ultmov = @dbPdv.connection.select_all(sql)
      if @movnvo == "Z" or @movnvo == "B" or @movnvo == "IS"
        @nummovf = @ultmov[0]['UltMovDia']
      else
        @nummovf = @ultmov[0]['UltMovDia'].to_i - 1
      end

      if @movnvo == "Z"
        sql = "UPDATE #{@nomDbPdv}#{@consec_wp} set UltCotiza = UltCotiza + 1 where Sucursal = #{@sucursal}"
        begin
          @dbPdv.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo finalizar el movimiento, error: #{exc.message}"
        end

        sql = "SELECT UltCotiza from #{@nomDbPdv}#{@consec_wp} where Sucursal = #{@sucursal}"
        @ultmov = @dbPdv.connection.select_all(sql)
        @numcotizaf = @ultmov[0]['UltCotiza']

        sql = "INSERT INTO #{@nomDbPdv}#{@cotiza_wp} "
        sql +="(Sucursal,Idvendedor,Fecha,NumCotiza,Nummov,Tipo_subt,Status,Status2,"
        sql +="Idcliente,Contacto,NotaSup,Vigencia,NotaInf,DatosVend) "
        sql +="SELECT Sucursal,IdVendedor,Fecha,#{@numcotizaf},#{@nummovf},Tipo_subt,'T','T',"
        sql +="Idcliente,Contacto,NotaSup,Vigencia,NotaInf,DatosVend "
        sql +="from #{@nomDbPdv}#{@cotizac_wp} "
        sql +="where  "
        sql +="Sucursal = #{@sucursal} and idvendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
        begin
          @dbPdv.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo finalizar el movimiento, error: #{exc.message}"
        end

        sql = "DELETE from #{@nomDbPdv}#{@cotizac_wp} "
        sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
        begin
          @dbPdv.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo finalizar el movimiento, error: #{exc.message}"
        end
      end

      sql = "INSERT INTO #{@nomDbPdv}#{@hcotiza_wp} "
      sql +="(Sucursal,Fecha,Nummov,Tipo_subt,Status,Status2,"
      sql +="Total,Totvaluado,Idcliente,Idsucursal,Foliointer,Folioinfo,Idvendedor,"
      sql +="IdObra,Subtotfac,Pordescfac,Descfac,Ivafac,Observac,Fechasist) "
      sql +="SELECT Sucursal,Fecha,#{@nummovf},Tipo_subt,'T','T', "
      if @movnvo == "V" or @movnvo == "Z" 
        sql +="Total,Totvaluado,Idcliente,0,Foliointer,Folioinfo,IdVendedor, "
      else
        sql +="Total,Totvaluado,Idcliente,IdSucursal,Foliointer,Folioinfo,IdVendedor, "
      end
      sql +="IdObra,Subtotfac,Pordescfac,Descfac,Ivafac,Observac,Fechasist "
      sql +="from #{@nomDbPdv}#{@hcarrito_wp} "
      sql +="where  "
      sql +="Sucursal = #{@sucursal} and idvendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo finalizar el movimiento, error: #{exc.message}"
      end

      sql = "INSERT INTO #{@nomDbPdv}#{@dcotiza_wp} "
      sql +="(Sucursal,Fecha,Nummov,Idrenglon,Tipo_subt,Status,Status2,"
      sql +="Clave,Cveasoc,Descrip,UMedida,Preciolp,Costolp,Cantidad,Preciofin,Preunifac,"
      sql +="Pordesfac,Totrenfac,Tipodesc) "
      sql +="SELECT Sucursal,Fecha,#{@nummovf},Idrenglon,Tipo_subt,'T','T',"
      sql +="Clave,Cveasoc,Descrip,UMedida,Preciolp,Costolp,Cantidad,Preciofin,Preunifac,"
      sql +="Pordesfac,Totrenfac,Tipodesc "
      sql +="from #{@nomDbPdv}#{@dcarrito_wp} "
      sql +="where  "
      sql +="Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo finalizar el movimiento, error: #{exc.message}"
      end

      @nummovf = @ultmov[0]['UltMovDia']
      if @movnvo == "V"
        sql = "INSERT INTO #{@nomDbPdv}#{@hcotiza_wp} "
        sql +="(Sucursal,Fecha,Nummov,Tipo_subt,Status,Status2,"
        sql +="Total,Totvaluado,Idcliente,Idsucursal,Foliointer,Folioinfo,Idvendedor,"
        sql +="IdObra,Subtotfac,Descfac,Ivafac,Observac,Fechasist) "
        sql +="SELECT Sucursal,Fecha,#{@nummovf},'IE','T','T', "
        sql +="Totvaluado,Totvaluado,0,IdSucursal,Foliointer,'',0, "
        sql +="IdObra,Totvaluado,0,0,Observac,Fechasist "
        sql +="from #{@nomDbPdv}#{@hcarrito_wp} "
        sql +="where  "
        sql +="Sucursal = #{@sucursal} and idvendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
        begin
          @dbPdv.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo finalizar el movimiento, error: #{exc.message}"
        end

        sql = "INSERT INTO #{@nomDbPdv}#{@dcotiza_wp} "
        sql +="(Sucursal,Fecha,Nummov,Idrenglon,Tipo_subt,Status,Status2,"
        sql +="Clave,Cveasoc,Descrip,UMedida,Preciolp,Costolp,Cantidad,Preciofin,Preunifac,"
        sql +="Pordesfac,Totrenfac,Tipodesc) "
        sql +="SELECT Sucursal,Fecha,#{@nummovf},Idrenglon,'IE','T','T',"
        sql +="Clave,Cveasoc,Descrip,UMedida,Preciolp,Costolp,Cantidad,Preciofin,Preciolp,"
        sql +="0,Preciofin,'' "
        sql +="from #{@nomDbPdv}#{@dcarrito_wp} "
        sql +="where  "
        sql +="Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
        begin
          @dbPdv.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo finalizar el movimiento, error: #{exc.message}"
        end
      else
        if @movnvo == "IE"
          sql = "INSERT INTO #{@nomDbPdv}#{@hcotiza_wp} "
          sql +="(Sucursal,Fecha,Nummov,Tipo_subt,Status,Status2,"
          sql +="Total,Totvaluado,Idcliente,Idsucursal,Foliointer,Folioinfo,Idvendedor,"
          sql +="IdObra,Subtotfac,Descfac,Ivafac,Observac,Fechasist) "
          sql +="SELECT Sucursal,Fecha,#{@nummovf},'B','T','T', "
          sql +="Total,Totvaluado,0,0,0,'',0, "
          sql +="IdObra,Subtotfac,0,Ivafac,Observac,Fechasist "
          sql +="from #{@nomDbPdv}#{@hcarrito_wp} "
          sql +="where  "
          sql +="Sucursal = #{@sucursal} and idvendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
          begin
            @dbPdv.connection.execute(sql)
          rescue Exception => exc 
            return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo finalizar el movimiento, error: #{exc.message}"
          end

          sql = "INSERT INTO #{@nomDbPdv}#{@dcotiza_wp} "
          sql +="(Sucursal,Fecha,Nummov,Idrenglon,Tipo_subt,Status,Status2,"
          sql +="Clave,Cveasoc,Descrip,UMedida,Preciolp,Costolp,Cantidad,Preciofin,Preunifac,"
          sql +="Pordesfac,Totrenfac,Tipodesc) "
          sql +="SELECT Sucursal,Fecha,#{@nummovf},Idrenglon,'B','T','T',"
          sql +="Clave,Cveasoc,Descrip,UMedida,Preciolp,Costolp,Cantidad,Preciofin,Preunifac,"
          sql +="0,Totrenfac,'' "
          sql +="from #{@nomDbPdv}#{@dcarrito_wp} "
          sql +="where  "
          sql +="Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
          begin
            @dbPdv.connection.execute(sql)
          rescue Exception => exc 
            return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo finalizar el movimiento, error: #{exc.message}"
          end
        end
      end

      sql = "DELETE from #{@nomDbPdv}#{@hcarrito_wp} "
      sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo finalizar el movimiento, error: #{exc.message}"
      end

      sql = "DELETE from #{@nomDbPdv}#{@dcarrito_wp} "
      sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo finalizar el movimiento, error: #{exc.message}"
      end

      #sql = "INSERT IGNORE INTO #{@nomDbPdv}findia (Sucursal,Fecha) "
      #sql +="SLECT #{@sucursal},CURDATE() + 0"
      #@dbPdv.connection.execute(sql)
      @existePdf = "0"

      return redirect_to "/pdv", notice: "Finalizo Exitosamente"

    end

    if params.has_key?(:pendiente) && params[:pendiente].to_i == 1
      sql = "UPDATE #{@nomDbPdv}#{@hcarrito_wp} set Status2 = 'P' "
      sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo dejar pendiente el movimiento, error: #{exc.message}"
      end

      sql = "UPDATE #{@nomDbPdv}#{@dcarrito_wp} set Status2 = 'P' "
      sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv_selprod?cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo dejar pendiente el movimiento, error: #{exc.message}"
      end

      if @movnvo.to_s == "Z"
        sql = "UPDATE #{@nomDbPdv}#{@cotizac_wp} set Status2 = 'P' "
        sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
        begin
          @dbPdv.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo dejar pendiente el movimiento, error: #{exc.message}"
        end
      end

      redirect_to "/pdv", notice: "Se dejo Pendiente Exitosamente"
    end

    if params.has_key?(:cancelar) && params[:cancelar].to_i == 1
      sql = "DELETE from #{@nomDbPdv}#{@hcarrito_wp} "
      sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo cancelar el movimiento, error: #{exc.message}"
      end

      sql = "DELETE from #{@nomDbPdv}#{@dcarrito_wp} "
      sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo cancelar el movimiento, error: #{exc.message}"
      end

      if @movnvo.to_s == "Z"
        sql = "DELETE from #{@nomDbPdv}#{@cotizac_wp} "
        sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
        begin
          @dbPdv.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se pudo dejar pendiente el movimiento, error: #{exc.message}"
        end
      end

      return redirect_to "/pdv", notice: "Se eliminó la cotización exitosamente"
    end
    @existePdf = "0"
    @numcotiza = 0 if !@numcotiza
    @folio = "#{'%03d' % @sucursal}-#{'%03d' % @vendedor}-#{'%05d' % @numcotiza}-p"
    @existePdf = "1" if File.exist?("public/tmpfiles/#{@folio}.pdf")
#    raise @existePdf.to_s.inspect

    if params.has_key?(:pdf) && params[:pdf].to_i == 1
      return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "Debe seleccionar un Cliente" if @cliente.to_i == 0

      if @hcarrito && @hcarrito.length == 1
        sql = "SELECT * FROM #{@nomDbFacEle}sucfac WHERE sucursal = #{@hcarrito[0]['Sucursal']}"
        @succotiza = @dbPdv.connection.select_all(sql)
        sql = "SELECT * FROM #{@nomDbComun}sucursal WHERE Num_suc = #{@hcarrito[0]['Sucursal']}"
        @catsuc = @dbPdv.connection.select_all(sql)
        sql = "SELECT Nombre,Callenum,NumExt,NumInt,Colonia,Cp,UCASE(Delemuni) as Delemuni,Contacto,UCASE(NomEstado) as NomEstado FROM #{@nomDbPdv}clientes as c inner join #{@nomDbComun}estado as e "
        sql += "ON c.Estado = e.IdEstado "
        sql += "WHERE sucursal = #{@hcarrito[0]['Sucursal']} and Idcliente = #{@cliente}"
        @clicotiza = @dbPdv.connection.select_all(sql)
        sql = "SELECT * FROM #{@nomDbComun}empresa WHERE IdEmpresa = #{@sitio[0].idEmpresa.to_i}"
        @empcotiza = @dbPdv.connection.select_all(sql)
        sql = "SELECT *,Date_format(date(Fecha) + interval Vigencia day,'%d/%m/%Y') as Fechavig FROM #{@nomDbPdv}#{@cotizac_wp} WHERE Sucursal = #{@sucursal} "
        sql +="and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 "
        sql +="and NumCotiza = #{@numcotiza} and Nummov = #{@nummov}"
        @datoscotiza = @dbPdv.connection.select_all(sql)

        @folio = "#{'%03d' % @sucursal}-#{'%03d' % @vendedor}-#{'%05d' % @numcotiza}-p"
#        raise @folio.inspect
        pdf = CotizaPdf.new(@hcarrito[0], @dcarrito, @succotiza[0], @clicotiza[0], @empcotiza[0], @datoscotiza[0], @catsuc[0], @ivatxt, "p")
        pdf.render_file("public/tmpfiles/#{@folio}.pdf")
        redirect_to "/pdv_selprod?vendedor=#{@vendedor}&movnvo=#{@movnvo}&tab=2", notice: "PDF creado correctamente"
#        respond_to do |format|
#          format.html
#          format.pdf do
#            pdf = CotizaPdf.new(@hcarrito[0], @dcarrito, @succotiza[0], @clicotiza[0], @empcotiza[0], @datoscotiza[0], @catsuc[0])
#            send_data pdf.render
#          end
#        end
      else
        redirect_to "/pdv_selprod?vendedor=#{@vendedor}&movnvo=#{@movnvo}&tab=2", alert: "Cotización no encontrada"
      end
    end


  end

  def pdv_selprod_edit
    @vendedor = params[:vendedor] if params.has_key?(:vendedor)
    get_filtros_from_user
    @nummov = params[:nummov] if params.has_key?(:nummov)
    @clave = params[:clave] if params.has_key?(:clave)
    @cliente = params[:cliente] if params.has_key?(:cliente)
    @idrenglon = params[:idrenglon] if params.has_key?(:idrenglon)
    @descrip = params[:descrip] if params.has_key?(:descrip)
    @movnvo = params[:movnvo] if params.has_key?(:movnvo)
    titulomov(@movnvo)
    return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&tab=2&movnvo=#{@movnvo}", alert: "Faltan Parametros" if !@clave or @clave == ""

    sql = "SELECT * FROM #{@nomDbPdv}#{@dcarrito_wp} WHERE Sucursal = #{@sucursal} "
    sql +="and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 "
    sql +="and Nummov = #{@nummov} and IdRenglon = #{@idrenglon} and Clave = '#{@clave}'"
    @prodmod = @dbPdv.connection.select_all(sql)
  end

  def pdv_selprod_update
    @vendedor = params[:vendedor] if params.has_key?(:vendedor)
    get_filtros_from_user
    @nummov = params[:nummov] if params.has_key?(:nummov)
    @idrenglon = params[:idrenglon] if params.has_key?(:idrenglon)
    @clave = params[:clave] if params.has_key?(:clave)
    @descrip = params[:descrip] if params.has_key?(:descrip)
    @umedida = params[:umedida] if params.has_key?(:umedida)
    @cantidad = params[:cantidad] if params.has_key?(:cantidad)
    @pordesfac = params[:pordesfac] if params.has_key?(:pordesfac)
    @preunifac = params[:preunifac] if params.has_key?(:pordesfac)
    @movnvo = params[:movnvo] if params.has_key?(:movnvo)
    titulomov(@movnvo)
#raise @pordesfac.inspect
    return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&tab=2&movnvo=#{@movnvo}", alert: "Faltan Parametros Clave" if !@clave or @clave == ""
#    return redirect_to "/pdv_selprod_edit?nummov=#{@nummov}&idrenglon=#{@idrenglon}", alert: "Ingresa Renglon válido" if @idrenglon.to_i <= 0
    sql = "UPDATE #{@nomDbPdv}#{@dcarrito_wp} set Descrip = '#{@descrip}', UMedida = '#{@umedida}',"
    sql +="Cantidad = #{@cantidad},"
    if @cliente.to_i == 0
      sql +="Preunifac = if(#{@preunifac} != Preunifac,#{@preunifac},Preunifac), "
    else
      sql +="Preunifac = if(#{@preunifac} != Preunifac,round(#{@preunifac}/#{@iva},2),Preunifac), "
    end
    sql +="Pordesfac = #{@pordesfac} "
    sql +="WHERE Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 "
    sql +="and Nummov = #{@nummov} and IdRenglon = #{@idrenglon} and Clave = '#{@clave}'"
#    raise sql.inspect
    begin
      @dbPdv.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&tab=2&movnvo=#{@movnvo}", alert: "No se han podido guardar los datos, error: #{exc.message}"
    end
#    descuentos_en_detalle()
    sql = "SELECT count(*) as TotDescCero from #{@nomDbPdv}#{@dcarrito_wp} "
    sql +="WHERE Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 "
    sql +="and Nummov = #{@nummov} and Pordesfac != 0"
    @desccero = @dbPdv.connection.select_all(sql)

    if @desccero[0]['TotDescCero'].to_i > 0

      sql = "SELECT PorDescFac from #{@nomDbPdv}#{@hcarrito_wp} "
      sql +="WHERE Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 "
      sql +="and Nummov = #{@nummov}"
      @descglob = @dbPdv.connection.select_all(sql)
      @descaplic = @descglob[0]['PorDescFac'].to_f

      sql = "UPDATE #{@nomDbPdv}#{@dcarrito_wp} set "
      sql +="Pordesfac = #{@descaplic} "
      sql +="WHERE Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 "
      sql +="and Nummov = #{@nummov} and Pordesfac = 0"
  #    raise sql.inspect
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&tab=2&movnvo=#{@movnvo}", alert: "No se han podido guardar los datos, error: #{exc.message}"
      end

      sql = "UPDATE #{@nomDbPdv}#{@hcarrito_wp} set "
      sql +="PorDescFac = 0, "
      sql +="DescFac = 0 "
      sql +="WHERE Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 "
      sql +="and Nummov = #{@nummov}"
  #    raise sql.inspect
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&tab=2&movnvo=#{@movnvo}", alert: "No se han podido guardar los datos, error: #{exc.message}"
      end
    end
#raise @titulomov.inspect
    redirect_to "/pdv_selprod?vendedor=#{@vendedor}&recalcular=1&tab=2&movnvo=#{@movnvo}", notice: "Datos guardados exitosamente"
  end

  def pdv_selprod_destroy
    @vendedor = params[:vendedor] if params.has_key?(:vendedor)
    get_filtros_from_user
    @nummov = params[:nummov] if params.has_key?(:nummov)
    @clave = params[:clave] if params.has_key?(:clave)
    @cliente = params[:cliente] if params.has_key?(:cliente)
    @idrenglon = params[:idrenglon] if params.has_key?(:idrenglon)
    @descrip = params[:descrip] if params.has_key?(:descrip)
    @movnvo = params[:movnvo] if params.has_key?(:movnvo)
    titulomov(@movnvo)

    return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&#{@lfiltro}=#{@filtro}", alert: "Faltan parametros" if !@sucursal or @sucursal == ""

    sql = "DELETE FROM #{@nomDbPdv}#{@dcarrito_wp} WHERE Sucursal = #{@sucursal} "
    sql +="and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov} "
    sql +="and Idrenglon = #{@idrenglon} and Clave = '#{@clave}'"
    begin
      @dbPdv.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&#{@lfiltro}=#{@filtro}&tab=2", alert: "No se ha podido borrar el producto, error: #{exc.message}"
    end

    #Recorre los renglones por el renglon eliminado
    sql = "SELECT * FROM #{@nomDbPdv}#{@dcarrito_wp} "
    sql +="WHERE Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 "
    sql +="and Nummov = #{@nummov} and Idrenglon > #{@idrenglon}"
    @recorreren = @dbPdv.connection.select_all(sql)
    @recorreren.each do |s| 
      sql = "UPDATE #{@nomDbPdv}#{@dcarrito_wp} Set IdRenglon = IdRenglon - 1 "
      sql +="WHERE Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} "
      sql +="and Fecha = CURDATE() + 0 and Nummov = #{@nummov} and Idrenglon = #{s['Idrenglon']}"
      @dbPdv.connection.execute(sql)
    end

    redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&recalcular=1&#{@lfiltro}=#{@filtro}&tab=2", notice: "Producto ( #{@descrip} ) eliminado exitosamente"
  end

  def pdv_desc_global_edit
    @vendedor = params[:vendedor] if params.has_key?(:vendedor)
    get_filtros_from_user
    @nummov = params[:nummov] if params.has_key?(:nummov)
    @cliente = params[:cliente] if params.has_key?(:cliente)
    @descuento = params[:descuento] if params.has_key?(:descuento)
    @descuentopesos = params[:descuentopesos] if params.has_key?(:descuentopesos)
    @prodcondesc = params[:prodcondesc] if params.has_key?(:prodcondesc)
    @prodsindesc = params[:prodsindesc] if params.has_key?(:prodsindesc)
    @seltipodesc = params[:seltipodesc] if params.has_key?(:seltipodesc)
    @movnvo = params[:movnvo] if params.has_key?(:movnvo)
    titulomov(@movnvo)
  end

  def pdv_desc_global_update
    @vendedor = params[:vendedor] if params.has_key?(:vendedor)
    get_filtros_from_user
    @nummov = params[:nummov] if params.has_key?(:nummov)
    @cliente = params[:cliente] if params.has_key?(:cliente)
    @descuento = params[:descuento] if params.has_key?(:descuento)
    @descuentopesos = params[:descuentopesos] if params.has_key?(:descuentopesos)
    @prodcondesc = params[:prodcondesc] if params.has_key?(:prodcondesc)
    @prodsindesc = params[:prodsindesc] if params.has_key?(:prodsindesc)
    @seltipodesc = params[:seltipodesc] if params.has_key?(:seltipodesc)
    @movnvo = params[:movnvo] if params.has_key?(:movnvo)
    titulomov(@movnvo)
#    return redirect_to "/pdv_selprod?tab=2", alert: "Faltan Parametros" if !@clave or @clave == ""
#raise  @descuentopesos.to_f.inspect    

    if params[:descglobal].to_i == 1 #Cancelar Parciales
      elimina_desc_detalle()

      if @seltipodesc.to_i == 1 #descuento en porcentaje
        #Se calcula el descuento en $ a partir del porcentaje
        sql = "SELECT sum(Cantidad * Preunifac) as Subtotfac "
        sql +="from #{@nomDbPdv}#{@dcarrito_wp} "
        sql +="where "
        sql +="Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} "
        sql +="and Fecha = CURDATE() + 0 and Nummov = #{@nummov}"
        @subtot = @dbPdv.connection.select_all(sql)

        @descuentopesos = ((@descuento.to_f * @subtot[0]['Subtotfac'].to_f) / 100).round(2)
      end
      actualiza_desc_global(@descuento,@descuentopesos)
    else 
      if params[:descglobal].to_i == 2 #Aplicar a Productos sin Descuento
        sql = "UPDATE #{@nomDbPdv}#{@dcarrito_wp} "
        sql +="set Pordesfac = #{@descuento} "
        sql +="WHERE Sucursal = #{@sucursal} "
        sql +="and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Nummov = #{@nummov} "
        sql +="and Pordesfac = 0"
        begin
          @dbPdv.connection.execute(sql)
        rescue Exception => exc 
          return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&tab=2", alert: "No se ha podido aplicar descuento global, error: #{exc.message}"
        end
      end
    end

    redirect_to "/pdv_selprod?vendedor=#{@vendedor}&cliente=#{@cliente}&movnvo=#{@movnvo}&recalcular=1&tab=2", notice: "Descuento Global aplicado exitosamente"
  end

  def pdv_cotiza_edit
    @vendedor = params[:vendedor] if params.has_key?(:vendedor)
    get_filtros_from_user
    @numcotiza = params[:numcotiza] if params.has_key?(:numcotiza)
    @nummov = params[:nummov] if params.has_key?(:nummov)
    @movnvo = params[:movnvo] if params.has_key?(:movnvo)
    titulomov(@movnvo)
#    raise @numcotiza.inspect
    return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&tab=2&movnvo=#{@movnvo}", alert: "Faltan Parametros" if !@numcotiza or @numcotiza.to_i == 0

    sql = "SELECT * FROM #{@nomDbPdv}#{@cotizac_wp} WHERE Sucursal = #{@sucursal} "
    sql +="and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 "
    sql +="and NumCotiza = #{@numcotiza} and Nummov = #{@nummov}"
    @cotizamod = @dbPdv.connection.select_all(sql)
  end

  def pdv_cotiza_update
    @vendedor = params[:vendedor] if params.has_key?(:vendedor)
    get_filtros_from_user
    @numcotiza = params[:numcotiza] if params.has_key?(:numcotiza)
    @nummov = params[:nummov] if params.has_key?(:nummov)
    @contacto = params[:contacto] if params.has_key?(:contacto)
    @notasup = params[:notasup] if params.has_key?(:notasup)
    @vigencia = params[:vigencia] if params.has_key?(:vigencia)
    @notainf = params[:notainf] if params.has_key?(:notainf)
    @datosvend = params[:datosvend] if params.has_key?(:datosvend)
    @movnvo = params[:movnvo] if params.has_key?(:movnvo)
    titulomov(@movnvo)

    return redirect_to "/pdv_selprod?tab=2&movnvo=#{@movnvo}", alert: "Faltan Parametros Clave" if !@numcotiza or @numcotiza.to_i == 0
    return redirect_to "/pdv_cotiza_edit?numcotiza=#{@numcotiza}&nummov=#{@nummov}&movnvo=#{@movnvo}", alert: "Contacto tiene #{@contacto.length.to_s} caracteres y solo permite 100" if @contacto.length > 100

    sql = "UPDATE #{@nomDbPdv}#{@cotizac_wp} set Contacto = '#{@contacto}',NotaSup = '#{@notasup}',"
    sql +="Vigencia = '#{@vigencia}', NotaInf = '#{@notainf}', DatosVend = '#{@datosvend}' "
    sql +="WHERE Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 "
    sql +="and NumCotiza = #{@numcotiza} and Nummov = #{@nummov}"
#    raise sql.inspect
    begin
      @dbPdv.connection.execute(sql)
    rescue Exception => exc 
      return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&tab=2&movnvo=#{@movnvo}", alert: "No se han podido guardar los datos, error: #{exc.message}"
    end

    redirect_to "/pdv_selprod?vendedor=#{@vendedor}&movnvo=#{@movnvo}&tab=2", notice: "Datos guardados exitosamente"
  end

  def pdv_cotiza_terminada
    @vendedor = params[:vendedor] if params.has_key?(:vendedor)
    get_filtros_from_user
    @filtro = params[:filtro] if params.has_key?(:filtro)
    @fechamov = params[:fechamov] if params.has_key?(:fechamov)
    @nummov = params[:nummov] if params.has_key?(:nummov)
    @nomfiltro = params[:nomfiltro] if params.has_key?(:nomfiltro)
    @movnvo = "Z"

    sql = "SELECT Sucursal,IdVendedor,Fecha,Nummov,Tipo_subt,Status,Status2,Total,Totvaluado,Idcliente,IdSucursal, "
    sql +="Controlfac,Foliointer,Folioinfo,IdObra,Subtotfac,Pordescfac,Descfac,Ivafac,Observac "
    sql +="from #{@nomDbPdv}#{@hcotiza_wp} "
    sql +="where  Sucursal = #{@sucursal} and Fecha = #{@fechamov} and Nummov = #{@nummov}"
#raise sql.inspect
    @hcarrito = @dbPdv.connection.select_all(sql)

    sql = "SELECT Sucursal,Fecha,Nummov,Idrenglon,Tipo_subt,Status,Status2,Clave,Cveasoc,Descrip, "
    sql +="UMedida,Preciolp,Costolp,Cantidad,Preciofin,Preunifac,Pordesfac,(round((Preunifac * Pordesfac)/100,2) * Cantidad) * -1 as PordesfacP,Totrenfac,Tipodesc "
    sql +="from #{@nomDbPdv}#{@dcotiza_wp} "
    sql +="where  Sucursal = #{@sucursal} and Fecha = #{@fechamov} and Nummov = #{@nummov}"
    @dcarrito = @dbPdv.connection.select_all(sql)

    @tipo_subt = @hcarrito[0]['Tipo_subt']
    if @tipo_subt == "Z$"
      @tipoventa = "1" #Contado
      @titulotipoventa = "Cotización de Contado"
    else
      @tipoventa = "2" #Crédito
      @titulotipoventa = "Cotización de Crédito"  
    end


    sql = "SELECT NumCotiza from #{@nomDbPdv}#{@cotiza_wp} where Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = #{@fechamov} and Nummov = #{@nummov}"
    @numcotizaexist = @dbPdv.connection.select_all(sql)
    @numcotiza = @numcotizaexist[0]['NumCotiza'] if @numcotizaexist.count > 0

    sql = "SELECT Num_suc,Nombre FROM #{@nomDbComun}sucursal where Num_suc = #{@sucursal}"
    @nomidsucexist = @dbPdv.connection.select_all(sql)
    @idsuctitulo = 0
    @idsuctitulo = @nomidsucexist[0]['Num_suc']
    @nomidsuctitulo = @nomidsucexist[0]['Nombre']


    @cliente = @hcarrito[0]['Idcliente']
    sql = "SELECT Nombre, Rfc from #{@nomDbPdv}#{@clientes_wp} "
    sql +="WHERE Sucursal = #{@sucursal} and IdCliente = #{@cliente}"
    @clientes = @dbPdv.connection.select_all(sql)
    @nomcli = @clientes[0]['Nombre']
    @rfc = @clientes[0]['Rfc']


    if params.has_key?(:exportar) && params[:exportar].to_i == 1

      sql = "UPDATE #{@nomDbPdv}#{@hcarrito_wp} set Status2 = 'P' "
      sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Tipo_subt like 'Z%' and Status2 = '?'"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv?vendedor=<%=@vendedor%>&filtro=<%=@filtro%>", alert: "No se pudo exportar la cotización, error: #{exc.message}"
      end

      sql = "UPDATE #{@nomDbPdv}#{@dcarrito_wp} set Status2 = 'P' "
      sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Tipo_subt like 'Z%' and Status2 = '?'"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv?vendedor=<%=@vendedor%>&filtro=<%=@filtro%>", alert: "No se pudo exportar la cotización, error: #{exc.message}"
      end

      sql = "UPDATE #{@nomDbPdv}#{@cotizac_wp} set Status2 = 'P' "
      sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 and Tipo_subt like 'Z%' and Status2 = '?'"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv?vendedor=<%=@vendedor%>&filtro=<%=@filtro%>", alert: "No se pudo exportar la cotización, error: #{exc.message}"
      end

      #Suma un movimiento al dia
      sql = "UPDATE #{@nomDbPdv}#{@consec_wp} set UltMovDiaC = UltMovDiaC + 1,UltCotizaC = UltCotizaC + 1 where Sucursal = #{@sucursal}"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv?vendedor=<%=@vendedor%>&filtro=<%=@filtro%>", alert: "No se pudo exportar la cotización, error: #{exc.message}"
      end

      #Obtiene el nuevo nummov
      sql = "SELECT UltMovDiaC,UltCotizaC from #{@nomDbPdv}#{@consec_wp} where Sucursal = #{@sucursal}"
      @ultmov = @dbPdv.connection.select_all(sql)
      @nummovf = @ultmov[0]['UltMovDiaC']
      @numcotizaf = @ultmov[0]['UltCotizaC']

      sql = "INSERT INTO #{@nomDbPdv}#{@cotizac_wp} "
      sql +="(Sucursal,IdVendedor,Fecha,NumCotiza,Nummov,Tipo_subt,Status,Status2,"
      sql +="Idcliente,Contacto,NotaSup,Vigencia,NotaInf,DatosVend) "
      sql +="SELECT Sucursal,IdVendedor,CURDATE() + 0,#{@numcotizaf},#{@nummovf},Tipo_subt,'T','?',"
      sql +="Idcliente,Contacto,NotaSup,Vigencia,NotaInf,DatosVend "
      sql +="from #{@nomDbPdv}#{@cotiza_wp} "
      sql +="where  "
      sql +="Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = '#{@fechamov}' and Nummov = #{@nummov}"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv?vendedor=<%=@vendedor%>&filtro=<%=@filtro%>", alert: "No se pudo exportar la cotización, error: #{exc.message}"
      end
#raise sql.inspect

      sql = "INSERT INTO #{@nomDbPdv}#{@hcarrito_wp} "
      sql +="(Sucursal,Idvendedor,Fecha,Nummov,Tipo_subt,Status,Status2,"
      sql +="Total,Totvaluado,Idcliente,Idsucursal,Foliointer,Folioinfo,"
      sql +="IdObra,Subtotfac,Pordescfac,Descfac,Ivafac,Observac,Fechasist) "
      sql +="SELECT Sucursal,Idvendedor,CURDATE() + 0,#{@nummovf},Tipo_subt,'T','?', "
      sql +="Total,Totvaluado,Idcliente,0,Foliointer,Folioinfo, "
      sql +="IdObra,Subtotfac,0,0,Ivafac,Observac,Fechasist "
      sql +="from #{@nomDbPdv}#{@hcotiza_wp} "
      sql +="where  "
      sql +="Sucursal = #{@sucursal} and Fecha = '#{@fechamov}' and Nummov = #{@nummov}"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv?vendedor=<%=@vendedor%>&filtro=<%=@filtro%>", alert: "No se pudo exportar la cotización, error: #{exc.message}"
      end

      sql = "INSERT INTO #{@nomDbPdv}#{@dcarrito_wp} "
      sql +="(Sucursal,IdVendedor,Fecha,Nummov,Idrenglon,Tipo_subt,Status,Status2,"
      sql +="Clave,Cveasoc,Descrip,UMedida,Preciolp,Costolp,Cantidad,Preciofin,Preunifac,"
      sql +="Pordesfac,Totrenfac,Tipodesc) "
      sql +="SELECT Sucursal,#{@vendedor},CURDATE() + 0,#{@nummovf},Idrenglon,Tipo_subt,'T','?',"
      sql +="Clave,Cveasoc,Descrip,UMedida,Preciolp,Costolp,Cantidad,Preciofin,Preunifac,"
      sql +="0,Totrenfac,Tipodesc "
      sql +="from #{@nomDbPdv}#{@dcotiza_wp} "
      sql +="where  "
      sql +="Sucursal = #{@sucursal} and Fecha = '#{@fechamov}' and Nummov = #{@nummov}"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv?vendedor=<%=@vendedor%>&filtro=<%=@filtro%>", alert: "No se pudo exportar la cotización, error: #{exc.message}"
      end

      return redirect_to "/pdv_selprod?vendedor=#{@vendedor}&movnvo=#{@movnvo}&recalcular=1&tab=2", notice: "Se Exporto Exitosamente"

    end

    if params.has_key?(:cancelar) && params[:cancelar].to_i == 1
      sql = "UPDATE #{@nomDbPdv}#{@hcotiza_wp} set Status2 = 'C' "
      sql +="where  Sucursal = #{@sucursal} and Fecha = #{@fechamov} and Nummov = #{@nummov}"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv_cotiza_terminada?vendedor=<%=@vendedor%>&fechamov=<%=@fechamov%>&nummov=<%=@nummov%>&filtro=<%=@filtro%>&nomfiltro=<%=@nomfiltro%>", alert: "No se pudo cancelar la cotización, error: #{exc.message}"
      end

      sql = "UPDATE #{@nomDbPdv}#{@dcotiza_wp} set Status2 = 'C' "
      sql +="where  Sucursal = #{@sucursal} and Fecha = #{@fechamov} and Nummov = #{@nummov}"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv_cotiza_terminada?vendedor=<%=@vendedor%>&fechamov=<%=@fechamov%>&nummov=<%=@nummov%>&filtro=<%=@filtro%>&nomfiltro=<%=@nomfiltro%>", alert: "No se pudo cancelar la cotización, error: #{exc.message}"
      end

      sql = "UPDATE #{@nomDbPdv}#{@cotiza_wp} set Status2 = 'C' "
      sql +="where  Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = #{@fechamov} and Nummov = #{@nummov}"
      begin
        @dbPdv.connection.execute(sql)
      rescue Exception => exc 
        return redirect_to "/pdv_cotiza_terminada?vendedor=<%=@vendedor%>&fechamov=<%=@fechamov%>&nummov=<%=@nummov%>&filtro=<%=@filtro%>&nomfiltro=<%=@nomfiltro%>", alert: "No se pudo cancelar la cotización, error: #{exc.message}"
      end

      return redirect_to "/pdv?vendedor=#{@vendedor}&filtro=#{@filtro}", notice: "Se Cancelo Exitosamente"

    end

    @existePdf = "0"
    @numcotiza = 0 if !@numcotiza
    @folio = "#{'%03d' % @sucursal}-#{'%03d' % @vendedor}-#{'%05d' % @numcotiza}"
    @existePdf = "1" if File.exist?("public/tmpfiles/#{@folio}.pdf")
#    raise @existePdf.to_s.inspect

    if params.has_key?(:pdf) && params[:pdf].to_i == 1
      if @hcarrito && @hcarrito.length == 1
        sql = "SELECT * FROM #{@nomDbFacEle}sucfac WHERE sucursal = #{@hcarrito[0]['Sucursal']}"
        @succotiza = @dbPdv.connection.select_all(sql)
        sql = "SELECT * FROM #{@nomDbComun}sucursal WHERE Num_suc = #{@hcarrito[0]['Sucursal']}"
        @catsuc = @dbPdv.connection.select_all(sql)
        sql = "SELECT Nombre,Callenum,NumExt,NumInt,Colonia,Cp,UCASE(Delemuni) as Delemuni,Contacto,UCASE(NomEstado) as NomEstado FROM #{@nomDbPdv}clientes as c inner join #{@nomDbComun}estado as e "
        sql += "ON c.Estado = e.IdEstado "
        sql += "WHERE sucursal = #{@hcarrito[0]['Sucursal']} and Idcliente = #{@cliente}"
        @clicotiza = @dbPdv.connection.select_all(sql)
        sql = "SELECT * FROM #{@nomDbComun}empresa WHERE IdEmpresa = #{@sitio[0].idEmpresa.to_i}"
        @empcotiza = @dbPdv.connection.select_all(sql)
        sql = "SELECT * FROM #{@nomDbPdv}#{@cotiza_wp} WHERE Sucursal = #{@sucursal} "
        sql +="and IdVendedor = #{@vendedor} and Fecha = #{@fechamov} "
        sql +="and NumCotiza = #{@numcotiza} and Nummov = #{@nummov}"
        @datoscotiza = @dbPdv.connection.select_all(sql)

        @folio = "#{'%03d' % @sucursal}-#{'%03d' % @vendedor}-#{'%05d' % @numcotiza}"
#        raise @folio.inspect
        pdf = CotizaPdf.new(@hcarrito[0], @dcarrito, @succotiza[0], @clicotiza[0], @empcotiza[0], @datoscotiza[0], @catsuc[0], @ivatxt, "t")
        pdf.render_file("public/tmpfiles/#{@folio}.pdf")
        redirect_to "/pdv_cotiza_terminada?vendedor=#{@vendedor}&fechamov=#{@fechamov}&nummov=#{@nummov}&movnvo=#{@movnvo}", notice: "PDF creado correctamente"
#        respond_to do |format|
#          format.html
#          format.pdf do
#            pdf = CotizaPdf.new(@hcarrito[0], @dcarrito, @succotiza[0], @clicotiza[0], @empcotiza[0], @datoscotiza[0], @catsuc[0])
#            send_data pdf.render
#          end
#        end
      else
        redirect_to "/pdv", alert: "Cotización no encontrada"
      end
    end

  end

  def pdv_cotiza_pdf
#    if ( params.has_key?(:numcotiza) && params[:numcotiza].length > 0 && params.has_key?(:nummov) && params[:nummov].length > 0 && params.has_key?(:status) && params[:status].length > 0 )
    if ( params.has_key?(:nummov) && params[:nummov].length > 0 && params.has_key?(:status) && params[:status].length > 0 )

      get_filtros_from_user
      @numcotiza = params[:numcotiza] if params.has_key?(:numcotiza)
      @nummov = params[:nummov] if params.has_key?(:nummov)
      @status = params[:status] if params.has_key?(:status)

#      sql = "SELECT * FROM #{@nomDbPdv}hcotiza "
      sql = "SELECT * FROM #{@nomDbPdv}#{@hcarrito_wp} "
      sql +="WHERE Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Fecha = CURDATE() + 0 "
      sql +="and Nummov = #{@nummov}"
      @hcotiza = @dbPdv.connection.select_all(sql)
      if @hcotiza && @hcotiza.length == 1
        respond_to do |format|
          format.html
          format.pdf do
            # Se deben obtener los detalles de los productos para el PDF
#            sql = "SELECT * FROM #{@nomDbPdv}dcotiza WHERE Sucursal = #{@hcotiza[0]['Sucursal']} and Fecha =  #{@hcotiza[0]['Fecha']} and NumMov = #{@hcotiza[0]['NumMov']} and status2 = 'T'"
            sql = "SELECT * FROM #{@nomDbPdv}#{@dcarrito_wp} WHERE Sucursal = #{@hcotiza[0]['Sucursal']} and Fecha =  #{@hcotiza[0]['Fecha']} and NumMov = #{@hcotiza[0]['NumMov']}"
            @dcotiza = @dbPdv.connection.select_all(sql)
            sql = "SELECT * FROM #{@nomDbFacEle}sucfac WHERE sucursal = #{@hcotiza[0]['Sucursal']}"
            @succotiza = @dbPdv.connection.select_all(sql)
            sql = "SELECT * FROM #{@nomDbPdv}clientes WHERE sucursal = #{@hcotiza[0]['Sucursal']} and cliente = #{@hcotiza[0]['IdCliente']}"
            @clicotiza = @dbPdv.connection.select_all(sql)
            sql = "SELECT * FROM #{@nomDbComun}empresa WHERE IdEmpresa = #{@sitio[0].idEmpresa.to_i}"
            @empcotiza = @dbPdv.connection.select_all(sql)

            pdf = CotizaPdf.new(@hcotiza[0], @dcotiza, @succotiza[0], @clicotiza[0], @empcotiza[0])
            send_data pdf.render
          end
        end
      else
        redirect_to "/pdv_selprod?vendedor=#{@vendedor}&movnvo=#{@movnvo}&tab=2", notice: "Cotización no encontrada"
      end
    else
      redirect_to "/pdv?vendedor=#{@vendedor}&movnvo=#{@movnvo}&tab=2", notice: "Cotización no encontrada"
    end

  end

  def pdv_pendientes
    @vendedor = params[:vendedor] if params.has_key?(:vendedor)
    get_filtros_from_user

    sql = "SELECT * "
    sql +="from #{@nomDbPdv}#{@hcarrito_wp} "
    sql +="where "
    sql +="Sucursal = #{@sucursal} "
    sql +="and IdVendedor = #{@vendedor} " if @soloelvendedor == 1
    sql +="and Fecha = CURDATE() + 0 and Status2 = 'P'"
    @hcarritopend = @dbPdv.connection.select_all(sql)

    @nummov = 0
    @nummov = @hcarritopend[0]['Nummov'] if @hcarritopend.count > 0
    @nummov = params[:nummov] if params.has_key?(:nummov)

    @movnvo = @hcarritopend[0]['Tipo_subt'] if @hcarritopend.count > 0
    @movnvo = "V" if @hcarritopend.count > 0 && @movnvo[0] == "V"
    @movnvo = "Z" if @hcarritopend.count > 0 && @movnvo[0] == "Z"
    titulomov(@movnvo) if @hcarritopend.count > 0

    sql = "SELECT * "
    sql +="from #{@nomDbPdv}#{@dcarrito_wp} "
    sql +="where "
#    sql +="Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} and Nummov = #{@nummov} "
    sql +="Sucursal = #{@sucursal} and Nummov = #{@nummov} "
    sql +="and Fecha = CURDATE() + 0 and Status2 = 'P'"
    @dcarritopend = @dbPdv.connection.select_all(sql)
  end

  private 

  def get_filtros_from_user
    @permiso = Permiso.joins("LEFT JOIN cat_roles ON permisos.permiso = cat_roles.nomPermiso").where("idUsuario = #{current_user.id} AND p1 = #{@sitio[0].idEmpresa.to_i}").order("cat_roles.nivel").limit(1)
    if @permiso && @permiso.count == 1
      @zona = 0
      @sucursal = 0
      @soloelvendedor = 0
#      @vendedor = params[:vendedor] if params.has_key?(:vendedor)
      @sistemawp = 1
      if @permiso[0].p2 != "" && @permiso[0].p2 != "0"
        @zona = @permiso[0].p2.to_i
      end
      if @permiso[0].p3 != "" && @permiso[0].p3 != "0"
        p3 = @permiso[0].p3.to_s.split(',').map{|i| i.to_i}
        @sucursal = p3[0].to_i
        @sucinter = p3[1].to_i
      end

      if @permiso[0].p4 != "" && @permiso[0].p4 != "0"
        p4 = @permiso[0].p4.to_s.split(',').map{|i| i.to_i}
        @vendedor = p4[0].to_s  if !@vendedor && p4[0].to_i != 0
        @soloelvendedor = 1  if p4[0].to_i != 0
        @sistemawp = p4[1].to_i
      end

      if @sucursal.to_i == 0
        @sucursal = 175 
        @sistemawp = 1
      end

      sql = "SELECT Nombre,Codigo,StockCero,ZonaAsig FROM #{@nomDbComun}sucursal where Num_suc = #{@sucursal}"
      sucs = @dbPdv.connection.select_all(sql)
      @nomsuc = sucs[0]['Nombre'].to_s rescue ""
      @codigosuc = sucs[0]['Codigo'].to_s rescue 0
#      @stockcero = sucs[0]['StockCero'].to_s
      @stockcero = "1"
      @zona = sucs[0]['ZonaAsig'].to_s rescue ''
      @filtro = "VIG"

      if @sistemawp.to_i == 0
        @clientes_wp = "clientes"
        @findia_wp = "findia"
        @obras_wp = "obras"
        @consec_wp = "consec"
        @hcarrito_wp = "hcarrito"
        @dcarrito_wp = "dcarrito"
        @cotiza_wp = "cotiza"
        @cotizac_wp = "cotizac"
        @hcotiza_wp = "hcotiza"
        @dcotiza_wp = "dcotiza"
        @dcredito_wp = "dcredito"
      else
        @clientes_wp = "wpclientes"
        @findia_wp = "wpfindia"
        @obras_wp = "wpobras"
        @consec_wp = "wpconsec"
        @hcarrito_wp = "wphcarrito"
        @dcarrito_wp = "wpdcarrito"
        @cotiza_wp = "wpcotiza"
        @cotizac_wp = "wpcotizac"
        @hcotiza_wp = "wphcotiza"
        @dcotiza_wp = "wpdcotiza"
        @dcredito_wp = "wpdcredito"
      end

      if @zona.to_i == 0 or @sucursal.to_i == 0 or @sistema.to_i < 0 or @sistema.to_i > 1
        return redirect_to "/", alert: "No autorizado"
      end

      sql = "SELECT Iva from #{@nomDbComun}iva inner join #{@nomDbComun}sucursal "
      sql +="ON Zona = Zonaasig "
      sql +="WHERE Num_suc = #{@sucursal} and FechaFac <= CURDATE() + 0 "
      sql +="ORDER BY FechaFac DESC Limit 1"
      @ivazona = @dbPdv.connection.select_all(sql)
      @iva = (@ivazona[0]['Iva'].to_i + 100).to_f / 100
      @ivatxt = @ivazona[0]['Iva'].to_i

      @nomvendedor = "Sin Vendedor"
#      raise @vendedor.inspect
      if @vendedor && @vendedor.to_i > 0
        sql = "SELECT IdVend,Nombre FROM #{@nomDbPdv}vendedor where IdVend = '#{@vendedor}'" 
        vendedores = @dbPdv.connection.select_all(sql)
        @nomvendedor = vendedores[0]['Nombre'].to_s if vendedores.count > 0
        return redirect_to "/", alert: "Vendedor invalido, no autorizado" if vendedores.count == 0
      end

    else
      return redirect_to "/", alert: "No autorizado"
    end
  end

  def titulomov(movnvo)
    case movnvo.to_s
    when "V"  
      @titulomov="Venta Nueva"
    when "Z" 
      @titulomov="Cotización Nueva"
    when "IE" 
      @titulomov="Intercambio de Entrada Nuevo"
    when "IS" 
      @titulomov="Intercambio de Salida Nuevo"
    when "B" 
      @titulomov="Baja de Mercancía Nueva"
    when "ZV" 
      @titulomov="Cotizaciones Vigentes"
    when "Zv" 
      @titulomov="Cotizaciones Venciadas"
    when "ZF" 
      @titulomov="Cotizaciones Facturadas"
    when "Zf" 
      @titulomov="Cotizaciones Canceladas"
    end
  end

  def descuentos_en_detalle()
    sql = "SELECT count(*) as TotConDesc from #{@nomDbPdv}#{@dcarrito_wp} "
    sql +="where "
    sql +="Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} "
    sql +="and Fecha = CURDATE() + 0 and Nummov = #{@nummov} and Pordesfac > 0"
    @condesc = @dbPdv.connection.select_all(sql)
    @prodcondesc = @condesc[0]['TotConDesc'].to_i

    sql = "SELECT count(*) as TotSinDesc from #{@nomDbPdv}#{@dcarrito_wp} "
    sql +="where "
    sql +="Sucursal = #{@sucursal} and IdVendedor = #{@vendedor} "
    sql +="and Fecha = CURDATE() + 0 and Nummov = #{@nummov} and Pordesfac = 0"
    @sindesc = @dbPdv.connection.select_all(sql)
    @prodsindesc = @sindesc[0]['TotSinDesc'].to_i
  end

  def elimina_desc_detalle()
    sql = "UPDATE #{@nomDbPdv}#{@dcarrito_wp} "
    sql +="Set "
    sql +="Pordesfac = 0 "
    sql +="where "
    sql +="Sucursal = #{@sucursal} "
    sql +="and IdVendedor = #{@vendedor} "
    sql +="and Fecha = CURDATE() + 0 "
    sql +="and Nummov = #{@nummov} "
#      raise sql.inspect
    @dbPdv.connection.execute(sql)
  end

  def actualiza_desc_global(descuento,descuentopesos)
    sql = "UPDATE #{@nomDbPdv}#{@hcarrito_wp} "
    sql +="Set "
    sql +="PorDescfac = #{descuento.to_f}, "
    sql +="Descfac = #{descuentopesos.to_f} "
    sql +="where "
    sql +="Sucursal = #{@sucursal} "
    sql +="and IdVendedor = #{@vendedor} "
    sql +="and Fecha = CURDATE() + 0 "
    sql +="and Nummov = #{@nummov} "
#      raise sql.inspect
    @dbPdv.connection.execute(sql)
#    begin
#      @dbPdv.connection.execute(sql)
#    rescue Exception => exc 
#      return redirect_to "/pdv_selprod?cliente=#{@cliente}&tab=2", alert: "No se pudo Actualizar descuento global, error: #{exc.message}"
#    end
  end

end
