class CalcObjetivosController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app

  include ActionView::Helpers::NumberHelper

  def calc_objetivos
  #  <medium>
  #    <%= link_to "Regresar", "/calc_objetivos" %>
  #  </medium>
  #    <medium>
  #      <%= link_to "Regresar", "/calc_objetivos_objetivo" %> 
  #    </medium>
  end

  def calc_objetivos_estadistica
    @continua = 0

    @anosel = params[:anosel].to_s if params.has_key?(:anosel)
    @niveldetalle = params[:niveldetalle].to_s if params.has_key?(:niveldetalle)
    @agrupaval = params[:agrupa].to_s if params.has_key?(:agrupa)
    @subagrupaval = params[:subagrupa].to_s if params.has_key?(:subagrupa)
    @sucursalval = params[:agrupasuc].to_s if params.has_key?(:agrupasuc)

    if @niveldetalle.to_s != ""
      @continua = 1
    end

    if @continua > 0
      dato = 'vtaNeta'
      @descdato = 'Venta Neta Total'

      joinAgrupa = ""
      joinAgrupa = " left join " + @nomDbComun.to_s + "agrupasuc as t3 on (t3.IdSucursal = t2.Sucursal) " if @sucursalval.to_i == 0

      if @niveldetalle.to_s == "Región"
        whereAgrupacion = "t3.IdAgrupa = Agrupa "
        whereAgrupacion = "t3.IdAgrupa = " + @agrupaval + " and t3.IdSubAgrupa = SubAgrupa " if @agrupaval.to_i > 0
        whereAgrupacion = "t3.IdAgrupa = " + @agrupaval + " and t3.IdSubAgrupa = " + @subagrupaval + " and t3.IdSucursal = suc " if @subagrupaval.to_i > 0
      else
        if @niveldetalle.to_s == "Ciudad"
          whereAgrupacion = "t3.IdAgrupa = Agrupa and t3.IdSubAgrupa = SubAgrupa "
          whereAgrupacion = "t3.IdAgrupa = " + @agrupaval + " and t3.IdSubAgrupa = SubAgrupa " if @agrupaval.to_i > 0
        else
          if @niveldetalle.to_s == "Sucursal"
            whereAgrupacion = "t3.IdSucursal = Suc "
            whereAgrupacion = "t3.IdAgrupa = " + @agrupaval + " and t3.IdSucursal = Suc " if @agrupaval.to_i > 0
            whereAgrupacion = "t3.IdAgrupa = " + @agrupaval + " and t3.IdSubAgrupa = " + @subagrupaval + " and t3.IdSucursal = Suc " if @subagrupaval.to_i > 0
          else
            whereAgrupacion = "t3.Objetivo = 1 "
            whereAgrupacion = "t3.IdAgrupa = " + @agrupaval + " " if @agrupaval.to_i > 0
            whereAgrupacion = "t3.IdAgrupa = " + @agrupaval + " and t3.IdSubAgrupa = " + @subagrupaval + " " if @subagrupaval.to_i > 0
            whereAgrupacion = "t2.Sucursal = " + @sucursalval + " " if @sucursalval.to_i > 0
          end
        end
      end

      whereSucursal = ""
      whereSucursal = " and sucursal = " + @sucursalval if @sucursalval.to_i > 0

#raise whereAgrupacion


      iva = ""
      indice = ""

      iva = "/(((SELECT max(iva) from " + @nomDbComun.to_s + "iva where zona = t2.zonaasig and left(FechaFac,4) <= left(t2.mes,4)) +100)/100)"
      tipoindice = params[:deflactar].to_s.gsub('.', '') if params.has_key?(:deflactar)
#raise @nomDbEsta.inspect
#raise @nomDbComun.inspect
      if params[:deflactar].to_s != "nodefinido"
        indice = "/((SELECT " + tipoindice + " from " + @nomDbEsta.to_s + "promediosindices Where Ano = left(t2.mes,4) and Mes = right(t2.mes,2))"
        indice += "/COALESCE((SELECT " + tipoindice + " from " + @nomDbEsta.to_s + "promediosindices Where Ano = (" + @anosel.to_s + " - 1) and Mes = 12),1))"
      end  

      if @niveldetalle.to_s == "Región"
        campoInfo = "Región"
#        campoInfo = "(SELECT Nombre FROM " + @nomDbComun.to_s + "agrupa where IdAgrupa = Agrupa) as Región"
        selectInfo = " SELECT " + @anosel.to_s + " as Año, IdAgrupa as Agrupa, Nombre as Región FROM " + @nomDbComun.to_s + "agrupa where Objetivo = 1 order by NumOrd"
        campoInfo = "Ciudad" if @agrupaval.to_i > 0
#        campoInfo = "(SELECT Nombre FROM " + @nomDbComun.to_s + "subagrupa where IdAgrupa = " + @agrupaval + " and IdSubAgrupa = SubAgrupa) as Ciudad" if @agrupaval.to_i > 0
        selectInfo = " SELECT " + @anosel.to_s + " as Año, IdSubAgrupa as SubAgrupa, Nombre as Ciudad FROM " + @nomDbComun.to_s + "subagrupa where  IdAgrupa = " + @agrupaval + " order by NumOrd" if @agrupaval.to_i > 0
        campoInfo = "Sucursal" if @subagrupaval.to_i > 0
#        campoInfo = "(SELECT Nombre FROM " + @nomDbComun.to_s + "agrupasuc where IdAgrupa = " + @agrupaval + " and IdSubAgrupa = " + @subagrupaval + " and IdSucursal = Suc) as Sucursal" if @subagrupaval.to_i > 0
        selectInfo = " SELECT " + @anosel.to_s + " as Año, IdSucursal as Suc, Nombre as Sucursal FROM " + @nomDbComun.to_s + "agrupasuc where  IdAgrupa = " + @agrupaval + " and IdSubAgrupa = " + @subagrupaval + " order by NumOrd" if @subagrupaval.to_i > 0
      else
        if @niveldetalle.to_s == "Ciudad"
          campoInfo = "Ciudad"
#          campoInfo = "(SELECT Nombre FROM " + @nomDbComun.to_s + "subagrupa where IdAgrupa = Agrupa and IdSubAgrupa = SubAgrupa) as Ciudad"
          selectInfo = " SELECT " + @anosel.to_s + " as Año, IdAgrupa as Agrupa, IdSubAgrupa as SubAgrupa, Nombre as Ciudad FROM " + @nomDbComun.to_s + "subagrupa where Objetivo = 1 order by IdAgrupa,NumOrd"
#          campoInfo = "(SELECT Nombre FROM " + @nomDbComun.to_s + "subagrupa where IdAgrupa = " + @agrupaval + " and IdSubAgrupa = SubAgrupa) as Ciudad" if @agrupaval.to_i > 0
          selectInfo = " SELECT " + @anosel.to_s + " as Año, IdSubAgrupa as SubAgrupa, Nombre as Ciudad FROM " + @nomDbComun.to_s + "subagrupa where  IdAgrupa = " + @agrupaval + " order by NumOrd" if @agrupaval.to_i > 0
        else
          if @niveldetalle.to_s == "Sucursal"
            campoInfo = "Sucursal"
            selectInfo = " SELECT " + @anosel.to_s + " as Año, IdSucursal as Suc, Nombre as Sucursal FROM " + @nomDbComun.to_s + "agrupasuc where Objetivo = 1 order by IdAgrupa,IdSubAgrupa,NumOrd"
#            campoInfo = "(SELECT Nombre FROM " + @nomDbComun.to_s + "agrupasuc where IdAgrupa = " + @agrupaval + " and IdSucursal = Suc) as Sucursal" if @agrupaval.to_i > 0
            selectInfo = " SELECT " + @anosel.to_s + " as Año, IdSucursal as Suc, Nombre as Sucursal FROM comun.agrupasuc where IdAgrupa = " + @agrupaval + " order by IdSubAgrupa,NumOrd" if @agrupaval.to_i > 0
#            campoInfo = "(SELECT Nombre FROM " + @nomDbComun.to_s + "agrupasuc where IdAgrupa = " + @agrupaval + " and IdSubAgrupa = " + @subagrupaval + " and IdSucursal = Suc) as Sucursal" if @subagrupaval.to_i > 0
            selectInfo = " SELECT " + @anosel.to_s + " as Año, IdSucursal as Suc, Nombre as Sucursal FROM comun.agrupasuc where IdAgrupa = " + @agrupaval + " and IdSubAgrupa = " + @subagrupaval + " order by NumOrd" if @subagrupaval.to_i > 0
          else
            campoInfo = "Año"
            selectInfo = " SELECT DISTINCT left(mes,4) as Año FROM htotalmes where left(mes,4) >= 2005 and left(mes,4) <= " + @anosel.to_s + " " + whereSucursal + " order by left(mes,4) DESC"
          end
        end
      end

      sql = "SELECT " + campoInfo + "," 
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
      sql += selectInfo
      sql += ") tmp"
#raise sql
      @estadistica = @dbEsta.connection.select_all(sql)


#Esto es para la Gráfica
      @categorias = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic']
      @ytitulo = 'Ventas ( $ )'
      @tultip = ''

      @series = []
      @estadistica.each do |m|
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
        if @niveldetalle.to_s == "Región"
          @series.push( { name: m['Región'], data: datos } ) if @agrupaval.to_i == 0
          @series.push( { name: m['Ciudad'], data: datos } ) if @agrupaval.to_i > 0 and @subagrupaval.to_i == 0
          @series.push( { name: m['Sucursal'], data: datos } ) if @subagrupaval.to_i > 0
        else
          if @niveldetalle.to_s == "Ciudad"
            @series.push( { name: m['Ciudad'], data: datos } )
          else
            if @niveldetalle.to_s == "Sucursal"
              @series.push( { name: m['Sucursal'], data: datos } )
            else
              @series.push( { name: m['Año'], data: datos } )
            end
          end
        end
      end
#raise @series.inspect

      if @sucursalval.to_i > 0
        sql = "SELECT Nombre FROM sucursal where Num_Suc = " + @sucursalval 
        @nomsuc = @dbComun.connection.select_all(sql)
      end

      @tituloAgrupa = ''

      if @agrupaval.to_i > 0
        sql = "SELECT Nombre FROM agrupa where IdAgrupa = " + @agrupaval
        @nomAgrupa = @dbComun.connection.select_all(sql)
        @tituloAgrupa = @nomAgrupa[0]['Nombre']
      end

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

    sql = "SELECT DISTINCT left(mes,4) as Año from htotalmes where left(mes,4) >= 2005 ORDER BY Año DESC"
    @tablaanosel = @dbEsta.connection.select_all(sql)

    sql = "SELECT IdAgrupa,Nombre FROM agrupa where Objetivo = 1 order by NumOrd"
    @region = @dbComun.connection.select_all(sql)

    sql = "SELECT IdSubAgrupa,Nombre FROM subagrupa where IdAgrupa = #{@region[0]['IdAgrupa']} order by NumOrd"
    #raise sql.inspect
    @subagrupa = @dbComun.connection.select_all(sql)

    sql = "SELECT IdSucursal,Nombre FROM agrupasuc where IdAgrupa = #{@region[0]['IdAgrupa']} and IdSubAgrupa = #{@subagrupa[0]['IdSubAgrupa']} order by NumOrd"
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
#    datos = params[:data].to_i if params.has_key?(:data)
#    raise datos.inspect
#    agrupa = params[:agrupa].to_i if params.has_key?(:agrupa)
    #raise @agrupa.inspect
#    if agrupa > 0
#      sql = "SELECT IdSubAgrupa,subagrupa.Nombre FROM subagrupa where IdAgrupa = #{agrupa} order by subagrupa.NumOrd"
#      @subagrupa = @dbComun.connection.select_all(sql)
#      render json: @subagrupa
#    end
     raise 'lola'
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

  def calc_objetivos_objetivo
    @continua = 0

    @anosel = params[:anosel].to_s if params.has_key?(:anosel)
    @region = params[:region].to_s if params.has_key?(:region)
    @nivelopc = params[:nivelopc].to_s if params.has_key?(:nivelopc)
    @titulo = ""
    @nomRegion = ""

    if @anosel.to_i > 0
      @continua = 1
    end

    if @continua > 0
      @anoant = @anosel.to_i - 1

      #Se crean los registros para este Año
      for n in 1..12
        sql = "INSERT IGNORE INTO indicesobjetivo "
        sql += "select " + @anosel.to_s + "," + n.to_s + ",REPLACE(LAST_DAY(concat(" + @anosel.to_s + ",LPAD(" + n.to_s + ",2,'0'),'01')),'-',''),0,0,0,0,0,0,0,0,0"
        @dbEsta.connection.execute(sql)
      end

      #Se ponen los Porcentajes de Inflación del Año Anterior
      sql = "UPDATE indicesobjetivo as t1 inner join indicesobjetivo as t2 "
      sql += "on "
      sql += "t1.mes = t2.mes "
      sql += "set "
      sql += "t1.PorceInflacionINPC = t2.PorceInflacionINPC "
      sql += "where "
      sql += "t1.ano = " + @anosel.to_s + " "
      sql += "and t2.ano = " + @anoant.to_s
      @dbEsta.connection.execute(sql)

      #Se calcula el nuevo INPC supuesto de acuerdo al año anterior
      for n in 1..12
        sql = "UPDATE indicesobjetivo as t1 inner join indicesobjetivo as t2 "
        sql += "on "
        sql += "if(t1.mes = 1,t1.ano -1,t1.ano) = t2.ano "
        sql += "and if(t1.mes = 1,12,t1.mes - 1) = t2.mes "
        sql += "set "
        sql += "t1.INPC = round(t2.INPC*(1+(t1.PorceInflacionINPC/100)),4) "
        sql += "where "
        sql += "t1.ano = " + @anosel.to_s + " and t1.mes = " + n.to_s
        @dbEsta.connection.execute(sql)
      end

      #Actualiza Indices Reales
      sql = "UPDATE indicesobjetivo as t1 inner join promediosindices as t2 "
      sql += "on "
      sql += "t1.ano = t2.ano "
      sql += "and t1.mes = t2.mes "
      sql += "set "
      sql += "t1.INPC = t2.INPC, "
      sql += "t1.IIP = t2.IIP, "
      sql += "t1.IC = t2.IC, "
      sql += "t1.PorcientoCosto = t2.PorcientoCosto "
      sql += "where "
      sql += "t1.ano = " + @anosel.to_s
      @dbEsta.connection.execute(sql)

      sql = "INSERT INTO #{@nomDbEsta}indicesobjetivo (Ano,Mes,FechaFinMes,InflacionVsAnoAntINPC) "
      sql += "SELECT Ano,Mes,FechaFinMes,InflacionVsAnoAntINPC "
      sql += "FROM  "
      sql += "( "
      sql += "SELECT Ano,Mes,FechaFinMes, "
      sql += "round(((p.INPC/(select INPC from #{@nomDbEsta}indicesobjetivo where ano = p.Ano -1 and mes = p.mes)) - 1) * 100,4) as InflacionVsAnoAntINPC "
      sql += "from #{@nomDbEsta}indicesobjetivo as p "
      sql += "where Ano = " + @anosel.to_s + " "
      sql += ") tmp "
      sql += "ON DUPLICATE KEY UPDATE "
      sql += "InflacionVsAnoAntINPC = tmp.InflacionVsAnoAntINPC"
      @dbEsta.connection.execute(sql)

      #Actualiza PorceInflacionINPC Real
      sql = "UPDATE indicesobjetivo as t1 inner join promediosindices as t2 "
      sql += "on "
      sql += "t1.ano = t2.ano "
      sql += "and t1.mes = t2.mes "
      sql += "inner join indicesobjetivo as t3 "
      sql += "on "
      sql += "if(t1.mes = 1,t1.ano -1,t1.ano) = t3.ano "
      sql += "and if(t1.mes = 1,12,t1.mes - 1) = t3.mes "
      sql += "set "
      sql += "t1.PorceInflacionINPC = round(((t1.INPC/t3.INPC) -1) * 100,4) "
      sql += "where "
      sql += "t1.ano = " + @anosel.to_s
      @dbEsta.connection.execute(sql)

      for n in 1..12
        sql = "UPDATE indicesobjetivo as t1 inner join indicesobjetivo as t2 "
        sql += "on "
        sql += "t1.ano = t2.ano "
        sql += "and if(t1.mes = 1,1,t1.mes - 1) = t2.mes "
        sql += "set "
        sql += "t1.InflacionAcumINPC = if(t1.mes = 1,t1.PorceInflacionINPC,round((((1+(t2.InflacionAcumINPC/100))*(1+(t1.PorceInflacionINPC/100)))-1)*100,4)) "
        sql += "where "
        sql += "t1.ano = " + @anosel.to_s + " and t1.mes = " + n.to_s
        @dbEsta.connection.execute(sql)
      end

      if @region.to_i == 0
        tablaobj = "objciudad"
        regTotales = ""
      else
        tablaobj = "objsucursal"
        regTotales = @region.to_s
      end
#        raise regTotales.inspect

      sqlUpdate = "Enero = obj.Enero,"
      sqlUpdate += "Febrero = obj.Febrero,"
      sqlUpdate += "Marzo = obj.Marzo,"
      sqlUpdate += "Abril = obj.Abril,"
      sqlUpdate += "Mayo = obj.Mayo,"
      sqlUpdate += "Junio = obj.Junio,"
      sqlUpdate += "Julio = obj.Julio,"
      sqlUpdate += "Agosto = obj.Agosto,"
      sqlUpdate += "Septiembre = obj.Septiembre,"
      sqlUpdate += "Octubre = obj.Octubre,"
      sqlUpdate += "Noviembre = obj.Noviembre,"
      sqlUpdate += "Diciembre = obj.Diciembre"

      sqlSum = "SUM(Enero) as Enero,"
      sqlSum += "SUM(Febrero) as Febrero,"
      sqlSum += "SUM(Marzo) as Marzo,"
      sqlSum += "SUM(Abril) as Abril,"
      sqlSum += "SUM(Mayo) as Mayo,"
      sqlSum += "SUM(Junio) as Junio,"
      sqlSum += "SUM(Julio) as Julio,"
      sqlSum += "SUM(Agosto) as Agosto,"
      sqlSum += "SUM(Septiembre) as Septiembre,"
      sqlSum += "SUM(Octubre) as Octubre,"
      sqlSum += "SUM(Noviembre) as Noviembre,"
      sqlSum += "SUM(Diciembre) as Diciembre "

      if @region.to_i == 0
        nomSubAgrupa = "Ciudad"
        idSubAgrupa = "IdCiudad"
        whereRegion = ""
        whereRegion1 = ""
        whereRegion2 = ""
      else
        nomSubAgrupa = "Sucursal"
        idSubAgrupa = "IdSucursal"
        whereRegion = " and IdRegion = " + @region.to_s
        whereRegion1 = " and IdRegion = " + @region.to_s + "1"
        whereRegion2 = " and IdRegion = " + @region.to_s + "2"
      end

