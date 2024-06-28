#!/bin/env ruby
# encoding: utf-8
class EstaventasController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app

  include ActionView::Helpers::NumberHelper

  def estaventas
    @continua = 0
    @agrupaval = params[:agrupa].to_s if params.has_key?(:agrupa)
    @subagrupaval = params[:subagrupa].to_s if params.has_key?(:subagrupa)
    @sucursalval = params[:agrupasuc].to_s if params.has_key?(:agrupasuc)
    estadisticat = params[:estadisticat].to_i if params.has_key?(:estadisticat)
    estadisticap = params[:estadisticap].to_i if params.has_key?(:estadisticap)

    if (@agrupaval.to_i > 0 or @subagrupaval.to_i > 0 or @sucursalval.to_i > 0) && estadisticat > 0
      @continua = 1
    end

    if @continua > 0
      case estadisticat
      when 1 
        dato = 'vtaNeta'
        @descdato = 'Venta Neta Total'
      when 2 
        dato = 'vtaStock'
        @descdato = 'Venta Stock Total'
      when 3 
        dato = 'vtaCosto'
        @descdato = 'Venta Costo Total'
      when 4 
        dato = 'tickets'
        @descdato = 'Tickets Totales'
      when 5 
        dato = 'renglones'
        @descdato = 'Renglones Totales'
      when 6 
        dato = 'articulos'
        @descdato = 'Articulos Totales'
      end

#raise estadisticad.inspect
      case estadisticap
      when 11 
        dato = 'vtaNetaContGral'
        @descdato = 'Venta Neta Contado General'
      when 12 
        dato = 'vtaNetaContCliDes'
        @descdato = 'Venta Neta de Contado Clientes con Descuento'
      when 13 
        dato = 'vtaNetaCredito'
        @descdato = 'Venta Neta de Crédito'
      when 21 
        dato = 'vtaStockContGral'
        @descdato = 'Venta Stock de Contado General'
      when 22 
        dato = 'vtaStockContCliDes'
        @descdato = 'Venta Stock de Contado Clientes con Descuento'
      when 23 
        dato = 'vtaStockCredito'
        @descdato = 'Venta Stock de Crédito'
      when 31 
        dato = 'vtaCostoContGral'
        @descdato = 'Venta Costo de Contado General'
      when 32 
        dato = 'vtaCostoContCliDes'
        @descdato = 'Venta Costo de Contado Clientes con Descuento'
      when 33 
        dato = 'vtaCostoCredito'
        @descdato = 'Venta Costo de Crédito'
      when 41 
        dato = 'TicketsContGral'
        @descdato = 'Tickets de Contado General'
      when 42 
        dato = 'TicketsContCliDes'
        @descdato = 'Tickets de Contado Clientes con Descuento'
      when 43 
        dato = 'TicketsCredito'
        @descdato = 'Tickets de Crédito'
      when 51 
        dato = 'RenglonesContGral'
        @descdato = 'Renglones de Contado General'
      when 52 
        dato = 'RenglonesContCliDes'
        @descdato = 'Renglones de Contado Clientes con Descuento'
      when 53 
        dato = 'RenglonesCredito'
        @descdato = 'Renglones de Crédito'
      when 61 
        dato = 'ArticulosContGral'
        @descdato = 'Artículos de Contado General'
      when 62 
        dato = 'ArticulosContCliDes'
        @descdato = 'Artículos de Contado Clientes con Descuento'
      when 63 
        dato = 'ArticulosCredito'
        @descdato = 'Artículos de Crédito'
      end

      joinAgrupa =" left join " + @nomDbComun.to_s + "agrupasuc as t3 on (t3.IdSucursal = t2.Sucursal) "
      joinAgrupa +=" left join " + @nomDbComun.to_s + "subagrupa as sb using(IdAgrupa,IdSubAgrupa) " if @subagrupaval.to_i > 0
      joinAgrupa =" left join " + @nomDbComun.to_s + "sucursal as sb on (t2.Sucursal = Num_suc) " if @sucursalval.to_i > 0

      whereAgrupacion ="t3.IdAgrupa = " + @agrupaval + " "
      whereAgrupacion ="sb.IdAgrupa = " + @agrupaval + " and sb.IdSubAgrupa = " + @subagrupaval + " " if @subagrupaval.to_i > 0
      whereAgrupacion ="t2.Sucursal = " + @sucursalval + " " if @sucursalval.to_i > 0

      whereSucursal = ""
      whereSucursal = " and sucursal = " + @sucursalval if @sucursalval.to_i > 0

      iva = ""
      indice = ""

      @estadistica = estadisticat
      @estadistica = estadisticap if estadisticap > 0

      case @estadistica
      when 1,2,3,11,12,13,21,22,23,31,32,33
        iva = "/(((SELECT max(iva) from " + @nomDbComun.to_s + "iva where zona = t2.zonaasig and left(FechaFac,4) <= left(t2.mes,4)) +100)/100)"
        tipoindice = params[:deflactar].to_s.gsub('.', '') if params.has_key?(:deflactar)