#      if @nivelopc.to_s == "Objetivo"
        dato = 'vtaNeta'
        tipoindice = "INPC"
        iva = "/(((SELECT max(iva) from " + @nomDbComun.to_s + "iva where zona = t2.zonaasig and left(FechaFac,4) <= left(t2.mes,4)) +100)/100)"
        joinAgrupa = " left join " + @nomDbComun.to_s + "agrupasuc as t3 on (t3.IdSucursal = t2.Sucursal) "
        if @region.to_i == 0
          whereAgrupacion = "t3.IdAgrupa = Agrupa and t3.IdSubAgrupa = SubAgrupa "
          campoInfo = "(SELECT Nombre FROM " + @nomDbComun.to_s + "subagrupa where IdAgrupa = Agrupa and IdSubAgrupa = SubAgrupa) as Nombre"
          selectInfo = " SELECT " + @anoant.to_s + " as Año, IdAgrupa as Agrupa, IdSubAgrupa as SubAgrupa FROM " + @nomDbComun.to_s + "subagrupa where Objetivo = 1 order by IdAgrupa,NumOrd"
        else
          whereAgrupacion = "t3.IdAgrupa = " + @region.to_s + " and t3.IdSucursal = SubAgrupa "
          campoInfo = "(SELECT Nombre FROM " + @nomDbComun.to_s + "agrupasuc where IdAgrupa = " + @region.to_s + " and IdSucursal = SubAgrupa) as Nombre"
          selectInfo = " SELECT " + @anoant.to_s + " as Año, IdAgrupa as Agrupa, IdSucursal as SubAgrupa FROM " + @nomDbComun.to_s + "agrupasuc where IdAgrupa = " + @region.to_s + " order by IdSucursal"
        end
  #raise @nomDbEsta.inspect
  #raise @nomDbComun.inspect

  #Venta Año Anterior

        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",1,Agrupa,SubAgrupa,Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",1,Agrupa,SubAgrupa," + campoInfo + ", "
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'01')) as Enero,"
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'02')) as Febrero,"
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'03')) as Marzo,"
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'04')) as Abril,"
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'05')) as Mayo,"
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'06')) as Junio,"
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'07')) as Julio,"
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'08')) as Agosto,"
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'09')) as Septiembre,"
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'10')) as Octubre,"
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'11')) as Noviembre,"
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'12')) as Diciembre "
        sql += "FROM "
        sql += "( "
        sql += selectInfo
        sql += ") tmp"
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
  #raise sql
        @dbEsta.connection.execute(sql)

        sql = "SELECT Nombre as " + nomSubAgrupa + ",Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre from " + tablaobj + " where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 1"
        @antvtaneta = @dbEsta.connection.select_all(sql)

  #Venta Ant. Precios Actuales
        indice = "/((SELECT " + tipoindice + " from " + @nomDbEsta.to_s + "promediosindices Where Ano = left(t2.mes,4) and Mes = right(t2.mes,2))"
        indice += "/COALESCE((SELECT " + tipoindice + " from " + @nomDbEsta.to_s + "promediosindices Where Ano = (year(curdate()) - 1) and Mes = 12),1))"

        indice = " * (1+((SELECT InflacionVsAnoAntINPC from indicesobjetivo where Ano = " + @anosel.to_s + " and Mes = "
        if @region.to_i == 0
          @from1 = "from objciudad where Ano = " + @anosel.to_s + " and IdObjetivo = 1 and IdRegion = Agrupa and IdCiudad = SubAgrupa)"
        else
          @from1 = "from objsucursal where Ano = " + @anosel.to_s + " and IdObjetivo = 1 and IdRegion = Agrupa and IdSucursal = SubAgrupa)"
        end

        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",2,Agrupa,SubAgrupa,Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",2,Agrupa,SubAgrupa," + campoInfo + ", "
        sql += "ROUND((SELECT Enero      " + @from1 + indice + "1 )/100)),2) as Enero,"
        sql += "ROUND((SELECT Febrero    " + @from1 + indice + "2 )/100)),2) as Febrero,"
        sql += "ROUND((SELECT Marzo      " + @from1 + indice + "3 )/100)),2) as Marzo,"
        sql += "ROUND((SELECT Abril      " + @from1 + indice + "4 )/100)),2) as Abril,"
        sql += "ROUND((SELECT Mayo       " + @from1 + indice + "5 )/100)),2) as Mayo,"
        sql += "ROUND((SELECT Junio      " + @from1 + indice + "6 )/100)),2) as Junio,"
        sql += "ROUND((SELECT Julio      " + @from1 + indice + "7 )/100)),2) as Julio,"
        sql += "ROUND((SELECT Agosto     " + @from1 + indice + "8 )/100)),2) as Agosto,"
        sql += "ROUND((SELECT Septiembre " + @from1 + indice + "9 )/100)),2) as Septiembre,"
        sql += "ROUND((SELECT Octubre    " + @from1 + indice + "10)/100)),2) as Octubre,"
        sql += "ROUND((SELECT Noviembre  " + @from1 + indice + "11)/100)),2) as Noviembre,"
        sql += "ROUND((SELECT Diciembre  " + @from1 + indice + "12)/100)),2) as Diciembre "
        sql += "FROM "
        sql += "( "
        sql += selectInfo
        sql += ") tmp "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

        sql = "SELECT Nombre as " + nomSubAgrupa + ",Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre from " + tablaobj + " where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 2"
        @antvtanetaact = @dbEsta.connection.select_all(sql)

  #Objetivo Crecimiento Real
        sql = "INSERT IGNORE INTO " + tablaobj + " "
        if @region.to_i == 0
          sql += "SELECT " + @anosel.to_s + ",3,IdAgrupa,IdSubAgrupa,Nombre,3,3,3,3,3,3,3,3,3,3,3,3 FROM " + @nomDbComun.to_s + "subagrupa where Objetivo = 1 order by IdAgrupa,NumOrd"
        else
          sql += "SELECT " + @anosel.to_s + ",3,IdAgrupa,IdSucursal,Nombre,3,3,3,3,3,3,3,3,3,3,3,3 FROM " + @nomDbComun.to_s + "agrupasuc where IdAgrupa = " + @region.to_s + " order by IdSucursal"
        end
        @dbEsta.connection.execute(sql)

        if @region.to_i == 0
          sql = "SELECT Nombre as " + nomSubAgrupa + ",Ano,IdRegion,IdCiudad,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre from " + tablaobj + " where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 3 order by IdRegion,IdCiudad"
        else
          sql = "SELECT Nombre as " + nomSubAgrupa + ",Ano,IdRegion,IdSucursal,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre from " + tablaobj + " where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 3 order by IdRegion,IdSucursal"
        end
        @objcrereal = @dbEsta.connection.select_all(sql)

  #Objetivo
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",4,IdRegion," + idSubAgrupa + ",Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",4,t1.IdRegion,t1." + idSubAgrupa + ",t1.Nombre, "
        sql += "ROUND((t1.Enero      * (1+(t2.Enero     /100)))/5000,0) * 5000 as Enero, "
        sql += "ROUND((t1.Febrero    * (1+(t2.Febrero   /100)))/5000,0) * 5000 as Febrero, "
        sql += "ROUND((t1.Marzo      * (1+(t2.Marzo     /100)))/5000,0) * 5000 as Marzo, "
        sql += "ROUND((t1.Abril      * (1+(t2.Abril     /100)))/5000,0) * 5000 as Abril, "
        sql += "ROUND((t1.Mayo       * (1+(t2.Mayo      /100)))/5000,0) * 5000 as Mayo, "
        sql += "ROUND((t1.Junio      * (1+(t2.Junio     /100)))/5000,0) * 5000 as Junio, "
        sql += "ROUND((t1.Julio      * (1+(t2.Julio     /100)))/5000,0) * 5000 as Julio, "
        sql += "ROUND((t1.Agosto     * (1+(t2.Agosto    /100)))/5000,0) * 5000 as Agosto, "
        sql += "ROUND((t1.Septiembre * (1+(t2.Septiembre/100)))/5000,0) * 5000 as Septiembre, "
        sql += "ROUND((t1.Octubre    * (1+(t2.Octubre   /100)))/5000,0) * 5000 as Octubre, "
        sql += "ROUND((t1.Noviembre  * (1+(t2.Noviembre /100)))/5000,0) * 5000 as Noviembre, "
        sql += "ROUND((t1.Diciembre  * (1+(t2.Diciembre /100)))/5000,0) * 5000 as Diciembre "
        sql += "FROM " + tablaobj + " as t1 INNER JOIN " + tablaobj + " as t2 "
        sql += "USING(Ano,IdRegion," + idSubAgrupa + ") "
        sql += "WHERE "
        sql += "t1.Ano = " + @anosel.to_s + " "
        sql += "and t1.IdObjetivo = 2 "
        sql += "and t2.IdObjetivo = 3 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

        if @region.to_i == 0
          sql = "SELECT Nombre as " + nomSubAgrupa + ",Ano,IdRegion,IdCiudad,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre from " + tablaobj + " where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 4"
        else
          sql = "SELECT Nombre as " + nomSubAgrupa + ",Ano,IdRegion,IdSucursal,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre from " + tablaobj + " where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 4"
        end
        @objetivo = @dbEsta.connection.select_all(sql)

  #Venta Real   ( Primer se pone el Objetivo y luego se substituye por la Venta Real que va Existiendo )
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT Ano,5,IdRegion," + idSubAgrupa + ",Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre from " + tablaobj + " as obj where Ano = " + @anosel.to_s + " and IdObjetivo = 4 "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

        if @region.to_i == 0
          selectInfo = " SELECT " + @anosel.to_s + " as Año, IdAgrupa as Agrupa, IdSubAgrupa as SubAgrupa FROM " + @nomDbComun.to_s + "subagrupa where Objetivo = 1 order by IdAgrupa,NumOrd"
        else
          selectInfo = " SELECT " + @anosel.to_s + " as Año, IdAgrupa as Agrupa, IdSucursal as SubAgrupa FROM " + @nomDbComun.to_s + "agrupasuc where IdAgrupa = " + @region.to_s + " order by IdSubAgrupa,NumOrd"
        end

        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",6,Agrupa,SubAgrupa,Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",6,Agrupa,SubAgrupa," + campoInfo + ", "
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'01')) as Enero,"
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'02')) as Febrero,"
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'03')) as Marzo,"
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'04')) as Abril,"
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'05')) as Mayo,"
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'06')) as Junio,"
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'07')) as Julio,"
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'08')) as Agosto,"
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'09')) as Septiembre,"
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'10')) as Octubre,"
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'11')) as Noviembre,"
        sql += "(SELECT COALESCE(ROUND(SUM(t2." + dato + iva + "),2),0) from htotalmes as t2 " + joinAgrupa + " Where " + whereAgrupacion + " and t2.mes = concat(Año,'12')) as Diciembre "
        sql += "FROM "
        sql += "( "
        sql += selectInfo
        sql += ") tmp"
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
#raise sql
        @dbEsta.connection.execute(sql)

        sql = "UPDATE " + tablaobj + " as t1 INNER JOIN " + tablaobj + " as t2 "
        sql += "using(Ano,IdRegion," + idSubAgrupa + ") "
        sql += "SET "
        sql += "t1.Enero      = if(t2.Enero      > 0,t2.Enero     ,t1.Enero), "
        sql += "t1.Febrero    = if(t2.Febrero    > 0,t2.Febrero   ,t1.Febrero), "
        sql += "t1.Marzo      = if(t2.Marzo      > 0,t2.Marzo     ,t1.Marzo), "
        sql += "t1.Abril      = if(t2.Abril      > 0,t2.Abril     ,t1.Abril), "
        sql += "t1.Mayo       = if(t2.Mayo       > 0,t2.Mayo      ,t1.Mayo), "
        sql += "t1.Junio      = if(t2.Junio      > 0,t2.Junio     ,t1.Junio), "
        sql += "t1.Julio      = if(t2.Julio      > 0,t2.Julio     ,t1.Julio), "
        sql += "t1.Agosto     = if(t2.Agosto     > 0,t2.Agosto    ,t1.Agosto), "
        sql += "t1.Septiembre = if(t2.Septiembre > 0,t2.Septiembre,t1.Septiembre), "
        sql += "t1.Octubre    = if(t2.Octubre    > 0,t2.Octubre   ,t1.Octubre), "
        sql += "t1.Noviembre  = if(t2.Noviembre  > 0,t2.Noviembre ,t1.Noviembre), "
        sql += "t1.Diciembre  = if(t2.Diciembre  > 0,t2.Diciembre ,t1.Diciembre) "
        sql += "WHERE "
        sql += "t1.Ano = " + @anosel.to_s + " "
        sql += "and t1.IdObjetivo = 5 "
        sql += "and t2.IdObjetivo = 6 "
        @dbEsta.connection.execute(sql)

        sql = "SELECT Nombre as " + nomSubAgrupa + ",Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre from " + tablaobj + " where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 5"
        @vtanetareal = @dbEsta.connection.select_all(sql)

  #Variación Vs Objetivo ($)
        sql = "SELECT t1.Nombre as " + nomSubAgrupa + ", "
        sql += "(t1.Enero      - t2.Enero     ) as Enero, "
        sql += "(t1.Febrero    - t2.Febrero   ) as Febrero, "
        sql += "(t1.Marzo      - t2.Marzo     ) as Marzo, "
        sql += "(t1.Abril      - t2.Abril     ) as Abril, "
        sql += "(t1.Mayo       - t2.Mayo      ) as Mayo, "
        sql += "(t1.Junio      - t2.Junio     ) as Junio, "
        sql += "(t1.Julio      - t2.Julio     ) as Julio, "
        sql += "(t1.Agosto     - t2.Agosto    ) as Agosto, "
        sql += "(t1.Septiembre - t2.Septiembre) as Septiembre, "
        sql += "(t1.Octubre    - t2.Octubre   ) as Octubre, "
        sql += "(t1.Noviembre  - t2.Noviembre ) as Noviembre, "
        sql += "(t1.Diciembre  - t2.Diciembre ) as Diciembre "
        sql += "FROM " + tablaobj + " as t1 INNER JOIN " + tablaobj + " as t2 "
        sql += "USING(Ano,IdRegion," + idSubAgrupa + ") "
        sql += "WHERE t1.Ano = " + @anosel.to_s + whereRegion + " "
        sql += "and t1.IdObjetivo = 5 "
        sql += "and t2.IdObjetivo = 4 "
        @varvsobjetivo = @dbEsta.connection.select_all(sql)

  #Variación Vs Objetivo (%)
        sql = "SELECT t1.Nombre as " + nomSubAgrupa + ", "
        sql += "((t1.Enero      - t2.Enero     ) / t3.Enero     ) * 100 as Enero, "
        sql += "((t1.Febrero    - t2.Febrero   ) / t3.Febrero   ) * 100 as Febrero, "
        sql += "((t1.Marzo      - t2.Marzo     ) / t3.Marzo     ) * 100 as Marzo, "
        sql += "((t1.Abril      - t2.Abril     ) / t3.Abril     ) * 100 as Abril, "
        sql += "((t1.Mayo       - t2.Mayo      ) / t3.Mayo      ) * 100 as Mayo, "
        sql += "((t1.Junio      - t2.Junio     ) / t3.Junio     ) * 100 as Junio, "
        sql += "((t1.Julio      - t2.Julio     ) / t3.Julio     ) * 100 as Julio, "
        sql += "((t1.Agosto     - t2.Agosto    ) / t3.Agosto    ) * 100 as Agosto, "
        sql += "((t1.Septiembre - t2.Septiembre) / t3.Septiembre) * 100 as Septiembre, "
        sql += "((t1.Octubre    - t2.Octubre   ) / t3.Octubre   ) * 100 as Octubre, "
        sql += "((t1.Noviembre  - t2.Noviembre ) / t3.Noviembre ) * 100 as Noviembre, "
        sql += "((t1.Diciembre  - t2.Diciembre ) / t3.Diciembre ) * 100 as Diciembre "
        sql += "FROM " + tablaobj + " as t1 INNER JOIN " + tablaobj + " as t2 "
        sql += "USING(Ano,IdRegion," + idSubAgrupa + ") "
        sql += "INNER JOIN " + tablaobj + " as t3 "
        sql += "USING(Ano,IdRegion," + idSubAgrupa + ") "
        sql += "WHERE t1.Ano = " + @anosel.to_s + whereRegion + " "
        sql += "and t1.IdObjetivo = 5 "
        sql += "and t2.IdObjetivo = 4 "
        sql += "and t3.IdObjetivo = 4 "
        @varvsobjporce = @dbEsta.connection.select_all(sql)

  #TOTALES
  #Venta Año Anterior
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",Objetivo,Agrupa,SubAgrupa,Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",90 as Objetivo," + regTotales + "1 as Agrupa,1 as SubAgrupa,'Venta Año Anterior' as Nombre,"
        sql += sqlSum
        sql += "from " + tablaobj + " as obj where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 1 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

  #Venta Año Anterior Actual
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",Objetivo,Agrupa,SubAgrupa,Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",90 as Objetivo," + regTotales + "1 as Agrupa,2 as SubAgrupa,'Venta Año Anterior Actual' as Nombre,"
        sql += sqlSum
        sql += "from " + tablaobj + " as obj where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 2 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

  #Objetivo
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",Objetivo,Agrupa,SubAgrupa,Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",90 as Objetivo," + regTotales + "1 as Agrupa,3 as SubAgrupa,'Objetivo' as Nombre,"
        sql += sqlSum
        sql += "from " + tablaobj + " as obj where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 4 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

  #Venta Real y Objetivo
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",Objetivo,Agrupa,SubAgrupa,Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",90 as Objetivo," + regTotales + "1 as Agrupa,4 as SubAgrupa,'Venta Real' as Nombre,"
        sql += sqlSum
        sql += "from " + tablaobj + " as obj where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 5 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

  #Venta Real
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",Objetivo,Agrupa,SubAgrupa,Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",90 as Objetivo," + regTotales + "1 as Agrupa,9 as SubAgrupa,'Venta Real' as Nombre,"
        sql += sqlSum
        sql += "from " + tablaobj + " as obj where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 6 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

  #Variación vs. Objetivo ($)
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",Objetivo,Agrupa,SubAgrupa,Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",90 as Objetivo," + regTotales + "1 as Agrupa,5 as SubAgrupa,'Variación vs. Objetivo ($)' as Nombre, "
        sql += "(t1.Enero      - t2.Enero     ) as Enero, "
        sql += "(t1.Febrero    - t2.Febrero   ) as Febrero, "
        sql += "(t1.Marzo      - t2.Marzo     ) as Marzo, "
        sql += "(t1.Abril      - t2.Abril     ) as Abril, "
        sql += "(t1.Mayo       - t2.Mayo      ) as Mayo, "
        sql += "(t1.Junio      - t2.Junio     ) as Junio, "
        sql += "(t1.Julio      - t2.Julio     ) as Julio, "
        sql += "(t1.Agosto     - t2.Agosto    ) as Agosto, "
        sql += "(t1.Septiembre - t2.Septiembre) as Septiembre, "
        sql += "(t1.Octubre    - t2.Octubre   ) as Octubre, "
        sql += "(t1.Noviembre  - t2.Noviembre ) as Noviembre, "
        sql += "(t1.Diciembre  - t2.Diciembre ) as Diciembre "
        sql += "FROM " + tablaobj + " as t1 INNER JOIN " + tablaobj + " as t2 "
        sql += "USING(Ano,IdRegion) "
        sql += "WHERE t1.Ano = " + @anosel.to_s + whereRegion1 + " "
        sql += "and t1.IdObjetivo = 90 and t1.IdRegion = " + regTotales + "1 and t1." + idSubAgrupa + " = 4 "
        sql += "and t2.IdObjetivo = 90 and t2.IdRegion = " + regTotales + "1 and t2." + idSubAgrupa + " = 3 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

  #Variación vs. Objetivo (%)
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",Objetivo,Agrupa,SubAgrupa,Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",90 as Objetivo," + regTotales + "1 as Agrupa,6 as SubAgrupa,'Variación vs. Objetivo (%)' as Nombre, "
        sql += "(t1.Enero      / t2.Enero     ) * 100 as Enero, "
        sql += "(t1.Febrero    / t2.Febrero   ) * 100 as Febrero, "
        sql += "(t1.Marzo      / t2.Marzo     ) * 100 as Marzo, "
        sql += "(t1.Abril      / t2.Abril     ) * 100 as Abril, "
        sql += "(t1.Mayo       / t2.Mayo      ) * 100 as Mayo, "
        sql += "(t1.Junio      / t2.Junio     ) * 100 as Junio, "
        sql += "(t1.Julio      / t2.Julio     ) * 100 as Julio, "
        sql += "(t1.Agosto     / t2.Agosto    ) * 100 as Agosto, "
        sql += "(t1.Septiembre / t2.Septiembre) * 100 as Septiembre, "
        sql += "(t1.Octubre    / t2.Octubre   ) * 100 as Octubre, "
        sql += "(t1.Noviembre  / t2.Noviembre ) * 100 as Noviembre, "
        sql += "(t1.Diciembre  / t2.Diciembre ) * 100 as Diciembre "
        sql += "FROM " + tablaobj + " as t1 INNER JOIN " + tablaobj + " as t2 "
        sql += "USING(Ano,IdRegion) "
        sql += "WHERE t1.Ano = " + @anosel.to_s + whereRegion1 + " "
        sql += "and t1.IdObjetivo = 90 and t1.IdRegion = " + regTotales + "1 and t1." + idSubAgrupa + " = 5 "
        sql += "and t2.IdObjetivo = 90 and t2.IdRegion = " + regTotales + "1 and t2." + idSubAgrupa + " = 3 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

  #Crecimiento Real vs. Año Anterior
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",Objetivo,Agrupa,SubAgrupa,Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",90 as Objetivo," + regTotales + "1 as Agrupa,7 as SubAgrupa,'Crecimiento Real vs. Año Anterior' as Nombre, "
        sql += "((t1.Enero      / t2.Enero     ) - 1) * 100 as Enero, "
        sql += "((t1.Febrero    / t2.Febrero   ) - 1) * 100 as Febrero, "
        sql += "((t1.Marzo      / t2.Marzo     ) - 1) * 100 as Marzo, "
        sql += "((t1.Abril      / t2.Abril     ) - 1) * 100 as Abril, "
        sql += "((t1.Mayo       / t2.Mayo      ) - 1) * 100 as Mayo, "
        sql += "((t1.Junio      / t2.Junio     ) - 1) * 100 as Junio, "
        sql += "((t1.Julio      / t2.Julio     ) - 1) * 100 as Julio, "
        sql += "((t1.Agosto     / t2.Agosto    ) - 1) * 100 as Agosto, "
        sql += "((t1.Septiembre / t2.Septiembre) - 1) * 100 as Septiembre, "
        sql += "((t1.Octubre    / t2.Octubre   ) - 1) * 100 as Octubre, "
        sql += "((t1.Noviembre  / t2.Noviembre ) - 1) * 100 as Noviembre, "
        sql += "((t1.Diciembre  / t2.Diciembre ) - 1) * 100 as Diciembre "
        sql += "FROM " + tablaobj + " as t1 INNER JOIN " + tablaobj + " as t2 "
        sql += "USING(Ano,IdRegion) "
        sql += "WHERE t1.Ano = " + @anosel.to_s + whereRegion1 + " "
        sql += "and t1.IdObjetivo = 90 and t1.IdRegion = " + regTotales + "1 and t1." + idSubAgrupa + " = 4 "
        sql += "and t2.IdObjetivo = 90 and t2.IdRegion = " + regTotales + "1 and t2." + idSubAgrupa + " = 2 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

  #Crecimiento Nominal vs. Año Anterior
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",Objetivo,Agrupa,SubAgrupa,Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",90 as Objetivo," + regTotales + "1 as Agrupa,8 as SubAgrupa,'Crecimiento Nominal vs. Año Anterior' as Nombre, "
        sql += "((t1.Enero      / t2.Enero     ) - 1) * 100 as Enero, "
        sql += "((t1.Febrero    / t2.Febrero   ) - 1) * 100 as Febrero, "
        sql += "((t1.Marzo      / t2.Marzo     ) - 1) * 100 as Marzo, "
        sql += "((t1.Abril      / t2.Abril     ) - 1) * 100 as Abril, "
        sql += "((t1.Mayo       / t2.Mayo      ) - 1) * 100 as Mayo, "
        sql += "((t1.Junio      / t2.Junio     ) - 1) * 100 as Junio, "
        sql += "((t1.Julio      / t2.Julio     ) - 1) * 100 as Julio, "
        sql += "((t1.Agosto     / t2.Agosto    ) - 1) * 100 as Agosto, "
        sql += "((t1.Septiembre / t2.Septiembre) - 1) * 100 as Septiembre, "
        sql += "((t1.Octubre    / t2.Octubre   ) - 1) * 100 as Octubre, "
        sql += "((t1.Noviembre  / t2.Noviembre ) - 1) * 100 as Noviembre, "
        sql += "((t1.Diciembre  / t2.Diciembre ) - 1) * 100 as Diciembre "
        sql += "FROM " + tablaobj + " as t1 INNER JOIN " + tablaobj + " as t2 "
        sql += "USING(Ano,IdRegion) "
        sql += "WHERE t1.Ano = " + @anosel.to_s + whereRegion1 + " "
        sql += "and t1.IdObjetivo = 90 and t1.IdRegion = " + regTotales + "1 and t1." + idSubAgrupa + " = 4 "
        sql += "and t2.IdObjetivo = 90 and t2.IdRegion = " + regTotales + "1 and t2." + idSubAgrupa + " = 1 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

        if @region.to_i == 0
          entidad = "IdCiudad"
        else
          entidad = "IdSucursal"
        end
        sql = "SELECT Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre from " + tablaobj + " where Ano = " + @anosel.to_s + " and IdObjetivo = 90 and IdRegion = " + regTotales + "1 and " + entidad + " != 9"
        @totales = @dbEsta.connection.select_all(sql)

  #Supuestos
        @Nombre = "(CASE "
        @Nombre += "WHEN DatoX = 1  THEN 'Indice Nacinal de P.C.'  "
        @Nombre += "WHEN DatoX = 2  THEN '% de Inflacion' "
        @Nombre += "WHEN DatoX = 3  THEN 'Inflacion Acumulada' "
        @Nombre += "WHEN DatoX = 4  THEN 'Inflacion Vs. Año Anterior' "
        @Nombre += "ELSE 'Error' "
        @Nombre += "END)"

        @Dato = "(CASE "
        @Dato += "WHEN DatoX = 1  THEN INPC " 
        @Dato += "WHEN DatoX = 2  THEN PorceInflacionINPC "
        @Dato += "WHEN DatoX = 3  THEN InflacionAcumINPC "
        @Dato += "WHEN DatoX = 4  THEN InflacionVsAnoAntINPC "
        @Dato += "ELSE INPC "
        @Dato += "END)"

        sql = "SELECT " + @Nombre + " as Nombre, "
        sql += "(SELECT " + @Dato + " from indicesobjetivo as t2 Where t2.Ano = Año and t2.mes = 1) as Enero,"
        sql += "(SELECT " + @Dato + " from indicesobjetivo as t2 Where t2.Ano = Año and t2.mes = 2) as Febrero,"
        sql += "(SELECT " + @Dato + " from indicesobjetivo as t2 Where t2.Ano = Año and t2.mes = 3) as Marzo,"
        sql += "(SELECT " + @Dato + " from indicesobjetivo as t2 Where t2.Ano = Año and t2.mes = 4) as Abril,"
        sql += "(SELECT " + @Dato + " from indicesobjetivo as t2 Where t2.Ano = Año and t2.mes = 5) as Mayo,"
        sql += "(SELECT " + @Dato + " from indicesobjetivo as t2 Where t2.Ano = Año and t2.mes = 6) as Junio,"
        sql += "(SELECT " + @Dato + " from indicesobjetivo as t2 Where t2.Ano = Año and t2.mes = 7) as Julio,"
        sql += "(SELECT " + @Dato + " from indicesobjetivo as t2 Where t2.Ano = Año and t2.mes = 8) as Agosto,"
        sql += "(SELECT " + @Dato + " from indicesobjetivo as t2 Where t2.Ano = Año and t2.mes = 9) as Septiembre,"
        sql += "(SELECT " + @Dato + " from indicesobjetivo as t2 Where t2.Ano = Año and t2.mes = 10) as Octubre,"
        sql += "(SELECT " + @Dato + " from indicesobjetivo as t2 Where t2.Ano = Año and t2.mes = 11) as Noviembre,"
        sql += "(SELECT " + @Dato + " from indicesobjetivo as t2 Where t2.Ano = Año and t2.mes = 12) as Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT Ano as Año,Mes as DatoX FROM indicesobjetivo where Ano = " + @anosel.to_s + " limit 4 "
        sql += ") tmp"
        @supuestos = @dbEsta.connection.select_all(sql)