#raise @nomDbEsta.inspect
#raise @nomDbComun.inspect
        if params[:deflactar].to_s != "nodefinido"
          indice = "/((SELECT " + tipoindice + " from " + @nomDbEsta.to_s + "promediosindices Where Ano = left(t2.mes,4) and Mes = right(t2.mes,2))"
          indice += "/COALESCE((SELECT " + tipoindice + " from " + @nomDbEsta.to_s + "promediosindices Where Ano = (year(curdate()) - 1) and Mes = 12),1))"
        end  
      end 


      sql = "SELECT Año," 
      sql += "(SELECT ROUND(SUM(t2." + dato + iva + indice + "),2) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'01')) as Enero,"
      sql += "(SELECT ROUND(SUM(t2." + dato + iva + indice + "),2) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'02')) as Febrero,"
      sql += "(SELECT ROUND(SUM(t2." + dato + iva + indice + "),2) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'03')) as Marzo,"
      sql += "(SELECT ROUND(SUM(t2." + dato + iva + indice + "),2) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'04')) as Abril,"
      sql += "(SELECT ROUND(SUM(t2." + dato + iva + indice + "),2) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'05')) as Mayo,"
      sql += "(SELECT ROUND(SUM(t2." + dato + iva + indice + "),2) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'06')) as Junio,"
      sql += "(SELECT ROUND(SUM(t2." + dato + iva + indice + "),2) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'07')) as Julio,"
      sql += "(SELECT ROUND(SUM(t2." + dato + iva + indice + "),2) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'08')) as Agosto,"
      sql += "(SELECT ROUND(SUM(t2." + dato + iva + indice + "),2) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'09')) as Septiembre,"
      sql += "(SELECT ROUND(SUM(t2." + dato + iva + indice + "),2) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'10')) as Octubre,"
      sql += "(SELECT ROUND(SUM(t2." + dato + iva + indice + "),2) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'11')) as Noviembre,"
      sql += "(SELECT ROUND(SUM(t2." + dato + iva + indice + "),2) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'12')) as Diciembre "
      sql += "FROM "
      sql += "( "
      sql += " SELECT DISTINCT left(mes,4) as Año FROM htotalmes where left(mes,4) >= 2005 " + whereSucursal + " order by left(mes,4) DESC"
      sql += ") tmp"
# raise sql.inspect
      @antsaldos = @dbEsta.connection.select_all(sql)


#Esto es para la Gráfica
      @categorias = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic']
      case @estadistica
      when 1,2,3,11,12,13,21,22,23,31,32,33
        @ytitulo = 'Ventas ( $ )'
      when 4,41,42,43
        @ytitulo = 'Tikets'
      when 5,51,52,53
        @ytitulo = 'Renglones'
      when 6,61,62,63
        @ytitulo = 'Artículos'
      end 
      @tultip = ''

      @series = []
      @antsaldos.each do |m|
        datos = []
        ene = nil;feb = nil;mar = nil;abr = nil;may = nil;jun = nil
        jul = nil;ago = nil;sep = nil;oct = nil;nov = nil;dic = nil
        ene = Float(m['Enero'])       if m['Enero'] != nil
        feb = Float(m['Febrero'])     if m['Febrero'] != nil
        mar = Float(m['Marzo'])       if m['Marzo'] != nil
        abr = Float(m['Abril'])       if m['Abril'] != nil
        may = Float(m['Mayo'])        if m['Mayo'] != nil
        jun = Float(m['Junio'])       if m['Junio'] != nil
        jul = Float(m['Julio'])       if m['Julio'] != nil
        ago = Float(m['Agosto'])      if m['Agosto'] != nil
        sep = Float(m['Septiembre'])  if m['Septiembre'] != nil
        oct = Float(m['Octubre'])     if m['Octubre'] != nil
        nov = Float(m['Noviembre'])   if m['Noviembre'] != nil
        dic = Float(m['Diciembre'])   if m['Diciembre'] != nil
        datos.push(ene)
        datos.push(feb)
        datos.push(mar)
        datos.push(abr)
        datos.push(may)
        datos.push(jun)
        datos.push(jul)
        datos.push(ago)
        datos.push(sep)
        datos.push(oct)
        datos.push(nov)
        datos.push(dic)
        @series.push( { name: m['Año'], data: datos } )
      end