#      else

  #ACUMULADOS
        acumEne = "(Enero)"
        acumFeb = "(Enero + Febrero)"
        acumMar = "(Enero + Febrero + Marzo)"
        acumAbr = "(Enero + Febrero + Marzo + Abril)"
        acumMay = "(Enero + Febrero + Marzo + Abril + Mayo)"
        acumJun = "(Enero + Febrero + Marzo + Abril + Mayo + Junio)"
        acumJul = "(Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio)"
        acumAgo = "(Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio + Agosto)"
        acumSep = "(Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio + Agosto + Septiembre)"
        acumOct = "(Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio + Agosto + Septiembre + Octubre)"
        acumNov = "(Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio + Agosto + Septiembre + Octubre + Noviembre)"
        acumDic = "(Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio + Agosto + Septiembre + Octubre + Noviembre + Diciembre)"

        sqlAcum = "ROUND(Enero,2) as Enero,"
        sqlAcum += "ROUND(Enero + Febrero,2) as Febrero,"
        sqlAcum += "ROUND(Enero + Febrero + Marzo,2) as Marzo,"
        sqlAcum += "ROUND(Enero + Febrero + Marzo + Abril,2) as Abril,"
        sqlAcum += "ROUND(Enero + Febrero + Marzo + Abril + Mayo,2) as Mayo,"
        sqlAcum += "ROUND(Enero + Febrero + Marzo + Abril + Mayo + Junio,2) as Junio,"
        sqlAcum += "ROUND(Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio,2) as Julio,"
        sqlAcum += "ROUND(Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio + Agosto,2) as Agosto,"
        sqlAcum += "ROUND(Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio + Agosto + Septiembre,2) as Septiembre,"
        sqlAcum += "ROUND(Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio + Agosto + Septiembre + Octubre,2) as Octubre,"
        sqlAcum += "ROUND(Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio + Agosto + Septiembre + Octubre + Noviembre,2) as Noviembre,"
        sqlAcum += "ROUND(Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio + Agosto + Septiembre + Octubre + Noviembre + Diciembre,2) as Diciembre "

  #Venta Año Anterior
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",21,IdRegion," + idSubAgrupa + ",Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",21,IdRegion," + idSubAgrupa + ",Nombre, "
        sql += sqlAcum
        sql += "FROM " + tablaobj + " as obj where Ano = " + @anosel.to_s + " and IdObjetivo = 1 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

        sql = "SELECT Nombre as " + nomSubAgrupa + ",Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre from " + tablaobj + " where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 21"
        @antvtanetaacum = @dbEsta.connection.select_all(sql)

  #Venta Año Anterior Actual
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",22,IdRegion," + idSubAgrupa + ",Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",22,IdRegion," + idSubAgrupa + ",Nombre, "
        sql += sqlAcum
        sql += "FROM " + tablaobj + " as obj where Ano = " + @anosel.to_s + " and IdObjetivo = 2 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

        sql = "SELECT Nombre as " + nomSubAgrupa + ",Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre from " + tablaobj + " where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 22"
        @antvtanetaactacum = @dbEsta.connection.select_all(sql)

  #Objetivo
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",23,IdRegion," + idSubAgrupa + ",Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",23,IdRegion," + idSubAgrupa + ",Nombre, "
        sql += sqlAcum
        sql += "FROM " + tablaobj + " as obj where Ano = " + @anosel.to_s + " and IdObjetivo = 4 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

        sql = "SELECT Nombre as " + nomSubAgrupa + ",Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre from " + tablaobj + " where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 23"
        @objetivoacum = @dbEsta.connection.select_all(sql)

  #VentaReal
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",24,IdRegion," + idSubAgrupa + ",Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",24,IdRegion," + idSubAgrupa + ",Nombre, "
        sql += sqlAcum
        sql += "FROM " + tablaobj + " as obj where Ano = " + @anosel.to_s + " and IdObjetivo = 5 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

        sql = "SELECT Nombre as " + nomSubAgrupa + ",Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre from " + tablaobj + " where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 24"
        @vtanetarealacum = @dbEsta.connection.select_all(sql)

  #Variación vs. Objetivo ($)
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",25,IdRegion," + idSubAgrupa + ",Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",25,t1.IdRegion,t1." + idSubAgrupa + ",t1.Nombre, "
        sql += "(t1.Enero      - t2.Enero     ) as Enero, "
        sql += "(t1.Febrero    - t2.Febrero   ) as Febrero, "
        sql += "(t1.Marzo      - t2.Marzo     ) as Marzo, "
        sql += "(t1.Abril      - t2.Abril     ) as Abril, "
        sql += "(t1.Mayo       - t2.Mayo      ) as Mayo, "
        sql += "(t1.Junio      - t2.Junio     ) as Junio, "
        sql += "(t1.Julio      - t2.Julio     ) as Julio, "
        sql += "(t1.Agosto     - t2.Agosto    ) as Agosto, "
        sql += "(t1.Septiembre - t2.Septiembre) as Septiembre, "
        sql += "(t1.Octubre    - t2.Octubre   ) as Octubre, "
        sql += "(t1.Noviembre  - t2.Noviembre ) as Noviembre, "
        sql += "(t1.Diciembre  - t2.Diciembre ) as Diciembre "
        sql += "FROM " + tablaobj + " as t1 INNER JOIN " + tablaobj + " as t2 "
        sql += "USING(Ano,IdRegion," + idSubAgrupa + ") "
        sql += "WHERE t1.Ano = " + @anosel.to_s + whereRegion + " "
        sql += "and t1.IdObjetivo = 24 "
        sql += "and t2.IdObjetivo = 23 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

        sql = "SELECT Nombre as " + nomSubAgrupa + ",Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre from " + tablaobj + " where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 25"
        @varvsobjetivoacum = @dbEsta.connection.select_all(sql)

  #Variación vs. Objetivo (%)
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",26,IdRegion," + idSubAgrupa + ",Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",26,t1.IdRegion,t1." + idSubAgrupa + ",t1.Nombre, "
        sql += "COALESCE((t1.Enero      / t2.Enero     ) * 100,0) as Enero, "
        sql += "COALESCE((t1.Febrero    / t2.Febrero   ) * 100,0) as Febrero, "
        sql += "COALESCE((t1.Marzo      / t2.Marzo     ) * 100,0) as Marzo, "
        sql += "COALESCE((t1.Abril      / t2.Abril     ) * 100,0) as Abril, "
        sql += "COALESCE((t1.Mayo       / t2.Mayo      ) * 100,0) as Mayo, "
        sql += "COALESCE((t1.Junio      / t2.Junio     ) * 100,0) as Junio, "
        sql += "COALESCE((t1.Julio      / t2.Julio     ) * 100,0) as Julio, "
        sql += "COALESCE((t1.Agosto     / t2.Agosto    ) * 100,0) as Agosto, "
        sql += "COALESCE((t1.Septiembre / t2.Septiembre) * 100,0) as Septiembre, "
        sql += "COALESCE((t1.Octubre    / t2.Octubre   ) * 100,0) as Octubre, "
        sql += "COALESCE((t1.Noviembre  / t2.Noviembre ) * 100,0) as Noviembre, "
        sql += "COALESCE((t1.Diciembre  / t2.Diciembre ) * 100,0) as Diciembre "
        sql += "FROM " + tablaobj + " as t1 INNER JOIN " + tablaobj + " as t2 "
        sql += "USING(Ano,IdRegion," + idSubAgrupa + ") "
        sql += "WHERE t1.Ano = " + @anosel.to_s + whereRegion + " "
        sql += "and t1.IdObjetivo = 25 "
        sql += "and t2.IdObjetivo = 23 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

        sql = "SELECT Nombre as " + nomSubAgrupa + ",Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre from " + tablaobj + " where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 26"
        @varvsobjporceacum = @dbEsta.connection.select_all(sql)

  #Crecimiento Real vs. Año Anterior
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",27,IdRegion," + idSubAgrupa + ",Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",27,t1.IdRegion,t1." + idSubAgrupa + ",t1.Nombre, "
        sql += "COALESCE(((t1.Enero      / t2.Enero     ) - 1) * 100,0) as Enero, "
        sql += "COALESCE(((t1.Febrero    / t2.Febrero   ) - 1) * 100,0) as Febrero, "
        sql += "COALESCE(((t1.Marzo      / t2.Marzo     ) - 1) * 100,0) as Marzo, "
        sql += "COALESCE(((t1.Abril      / t2.Abril     ) - 1) * 100,0) as Abril, "
        sql += "COALESCE(((t1.Mayo       / t2.Mayo      ) - 1) * 100,0) as Mayo, "
        sql += "COALESCE(((t1.Junio      / t2.Junio     ) - 1) * 100,0) as Junio, "
        sql += "COALESCE(((t1.Julio      / t2.Julio     ) - 1) * 100,0) as Julio, "
        sql += "COALESCE(((t1.Agosto     / t2.Agosto    ) - 1) * 100,0) as Agosto, "
        sql += "COALESCE(((t1.Septiembre / t2.Septiembre) - 1) * 100,0) as Septiembre, "
        sql += "COALESCE(((t1.Octubre    / t2.Octubre   ) - 1) * 100,0) as Octubre, "
        sql += "COALESCE(((t1.Noviembre  / t2.Noviembre ) - 1) * 100,0) as Noviembre, "
        sql += "COALESCE(((t1.Diciembre  / t2.Diciembre ) - 1) * 100,0) as Diciembre "
        sql += "FROM " + tablaobj + " as t1 INNER JOIN " + tablaobj + " as t2 "
        sql += "USING(Ano,IdRegion," + idSubAgrupa + ") "
        sql += "WHERE t1.Ano = " + @anosel.to_s + whereRegion + " "
        sql += "and t1.IdObjetivo = 24 "
        sql += "and t2.IdObjetivo = 22 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

        sql = "SELECT Nombre as " + nomSubAgrupa + ",Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre from " + tablaobj + " where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 27"
        @crecirealvsanoantacum = @dbEsta.connection.select_all(sql)

  #Crecimiento Nominal vs. Año Anterior
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",28,IdRegion," + idSubAgrupa + ",Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",28,t1.IdRegion,t1." + idSubAgrupa + ",t1.Nombre, "
        sql += "COALESCE(((t1.Enero      / t2.Enero     ) - 1) * 100,0) as Enero, "
        sql += "COALESCE(((t1.Febrero    / t2.Febrero   ) - 1) * 100,0) as Febrero, "
        sql += "COALESCE(((t1.Marzo      / t2.Marzo     ) - 1) * 100,0) as Marzo, "
        sql += "COALESCE(((t1.Abril      / t2.Abril     ) - 1) * 100,0) as Abril, "
        sql += "COALESCE(((t1.Mayo       / t2.Mayo      ) - 1) * 100,0) as Mayo, "
        sql += "COALESCE(((t1.Junio      / t2.Junio     ) - 1) * 100,0) as Junio, "
        sql += "COALESCE(((t1.Julio      / t2.Julio     ) - 1) * 100,0) as Julio, "
        sql += "COALESCE(((t1.Agosto     / t2.Agosto    ) - 1) * 100,0) as Agosto, "
        sql += "COALESCE(((t1.Septiembre / t2.Septiembre) - 1) * 100,0) as Septiembre, "
        sql += "COALESCE(((t1.Octubre    / t2.Octubre   ) - 1) * 100,0) as Octubre, "
        sql += "COALESCE(((t1.Noviembre  / t2.Noviembre ) - 1) * 100,0) as Noviembre, "
        sql += "COALESCE(((t1.Diciembre  / t2.Diciembre ) - 1) * 100,0) as Diciembre "
        sql += "FROM " + tablaobj + " as t1 INNER JOIN " + tablaobj + " as t2 "
        sql += "USING(Ano,IdRegion," + idSubAgrupa + ") "
        sql += "WHERE t1.Ano = " + @anosel.to_s + whereRegion + " "
        sql += "and t1.IdObjetivo = 24 "
        sql += "and t2.IdObjetivo = 21 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

        sql = "SELECT Nombre as " + nomSubAgrupa + ",Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre from " + tablaobj + " where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 28"
        @crecinomivsanoantacum = @dbEsta.connection.select_all(sql)

        puts "*" * 1000
        puts regTotales
  #ACUMULADOS EMPRESA
        #Venta Año Anterior
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",Objetivo,Agrupa,SubAgrupa,Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",90 as Objetivo," + regTotales + "2 as Agrupa,1 as SubAgrupa,'Venta Año Anterior' as Nombre,"
        sql += sqlSum
        sql += "from " + tablaobj + " as obj where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 21 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        begin 
          @dbEsta.connection.execute(sql)
        rescue 
          return
        end


        #Venta Año Ant. Precios Actuales
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",Objetivo,Agrupa,SubAgrupa,Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",90 as Objetivo," + regTotales + "2 as Agrupa,2 as SubAgrupa,'Venta Año Ant. Precios Actuales' as Nombre,"
        sql += sqlSum
        sql += "from " + tablaobj + " as obj where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 22 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

        #Objetivo
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",Objetivo,Agrupa,SubAgrupa,Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",90 as Objetivo," + regTotales + "2 as Agrupa,3 as SubAgrupa,'Objetivo' as Nombre,"
        sql += sqlSum
        sql += "from " + tablaobj + " as obj where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 23 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

        #Venta Real
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",Objetivo,Agrupa,SubAgrupa,Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",90 as Objetivo," + regTotales + "2 as Agrupa,4 as SubAgrupa,'Venta Real' as Nombre,"
        sql += sqlSum
        sql += "from " + tablaobj + " as obj where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 24 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

        #Variación vs. Objetivo ($)
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",Objetivo,Agrupa,SubAgrupa,Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",90 as Objetivo," + regTotales + "2 as Agrupa,5 as SubAgrupa,'Variación vs. Objetivo ($)' as Nombre,"
        sql += sqlSum
        sql += "from " + tablaobj + " as obj where Ano = " + @anosel.to_s + whereRegion + " and IdObjetivo = 25 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

  #Variación vs. Objetivo (%)
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",90,IdRegion," + idSubAgrupa + ",Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",90," + regTotales + "2 as IdRegion,6 as " + idSubAgrupa + ",'Variación vs. Objetivo (%)' as Nombre, "
        sql += "(t1.Enero      / t2.Enero     ) * 100 as Enero, "
        sql += "(t1.Febrero    / t2.Febrero   ) * 100 as Febrero, "
        sql += "(t1.Marzo      / t2.Marzo     ) * 100 as Marzo, "
        sql += "(t1.Abril      / t2.Abril     ) * 100 as Abril, "
        sql += "(t1.Mayo       / t2.Mayo      ) * 100 as Mayo, "
        sql += "(t1.Junio      / t2.Junio     ) * 100 as Junio, "
        sql += "(t1.Julio      / t2.Julio     ) * 100 as Julio, "
        sql += "(t1.Agosto     / t2.Agosto    ) * 100 as Agosto, "
        sql += "(t1.Septiembre / t2.Septiembre) * 100 as Septiembre, "
        sql += "(t1.Octubre    / t2.Octubre   ) * 100 as Octubre, "
        sql += "(t1.Noviembre  / t2.Noviembre ) * 100 as Noviembre, "
        sql += "(t1.Diciembre  / t2.Diciembre ) * 100 as Diciembre "
        sql += "FROM " + tablaobj + " as t1 INNER JOIN " + tablaobj + " as t2 "
        sql += "USING(Ano,IdRegion) "
        sql += "WHERE t1.Ano = " + @anosel.to_s + whereRegion2 + " "
        sql += "and t1.IdObjetivo = 90 and t1.IdRegion = " + regTotales + "2 and t1." + idSubAgrupa + " = 5 "
        sql += "and t2.IdObjetivo = 90 and t2.IdRegion = " + regTotales + "2 and t2." + idSubAgrupa + " = 3 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

  #Crecimiento Real vs. Año Anterior
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",90,IdRegion," + idSubAgrupa + ",Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",90," + regTotales + "2 as IdRegion,7 as " + idSubAgrupa + ",'Crecimiento Real vs. Año Anterior' as Nombre, "
        sql += "((t1.Enero      / t2.Enero     ) - 1) * 100 as Enero, "
        sql += "((t1.Febrero    / t2.Febrero   ) - 1) * 100 as Febrero, "
        sql += "((t1.Marzo      / t2.Marzo     ) - 1) * 100 as Marzo, "
        sql += "((t1.Abril      / t2.Abril     ) - 1) * 100 as Abril, "
        sql += "((t1.Mayo       / t2.Mayo      ) - 1) * 100 as Mayo, "
        sql += "((t1.Junio      / t2.Junio     ) - 1) * 100 as Junio, "
        sql += "((t1.Julio      / t2.Julio     ) - 1) * 100 as Julio, "
        sql += "((t1.Agosto     / t2.Agosto    ) - 1) * 100 as Agosto, "
        sql += "((t1.Septiembre / t2.Septiembre) - 1) * 100 as Septiembre, "
        sql += "((t1.Octubre    / t2.Octubre   ) - 1) * 100 as Octubre, "
        sql += "((t1.Noviembre  / t2.Noviembre ) - 1) * 100 as Noviembre, "
        sql += "((t1.Diciembre  / t2.Diciembre ) - 1) * 100 as Diciembre "
        sql += "FROM " + tablaobj + " as t1 INNER JOIN " + tablaobj + " as t2 "
        sql += "USING(Ano,IdRegion) "
        sql += "WHERE t1.Ano = " + @anosel.to_s + whereRegion2 + " "
        sql += "and t1.IdObjetivo = 90 and t1.IdRegion = " + regTotales + "2 and t1." + idSubAgrupa + " = 4 "
        sql += "and t2.IdObjetivo = 90 and t2.IdRegion = " + regTotales + "2 and t2." + idSubAgrupa + " = 2 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

  #Crecimiento Nominal vs. Año Anterior
        sql = "INSERT INTO " + tablaobj + " "
        sql += "SELECT " + @anosel.to_s + ",90,IdRegion," + idSubAgrupa + ",Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre "
        sql += "FROM "
        sql += "( "
        sql += "SELECT " + @anosel.to_s + ",90," + regTotales + "2 as IdRegion,8 as " + idSubAgrupa + ",'Crecimiento Nominal vs. Año Anterior' as Nombre, "
        sql += "((t1.Enero      / t2.Enero     ) - 1) * 100 as Enero, "
        sql += "((t1.Febrero    / t2.Febrero   ) - 1) * 100 as Febrero, "
        sql += "((t1.Marzo      / t2.Marzo     ) - 1) * 100 as Marzo, "
        sql += "((t1.Abril      / t2.Abril     ) - 1) * 100 as Abril, "
        sql += "((t1.Mayo       / t2.Mayo      ) - 1) * 100 as Mayo, "
        sql += "((t1.Junio      / t2.Junio     ) - 1) * 100 as Junio, "
        sql += "((t1.Julio      / t2.Julio     ) - 1) * 100 as Julio, "
        sql += "((t1.Agosto     / t2.Agosto    ) - 1) * 100 as Agosto, "
        sql += "((t1.Septiembre / t2.Septiembre) - 1) * 100 as Septiembre, "
        sql += "((t1.Octubre    / t2.Octubre   ) - 1) * 100 as Octubre, "
        sql += "((t1.Noviembre  / t2.Noviembre ) - 1) * 100 as Noviembre, "
        sql += "((t1.Diciembre  / t2.Diciembre ) - 1) * 100 as Diciembre "
        sql += "FROM " + tablaobj + " as t1 INNER JOIN " + tablaobj + " as t2 "
        sql += "USING(Ano,IdRegion) "
        sql += "WHERE t1.Ano = " + @anosel.to_s + whereRegion2 + " "
        sql += "and t1.IdObjetivo = 90 and t1.IdRegion = " + regTotales + "2 and t1." + idSubAgrupa + " = 4 "
        sql += "and t2.IdObjetivo = 90 and t2.IdRegion = " + regTotales + "2 and t2." + idSubAgrupa + " = 1 "
        sql += ") obj "
        sql += "ON DUPLICATE KEY UPDATE "
        sql += sqlUpdate
        @dbEsta.connection.execute(sql)

        sql = "SELECT Nombre,Enero,Febrero,Marzo,Abril,Mayo,Junio,Julio,Agosto,Septiembre,Octubre,Noviembre,Diciembre from " + tablaobj + " where Ano = " + @anosel.to_s + " and IdObjetivo = 90 and IdRegion = " + regTotales + "2"
        @totalesacum = @dbEsta.connection.select_all(sql)

        if @nivelopc == "CreciEspSuc" || @nivelopc == "CreciEspCd"

#Sucursal
          query_objetivos_reg_suc(1,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsucene = @dbEsta.connection.select_all(@sqlsuc)

          query_objetivos_reg_suc(2,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsucfeb = @dbEsta.connection.select_all(@sqlsuc)

          query_objetivos_reg_suc(3,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsucmar = @dbEsta.connection.select_all(@sqlsuc)

          query_objetivos_reg_suc(4,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsucabr = @dbEsta.connection.select_all(@sqlsuc)

          query_objetivos_reg_suc(5,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsucmay = @dbEsta.connection.select_all(@sqlsuc)

          query_objetivos_reg_suc(6,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsucjun = @dbEsta.connection.select_all(@sqlsuc)

          query_objetivos_reg_suc(7,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsucjul = @dbEsta.connection.select_all(@sqlsuc)

          query_objetivos_reg_suc(8,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsucago = @dbEsta.connection.select_all(@sqlsuc)

          query_objetivos_reg_suc(9,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsucsep = @dbEsta.connection.select_all(@sqlsuc)

          query_objetivos_reg_suc(10,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsucoct = @dbEsta.connection.select_all(@sqlsuc)

          query_objetivos_reg_suc(11,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsucnov = @dbEsta.connection.select_all(@sqlsuc)

          query_objetivos_reg_suc(12,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsucdic = @dbEsta.connection.select_all(@sqlsuc)

    #Totales
          query_objetivos_reg_tot_suc(1,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsuctotene = @dbEsta.connection.select_all(@sqlsuc)

          query_objetivos_reg_tot_suc(2,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsuctotfeb = @dbEsta.connection.select_all(@sqlsuc)

          query_objetivos_reg_tot_suc(3,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsuctotmar = @dbEsta.connection.select_all(@sqlsuc)

          query_objetivos_reg_tot_suc(4,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsuctotabr = @dbEsta.connection.select_all(@sqlsuc)

          query_objetivos_reg_tot_suc(5,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsuctotmay = @dbEsta.connection.select_all(@sqlsuc)

          query_objetivos_reg_tot_suc(6,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsuctotjun = @dbEsta.connection.select_all(@sqlsuc)

          query_objetivos_reg_tot_suc(7,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsuctotjul = @dbEsta.connection.select_all(@sqlsuc)

          query_objetivos_reg_tot_suc(8,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsuctotago = @dbEsta.connection.select_all(@sqlsuc)

          query_objetivos_reg_tot_suc(9,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsuctotsep = @dbEsta.connection.select_all(@sqlsuc)

          query_objetivos_reg_tot_suc(10,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsuctotoct = @dbEsta.connection.select_all(@sqlsuc)

          query_objetivos_reg_tot_suc(11,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsuctotnov = @dbEsta.connection.select_all(@sqlsuc)

          query_objetivos_reg_tot_suc(12,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objsuctotdic = @dbEsta.connection.select_all(@sqlsuc)

  #Ciudad
          query_objetivos_reg_cd(1,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdene = @dbEsta.connection.select_all(@sqlcd)

          query_objetivos_reg_cd(2,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdfeb = @dbEsta.connection.select_all(@sqlcd)

          query_objetivos_reg_cd(3,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdmar = @dbEsta.connection.select_all(@sqlcd)

          query_objetivos_reg_cd(4,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdabr = @dbEsta.connection.select_all(@sqlcd)

          query_objetivos_reg_cd(5,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdmay = @dbEsta.connection.select_all(@sqlcd)

          query_objetivos_reg_cd(6,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdjun = @dbEsta.connection.select_all(@sqlcd)

          query_objetivos_reg_cd(7,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdjul = @dbEsta.connection.select_all(@sqlcd)

          query_objetivos_reg_cd(8,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdago = @dbEsta.connection.select_all(@sqlcd)

          query_objetivos_reg_cd(9,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdsep = @dbEsta.connection.select_all(@sqlcd)

          query_objetivos_reg_cd(10,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdoct = @dbEsta.connection.select_all(@sqlcd)

          query_objetivos_reg_cd(11,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdnov = @dbEsta.connection.select_all(@sqlcd)

          query_objetivos_reg_cd(12,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcddic = @dbEsta.connection.select_all(@sqlcd)

      #Totales
          query_objetivos_reg_tot_cd(1,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdtotene = @dbEsta.connection.select_all(@sqlcd)

          query_objetivos_reg_tot_cd(2,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdtotfeb = @dbEsta.connection.select_all(@sqlcd)

          query_objetivos_reg_tot_cd(3,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdtotmar = @dbEsta.connection.select_all(@sqlcd)

          query_objetivos_reg_tot_cd(4,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdtotabr = @dbEsta.connection.select_all(@sqlcd)

          query_objetivos_reg_tot_cd(5,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdtotmay = @dbEsta.connection.select_all(@sqlcd)

          query_objetivos_reg_tot_cd(6,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdtotjun = @dbEsta.connection.select_all(@sqlcd)

          query_objetivos_reg_tot_cd(7,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdtotjul = @dbEsta.connection.select_all(@sqlcd)

          query_objetivos_reg_tot_cd(8,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdtotago = @dbEsta.connection.select_all(@sqlcd)

          query_objetivos_reg_tot_cd(9,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdtotsep = @dbEsta.connection.select_all(@sqlcd)

          query_objetivos_reg_tot_cd(10,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdtotoct = @dbEsta.connection.select_all(@sqlcd)

          query_objetivos_reg_tot_cd(11,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdtotnov = @dbEsta.connection.select_all(@sqlcd)

          query_objetivos_reg_tot_cd(12,@anosel.to_s,@anoant.to_s,@region.to_s,@nomDbComun.to_s)
          @objcdtotdic = @dbEsta.connection.select_all(@sqlcd)

        end

#      end
    end

    sql = "SELECT DISTINCT left(mes,4) as Año from htotalmes where left(mes,4) >= 2005 ORDER BY Año DESC"
    @tablaanosel = @dbEsta.connection.select_all(sql)

    sql = "SELECT IdAgrupa,Nombre FROM agrupa where Objetivo = 1 order by NumOrd"
    @tablaregion = @dbComun.connection.select_all(sql)

    if @continua > 0    
      respond_to do |format|
        format.html
#        format.csv do 
#            out_arr = []
#            out_arr.push("Ciudad")
#            @vtanetareal.each do |m|
#                out_arr.push("#{m['Ciudad']}")
#            end
#            csv_file = "/tmp/objetivo_1111.csv"
#            dump_to_file(csv_file,out_arr.join("\n"))
#            send_file csv_file
#            return
#        end
      end
    end    

  end

  def calc_objetivos_analisis
    @continua = 0

    @anosel = params[:anosel].to_s if params.has_key?(:anosel)
    @region = params[:region].to_s if params.has_key?(:region)
    @nivelopc = params[:nivelopc].to_s if params.has_key?(:nivelopc)
    @titulo = ""
    @nomRegion = ""

    if @anosel.to_i > 0
      @continua = 1
    end

    if @continua > 0
      @anoant = @anosel.to_i - 1

  #CONTRIBUCION EN VENTAS    
      if @nivelopc == "ContriReg"

        query_contribucion_reg(1,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
        @contriene = @dbEsta.connection.select_all(@sqlreg)

        query_contribucion_reg(2,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
        @contrifeb = @dbEsta.connection.select_all(@sqlreg)

        query_contribucion_reg(3,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
        @contrimar = @dbEsta.connection.select_all(@sqlreg)

        query_contribucion_reg(4,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
        @contriabr = @dbEsta.connection.select_all(@sqlreg)

        query_contribucion_reg(5,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
        @contrimay = @dbEsta.connection.select_all(@sqlreg)

        query_contribucion_reg(6,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
        @contrijun = @dbEsta.connection.select_all(@sqlreg)

        query_contribucion_reg(7,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
        @contrijul = @dbEsta.connection.select_all(@sqlreg)

        query_contribucion_reg(8,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
        @contriago = @dbEsta.connection.select_all(@sqlreg)

        query_contribucion_reg(9,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
        @contrisep = @dbEsta.connection.select_all(@sqlreg)

        query_contribucion_reg(10,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
        @contrioct = @dbEsta.connection.select_all(@sqlreg)

        query_contribucion_reg(11,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
        @contrinov = @dbEsta.connection.select_all(@sqlreg)

        query_contribucion_reg(12,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
        @contridic = @dbEsta.connection.select_all(@sqlreg)

      else
        if @nivelopc == "ContriCd"
          query_contribucion_cd(1,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
          @contriene = @dbEsta.connection.select_all(@sqlcd)

          query_contribucion_cd(2,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
          @contrifeb = @dbEsta.connection.select_all(@sqlcd)

          query_contribucion_cd(3,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
          @contrimar = @dbEsta.connection.select_all(@sqlcd)

          query_contribucion_cd(4,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
          @contriabr = @dbEsta.connection.select_all(@sqlcd)

          query_contribucion_cd(5,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
          @contrimay = @dbEsta.connection.select_all(@sqlcd)

          query_contribucion_cd(6,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
          @contrijun = @dbEsta.connection.select_all(@sqlcd)

          query_contribucion_cd(7,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
          @contrijul = @dbEsta.connection.select_all(@sqlcd)

          query_contribucion_cd(8,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
          @contriago = @dbEsta.connection.select_all(@sqlcd)

          query_contribucion_cd(9,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
          @contrisep = @dbEsta.connection.select_all(@sqlcd)

          query_contribucion_cd(10,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
          @contrioct = @dbEsta.connection.select_all(@sqlcd)

          query_contribucion_cd(11,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
          @contrinov = @dbEsta.connection.select_all(@sqlcd)

          query_contribucion_cd(12,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
          @contridic = @dbEsta.connection.select_all(@sqlcd)

        else
          if @nivelopc == "ContriSuc"

            query_contribucion_suc(1,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
            @contriene = @dbEsta.connection.select_all(@sqlsuc)

            query_contribucion_suc(2,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
            @contrifeb = @dbEsta.connection.select_all(@sqlsuc)

            query_contribucion_suc(3,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
            @contrimar = @dbEsta.connection.select_all(@sqlsuc)

            query_contribucion_suc(4,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
            @contriabr = @dbEsta.connection.select_all(@sqlsuc)

            query_contribucion_suc(5,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
            @contrimay = @dbEsta.connection.select_all(@sqlsuc)

            query_contribucion_suc(6,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
            @contrijun = @dbEsta.connection.select_all(@sqlsuc)

            query_contribucion_suc(7,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
            @contrijul = @dbEsta.connection.select_all(@sqlsuc)

            query_contribucion_suc(8,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
            @contriago = @dbEsta.connection.select_all(@sqlsuc)

            query_contribucion_suc(9,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
            @contrisep = @dbEsta.connection.select_all(@sqlsuc)

            query_contribucion_suc(10,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
            @contrioct = @dbEsta.connection.select_all(@sqlsuc)

            query_contribucion_suc(11,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
            @contrinov = @dbEsta.connection.select_all(@sqlsuc)

            query_contribucion_suc(12,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
            @contridic = @dbEsta.connection.select_all(@sqlsuc)

          else
    #GLOBAL OBJETIVOS        
            if @nivelopc == "GlobalVsObj"
              if @region.to_i == 0

                query_global_ventas_reg(1,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjene = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_reg(1,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjenet = @dbEsta.connection.select_all(@sql)

                query_global_ventas_reg(2,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjfeb = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_reg(2,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjfebt = @dbEsta.connection.select_all(@sql)

                query_global_ventas_reg(3,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjmar = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_reg(3,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjmart = @dbEsta.connection.select_all(@sql)

                query_global_ventas_reg(4,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjabr = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_reg(4,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjabrt = @dbEsta.connection.select_all(@sql)

                query_global_ventas_reg(5,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjmay = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_reg(5,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjmayt = @dbEsta.connection.select_all(@sql)

                query_global_ventas_reg(6,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjjun = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_reg(6,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjjunt = @dbEsta.connection.select_all(@sql)

                query_global_ventas_reg(7,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjjul = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_reg(7,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjjult = @dbEsta.connection.select_all(@sql)

                query_global_ventas_reg(8,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjago = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_reg(8,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjagot = @dbEsta.connection.select_all(@sql)

                query_global_ventas_reg(9,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjsep = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_reg(9,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjsept = @dbEsta.connection.select_all(@sql)

                query_global_ventas_reg(10,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjoct = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_reg(10,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjoctt = @dbEsta.connection.select_all(@sql)

                query_global_ventas_reg(11,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjnov = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_reg(11,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjnovt = @dbEsta.connection.select_all(@sql)

                query_global_ventas_reg(12,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjdic = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_reg(12,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjdict = @dbEsta.connection.select_all(@sql)

                query_global_ventas_anual_reg(@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjanual = @dbEsta.connection.select_all(@sql)
                query_global_ventas_anual_total_reg(@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjanualt = @dbEsta.connection.select_all(@sql)
              else

                query_global_ventas_cd(1,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjene = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_cd(1,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjenet = @dbEsta.connection.select_all(@sql)

                query_global_ventas_cd(2,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjfeb = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_cd(2,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjfebt = @dbEsta.connection.select_all(@sql)

                query_global_ventas_cd(3,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjmar = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_cd(3,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjmart = @dbEsta.connection.select_all(@sql)

                query_global_ventas_cd(4,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjabr = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_cd(4,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjabrt = @dbEsta.connection.select_all(@sql)

                query_global_ventas_cd(5,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjmay = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_cd(5,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjmayt = @dbEsta.connection.select_all(@sql)

                query_global_ventas_cd(6,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjjun = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_cd(6,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjjunt = @dbEsta.connection.select_all(@sql)

                query_global_ventas_cd(7,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjjul = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_cd(7,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjjult = @dbEsta.connection.select_all(@sql)

                query_global_ventas_cd(8,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjago = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_cd(8,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjagot = @dbEsta.connection.select_all(@sql)

                query_global_ventas_cd(9,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjsep = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_cd(9,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjsept = @dbEsta.connection.select_all(@sql)

                query_global_ventas_cd(10,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjoct = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_cd(10,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjoctt = @dbEsta.connection.select_all(@sql)

                query_global_ventas_cd(11,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjnov = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_cd(11,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjnovt = @dbEsta.connection.select_all(@sql)

                query_global_ventas_cd(12,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjdic = @dbEsta.connection.select_all(@sql)
                query_global_ventas_total_cd(12,@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjdict = @dbEsta.connection.select_all(@sql)

                query_global_ventas_anual_cd(@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjanual = @dbEsta.connection.select_all(@sql)
                query_global_ventas_anual_total_cd(@anosel.to_s,@region.to_s,@nomDbComun.to_s)
                @globobjanualt = @dbEsta.connection.select_all(@sql)

              end

            else

      #GLOBAL VENTAS CONSOLIDADO              
              anual = "Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio + Agosto + Septiembre + Octubre + Noviembre + Diciembre"

              sql = "SELECT RIGHT(MAX(mes),2) as mes from htotalmes where mes like '" + @anosel.to_s + "%'"
              tabmesproc = @dbEsta.connection.select_all(sql)
              mesproc = "00"
              tabmesproc.each do |a| 
                mesproc = a['mes']
              end 
#              raise mesproc

              anualn = "Enero" if mesproc.to_i == 1
              anualn = "Enero + Febrero" if mesproc.to_i == 2
              anualn = "Enero + Febrero + Marzo" if mesproc.to_i == 3
              anualn = "Enero + Febrero + Marzo + Abril" if mesproc.to_i == 4
              anualn = "Enero + Febrero + Marzo + Abril + Mayo" if mesproc.to_i == 5
              anualn = "Enero + Febrero + Marzo + Abril + Mayo + Junio" if mesproc.to_i == 6
              anualn = "Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio" if mesproc.to_i == 7
              anualn = "Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio + Agosto" if mesproc.to_i == 8
              anualn = "Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio + Agosto + Septiembre" if mesproc.to_i == 9
              anualn = "Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio + Agosto + Septiembre + Octubre" if mesproc.to_i == 10
              anualn = "Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio + Agosto + Septiembre + Octubre + Noviembre" if mesproc.to_i == 11
              anualn = "Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio + Agosto + Septiembre + Octubre + Noviembre + Diciembre" if mesproc.to_i == 12

              anual1 = "t1.Enero" if mesproc.to_i == 1
              anual1 = "t1.Enero + t1.Febrero" if mesproc.to_i == 2
              anual1 = "t1.Enero + t1.Febrero + t1.Marzo" if mesproc.to_i == 3
              anual1 = "t1.Enero + t1.Febrero + t1.Marzo + t1.Abril" if mesproc.to_i == 4
              anual1 = "t1.Enero + t1.Febrero + t1.Marzo + t1.Abril + t1.Mayo" if mesproc.to_i == 5
              anual1 = "t1.Enero + t1.Febrero + t1.Marzo + t1.Abril + t1.Mayo + t1.Junio" if mesproc.to_i == 6
              anual1 = "t1.Enero + t1.Febrero + t1.Marzo + t1.Abril + t1.Mayo + t1.Junio + t1.Julio" if mesproc.to_i == 7
              anual1 = "t1.Enero + t1.Febrero + t1.Marzo + t1.Abril + t1.Mayo + t1.Junio + t1.Julio + t1.Agosto" if mesproc.to_i == 8
              anual1 = "t1.Enero + t1.Febrero + t1.Marzo + t1.Abril + t1.Mayo + t1.Junio + t1.Julio + t1.Agosto + t1.Septiembre" if mesproc.to_i == 9
              anual1 = "t1.Enero + t1.Febrero + t1.Marzo + t1.Abril + t1.Mayo + t1.Junio + t1.Julio + t1.Agosto + t1.Septiembre + t1.Octubre" if mesproc.to_i == 10
              anual1 = "t1.Enero + t1.Febrero + t1.Marzo + t1.Abril + t1.Mayo + t1.Junio + t1.Julio + t1.Agosto + t1.Septiembre + t1.Octubre + t1.Noviembre" if mesproc.to_i == 11
              anual1 = "t1.Enero + t1.Febrero + t1.Marzo + t1.Abril + t1.Mayo + t1.Junio + t1.Julio + t1.Agosto + t1.Septiembre + t1.Octubre + t1.Noviembre + t1.Diciembre" if mesproc.to_i == 12

              anual2 = "t2.Enero" if mesproc.to_i == 1
              anual2 = "t2.Enero + t2.Febrero" if mesproc.to_i == 2
              anual2 = "t2.Enero + t2.Febrero + t2.Marzo" if mesproc.to_i == 3
              anual2 = "t2.Enero + t2.Febrero + t2.Marzo + t2.Abril" if mesproc.to_i == 4
              anual2 = "t2.Enero + t2.Febrero + t2.Marzo + t2.Abril + t2.Mayo" if mesproc.to_i == 5
              anual2 = "t2.Enero + t2.Febrero + t2.Marzo + t2.Abril + t2.Mayo + t2.Junio" if mesproc.to_i == 6
              anual2 = "t2.Enero + t2.Febrero + t2.Marzo + t2.Abril + t2.Mayo + t2.Junio + t2.Julio" if mesproc.to_i == 7
              anual2 = "t2.Enero + t2.Febrero + t2.Marzo + t2.Abril + t2.Mayo + t2.Junio + t2.Julio + t2.Agosto" if mesproc.to_i == 8
              anual2 = "t2.Enero + t2.Febrero + t2.Marzo + t2.Abril + t2.Mayo + t2.Junio + t2.Julio + t2.Agosto + t2.Septiembre" if mesproc.to_i == 9
              anual2 = "t2.Enero + t2.Febrero + t2.Marzo + t2.Abril + t2.Mayo + t2.Junio + t2.Julio + t2.Agosto + t2.Septiembre + t2.Octubre" if mesproc.to_i == 10
              anual2 = "t2.Enero + t2.Febrero + t2.Marzo + t2.Abril + t2.Mayo + t2.Junio + t2.Julio + t2.Agosto + t2.Septiembre + t2.Octubre + t2.Noviembre" if mesproc.to_i == 11
              anual2 = "t2.Enero + t2.Febrero + t2.Marzo + t2.Abril + t2.Mayo + t2.Junio + t2.Julio + t2.Agosto + t2.Septiembre + t2.Octubre + t2.Noviembre + t2.Diciembre" if mesproc.to_i == 12

              if @region.to_i == 0
      #Nivel Empresa
      #Ventas Este Año
                sql = "SELECT t2.Nombre as Region, "
                sql += "SUM(t1.Enero     ) as Enero, "
                sql += "SUM(t1.Febrero   ) as Febrero, "
                sql += "SUM(t1.Marzo     ) as Marzo, "
                sql += "SUM(t1.Abril     ) as Abril, "
                sql += "SUM(t1.Mayo      ) as Mayo, "
                sql += "SUM(t1.Junio     ) as Junio, "
                sql += "SUM(t1.Julio     ) as Julio, "
                sql += "SUM(t1.Agosto    ) as Agosto, "
                sql += "SUM(t1.Septiembre) as Septiembre, "
                sql += "SUM(t1.Octubre   ) as Octubre, "
                sql += "SUM(t1.Noviembre ) as Noviembre, "
                sql += "SUM(t1.Diciembre ) as Diciembre, "
                sql += "SUM(" + anual + ") as Anual, "
                sql += "ROUND(((SUM(" + anual + "))/ "
                sql += "(SELECT SUM(" + anual + ") from objciudad as t4 Where t4.Ano = t1.Ano and t4.IdObjetivo = 6)) * 100,2) as Participacion "
                sql += "FROM objciudad as t1 INNER JOIN " + @nomDbComun.to_s + "agrupa as t2 "
                sql += "on(t1.IdRegion = t2.IdAgrupa) "
                sql += "WHERE t1.Ano = " + @anosel.to_s + " "
                sql += "and t1.IdObjetivo = 6 "
                sql += "and t2.Objetivo = 1 "
                sql += "GROUP BY t1.IdRegion "
                @vtanetareal = @dbEsta.connection.select_all(sql)

      #Ventas Año Anterior
                sql = "SELECT t3.Nombre as Region, "
                sql += "if(SUM(t2.Enero     ) = 0,0,SUM(t1.Enero     )) as Enero, "
                sql += "if(SUM(t2.Febrero   ) = 0,0,SUM(t1.Febrero   )) as Febrero, "
                sql += "if(SUM(t2.Marzo     ) = 0,0,SUM(t1.Marzo     )) as Marzo, "
                sql += "if(SUM(t2.Abril     ) = 0,0,SUM(t1.Abril     )) as Abril, "
                sql += "if(SUM(t2.Mayo      ) = 0,0,SUM(t1.Mayo      )) as Mayo, "
                sql += "if(SUM(t2.Junio     ) = 0,0,SUM(t1.Junio     )) as Junio, "
                sql += "if(SUM(t2.Julio     ) = 0,0,SUM(t1.Julio     )) as Julio, "
                sql += "if(SUM(t2.Agosto    ) = 0,0,SUM(t1.Agosto    )) as Agosto, "
                sql += "if(SUM(t2.Septiembre) = 0,0,SUM(t1.Septiembre)) as Septiembre, "
                sql += "if(SUM(t2.Octubre   ) = 0,0,SUM(t1.Octubre   )) as Octubre, "
                sql += "if(SUM(t2.Noviembre ) = 0,0,SUM(t1.Noviembre )) as Noviembre, "
                sql += "if(SUM(t2.Diciembre ) = 0,0,SUM(t1.Diciembre )) as Diciembre, "
                sql += "SUM(" + anual1 + ") as Anual, "
                sql += "ROUND((SUM(" + anual1 + ")/ "
                sql += "(SELECT SUM(" + anualn + ") from objciudad as t4 Where t4.Ano = t1.Ano and t4.IdObjetivo = 6)) * 100,2) as Participacion "
                sql += "FROM objciudad as t1 INNER JOIN objciudad as t2 "
                sql += "USING(IdObjetivo,IdRegion,IdCiudad) "
                sql += "INNER JOIN " + @nomDbComun.to_s + "agrupa as t3 "
                sql += "on(t1.IdRegion = t3.IdAgrupa) "
                sql += "WHERE t1.Ano = " + @anoant.to_s + " "
                sql += "and t2.Ano = " + @anosel.to_s + " "
                sql += "and t1.IdObjetivo = 6 "
                sql += "and t3.Objetivo = 1 "
                sql += "GROUP BY t1.IdRegion"

                @antvtaneta = @dbEsta.connection.select_all(sql)

      #Crecimiento Bruto
                sql = "SELECT t3.Nombre as Region, "
                sql += "if(SUM(t1.Enero)      = 0,0,((SUM(t1.Enero)      / SUM(t2.Enero     )) - 1) * 100) as Enero, "
                sql += "if(SUM(t1.Febrero)    = 0,0,((SUM(t1.Febrero)    / SUM(t2.Febrero   )) - 1) * 100) as Febrero, "
                sql += "if(SUM(t1.Marzo)      = 0,0,((SUM(t1.Marzo)      / SUM(t2.Marzo     )) - 1) * 100) as Marzo, "
                sql += "if(SUM(t1.Abril)      = 0,0,((SUM(t1.Abril)      / SUM(t2.Abril     )) - 1) * 100) as Abril, "
                sql += "if(SUM(t1.Mayo)       = 0,0,((SUM(t1.Mayo)       / SUM(t2.Mayo      )) - 1) * 100) as Mayo, "
                sql += "if(SUM(t1.Junio)      = 0,0,((SUM(t1.Junio)      / SUM(t2.Junio     )) - 1) * 100) as Junio, "
                sql += "if(SUM(t1.Julio)      = 0,0,((SUM(t1.Julio)      / SUM(t2.Julio     )) - 1) * 100) as Julio, "
                sql += "if(SUM(t1.Agosto)     = 0,0,((SUM(t1.Agosto)     / SUM(t2.Agosto    )) - 1) * 100) as Agosto, "
                sql += "if(SUM(t1.Septiembre) = 0,0,((SUM(t1.Septiembre) / SUM(t2.Septiembre)) - 1) * 100) as Septiembre, "
                sql += "if(SUM(t1.Octubre)    = 0,0,((SUM(t1.Octubre)    / SUM(t2.Octubre   )) - 1) * 100) as Octubre, "
                sql += "if(SUM(t1.Noviembre)  = 0,0,((SUM(t1.Noviembre)  / SUM(t2.Noviembre )) - 1) * 100) as Noviembre, "
                sql += "if(SUM(t1.Diciembre)  = 0,0,((SUM(t1.Diciembre)  / SUM(t2.Diciembre )) - 1) * 100) as Diciembre, "
                sql += "(((SUM(" + anual1 + ")  / SUM(" + anual2 + " )) - 1) * 100) as Anual "
                sql += "FROM objciudad as t1 INNER JOIN objciudad as t2 "
                sql += "USING(IdObjetivo,IdRegion,IdCiudad) "
                sql += "INNER JOIN " + @nomDbComun.to_s + "agrupa as t3 "
                sql += "on(t1.IdRegion = t3.IdAgrupa) "
                sql += "WHERE t1.Ano = " + @anosel.to_s + " "
                sql += "and t2.Ano = " + @anoant.to_s + " "
                sql += "and t1.IdObjetivo = 6 "
                sql += "and t3.Objetivo = 1 "
                sql += "GROUP BY t1.IdRegion"
                @crecimientobruto = @dbEsta.connection.select_all(sql)

      #Crecimiento Neto
                indice = "SELECT InflacionVsAnoAntINPC from indicesobjetivo where Ano = t1.Ano and Mes"

                sql = "SELECT t3.Nombre as Region, "
                sql += "if(SUM(t1.Enero)      = 0,0,(((SUM(t1.Enero)      /(((" + indice + " = 1 )/100)+1))/ SUM(t2.Enero     )) - 1) * 100) as Enero, "
                sql += "if(SUM(t1.Febrero)    = 0,0,(((SUM(t1.Febrero)    /(((" + indice + " = 2 )/100)+1))/ SUM(t2.Febrero   )) - 1) * 100) as Febrero, "
                sql += "if(SUM(t1.Marzo)      = 0,0,(((SUM(t1.Marzo)      /(((" + indice + " = 3 )/100)+1))/ SUM(t2.Marzo     )) - 1) * 100) as Marzo, "
                sql += "if(SUM(t1.Abril)      = 0,0,(((SUM(t1.Abril)      /(((" + indice + " = 4 )/100)+1))/ SUM(t2.Abril     )) - 1) * 100) as Abril, "
                sql += "if(SUM(t1.Mayo)       = 0,0,(((SUM(t1.Mayo)       /(((" + indice + " = 5 )/100)+1))/ SUM(t2.Mayo      )) - 1) * 100) as Mayo, "
                sql += "if(SUM(t1.Junio)      = 0,0,(((SUM(t1.Junio)      /(((" + indice + " = 6 )/100)+1))/ SUM(t2.Junio     )) - 1) * 100) as Junio, "
                sql += "if(SUM(t1.Julio)      = 0,0,(((SUM(t1.Julio)      /(((" + indice + " = 7 )/100)+1))/ SUM(t2.Julio     )) - 1) * 100) as Julio, "
                sql += "if(SUM(t1.Agosto)     = 0,0,(((SUM(t1.Agosto)     /(((" + indice + " = 8 )/100)+1))/ SUM(t2.Agosto    )) - 1) * 100) as Agosto, "
                sql += "if(SUM(t1.Septiembre) = 0,0,(((SUM(t1.Septiembre) /(((" + indice + " = 9 )/100)+1))/ SUM(t2.Septiembre)) - 1) * 100) as Septiembre, "
                sql += "if(SUM(t1.Octubre)    = 0,0,(((SUM(t1.Octubre)    /(((" + indice + " = 10)/100)+1))/ SUM(t2.Octubre   )) - 1) * 100) as Octubre, "
                sql += "if(SUM(t1.Noviembre)  = 0,0,(((SUM(t1.Noviembre)  /(((" + indice + " = 11)/100)+1))/ SUM(t2.Noviembre )) - 1) * 100) as Noviembre, "
                sql += "if(SUM(t1.Diciembre)  = 0,0,(((SUM(t1.Diciembre)  /(((" + indice + " = 12)/100)+1))/ SUM(t2.Diciembre )) - 1) * 100) as Diciembre, "
                sql += "((((SUM(" + anual1 + ")  /(((" + indice + " = 12)/100)+1))/ SUM(" + anual2 + " )) - 1) * 100) as Anual "
                sql += "FROM objciudad as t1 INNER JOIN objciudad as t2 "
                sql += "USING(IdObjetivo,IdRegion,IdCiudad) "
                sql += "INNER JOIN " + @nomDbComun.to_s + "agrupa as t3 "
                sql += "on(t1.IdRegion = t3.IdAgrupa) "
                sql += "WHERE t1.Ano = " + @anosel.to_s + " "
                sql += "and t2.Ano = " + @anoant.to_s + " "
                sql += "and t1.IdObjetivo = 6 "
                sql += "and t3.Objetivo = 1 "
                sql += "GROUP BY t1.IdRegion"
                @crecimientoneto = @dbEsta.connection.select_all(sql)

                #TOTALES

                sql = "SELECT if(t1.Nombre = 'Crecimiento Real vs. Año Anterior','Crecimiento Neto',if(t1.Nombre='Crecimiento Nominal vs. Año Anterior','Crecimiento Bruto',t1.Nombre)) as Nombre, "
                sql += "if(t2.Enero      = 0,0,t1.Enero     ) as Enero, "
                sql += "if(t2.Febrero    = 0,0,t1.Febrero   ) as Febrero, "
                sql += "if(t2.Marzo      = 0,0,t1.Marzo     ) as Marzo, "
                sql += "if(t2.Abril      = 0,0,t1.Abril     ) as Abril, "
                sql += "if(t2.Mayo       = 0,0,t1.Mayo      ) as Mayo, "
                sql += "if(t2.Junio      = 0,0,t1.Junio     ) as Junio, "
                sql += "if(t2.Julio      = 0,0,t1.Julio     ) as Julio, "
                sql += "if(t2.Agosto     = 0,0,t1.Agosto    ) as Agosto, "
                sql += "if(t2.Septiembre = 0,0,t1.Septiembre) as Septiembre, "
                sql += "if(t2.Octubre    = 0,0,t1.Octubre   ) as Octubre, "
                sql += "if(t2.Noviembre  = 0,0,t1.Noviembre ) as Noviembre, "
                sql += "if(t2.Diciembre  = 0,0,t1.Diciembre ) as Diciembre, "
                sql += "(" + anual1 + ") as Anual "
                sql += "from objciudad as t1 INNER JOIN objciudad as t2 "
                sql += "using(Ano,IdObjetivo,IdRegion) "
                sql += "where t1.Ano = " + @anosel.to_s + " and t1.IdObjetivo = 90 and t1.IdRegion = 1 "
                sql += "and (t1.IdCiudad = 1 or t1.IdCiudad = 4 or t1.IdCiudad = 7 or t1.IdCiudad = 8) "
                sql += "and t2.IdCiudad = 9"
                @totales = @dbEsta.connection.select_all(sql)

              else
      #Nivel Región          
      #Ventas Este Año
                sql = "SELECT t2.Nombre as Ciudad, "
                sql += "SUM(t1.Enero     ) as Enero,      "
                sql += "SUM(t1.Febrero   ) as Febrero,    "
                sql += "SUM(t1.Marzo     ) as Marzo,      "
                sql += "SUM(t1.Abril     ) as Abril,      "
                sql += "SUM(t1.Mayo      ) as Mayo,       "
                sql += "SUM(t1.Junio     ) as Junio,      "
                sql += "SUM(t1.Julio     ) as Julio,      "
                sql += "SUM(t1.Agosto    ) as Agosto,     "
                sql += "SUM(t1.Septiembre) as Septiembre, "
                sql += "SUM(t1.Octubre   ) as Octubre,    "
                sql += "SUM(t1.Noviembre ) as Noviembre,  "
                sql += "SUM(t1.Diciembre ) as Diciembre,  "
                sql += "SUM(" + anual + ") as Anual, "
                sql += "ROUND(((SUM(" + anual + "))/ "
                sql += "(SELECT SUM(" + anual + ") from objciudad as t4 Where t4.Ano = t1.Ano and t1.IdRegion = t4.IdRegion and t4.IdObjetivo = 6)) * 100,2) as Participacion "
                sql += "FROM objciudad as t1 INNER JOIN " + @nomDbComun.to_s + "subagrupa as t2 "
                sql += "on(t1.IdRegion = t2.IdAgrupa and t1.IdCiudad = t2.IdSubAgrupa) "
                sql += "WHERE t1.Ano = " + @anosel.to_s + " "
                sql += "and t1.IdRegion = " + @region.to_s + " "
                sql += "and t1.IdObjetivo = 6 "
                sql += "and t2.Objetivo = 1 "
                sql += "GROUP BY t1.IdRegion,t1.IdCiudad "
                @vtanetareal = @dbEsta.connection.select_all(sql)

      #Ventas Año Anterior
                sql = "SELECT t2.Nombre as Ciudad, "
                sql += "if(SUM(t2.Enero     ) = 0,0,SUM(t1.Enero     )) as Enero, "
                sql += "if(SUM(t2.Febrero   ) = 0,0,SUM(t1.Febrero   )) as Febrero, "
                sql += "if(SUM(t2.Marzo     ) = 0,0,SUM(t1.Marzo     )) as Marzo, "
                sql += "if(SUM(t2.Abril     ) = 0,0,SUM(t1.Abril     )) as Abril, "
                sql += "if(SUM(t2.Mayo      ) = 0,0,SUM(t1.Mayo      )) as Mayo, "
                sql += "if(SUM(t2.Junio     ) = 0,0,SUM(t1.Junio     )) as Junio, "
                sql += "if(SUM(t2.Julio     ) = 0,0,SUM(t1.Julio     )) as Julio, "
                sql += "if(SUM(t2.Agosto    ) = 0,0,SUM(t1.Agosto    )) as Agosto, "
                sql += "if(SUM(t2.Septiembre) = 0,0,SUM(t1.Septiembre)) as Septiembre, "
                sql += "if(SUM(t2.Octubre   ) = 0,0,SUM(t1.Octubre   )) as Octubre, "
                sql += "if(SUM(t2.Noviembre ) = 0,0,SUM(t1.Noviembre )) as Noviembre, "
                sql += "if(SUM(t2.Diciembre ) = 0,0,SUM(t1.Diciembre )) as Diciembre, "
                sql += "SUM(" + anual1 + ") as Anual, "
                sql += "ROUND(((SUM(" + anual1 + "))/ "
                sql += "(SELECT SUM(" + anualn + ") from objciudad as t4 Where t4.Ano = t1.Ano and t1.IdRegion = t4.IdRegion and t4.IdObjetivo = 6)) * 100,2) as Participacion "
                sql += "FROM objciudad as t1 INNER JOIN objciudad as t2 "
                sql += "USING(IdObjetivo,IdRegion,IdCiudad) "
                sql += "INNER JOIN " + @nomDbComun.to_s + "subagrupa as t3 "
                sql += "on(t1.IdRegion = t3.IdAgrupa and t1.IdCiudad = t3.IdSubAgrupa) "
                sql += "WHERE t1.Ano = " + @anoant.to_s + " "
                sql += "and t2.Ano = " + @anosel.to_s + " "
                sql += "and t1.IdRegion = " + @region.to_s + " "
                sql += "and t1.IdObjetivo = 6 "
                sql += "and t3.Objetivo = 1 "
                sql += "GROUP BY t1.IdRegion,t1.IdCiudad "
                @antvtaneta = @dbEsta.connection.select_all(sql)

      #Crecimiento Bruto
                sql = "SELECT t3.Nombre as Ciudad, "
                sql += "if(SUM(t1.Enero)      = 0,0,((SUM(t1.Enero)      / SUM(t2.Enero     )) - 1) * 100) as Enero, "
                sql += "if(SUM(t1.Febrero)    = 0,0,((SUM(t1.Febrero)    / SUM(t2.Febrero   )) - 1) * 100) as Febrero, "
                sql += "if(SUM(t1.Marzo)      = 0,0,((SUM(t1.Marzo)      / SUM(t2.Marzo     )) - 1) * 100) as Marzo, "
                sql += "if(SUM(t1.Abril)      = 0,0,((SUM(t1.Abril)      / SUM(t2.Abril     )) - 1) * 100) as Abril, "
                sql += "if(SUM(t1.Mayo)       = 0,0,((SUM(t1.Mayo)       / SUM(t2.Mayo      )) - 1) * 100) as Mayo, "
                sql += "if(SUM(t1.Junio)      = 0,0,((SUM(t1.Junio)      / SUM(t2.Junio     )) - 1) * 100) as Junio, "
                sql += "if(SUM(t1.Julio)      = 0,0,((SUM(t1.Julio)      / SUM(t2.Julio     )) - 1) * 100) as Julio, "
                sql += "if(SUM(t1.Agosto)     = 0,0,((SUM(t1.Agosto)     / SUM(t2.Agosto    )) - 1) * 100) as Agosto, "
                sql += "if(SUM(t1.Septiembre) = 0,0,((SUM(t1.Septiembre) / SUM(t2.Septiembre)) - 1) * 100) as Septiembre, "
                sql += "if(SUM(t1.Octubre)    = 0,0,((SUM(t1.Octubre)    / SUM(t2.Octubre   )) - 1) * 100) as Octubre, "
                sql += "if(SUM(t1.Noviembre)  = 0,0,((SUM(t1.Noviembre)  / SUM(t2.Noviembre )) - 1) * 100) as Noviembre, "
                sql += "if(SUM(t1.Diciembre)  = 0,0,((SUM(t1.Diciembre)  / SUM(t2.Diciembre )) - 1) * 100) as Diciembre, "
                sql += "(((SUM(" + anual1 + ")  / SUM(" + anual2 + " )) - 1) * 100) as Anual "
                sql += "FROM objciudad as t1 INNER JOIN objciudad as t2 "
                sql += "USING(IdObjetivo,IdRegion,IdCiudad) "
                sql += "INNER JOIN " + @nomDbComun.to_s + "subagrupa as t3 "
                sql += "on(t1.IdRegion = t3.IdAgrupa and t1.IdCiudad = t3.IdSubAgrupa) "
                sql += "WHERE t1.Ano = " + @anosel.to_s + " "
                sql += "and t2.Ano = " + @anoant.to_s + " "
                sql += "and t1.IdRegion = " + @region.to_s + " "
                sql += "and t1.IdObjetivo = 6 "
                sql += "and t3.Objetivo = 1 "
                sql += "GROUP BY t1.IdRegion,t1.IdCiudad"
                @crecimientobruto = @dbEsta.connection.select_all(sql)

      #Crecimiento Neto
                indice = "SELECT InflacionVsAnoAntINPC from indicesobjetivo where Ano = t1.Ano and Mes"

                sql = "SELECT t3.Nombre as Ciudad, "
                sql += "if(SUM(t1.Enero)      = 0,0,(((SUM(t1.Enero)      /(((" + indice + " = 1 )/100)+1))/ SUM(t2.Enero     )) - 1) * 100) as Enero, "
                sql += "if(SUM(t1.Febrero)    = 0,0,(((SUM(t1.Febrero)    /(((" + indice + " = 2 )/100)+1))/ SUM(t2.Febrero   )) - 1) * 100) as Febrero, "
                sql += "if(SUM(t1.Marzo)      = 0,0,(((SUM(t1.Marzo)      /(((" + indice + " = 3 )/100)+1))/ SUM(t2.Marzo     )) - 1) * 100) as Marzo, "
                sql += "if(SUM(t1.Abril)      = 0,0,(((SUM(t1.Abril)      /(((" + indice + " = 4 )/100)+1))/ SUM(t2.Abril     )) - 1) * 100) as Abril, "
                sql += "if(SUM(t1.Mayo)       = 0,0,(((SUM(t1.Mayo)       /(((" + indice + " = 5 )/100)+1))/ SUM(t2.Mayo      )) - 1) * 100) as Mayo, "
                sql += "if(SUM(t1.Junio)      = 0,0,(((SUM(t1.Junio)      /(((" + indice + " = 6 )/100)+1))/ SUM(t2.Junio     )) - 1) * 100) as Junio, "
                sql += "if(SUM(t1.Julio)      = 0,0,(((SUM(t1.Julio)      /(((" + indice + " = 7 )/100)+1))/ SUM(t2.Julio     )) - 1) * 100) as Julio, "
                sql += "if(SUM(t1.Agosto)     = 0,0,(((SUM(t1.Agosto)     /(((" + indice + " = 8 )/100)+1))/ SUM(t2.Agosto    )) - 1) * 100) as Agosto, "
                sql += "if(SUM(t1.Septiembre) = 0,0,(((SUM(t1.Septiembre) /(((" + indice + " = 9 )/100)+1))/ SUM(t2.Septiembre)) - 1) * 100) as Septiembre, "
                sql += "if(SUM(t1.Octubre)    = 0,0,(((SUM(t1.Octubre)    /(((" + indice + " = 10)/100)+1))/ SUM(t2.Octubre   )) - 1) * 100) as Octubre, "
                sql += "if(SUM(t1.Noviembre)  = 0,0,(((SUM(t1.Noviembre)  /(((" + indice + " = 11)/100)+1))/ SUM(t2.Noviembre )) - 1) * 100) as Noviembre, "
                sql += "if(SUM(t1.Diciembre)  = 0,0,(((SUM(t1.Diciembre)  /(((" + indice + " = 12)/100)+1))/ SUM(t2.Diciembre )) - 1) * 100) as Diciembre, "
                sql += "((((SUM(" + anual1 + ")  /(((" + indice + " = 12)/100)+1))/ SUM(" + anual2 + " )) - 1) * 100) as Anual "
                sql += "FROM objciudad as t1 INNER JOIN objciudad as t2 "
                sql += "USING(IdObjetivo,IdRegion,IdCiudad) "
                sql += "INNER JOIN " + @nomDbComun.to_s + "subagrupa as t3 "
                sql += "on(t1.IdRegion = t3.IdAgrupa and t1.IdCiudad = t3.IdSubAgrupa) "
                sql += "WHERE t1.Ano = " + @anosel.to_s + " "
                sql += "and t2.Ano = " + @anoant.to_s + " "
                sql += "and t1.IdObjetivo = 6 "
                sql += "and t1.IdRegion = " + @region.to_s + " "
                sql += "and t3.Objetivo = 1 "
                sql += "GROUP BY t1.IdRegion,t1.IdCiudad"
                @crecimientoneto = @dbEsta.connection.select_all(sql)

                #TOTALES
                sql = "SELECT if(t1.Nombre = 'Crecimiento Real vs. Año Anterior','Crecimiento Neto',if(t1.Nombre='Crecimiento Nominal vs. Año Anterior','Crecimiento Bruto',t1.Nombre)) as Nombre, "
                sql += "if(t2.Enero      = 0,0,t1.Enero     ) as Enero, "
                sql += "if(t2.Febrero    = 0,0,t1.Febrero   ) as Febrero, "
                sql += "if(t2.Marzo      = 0,0,t1.Marzo     ) as Marzo, "
                sql += "if(t2.Abril      = 0,0,t1.Abril     ) as Abril, "
                sql += "if(t2.Mayo       = 0,0,t1.Mayo      ) as Mayo, "
                sql += "if(t2.Junio      = 0,0,t1.Junio     ) as Junio, "
                sql += "if(t2.Julio      = 0,0,t1.Julio     ) as Julio, "
                sql += "if(t2.Agosto     = 0,0,t1.Agosto    ) as Agosto, "
                sql += "if(t2.Septiembre = 0,0,t1.Septiembre) as Septiembre, "
                sql += "if(t2.Octubre    = 0,0,t1.Octubre   ) as Octubre, "
                sql += "if(t2.Noviembre  = 0,0,t1.Noviembre ) as Noviembre, "
                sql += "if(t2.Diciembre  = 0,0,t1.Diciembre ) as Diciembre, "
                sql += "(" + anual1 + ") as Anual "
                sql += "from objsucursal as t1 INNER JOIN objsucursal as t2 "
                sql += "using(Ano,IdObjetivo,IdRegion) "
                sql += "where t1.Ano = " + @anosel.to_s + " and t1.IdObjetivo = 90 and t1.IdRegion = " + @region.to_s + "1 "
                sql += "and (t1.Idsucursal = 1 or t1.Idsucursal = 4 or t1.Idsucursal = 7 or t1.Idsucursal = 8) "
                sql += "and t2.Idsucursal = 9"
                @totales = @dbEsta.connection.select_all(sql)

              end

            end
          end
        end
      end

    end

    sql = "SELECT DISTINCT left(mes,4) as Año from htotalmes where left(mes,4) >= 2005 ORDER BY Año DESC"
    @tablaanosel = @dbEsta.connection.select_all(sql)

    sql = "SELECT IdAgrupa,Nombre FROM agrupa where Objetivo = 1 order by NumOrd"
    @tablaregion = @dbComun.connection.select_all(sql)

    if @continua > 0    
      respond_to do |format|
        format.html
#        format.csv do 
#            out_arr = []
#            out_arr.push("Region")
#            @crecimientoneto.each do |m|
#                out_arr.push("#{m['Region']}")
#            end
#            csv_file = "/tmp/objetivo_1112.csv"
#            dump_to_file(csv_file,out_arr.join("\n"))
#            send_file csv_file
#            return
#        end
      end
    end    

  end

  def calc_objetivos_gridcrecireal_porce_update
    datos = params[:datosAEnviar].to_s if params.has_key?(:datosAEnviar)
    datos = JSON.parse(datos) rescue []

    if datos.count > 0 
      datos.each do |dato|
        arrDato = dato.split('_')
        arrMesVal = arrDato[4].split('=')
        if arrDato[0] == "cd"
          sql = "UPDATE objciudad "
          sql += "set "
          sql += arrMesVal[0] + " = " + arrMesVal[1] + " "
          sql += "where "
          sql += "Ano = " + arrDato[1] + " "
          sql += "and IdObjetivo = 3 "
          sql += "and IdRegion = " + arrDato[2] + " "
          sql += "and IdCiudad = " + arrDato[3]
        else
          sql = "UPDATE objsucursal "
          sql += "set "
          sql += arrMesVal[0] + " = " + arrMesVal[1] + " "
          sql += "where "
          sql += "Ano = " + arrDato[1] + " "
          sql += "and IdObjetivo = 3 "
          sql += "and IdRegion = " + arrDato[2] + " "
          sql += "and IdSucursal = " + arrDato[3]
        end
        puts sql
        @dbEsta.connection.execute(sql)
      end
      render status: 200, json: { info: "Datos Guardados Exitosamente, espere porfavor... !RECALCULANDO¡" }
    else
      render status: 200, json: { info: "No hay datos por guardar" }
    end
  end

  def calc_objetivos_gridcrecireal_obj_update
    datos = params[:datosAEnviar].to_s if params.has_key?(:datosAEnviar)
    datos = JSON.parse(datos) rescue []

    if datos.count > 0 
      datos.each do |dato|
        arrDato = dato.split('_')
        arrMesVal = arrDato[4].split('=')
        if arrDato[0] == "cd"
          sql = "UPDATE objciudad as t1 inner join objciudad as t2 "
          sql += "USING(Ano,IdRegion,IdCiudad) "
          sql += "SET "
          sql += "t1." + arrMesVal[0] + " = ROUND(((" + arrMesVal[1] + " / t2." + arrMesVal[0] + " )-1) * 100,2) "  
          sql += "WHERE "
          sql += "t1.Ano = " + arrDato[1] + " "
          sql += "and t1.IdObjetivo = 3 "
          sql += "and t1.IdRegion = " + arrDato[2] + " "
          sql += "and t1.IdCiudad = " + arrDato[3] + " "
          sql += "and t2.IdObjetivo = 2 "
        else
          sql = "UPDATE objsucursal as t1 inner join objsucursal as t2 "
          sql += "USING(Ano,IdRegion,IdSucursal) "
          sql += "SET "
          sql += "t1." + arrMesVal[0] + " = ROUND(((" + arrMesVal[1] + " / t2." + arrMesVal[0] + " )-1) * 100,2) "  
          sql += "WHERE "
          sql += "t1.Ano = " + arrDato[1] + " "
          sql += "and t1.IdObjetivo = 3 "
          sql += "and t1.IdRegion = " + arrDato[2] + " "
          sql += "and t1.IdSucursal = " + arrDato[3] + " "
          sql += "and t2.IdObjetivo = 2 "
        end
        puts sql
        @dbEsta.connection.execute(sql)
      end
      render status: 200, json: { info: "Datos Guardados Exitosamente, espere porfavor... !RECALCULANDO¡" }
    else
      render status: 200, json: { info: "No hay datos por guardar" }
    end
  end

  private 
    def get_filtros_from_user
      filtros = []
      filtros.push("1")
      # if current_user.zonas? && current_user.zonas != "0"
      #   zonas = current_user.zonas.to_s.split(',').map{|i| i.to_i}.sort
      #   filtros.push("ZonaAsig = #{zonas.join(" OR ZonaAsig = ")}") if zonas.count > 0
      # end
      # if current_user.sucursales? && current_user.sucursales != "0"
      #   sucursales = current_user.sucursales.to_s.split(',').map{|i| i.to_i}.sort
      #   filtros.push("Sucursal = #{sucursales.join(" OR Sucursal = ")}") if sucursales.count > 0
      # end
      return filtros
    end

    def dump_to_file(filename,txt,modo="w")
      File.open(filename, modo) {|f| f.write(txt) }
    end

    def nomMes(mes)
      case mes
      when 1  
        @mesnum = "01"
        @mestxt = "Enero"
        @mesant = "12"
        @mesnumant = "12"
        @mesnomant = "Diciembre"
        @messig = "2"
        @mesnomsig = "Febrero"
      when 2 
        @mesnum = "02"
        @mestxt = "Febrero"
        @mesant = "1"
        @mesnumant = "01"
        @mesnomant = "Enero"
        @messig = "3"
        @mesnomsig = "Marzo"
      when 3 
        @mesnum = "03"
        @mestxt = "Marzo"
        @mesant = "2"
        @mesnomant = "Febrero"
        @messig = "4"
        @mesnomsig = "Abril"
      when 4 
        @mesnum = "04"
        @mestxt = "Abril"
        @mesant = "3"
        @mesnumant = "03"
        @mesnomant = "Marzo"
        @messig = "5"
        @mesnomsig = "Mayo"
      when 5 
        @mesnum = "05"
        @mestxt = "Mayo"
        @mesant = "4"
        @mesnumant = "04"
        @mesnomant = "Abril"
        @messig = "6"
        @mesnomsig = "Junio"
      when 6 
        @mesnum = "06"
        @mestxt = "Junio"
        @mesant = "5"
        @mesnumant = "05"
        @mesnomant = "Mayo"
        @messig = "7"
        @mesnomsig = "Julio"
      when 7 
        @mesnum = "07"
        @mestxt = "Julio"
        @mesant = "6"
        @mesnomant = "Junio"
        @messig = "8"
        @mesnomsig = "Agosto"
      when 8 
        @mesnum = "08"
        @mestxt = "Agosto"
        @mesant = "7"
        @mesnumant = "07"
        @mesnomant = "Julio"
        @messig = "9"
        @mesnomsig = "Septiembre"
      when 9 
        @mesnum = "09"
        @mestxt = "Septiembre"
        @mesant = "8"
        @mesnumant = "08"
        @mesnomant = "Agosto"
        @messig = "10"
        @mesnomsig = "Octubre"
      when 10 
        @mesnum = "10"
        @mestxt = "Octubre"
        @mesant = "9"
        @mesnumant = "09"
        @mesnomant = "Septiembre"
        @messig = "11"
        @mesnomsig = "Noviembre"
      when 11 
        @mesnum = "11"
        @mestxt = "Noviembre"
        @mesant = "10"
        @mesnumant = "10"
        @mesnomant = "Octubre"
        @messig = "12"
        @mesnomsig = "Diciembre"
      when 12 
        @mesnum = "12"
        @mestxt = "Diciembre"
        @mesant = "11"
        @mesnumant = "11"
        @mesnomant = "Noviembre"
        @messig = "1"
        @mesnomsig = "Enero"
      end
    end


    def query_contribucion_reg(mes,anosel,region,nomDbComun)
      nomMes(mes)

      fromjoin = "FROM htotalmes as t2 LEFT JOIN " + nomDbComun + "agrupasuc as t3 on (t3.IdSucursal = t2.Sucursal) "
      fromjoin += "left join " + nomDbComun + "subagrupa as sb using(IdAgrupa) "
      fromjoin += "Where t3.IdAgrupa = Agrupa and t2.mes = CONCAT(Año,'" + @mesnum + "')"

      @sqlreg = "SELECT NomRegion as Region, "
      @sqlreg += "(SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) as VentaNeta, "
      @sqlreg += "(SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa) as Objetivo, "
      @sqlreg += "(SELECT ROUND(SUM(t2.stockMercancia),2) " + fromjoin + ") as StockMercancia, "
      @sqlreg += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + ") as StockCxc, "
      @sqlreg += "(SELECT ROUND(SUM(t2.cobranza),2) " + fromjoin + ") as Cobranza, "
      @sqlreg += "(SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 24 and t2.IdRegion = Agrupa) as VentaTotal, "
      @sqlreg += "(SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 23 and t2.IdRegion = Agrupa) as ObjTotal, "
      @sqlreg += "ROUND(((SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 24 and t2.IdRegion = Agrupa) / "
      @sqlreg += "(SELECT SUM(" + @mestxt + ") from objsucursal as t2 Where Ano = Año and IdObjetivo = 90 and t2.IdSucursal = 4)) * 100,2) as Contribucion "
      @sqlreg += "FROM "
      @sqlreg += "( "
      @sqlreg += "  SELECT " + anosel + " as Año,IdAgrupa as Agrupa,Nombre as NomRegion FROM " + nomDbComun + "agrupa where Objetivo = 1 order by NumOrd "
      @sqlreg += ") tmp"
    end

    def query_contribucion_cd(mes,anosel,region,nomDbComun)
      nomMes(mes)

      fromjoin = "FROM htotalmes as t2 LEFT JOIN " + nomDbComun + "agrupasuc as t3 on (t3.IdSucursal = t2.Sucursal) "
      fromjoin += "left join " + nomDbComun + "subagrupa as sb using(IdAgrupa,IdSubAgrupa) "
      fromjoin += "Where t3.IdAgrupa = Agrupa and t3.IdSubAgrupa = SubAgrupa and t2.mes = CONCAT(Año,'" + @mesnum + "')"

      @sqlcd = "SELECT NomCiudad as Ciudad, "
      @sqlcd += "(SELECT " + @mestxt + " from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) as VentaNeta, "
      @sqlcd += "(SELECT " + @mestxt + " from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) as Objetivo, "
      @sqlcd += "(SELECT ROUND(SUM(t2.stockMercancia),2) " + fromjoin + ") as StockMercancia, "
      @sqlcd += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + ") as StockCxc, "
      @sqlcd += "(SELECT ROUND(SUM(t2.cobranza),2) " + fromjoin + ") as Cobranza, "
      @sqlcd += "(SELECT " + @mestxt + " from objciudad as t2 Where Ano = Año and IdObjetivo = 24 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) as VentaTotal, "
      @sqlcd += "(SELECT " + @mestxt + " from objciudad as t2 Where Ano = Año and IdObjetivo = 23 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) as ObjTotal, "
      @sqlcd += "ROUND(((SELECT " + @mestxt + " from objciudad as t2 Where Ano = Año and IdObjetivo = 24 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) / "
      @sqlcd += "(SELECT SUM(" + @mestxt + ") from objsucursal as t2 Where Ano = Año and IdObjetivo = 90 and t2.IdRegion = CONCAT(Agrupa,'2') and t2.IdSucursal = 4)) * 100,2) as Contribucion "
      @sqlcd += "FROM "
      @sqlcd += "( "
      @sqlcd += "  SELECT " + anosel + " as Año,IdAgrupa as Agrupa,IdSubAgrupa as SubAgrupa,Nombre as NomCiudad FROM " + nomDbComun + "subagrupa where IdAgrupa = " + region + " order by NumOrd "
      @sqlcd += ") tmp "
    end

    def query_contribucion_suc(mes,anosel,region,nomDbComun)
      nomMes(mes)
      @sqlsuc = "SELECT NomSuc as Sucursal, "
      @sqlsuc += "(SELECT " + @mestxt + " from objsucursal as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdSucursal = suc) as VentaNeta, "
      @sqlsuc += "(SELECT " + @mestxt + " from objsucursal as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdSucursal = suc) as Objetivo, "
      @sqlsuc += "(SELECT t2.stockMercancia from htotalmes as t2 Where t2.Sucursal = suc and t2.mes = CONCAT(Año,'" + @mesnum + "')) as StockMercancia, "
      @sqlsuc += "(SELECT t2.stockCxc from htotalmes as t2 Where t2.Sucursal = suc and t2.mes = CONCAT(Año,'" + @mesnum + "')) as StockCxc, "
      @sqlsuc += "(SELECT t2.cobranza from htotalmes as t2 Where t2.Sucursal = suc and t2.mes = CONCAT(Año,'" + @mesnum + "')) as Cobranza, "
      @sqlsuc += "(SELECT " + @mestxt + " from objsucursal as t2 Where Ano = Año and IdObjetivo = 24 and t2.IdSucursal = suc) as VentaTotal, "
      @sqlsuc += "(SELECT " + @mestxt + " from objsucursal as t2 Where Ano = Año and IdObjetivo = 23 and t2.IdSucursal = suc) as ObjTotal, "
      @sqlsuc += "((SELECT " + @mestxt + " from objsucursal as t2 Where Ano = Año and IdObjetivo = 24 and t2.IdSucursal = suc) / "
      @sqlsuc += "(SELECT " + @mestxt + " from objsucursal as t2 Where Ano = Año and IdObjetivo = 90 and t2.IdRegion = CONCAT(Agrupa,'2') and t2.IdSucursal = 4)) * 100 as Contribucion "
      @sqlsuc += "FROM "
      @sqlsuc += "( "
      @sqlsuc += "SELECT " + anosel + " as Año,IdAgrupa as Agrupa,IdSucursal as Suc,Nombre as NomSuc FROM " + nomDbComun + "agrupasuc where IdAgrupa = " + region + " order by IdSubAgrupa,NumOrd "
      @sqlsuc += ") tmp"
    end

    def query_global_ventas_reg(mes,anosel,region,nomDbComun)
      nomMes(mes)

      @sql = "SELECT NomRegion as Region, "
      @sql += "(SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) as VentaNeta, "
      @sql += "(SELECT SUM(" + @mestxt + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += " on(t3.IdAgrupa = t2.IdRegion and t3.IdSucursal = t2.IdSucursal) "
      @sql += " Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa) as ObjetivoGerencia, "
       
      @sql += "((SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) - "
      @sql += "(SELECT SUM(" + @mestxt + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += " on(t3.IdAgrupa = t2.IdRegion and t3.IdSucursal = t2.IdSucursal) "
      @sql += " Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa)) as DifGerencia, "
       
      @sql +="if((SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) = 0,0," 
      @sql += "(((SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) - "
      @sql += "(SELECT SUM(" + @mestxt + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += " on(t3.IdAgrupa = t2.IdRegion and t3.IdSucursal = t2.IdSucursal) "
      @sql += " Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa)) / "
      @sql += "(SELECT SUM(" + @mestxt + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += " on(t3.IdAgrupa = t2.IdRegion and t3.IdSucursal = t2.IdSucursal) "
      @sql += " Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa)) * 100) as PorceGerencia, "

      @sql += "(SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa) as ObjetivoDireccion, "

      @sql += "(SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) - "
      @sql += "(SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa) as DifDireccion, "

      @sql +="if((SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) = 0,0," 
      @sql += "(((SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) - "
      @sql += "(SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa)) / "
      @sql += "(SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa)) * 100) as PorceDireccion, "

      fromjoin = "FROM htotalmes as t2 LEFT JOIN " + nomDbComun + "agrupasuc as t3 on (t3.IdSucursal = t2.Sucursal) "
      fromjoin += "Where t3.IdAgrupa = Agrupa"

      @sql += "(SELECT ROUND(SUM(t2.stockMercancia),2) " + fromjoin + " and t2.mes = CONCAT(Año,'" + @mesnum + "')) as StockMercancia, "
      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and t2.mes = CONCAT(Año,'" + @mesnum + "')) as StockCxc, "

      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and t2.mes = if(MesSel = 1,CONCAT(Año - 1,'12'),CONCAT(Año,'" + @mesnumant + "'))   ) as StockCxcMesAnt, "

      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and t2.mes = CONCAT(Año,'" + @mesnum + "')) - "
      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and t2.mes = if(MesSel = 1,CONCAT(Año - 1,'12'),CONCAT(Año,'" + @mesnumant + "'))   ) as DifStockCxc "
       
      @sql += "FROM "
      @sql += "( "
      @sql += "  SELECT " + anosel + " as Año," + mes.to_s + " as MesSel,IdAgrupa as Agrupa,Nombre as NomRegion FROM " + nomDbComun + "agrupa where Objetivo = 1 order by NumOrd "
      @sql += ") tmp"
    end

    def query_global_ventas_total_reg(mes,anosel,region,nomDbComun)
      nomMes(mes)

      @sql = "SELECT 'Empresa' as Total, "
      @sql += "(SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6) as VentaNeta, "
      @sql += "(SELECT SUM(" + @mestxt + ") from objsucursal as t2 "
      @sql += " Where Ano = Año and IdObjetivo = 4) as ObjetivoGerencia, "
       
      @sql += "((SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6) - "
      @sql += "(SELECT SUM(" + @mestxt + ") from objsucursal as t2 "
      @sql += " Where Ano = Año and IdObjetivo = 4)) as DifGerencia, "
       
      @sql +="if((SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6) = 0,0," 
      @sql += "(((SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6) - "
      @sql += "(SELECT SUM(" + @mestxt + ") from objsucursal as t2 "
      @sql += " Where Ano = Año and IdObjetivo = 4)) / "
      @sql += "(SELECT SUM(" + @mestxt + ") from objsucursal as t2 "
      @sql += " Where Ano = Año and IdObjetivo = 4)) * 100) as PorceGerencia, "

      @sql += "(SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4) as ObjetivoDireccion, "

      @sql += "(SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6) - "
      @sql += "(SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4) as DifDireccion, "

      @sql +="if((SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6) = 0,0," 
      @sql += "(((SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6) - "
      @sql += "(SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4)) / "
      @sql += "(SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4)) * 100) as PorceDireccion, "

      @sql += "(SELECT ROUND(SUM(t2.stockMercancia),2) FROM htotalmes as t2 Where t2.mes = CONCAT(Año,'" + @mesnum + "')) as StockMercancia, "
      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) FROM htotalmes as t2 Where t2.mes = CONCAT(Año,'" + @mesnum + "')) as StockCxc, "

      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) FROM htotalmes as t2 Where t2.mes = if(MesSel = 1,CONCAT(Año - 1,'12'),CONCAT(Año,'" + @mesnumant + "'))   ) as StockCxcMesAnt, "

      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) FROM htotalmes as t2 Where t2.mes = CONCAT(Año,'" + @mesnum + "')) - "
      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) FROM htotalmes as t2 Where t2.mes = if(MesSel = 1,CONCAT(Año - 1,'12'),CONCAT(Año,'" + @mesnumant + "'))   ) as DifStockCxc "
       
      @sql += "FROM "
      @sql += "( "
      @sql += "  SELECT " + anosel + " as Año," + mes.to_s + " as MesSel"
      @sql += ") tmp"
    end

    def query_global_ventas_anual_reg(anosel,region,nomDbComun)
      meses = "Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio + Agosto + Septiembre + Octubre + Noviembre + Diciembre"

      @sql = "SELECT NomRegion as Region, "
      @sql += "(SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) as VentaNeta, "
      @sql += "(SELECT SUM(" + meses + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += " on(t3.IdAgrupa = t2.IdRegion and t3.IdSucursal = t2.IdSucursal) "
      @sql += " Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa) as ObjetivoGerencia, "
       
      @sql += "((SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) - "
      @sql += "(SELECT SUM(" + meses + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += " on(t3.IdAgrupa = t2.IdRegion and t3.IdSucursal = t2.IdSucursal) "
      @sql += " Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa)) as DifGerencia, "
       
      @sql +="if((SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) = 0,0," 
      @sql += "(((SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) - "
      @sql += "(SELECT SUM(" + meses + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += " on(t3.IdAgrupa = t2.IdRegion and t3.IdSucursal = t2.IdSucursal) "
      @sql += " Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa)) / "
      @sql += "(SELECT SUM(" + meses + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += " on(t3.IdAgrupa = t2.IdRegion and t3.IdSucursal = t2.IdSucursal) "
      @sql += " Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa)) * 100) as PorceGerencia, "

      @sql += "(SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa) as ObjetivoDireccion, "

      @sql += "(SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) - "
      @sql += "(SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa) as DifDireccion, "

      @sql +="if((SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) = 0,0," 
      @sql += "(((SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) - "
      @sql += "(SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa)) / "
      @sql += "(SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa)) * 100) as PorceDireccion, "

      fromjoin = "FROM htotalmes as t2 LEFT JOIN " + nomDbComun + "agrupasuc as t3 on (t3.IdSucursal = t2.Sucursal) "
      fromjoin += "Where t3.IdAgrupa = Agrupa"

      @sql += "(SELECT ROUND(SUM(t2.stockMercancia),2) " + fromjoin + " and left(t2.mes,4) = Año) as StockMercancia, "
      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and left(t2.mes,4) = Año) as StockCxc, "

      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and left(t2.mes,4) = Año - 1) as StockCxcMesAnt, "

      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and left(t2.mes,4) = Año) - "
      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and left(t2.mes,4) = Año - 1) as DifStockCxc "
       
      @sql += "FROM "
      @sql += "( "
      @sql += "  SELECT " + anosel + " as Año,IdAgrupa as Agrupa,Nombre as NomRegion FROM " + nomDbComun + "agrupa where Objetivo = 1 order by NumOrd "
      @sql += ") tmp"
    end

    def query_global_ventas_anual_total_reg(anosel,region,nomDbComun)
      meses = "Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio + Agosto + Septiembre + Octubre + Noviembre + Diciembre"

      @sql = "SELECT 'Empresa' as Total, "
      @sql += "(SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6) as VentaNeta, "
      @sql += "(SELECT SUM(" + meses + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += " on(t3.IdSucursal = t2.IdSucursal) "
      @sql += " Where Ano = Año and IdObjetivo = 4) as ObjetivoGerencia, "
       
      @sql += "((SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6) - "
      @sql += "(SELECT SUM(" + meses + ") from objsucursal as t2 "
      @sql += " Where Ano = Año and IdObjetivo = 4)) as DifGerencia, "
       
      @sql +="if((SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6) = 0,0," 
      @sql += "(((SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6) - "
      @sql += "(SELECT SUM(" + meses + ") from objsucursal as t2 "
      @sql += " Where Ano = Año and IdObjetivo = 4)) / "
      @sql += "(SELECT SUM(" + meses + ") from objsucursal as t2 "
      @sql += " Where Ano = Año and IdObjetivo = 4)) * 100) as PorceGerencia, "

      @sql += "(SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4) as ObjetivoDireccion, "

      @sql += "(SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6) - "
      @sql += "(SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4) as DifDireccion, "

      @sql +="if((SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6) = 0,0," 
      @sql += "(((SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6) - "
      @sql += "(SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4)) / "
      @sql += "(SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4)) * 100) as PorceDireccion, "

      @sql += "(SELECT ROUND(SUM(t2.stockMercancia),2) FROM htotalmes as t2 Where left(t2.mes,4) = Año) as StockMercancia, "
      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) FROM htotalmes as t2 Where left(t2.mes,4) = Año) as StockCxc, "

      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) FROM htotalmes as t2 Where left(t2.mes,4) = Año - 1) as StockCxcMesAnt, "

      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) FROM htotalmes as t2 Where left(t2.mes,4) = Año) - "
      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) FROM htotalmes as t2 Where left(t2.mes,4) = Año - 1) as DifStockCxc "
       
      @sql += "FROM "
      @sql += "( "
      @sql += "  SELECT " + anosel + " as Año "
      @sql += ") tmp"
    end

    def query_global_ventas_cd(mes,anosel,region,nomDbComun)
      nomMes(mes)

      @sql = "SELECT NomCiudad as Ciudad, "
      @sql += "(SELECT " + @mestxt + " from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) as VentaNeta, "
      @sql += "(SELECT SUM(" + @mestxt + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += "on(t3.IdAgrupa = t2.IdRegion and t3.IdSucursal = t2.IdSucursal) "
      @sql += "Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa and t3.IdSubAgrupa = SubAgrupa) as ObjetivoGerencia, "
       
      @sql += "((SELECT " + @mestxt + " from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) - "
      @sql += "(SELECT SUM(" + @mestxt + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += "on(t3.IdAgrupa = t2.IdRegion and t3.IdSucursal = t2.IdSucursal) "
      @sql += "Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa and t3.IdSubAgrupa = SubAgrupa)) as DifGerencia, "
       
      @sql +="if((SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) = 0,0," 
      @sql += "((((SELECT " + @mestxt + " from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) - "
      @sql += "(SELECT SUM(" + @mestxt + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += "on(t3.IdAgrupa = t2.IdRegion and t3.IdSucursal = t2.IdSucursal) "
      @sql += "Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa and t3.IdSubAgrupa = SubAgrupa))) / "
      @sql += "(SELECT SUM(" + @mestxt + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += "on(t3.IdAgrupa = t2.IdRegion and t3.IdSucursal = t2.IdSucursal) "
      @sql += "Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa and t3.IdSubAgrupa = SubAgrupa)) * 100) as PorceGerencia, "
       
      @sql += "(SELECT " + @mestxt + " from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) as ObjetivoDireccion, "

      @sql += "(SELECT " + @mestxt + " from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) - "
      @sql += "(SELECT " + @mestxt + " from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) as DifDireccion, "

      @sql +="if((SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) = 0,0," 
      @sql += "(((SELECT " + @mestxt + " from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) - "
      @sql += "(SELECT " + @mestxt + " from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa)) / "
      @sql += "(SELECT " + @mestxt + " from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa)) * 100) as PorceDireccion, "

      fromjoin = "FROM htotalmes as t2 LEFT JOIN " + nomDbComun + "agrupasuc as t3 on (t3.IdSucursal = t2.Sucursal) "
      fromjoin += "left join " + nomDbComun + "subagrupa as sb using(IdAgrupa,IdSubAgrupa) "
      fromjoin += "Where t3.IdAgrupa = Agrupa and t3.IdSubAgrupa = SubAgrupa"

      @sql += "(SELECT ROUND(SUM(t2.stockMercancia),2) " + fromjoin + " and t2.mes = CONCAT(Año,'" + @mesnum + "')) as StockMercancia, "
      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and t2.mes = CONCAT(Año,'" + @mesnum + "')) as StockCxc, "

      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and t2.mes = if(MesSel = 1,CONCAT(Año - 1,'12'),CONCAT(Año,'" + @mesnumant + "'))   ) as StockCxcMesAnt, "

      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and t2.mes = CONCAT(Año,'" + @mesnum + "')) - "
      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and t2.mes = if(MesSel = 1,CONCAT(Año - 1,'12'),CONCAT(Año,'" + @mesnumant + "'))   ) as DifStockCxc "

      @sql += "FROM "
      @sql += "( "
      @sql += "  SELECT " + anosel + " as Año," + mes.to_s + " as MesSel,IdAgrupa as Agrupa,IdSubAgrupa as SubAgrupa,Nombre as NomCiudad FROM " + nomDbComun + "subagrupa where IdAgrupa = " + region + " order by NumOrd "
      @sql += ") tmp"
    end

    def query_global_ventas_total_cd(mes,anosel,region,nomDbComun)
      nomMes(mes)

      @sql = "SELECT NomRegion as Total, "
      @sql += "(SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) as VentaNeta, "
      @sql += "(SELECT SUM(" + @mestxt + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += "on(t3.IdAgrupa = t2.IdRegion) "
      @sql += "Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa) as ObjetivoGerencia, "
       
      @sql += "((SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) - "
      @sql += "(SELECT SUM(" + @mestxt + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += "on(t3.IdAgrupa = t2.IdRegion) "
      @sql += "Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa)) as DifGerencia, "
       
      @sql +="if((SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) = 0,0," 
      @sql += "((((SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) - "
      @sql += "(SELECT SUM(" + @mestxt + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += "on(t3.IdAgrupa = t2.IdRegion) "
      @sql += "Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa))) / "
      @sql += "(SELECT SUM(" + @mestxt + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += "on(t3.IdAgrupa = t2.IdRegion) "
      @sql += "Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa)) * 100) as PorceGerencia, "
       
      @sql += "(SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa) as ObjetivoDireccion, "

      @sql += "(SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) - "
      @sql += "(SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa) as DifDireccion, "

      @sql +="if((SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) = 0,0," 
      @sql += "(((SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) - "
      @sql += "(SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa)) / "
      @sql += "(SELECT SUM(" + @mestxt + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa)) * 100) as PorceDireccion, "

      fromjoin = "FROM htotalmes as t2 LEFT JOIN " + nomDbComun + "agrupasuc as t3 on (t3.IdSucursal = t2.Sucursal) "
      fromjoin += "left join " + nomDbComun + "subagrupa as sb using(IdAgrupa) "
      fromjoin += "Where t3.IdAgrupa = Agrupa"

      @sql += "(SELECT ROUND(SUM(t2.stockMercancia),2) " + fromjoin + " and t2.mes = CONCAT(Año,'" + @mesnum + "')) as StockMercancia, "
      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and t2.mes = CONCAT(Año,'" + @mesnum + "')) as StockCxc, "

      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and t2.mes = if(MesSel = 1,CONCAT(Año - 1,'12'),CONCAT(Año,'" + @mesnumant + "'))   ) as StockCxcMesAnt, "

      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and t2.mes = CONCAT(Año,'" + @mesnum + "')) - "
      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and t2.mes = if(MesSel = 1,CONCAT(Año - 1,'12'),CONCAT(Año,'" + @mesnumant + "'))   ) as DifStockCxc "

      @sql += "FROM "
      @sql += "( "
      @sql += "  SELECT " + anosel + " as Año," + mes.to_s + " as MesSel,IdAgrupa as Agrupa,Nombre as NomRegion FROM " + nomDbComun + "agrupa where IdAgrupa = " + region + " order by NumOrd "
      @sql += ") tmp"
    end

    def query_global_ventas_anual_cd(anosel,region,nomDbComun)
      meses = "Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio + Agosto + Septiembre + Octubre + Noviembre + Diciembre"

      @sql = "SELECT NomCiudad as Ciudad, "
      @sql += "(SELECT " + meses + " from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) as VentaNeta, "
      @sql += "(SELECT SUM(" + meses + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += "on(t3.IdAgrupa = t2.IdRegion and t3.IdSucursal = t2.IdSucursal) "
      @sql += "Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa and t3.IdSubAgrupa = SubAgrupa) as ObjetivoGerencia, "
       
      @sql += "((SELECT " + meses + " from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) - "
      @sql += "(SELECT SUM(" + meses + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += "on(t3.IdAgrupa = t2.IdRegion and t3.IdSucursal = t2.IdSucursal) "
      @sql += "Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa and t3.IdSubAgrupa = SubAgrupa)) as DifGerencia, "
       
      @sql +="if((SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) = 0,0," 
      @sql += "((((SELECT " + meses + " from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) - "
      @sql += "(SELECT SUM(" + meses + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += "on(t3.IdAgrupa = t2.IdRegion and t3.IdSucursal = t2.IdSucursal) "
      @sql += "Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa and t3.IdSubAgrupa = SubAgrupa))) / "
      @sql += "(SELECT SUM(" + meses + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += "on(t3.IdAgrupa = t2.IdRegion and t3.IdSucursal = t2.IdSucursal) "
      @sql += "Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa and t3.IdSubAgrupa = SubAgrupa)) * 100) as PorceGerencia, "
       
      @sql += "(SELECT " + meses + " from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) as ObjetivoDireccion, "

      @sql += "(SELECT " + meses + " from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) - "
      @sql += "(SELECT " + meses + " from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) as DifDireccion, "

      @sql +="if((SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) = 0,0," 
      @sql += "(((SELECT " + meses + " from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) - "
      @sql += "(SELECT " + meses + " from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa)) / "
      @sql += "(SELECT " + meses + " from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa)) * 100) as PorceDireccion, "

      fromjoin = "FROM htotalmes as t2 LEFT JOIN " + nomDbComun + "agrupasuc as t3 on (t3.IdSucursal = t2.Sucursal) "
      fromjoin += "left join " + nomDbComun + "subagrupa as sb using(IdAgrupa,IdSubAgrupa) "
      fromjoin += "Where t3.IdAgrupa = Agrupa and t3.IdSubAgrupa = SubAgrupa"

      @sql += "(SELECT ROUND(SUM(t2.stockMercancia),2) " + fromjoin + " and left(t2.mes,4) = Año) as StockMercancia, "
      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and left(t2.mes,4) = Año) as StockCxc, "

      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and left(t2.mes,4) = Año - 1) as StockCxcMesAnt, "

      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and left(t2.mes,4) = Año) - "
      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and left(t2.mes,4) = Año - 1) as DifStockCxc "

      @sql += "FROM "
      @sql += "( "
      @sql += "  SELECT " + anosel + " as Año,IdAgrupa as Agrupa,IdSubAgrupa as SubAgrupa,Nombre as NomCiudad FROM " + nomDbComun + "subagrupa where IdAgrupa = " + region + " order by NumOrd "
      @sql += ") tmp"
    end

    def query_global_ventas_anual_total_cd(anosel,region,nomDbComun)
      meses = "Enero + Febrero + Marzo + Abril + Mayo + Junio + Julio + Agosto + Septiembre + Octubre + Noviembre + Diciembre"

      @sql = "SELECT NomRegion as Total, "
      @sql += "(SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) as VentaNeta, "
      @sql += "(SELECT SUM(" + meses + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += "on(t3.IdAgrupa = t2.IdRegion) "
      @sql += "Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa) as ObjetivoGerencia, "
       
      @sql += "((SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) - "
      @sql += "(SELECT SUM(" + meses + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += "on(t3.IdAgrupa = t2.IdRegion) "
      @sql += "Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa)) as DifGerencia, "
       
      @sql +="if((SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) = 0,0," 
      @sql += "((((SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) - "
      @sql += "(SELECT SUM(" + meses + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += "on(t3.IdAgrupa = t2.IdRegion) "
      @sql += "Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa))) / "
      @sql += "(SELECT SUM(" + meses + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sql += "on(t3.IdAgrupa = t2.IdRegion) "
      @sql += "Where Ano = Año and IdObjetivo = 4 and t3.IdAgrupa = Agrupa)) * 100) as PorceGerencia, "
       
      @sql += "(SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa) as ObjetivoDireccion, "

      @sql += "(SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) - "
      @sql += "(SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa) as DifDireccion, "

      @sql +="if((SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) = 0,0," 
      @sql += "(((SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) - "
      @sql += "(SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa)) / "
      @sql += "(SELECT SUM(" + meses + ") from objciudad as t2 Where Ano = Año and IdObjetivo = 4 and t2.IdRegion = Agrupa)) * 100) as PorceDireccion, "

      fromjoin = "FROM htotalmes as t2 LEFT JOIN " + nomDbComun + "agrupasuc as t3 on (t3.IdSucursal = t2.Sucursal) "
      fromjoin += "left join " + nomDbComun + "subagrupa as sb using(IdAgrupa) "
      fromjoin += "Where t3.IdAgrupa = Agrupa"

      @sql += "(SELECT ROUND(SUM(t2.stockMercancia),2) " + fromjoin + " and left(t2.mes,4) = Año) as StockMercancia, "
      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and left(t2.mes,4) = Año) as StockCxc, "

      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and left(t2.mes,4) = Año - 1) as StockCxcMesAnt, "

      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and left(t2.mes,4) = Año) - "
      @sql += "(SELECT ROUND(SUM(t2.stockCxc),2) " + fromjoin + " and left(t2.mes,4) = Año - 1) as DifStockCxc "

      @sql += "FROM "
      @sql += "( "
      @sql += "  SELECT " + anosel + " as Año,IdAgrupa as Agrupa,Nombre as NomRegion FROM " + nomDbComun + "agrupa where IdAgrupa = " + region + " order by NumOrd "
      @sql += ") tmp"
    end

    def indice(anosel,anocalc,mescalc)
      sql = "SELECT (pi1.INPC / pi2.INPC) as indice from promediosindices as pi1 inner join promediosindices as pi2"
      sql += "on(pi1.Ano = " + anocalc + " and pi1.Mes = " + mescalc + " and pi2.Ano = " + anosel + " and pi2.Mes = 1)"
      calcind = @dbEsta.connection.select_all(sql)
      if calcind && calcind.count == 1
        @indicec = calcind[0].indice 
      end
    end

    def query_objetivos_reg_cd(mes,anosel,anoant,region,nomDbComun)
      nomMes(mes)

      anosig = anosel.to_i + 1

      indcol1 = " / ROUND((SELECT (pi1.INPC / pi2.INPC) + .0001 as indice from indicesobjetivo as pi1 inner join indicesobjetivo as pi2 "
      indcol1 += "on(pi1.Ano = if(" + mes.to_s + " = 12," + anosel + "," + anoant + ") and pi1.Mes = " + @messig.to_s + " and pi2.Ano = " + anosel + " and pi2.Mes = 1)),4)"

      indcol2 = " / ROUND((SELECT (pi1.INPC / pi2.INPC) + .0001 as indice from indicesobjetivo as pi1 inner join indicesobjetivo as pi2 "
      indcol2 += "on(pi1.Ano = if(" + mes.to_s + " = 1," + anoant + "," + anosel + ") and pi1.Mes = " + @mesant.to_s + " and pi2.Ano = " + anosel + " and pi2.Mes = 1)),4)"

      indcol3 = " / ROUND((SELECT (pi1.INPC / pi2.INPC) + .0001 as indice from indicesobjetivo as pi1 inner join indicesobjetivo as pi2 "
      indcol3 += "on(pi1.Ano = " + anosel + " and pi1.Mes = " + mes.to_s + " and pi2.Ano = " + anosel + " and pi2.Mes = 1)),4)"

      @sqlcd = "SELECT NomCiudad as Ciudad, "
      @sqlcd += "(SELECT " + @mesnomsig + indcol1 + " from objciudad as t2 Where Ano = if(" + mes.to_s + " = 12," + anosel + "," + anoant + ") and IdObjetivo = 6 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) as VtaAMAnt, "

      @sqlcd += "(SELECT " + @mesnomant + indcol2 + " from objciudad as t2 Where Ano = if(" + mes.to_s + " = 1," + anoant + "," + anosel + ") and IdObjetivo = 6 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) as VtaAAntMSig, "

      @sqlcd += "(SELECT " + @mestxt + indcol3 + " from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) as VtaAMAct, "

      @sqlcd += "ROUND(((SELECT " + @mestxt + indcol3 + " from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) / "
      @sqlcd += "(SELECT SUM(" + @mestxt + indcol3 + ") from objsucursal as t2 Where Ano = Año and IdObjetivo = 90 and t2.IdRegion = CONCAT(Agrupa,'1') and t2.IdSucursal = 9)) * 100,2) as PorcePart, "

      @sqlcd += "COALESCE((SELECT SUM(" + @mesnomsig + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sqlcd += "on(IdRegion = IdAgrupa and t2.IdSucursal = t3.IdSucursal) "
      @sqlcd += "Where Ano = if(" + mes.to_s + " = 12," + anosig.to_s + "," + anosel + ") and IdObjetivo = 4 and t2.IdRegion = Agrupa and t3.IdSubAgrupa = SubAgrupa group by t2.IdRegion,t3.IdSubAgrupa),0) as ObjCalMSig, "

      @sqlcd += "ROUND((((SELECT SUM(" + @mesnomsig + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sqlcd += "on(IdRegion = IdAgrupa and t2.IdSucursal = t3.IdSucursal) "
      @sqlcd += "Where Ano = if(" + mes.to_s + " = 12," + anosig.to_s + "," + anosel + ") and IdObjetivo = 4 and t2.IdRegion = Agrupa and t3.IdSubAgrupa = SubAgrupa group by t2.IdRegion,t3.IdSubAgrupa) / "
      @sqlcd += "(SELECT " + @mesnomsig + indcol1 + " from objciudad as t2 Where Ano = if(" + mes.to_s + " = 12," + anosel + "," + anoant + ") and IdObjetivo = 6 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa)) - 1) * 100, 2) as CrecEsp, "

      @sqlcd += "(SELECT " + @mesnomsig + " from objciudad as t2 Where Ano = if(" + mes.to_s + " = 12," + anosig.to_s + "," + anosel + ") and IdObjetivo = 4 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) as ObjDir, "

      @sqlcd += "((((SELECT " + @mesnomsig + " from objciudad as t2 Where Ano = if(" + mes.to_s + " = 12," + anosig.to_s + "," + anosel + ") and IdObjetivo = 4 and t2.IdRegion = Agrupa and t2.IdCiudad = SubAgrupa) / "

      @sqlcd += "COALESCE((SELECT SUM(" + @mesnomsig + ") from objsucursal as t2 inner join " + nomDbComun + "agrupasuc as t3 "
      @sqlcd += "on(IdRegion = IdAgrupa and t2.IdSucursal = t3.IdSucursal) "
      @sqlcd += "Where Ano = if(" + mes.to_s + " = 12," + anosig.to_s + "," + anosel + ") and IdObjetivo = 4 and t2.IdRegion = Agrupa and t3.IdSubAgrupa = SubAgrupa group by t2.IdRegion,t3.IdSubAgrupa),0)) - 1 ) * 100 ) as ObjVsObj "

      @sqlcd += "FROM "
      @sqlcd += "( "
      @sqlcd += "  SELECT " + anosel + " as Año,IdAgrupa as Agrupa,IdSubAgrupa as SubAgrupa,Nombre as NomCiudad FROM " + nomDbComun + "subagrupa where IdAgrupa = " + region + " order by NumOrd "
      @sqlcd += ") tmp "
    end

    def query_objetivos_reg_suc(mes,anosel,anoant,region,nomDbComun)
      nomMes(mes)

      anosig = anosel.to_i + 1

      indcol1 = " / ROUND((SELECT (pi1.INPC / pi2.INPC) + .0001 as indice from indicesobjetivo as pi1 inner join indicesobjetivo as pi2 "
      indcol1 += "on(pi1.Ano = if(" + mes.to_s + " = 12," + anosel + "," + anoant + ") and pi1.Mes = " + @messig.to_s + " and pi2.Ano = " + anosel + " and pi2.Mes = 1)),4)"

      indcol2 = " / ROUND((SELECT (pi1.INPC / pi2.INPC) + .0001 as indice from indicesobjetivo as pi1 inner join indicesobjetivo as pi2 "
      indcol2 += "on(pi1.Ano = if(" + mes.to_s + " = 1," + anoant + "," + anosel + ") and pi1.Mes = " + @mesant.to_s + " and pi2.Ano = " + anosel + " and pi2.Mes = 1)),4)"

      indcol3 = " / ROUND((SELECT (pi1.INPC / pi2.INPC) + .0001 as indice from indicesobjetivo as pi1 inner join indicesobjetivo as pi2 "
      indcol3 += "on(pi1.Ano = " + anosel + " and pi1.Mes = " + mes.to_s + " and pi2.Ano = " + anosel + " and pi2.Mes = 1)),4)"

      @sqlsuc = "SELECT NomSuc as Sucursal, "
      @sqlsuc += "(SELECT " + @mesnomsig + indcol1 + " from objsucursal as t2 Where Ano = if(" + mes.to_s + " = 12," + anosel + "," + anoant + ") and IdObjetivo = 6 and t2.IdSucursal = suc) as VtaAMAnt, "

      @sqlsuc += "(SELECT " + @mesnomant + indcol2 + " from objsucursal as t2 Where Ano = if(" + mes.to_s + " = 1," + anoant + "," + anosel + ") and IdObjetivo = 6 and t2.IdSucursal = suc) as VtaAAntMSig, "

      @sqlsuc += "(SELECT " + @mestxt + indcol3 + " from objsucursal as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdSucursal = suc) as VtaAMAct, "

      @sqlsuc += "ROUND(((SELECT " + @mestxt + indcol3 + " from objsucursal as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdSucursal = suc) / "
      @sqlsuc += "(SELECT " + @mestxt + indcol3 + " from objsucursal as t2 Where Ano = Año and IdObjetivo = 90 and t2.IdRegion = CONCAT(Agrupa,'1') and t2.IdSucursal = 9)) * 100,2) as PorcePart, "

      @sqlsuc += "(SELECT " + @mesnomsig + " from objsucursal as t2 Where Ano = if(" + mes.to_s + " = 12," + anosig.to_s + "," + anosel + ") and IdObjetivo = 4 and t2.IdSucursal = suc) as ObjCalMSig,"

      @sqlsuc += "ROUND((((SELECT " + @mesnomsig + " from objsucursal as t2 Where Ano = if(" + mes.to_s + " = 12," + anosig.to_s + "," + anosel + ") and IdObjetivo = 4 and t2.IdSucursal = suc) / "
      @sqlsuc += "(SELECT " + @mesnomsig + indcol1 + " from objsucursal as t2 Where Ano = if(" + mes.to_s + " = 12," + anosel + "," + anoant + ") and IdObjetivo = 6 and t2.IdSucursal = suc)) - 1) * 100,2) as CrecEsp "

      @sqlsuc += "FROM "
      @sqlsuc += "( "
      @sqlsuc += "  SELECT " + anosel + " as Año,IdAgrupa as Agrupa,IdSucursal as Suc,Nombre as NomSuc FROM " + nomDbComun + "agrupasuc where IdAgrupa = " + region + " order by IdSucursal "
      @sqlsuc += ") tmp"

    end

    def query_objetivos_reg_tot_cd(mes,anosel,anoant,region,nomDbComun)
      nomMes(mes)

      anosig = anosel.to_i + 1

      indcol1 = " / ROUND((SELECT (pi1.INPC / pi2.INPC) + .0001 as indice from indicesobjetivo as pi1 inner join indicesobjetivo as pi2 "
      indcol1 += "on(pi1.Ano = if(" + mes.to_s + " = 12," + anosel + "," + anoant + ") and pi1.Mes = " + @messig.to_s + " and pi2.Ano = " + anosel + " and pi2.Mes = 1)),4)"

      indcol2 = " / ROUND((SELECT (pi1.INPC / pi2.INPC) + .0001 as indice from indicesobjetivo as pi1 inner join indicesobjetivo as pi2 "
      indcol2 += "on(pi1.Ano = if(" + mes.to_s + " = 1," + anoant + "," + anosel + ") and pi1.Mes = " + @mesant.to_s + " and pi2.Ano = " + anosel + " and pi2.Mes = 1)),4)"

      indcol3 = " / ROUND((SELECT (pi1.INPC / pi2.INPC) + .0001 as indice from indicesobjetivo as pi1 inner join indicesobjetivo as pi2 "
      indcol3 += "on(pi1.Ano = " + anosel + " and pi1.Mes = " + mes.to_s + " and pi2.Ano = " + anosel + " and pi2.Mes = 1)),4)"

      @sqlcd = "SELECT Nombre, "
      @sqlcd += "(SELECT SUM(" + @mesnomsig + ") " + indcol1 + " from objciudad as t2 Where Ano = if(" + mes.to_s + " = 12," + anosel + "," + anoant + ") and IdObjetivo = 6 and t2.IdRegion = Agrupa) as VtaAMAnt, "

      @sqlcd += "(SELECT SUM(" + @mesnomant + ") " + indcol2 + " from objciudad as t2 Where Ano = if(" + mes.to_s + " = 1," + anoant + "," + anosel + ") and IdObjetivo = 6 and t2.IdRegion = Agrupa) as VtaAAntMSig, "

      @sqlcd += "(SELECT SUM(" + @mestxt + ") " + indcol3 + " from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) as VtaAMAct, "

      @sqlcd += "ROUND(((SELECT SUM(" + @mestxt + ") " + indcol3 + " from objciudad as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) / "
      @sqlcd += "(SELECT SUM(" + @mestxt + ") " + indcol3 + " from objsucursal as t2 Where Ano = Año and IdObjetivo = 90 and t2.IdRegion = CONCAT(Agrupa,'1') and t2.IdSucursal = 9)) * 100,2) as PorcePart, "

      @sqlcd += "COALESCE((SELECT SUM(" + @mesnomsig + ") from objsucursal as t2 "
      @sqlcd += "Where Ano = if(" + mes.to_s + " = 12," + anosig.to_s + "," + anosel + ") and IdObjetivo = 4 and t2.IdRegion = Agrupa),0) as ObjCalMSig, "

      @sqlcd += "ROUND((((SELECT SUM(" + @mesnomsig + ") from objsucursal as t2 "
      @sqlcd += "Where Ano = if(" + mes.to_s + " = 12," + anosig.to_s + "," + anosel + ") and IdObjetivo = 4 and t2.IdRegion = Agrupa group by t2.IdRegion) / "
      @sqlcd += "(SELECT SUM(" + @mesnomsig + ") " + indcol1 + " from objciudad as t2 Where Ano = if(" + mes.to_s + " = 12," + anosel + "," + anoant + ") and IdObjetivo = 6 and t2.IdRegion = Agrupa)) - 1) * 100, 2) as CrecEsp, "

      @sqlcd += "(SELECT SUM(" + @mesnomsig + ") from objciudad as t2 Where Ano = if(" + mes.to_s + " = 12," + anosig.to_s + "," + anosel + ") and IdObjetivo = 4 and t2.IdRegion = Agrupa) as ObjDir, "

      @sqlcd += "((((SELECT SUM(" + @mesnomsig + ") from objciudad as t2 Where Ano = if(" + mes.to_s + " = 12," + anosig.to_s + "," + anosel + ") and IdObjetivo = 4 and t2.IdRegion = Agrupa) / "

      @sqlcd += "COALESCE((SELECT SUM(" + @mesnomsig + ") from objsucursal as t2 "
      @sqlcd += "Where Ano = if(" + mes.to_s + " = 12," + anosig.to_s + "," + anosel + ") and IdObjetivo = 4 and t2.IdRegion = Agrupa group by t2.IdRegion),0)) - 1 ) * 100 ) as ObjVsObj "

      @sqlcd += "FROM "
      @sqlcd += "( "
      @sqlcd += "  SELECT " + anosel + " as Año,IdAgrupa as Agrupa,Nombre FROM " + nomDbComun + "agrupa where IdAgrupa = " + region 
      @sqlcd += ") tmp "
    end

    def query_objetivos_reg_tot_suc(mes,anosel,anoant,region,nomDbComun)
      nomMes(mes)

      anosig = anosel.to_i + 1

      indcol1 = " / ROUND((SELECT (pi1.INPC / pi2.INPC) + .0001 as indice from indicesobjetivo as pi1 inner join indicesobjetivo as pi2 "
      indcol1 += "on(pi1.Ano = if(" + mes.to_s + " = 12," + anosel + "," + anoant + ") and pi1.Mes = " + @messig.to_s + " and pi2.Ano = " + anosel + " and pi2.Mes = 1)),4)"

      indcol2 = " / ROUND((SELECT (pi1.INPC / pi2.INPC) + .0001 as indice from indicesobjetivo as pi1 inner join indicesobjetivo as pi2 "
      indcol2 += "on(pi1.Ano = if(" + mes.to_s + " = 1," + anoant + "," + anosel + ") and pi1.Mes = " + @mesant.to_s + " and pi2.Ano = " + anosel + " and pi2.Mes = 1)),4)"

      indcol3 = " / ROUND((SELECT (pi1.INPC / pi2.INPC) + .0001 as indice from indicesobjetivo as pi1 inner join indicesobjetivo as pi2 "
      indcol3 += "on(pi1.Ano = " + anosel + " and pi1.Mes = " + mes.to_s + " and pi2.Ano = " + anosel + " and pi2.Mes = 1)),4)"

      @sqlsuc = "SELECT Nombre, "
      @sqlsuc += "(SELECT SUM(" + @mesnomsig + ") " + indcol1 + " from objsucursal as t2 Where Ano = if(" + mes.to_s + " = 12," + anosel + "," + anoant + ") and IdObjetivo = 6 and t2.IdRegion = Agrupa) as VtaAMAnt, "

      @sqlsuc += "(SELECT SUM(" + @mesnomant + ") " + indcol2 + " from objsucursal as t2 Where Ano = if(" + mes.to_s + " = 1," + anoant + "," + anosel + ") and IdObjetivo = 6 and t2.IdRegion = Agrupa) as VtaAAntMSig, "

      @sqlsuc += "(SELECT SUM(" + @mestxt + ") " + indcol3 + " from objsucursal as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) as VtaAMAct, "

      @sqlsuc += "ROUND(((SELECT SUM(" + @mestxt + ") " + indcol3 + " from objsucursal as t2 Where Ano = Año and IdObjetivo = 6 and t2.IdRegion = Agrupa) / "
      @sqlsuc += "(SELECT SUM(" + @mestxt + ") " + indcol3 + " from objsucursal as t2 Where Ano = Año and IdObjetivo = 90 and t2.IdRegion = CONCAT(Agrupa,'1') and t2.IdSucursal = 9)) * 100,2) as PorcePart, "

      @sqlsuc += "(SELECT SUM(" + @mesnomsig + ") from objsucursal as t2 Where Ano = if(" + mes.to_s + " = 12," + anosig.to_s + "," + anosel + ") and IdObjetivo = 4 and t2.IdRegion = Agrupa) as ObjCalMSig,"

      @sqlsuc += "ROUND((((SELECT SUM(" + @mesnomsig + ") from objsucursal as t2 Where Ano = if(" + mes.to_s + " = 12," + anosig.to_s + "," + anosel + ") and IdObjetivo = 4 and t2.IdRegion = Agrupa) / "
      @sqlsuc += "(SELECT SUM(" + @mesnomsig + ") " + indcol1 + " from objsucursal as t2 Where Ano = if(" + mes.to_s + " = 12," + anosel + "," + anoant + ") and IdObjetivo = 6 and t2.IdRegion = Agrupa)) - 1) * 100,2) as CrecEsp "

      @sqlsuc += "FROM "
      @sqlsuc += "( "
      @sqlsuc += "  SELECT " + anosel + " as Año,IdAgrupa as Agrupa,Nombre FROM " + nomDbComun + "agrupa where IdAgrupa = " + region 
      @sqlsuc += ") tmp"

    end

end