#raise @series.inspect

      if @sucursalval.to_i > 0
        sql = "SELECT Nombre FROM sucursal where Num_Suc = " + @sucursalval 
        @nomsuc = @dbComun.connection.select_all(sql)
      end

      sql = "SELECT Nombre,Excluyente FROM agrupa where IdAgrupa = " + @agrupaval
      @nomAgrupa = @dbComun.connection.select_all(sql)

      @tituloAgrupa = @nomAgrupa[0]['Nombre']
      @excluyente = @nomAgrupa[0]['Excluyente']

      if @subagrupaval.to_i > 0
        sql = "SELECT Nombre FROM subagrupa where IdAgrupa = " + @agrupaval + " and IdSubAgrupa = " + @subagrupaval
#        raise sql
        @nomSubagrupa = @dbComun.connection.select_all(sql)
        @tituloAgrupa += " -> " + @nomSubagrupa[0]['Nombre']
      end

      whereSucursal = ""
      if @sucursalval.to_i > 0
        sql = "SELECT Nombre FROM sucursal where Num_Suc = " + @sucursalval
        @nomSucursal = @dbComun.connection.select_all(sql)
        @tituloAgrupa = "Sucursal " + @sucursalval + " " + @nomSucursal[0]['Nombre']
      end

    end

    sql = "SELECT IdAgrupa,Nombre FROM agrupa order by NumOrd"
    @agrupa = @dbComun.connection.select_all(sql)

    sql = "SELECT IdSubAgrupa,Nombre FROM subagrupa where IdAgrupa = #{@agrupa[0]['IdAgrupa']} order by NumOrd"
    #raise sql.inspect
    @subagrupa = @dbComun.connection.select_all(sql)

    sql = "SELECT IdSucursal,Nombre FROM agrupasuc where IdAgrupa = #{@agrupa[0]['IdAgrupa']} and IdSubAgrupa = #{@subagrupa[0]['IdSubAgrupa']} order by NumOrd"
    #raise sql.inspect
    @agrupasuc = @dbComun.connection.select_all(sql)

    respond_to do |format|
      format.html
    #  format.csv do 
    #    out_arr = []
    #    out_arr.push("Sucursal,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre")
    #    @antsaldos.each do |m|
    #      out_arr.push(#{m['Sucursal']},#{number_to_currency(m['Enero'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['Febrero'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['Marzo'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['Abril'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['Mayo'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['Junio'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['Julio'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['Agosto'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['Septiembre'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['Octubre'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['Noviembre'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['Diciembre'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}")
    #    end
    #    csv_file = "/tmp/estaventas_#{DateTime.now.to_i}.csv"
    #    dump_to_file(csv_file,out_arr.join("\n"))
    #    send_file csv_file
    #    return
    #  end
    end   

  end

  def ajax_subagrupa
    agrupa = params[:agrupa].to_i if params.has_key?(:agrupa)
    #raise @agrupa.inspect
    if agrupa > 0
      sql = "SELECT IdSubAgrupa,subagrupa.Nombre,Excluyente FROM subagrupa inner join agrupa using (IdAgrupa) where IdAgrupa = #{agrupa} order by subagrupa.NumOrd"
  #    sql = "SELECT IdSubAgrupa,Nombre FROM subagrupa where IdAgrupa = #{agrupa} order by NumOrd"
      @subagrupa = @dbComun.connection.select_all(sql)
      render json: @subagrupa
    end
    # raise 'lola'
  end

  def ajax_agrupasuc
    agrupa = params[:agrupa].to_i if params.has_key?(:agrupa)
    subagrupa = params[:subagrupa].to_i if params.has_key?(:subagrupa)
    #raise agrupa.inspect + " " + subagrupa.inspect
    if agrupa > 0 and subagrupa > 0
      sql = "SELECT IdSucursal,Nombre FROM agrupasuc where IdAgrupa = #{agrupa} and IdSubAgrupa = #{subagrupa} order by NumOrd"
      @agrupasuc = @dbComun.connection.select_all(sql)
      render json: @agrupasuc
    end
  end

  private

    def dump_to_file(filename,txt,modo="w")
      File.open(filename, modo) {|f| f.write(txt) }
    end
end
