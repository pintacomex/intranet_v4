#!/bin/env ruby
# encoding: utf-8
class RepobjetivosController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app
  include ActionView::Helpers::NumberHelper

  def repobjetivos_zona
    @continua = 0

    if !params.has_key?(:periodo) || !params[:periodo].to_i
      anoFechaAct = DateTime.now.year.to_s
      mesFechaAct = DateTime.now.month.to_s
      anomesFechaAct = anoFechaAct + mesFechaAct.prepend("00").from(-2)
      params[:periodo] = anomesFechaAct
      params[:solosucsconobj] = "1"
    end
    @anomes = params[:periodo].to_s if params.has_key?(:periodo)
    ano = params[:periodo].to_s.first(4) if params.has_key?(:periodo)
    mes = params[:periodo].to_s.last(2) if params.has_key?(:periodo)
    @solosucsconobj = params[:solosucsconobj].to_i if params.has_key?(:solosucsconobj)
    if @solosucsconobj
      wheresolosucsconobj = "tObjV.Objetivo and "
    else
      wheresolosucsconobj = ""
    end

# Navegación y seguridad de la página
    user_permisos = { nivel: 0, wherezonaasig: "", primerzonaasig: 0, sucursal: 0 }
    @permisos = Permiso.where("idUsuario = #{current_user.id} and p1 = #{@sitio[0].idEmpresa}").order("p2")
    @permisos.each do |p|
      user_permisos[:nivel] = CatRole.where("nomPermiso = '#{p.permiso}'").first.nivel rescue -1
      if p.p2.to_i > 0
        if user_permisos[:primerzonaasig].to_i == 0
          user_permisos[:primerzonaasig] = p.p2.to_i
        end
        if user_permisos[:wherezonaasig].length > 0
          user_permisos[:wherezonaasig] = user_permisos[:wherezonaasig] + " or "
        end
        user_permisos[:wherezonaasig] = user_permisos[:wherezonaasig] + "tTotM.zonaAsig = " + p.p2.to_s
      end
      if p.p3.to_i > 0
        user_permisos[:sucursal] = p.p3.to_i
        break
      end
    end
    if @permisos.count == 0
      return redirect_to "/", alert: "No autorizado"
    end

    if user_permisos[:wherezonaasig].length > 0
      user_permisos[:wherezonaasig].prepend('(')
      user_permisos[:wherezonaasig] = user_permisos[:wherezonaasig] + ") and "
    end
    if (user_permisos[:nivel] <= 10 or user_permisos[:nivel] == 30 or user_permisos[:nivel] == 50)
      if user_permisos[:sucursal] > 0
        return redirect_to "/repobjetivos_suc?periodo=#{@anomes}&sucursal=#{user_permisos[:sucursal]}&zona=#{user_permisos[:primerzonaasig]}"
      end
    else
      return redirect_to "/", alert: "No autorizado"
    end
###
    @continua = 1   #Se puede eliminar pues siempre se reciben parámetros ya validados.

    if @continua > 0
      case mes.to_i
      when 1 
        @nommes = 'Enero'
      when 2 
        @nommes = 'Febrero'
      when 3 
        @nommes = 'Marzo'
      when 4 
        @nommes = 'Abril'
      when 5 
        @nommes = 'Mayo'
      when 6 
        @nommes = 'Junio'
      when 7 
        @nommes = 'Julio'
      when 8 
        @nommes = 'Agosto'
      when 9 
        @nommes = 'Septiembre'
      when 10 
        @nommes = 'Octubre'
      when 11 
        @nommes = 'Noviembre'
      when 12 
        @nommes = 'Diciembre'
      end

      iva = "(select " +
               "(max(iva) + 100) / 100 " +
             "from " + @nomDbComun.to_s + "iva " +
             "where " +
               "zona = tTotM.ZonaAsig and " +
               "left(FechaFac,6) <= " + @anomes + 
            ") "

      sql = 
        "select " +
          "NumZona as ColZona, " +
          "NomZona as ColNombre, " +
          "if (ObjetivoSuc > 0, ObjetivoSuc, 0) as ColObjetivo, " +
          "VtaNetaAcum as ColVtaNetaAcum, " +
          "if (ObjetivoSuc > 0, " +
             "if (ObjPropAcum = 0, " +
                 "if (VtaNetaAcum = 0, " +
                     "0, " +
                     "100 " +
                 "), " +
                 "round((VtaNetaAcum * 100) / ObjPropAcum, 2) - 100 " +
             "), " +
             "100 " +
          ") as ColAvancePropor, " +
          "VentaNetaCred as ColVentaNetaCred, " +
          "TotalCobranza as ColTotalCobranza, " +
          "StockCxC0_60Dias as ColStockCxC0_60Dias, " +
          "StockCxC61_Dias as ColStockCxC61_Dias, " +
          "StockMercancia as ColStockMercancia " +
        "from " +
        "( " +
          "select " +
            "tTotM.ZonaAsig as NumZona, " +
            "tZon.NomZona as NomZona, " +
            "sum(tObjV.Objetivo) as ObjetivoSuc, " +
            "sum((tTotM.vtaNeta / " + iva + ")) as VtaNetaAcum, " +
            "if (month(curdate()) = " + mes.to_s + ", " +
               "(sum(tObjV.Objetivo) / sum(tTotM.DiasHabDelMes)) * (sum(tTotM.DiasHabDelMes) - sum(tTotM.DiasHabFaltantes)), " +
               "coalesce (sum(tObjV.Objetivo) / if(sum(tTotM.DiasHabDelMes) > sum(tTotM.DiasTrabajados), " +
                                             "sum(tTotM.DiasHabDelMes), " +
                                             "sum(tTotM.DiasTrabajados)) " +
                        ",0 ) * sum(tTotM.DiasTrabajados) " +
            ") as ObjPropAcum, " +
            "sum(tTotM.vtaNetaCredito) as VentaNetaCred, " +
            "sum(tTotM.Cobranza) as TotalCobranza, " +
            "sum(tTotM.stockCxC0_60Dias) as StockCxC0_60Dias, " +
            "sum(tTotM.stockCxc - tTotM.stockCxC0_60Dias) as StockCxC61_Dias, " +
            "sum(tTotM.stockMercancia) as StockMercancia " +
          "from htotalmes as tTotM " +
            "inner join " + @nomDbComun.to_s + "sucursal as tSuc " +
            "on " +
              "tSuc.Num_suc = tTotM.Sucursal " +
            "inner join " + @nomDbComun.to_s + "zonas as tZon " +
            "on " +
              "tZon.NumZona = tTotM.ZonaAsig " +
            "left join " + @nomDbPdv.to_s + "objventas as tObjV " +
            "on " +
              "tObjV.IdSucursal = tTotM.Sucursal and " +
              "tObjV.IdAno = " + ano.to_s + " and " +
              "tObjV.IdMes = " + mes.to_s + " " +
          "where " +
            "tTotM.Mes = " + @anomes + " and " +
#            "(tSuc.TipoSuc = 'S' or tSuc.TipoSuc = 'B') and " +
            wheresolosucsconobj +
            user_permisos[:wherezonaasig] +
            "(tSuc.FechaTerm = '' or " +
            "(tSuc.FechaTerm <> '' and tSuc.FechaTerm >= '" + @anomes + "01')) " +
          "group by " +
            "tTotM.ZonaAsig " +
          "order by " +
            "tTotM.ZonaAsig " +
        ") qDeriv "
      @objventaszona = @dbEsta.connection.select_all(sql)
    end

    respond_to do |format|
      format.html
      format.csv do 
        out_arr = []
        if @continua > 0
          out_arr.push("")
          out_arr.push(" , , ,Reporte de, Objetivos, globales, por Zona")
          out_arr.push("")
          out_arr.push(" ,#{@nommes} de #{params[:periodo].to_s.first(4)}")
          out_arr.push("")
          out_arr.push("Zona,Nombre,Objetivo,VentaNetaAcum,AvancePropor,VentaNetaCred,TotalCobranza,StockCxC 0-60 dias,StockCxC 60+ dias,StockMercancia")
          @objventaszona.each do |m|
            out_arr.push("#{m['ColZona']},#{m['ColNombre']},#{number_to_currency(m['ColObjetivo'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['ColVtaNetaAcum'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_percentage(m['ColAvancePropor'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['ColVentaNetaCred'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['ColTotalCobranza'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['ColStockCxC0_60Dias'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['ColStockCxC61_Dias'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['ColStockMercancia'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}")
          end
        end
        csv_file = "/tmp/objventaszona_#{DateTime.now.to_i}.csv"
        dump_to_file(csv_file,out_arr.join("\n"))
        send_file csv_file
        return
      end
    end

  end

  def repobjetivos_suc
    @continua = 0

    @anomes = params[:periodo].to_s if params.has_key?(:periodo)
    ano    = params[:periodo].to_s.first(4) if params.has_key?(:periodo)
    mes    = params[:periodo].to_s.last(2) if params.has_key?(:periodo)
    @zona  = params[:zona].to_s if params.has_key?(:zona)
    @suc   = params[:sucursal].to_s if params.has_key?(:sucursal)

# Navegación y seguridad de la página
    user_permisos = { nivel: 0, primerzonaasig: 0, escorrectazonaurl: 0, sucursal: 0 }
    @permisos = Permiso.where("idUsuario = #{current_user.id} and p1 = #{@sitio[0].idEmpresa}").order("p2")
    @permisos.each do |p|
      user_permisos[:nivel] = CatRole.where("nomPermiso = '#{p.permiso}'").first.nivel rescue -1
      if p.p2.to_i > 0
        if user_permisos[:primerzonaasig].to_i == 0
          user_permisos[:primerzonaasig] = p.p2.to_i
        end
        if p.p2.to_i == @zona.to_i
          user_permisos[:escorrectazonaurl] = 1
        end
      else
        user_permisos[:escorrectazonaurl] = 1
      end
      if p.p3.to_i > 0
        user_permisos[:sucursal] = p.p3.to_i
        break
      end
    end
    if @permisos.count == 0
      return redirect_to "/", alert: "No autorizado"
    end

    if (user_permisos[:nivel] <= 10 or user_permisos[:nivel] == 30 or user_permisos[:nivel] == 50)
      if user_permisos[:sucursal] > 0 and user_permisos[:sucursal] != @suc
        params[:zona] = user_permisos[:primerzonaasig]
        params[:sucursal] = user_permisos[:sucursal]
        params[:solosucsconobj] = "0"
        @zona = params[:zona].to_s
        @suc  = params[:sucursal].to_s
      else
        if user_permisos[:escorrectazonaurl].to_i == 0
          params[:zona] = user_permisos[:primerzonaasig]
          @zona = params[:zona].to_s
          params[:solosucsconobj] = "1"
        end
      end
    else
      return redirect_to "/", alert: "No autorizado"
    end
###

    whereSucursal = ""
    if @suc.to_i > 0 
      whereSucursal = "tTotM.sucursal = " + @suc + " and "
    end
    @solosucsconobj = params[:solosucsconobj].to_i if params.has_key?(:solosucsconobj)
    if @solosucsconobj
      wheresolosucsconobj = "tObjV.Objetivo and "
    else
      wheresolosucsconobj = ""
    end

    if @zona.to_i > 0 && @anomes.to_i > 0
      @continua = 1
    end

    if @continua > 0
      case mes.to_i
      when 1 
        @nommes = 'Enero'
      when 2 
        @nommes = 'Febrero'
      when 3 
        @nommes = 'Marzo'
      when 4 
        @nommes = 'Abril'
      when 5 
        @nommes = 'Mayo'
      when 6 
        @nommes = 'Junio'
      when 7 
        @nommes = 'Julio'
      when 8 
        @nommes = 'Agosto'
      when 9 
        @nommes = 'Septiembre'
      when 10 
        @nommes = 'Octubre'
      when 11 
        @nommes = 'Noviembre'
      when 12 
        @nommes = 'Diciembre'
      end

      iva = "(select " +
               "(max(iva) + 100) / 100 " +
             "from " + @nomDbComun.to_s + "iva " +
             "where " +
               "zona = " + @zona + " and " +
               "left(FechaFac,6) <= " + @anomes + 
            ") "

      sql = 
        "select " +
          "NumSucursal as ColSucursal, " +
          "Nombre as ColNombre, " +
          "DatosAlDia as ColDatosAlDia, " +
          "if (ObjetivoSuc > 0, ObjetivoSuc, 0) as ColObjetivo, " +
          "VtaNetaAcum as ColVtaNetaAcum, " +
#          "ObjPropAcum as ColObjPropAcum, " +
          "if (ObjetivoSuc > 0, " +
             "if (ObjPropAcum = 0, " +
                 "if (VtaNetaAcum = 0, " +
                     "0, " +
                     "100 " +
                 "), " +
                 "round((VtaNetaAcum * 100) / ObjPropAcum, 2) - 100 " +
             "), " +
             "100 " +
          ") as ColAvancePropor, " +
          "VentaNetaCred as ColVentaNetaCred, " +
          "TotalCobranza as ColTotalCobranza, " +
          "StockCxC0_60Dias as ColStockCxC0_60Dias, " +
          "StockCxC61_Dias as ColStockCxC61_Dias, " +
          "StockMercancia as ColStockMercancia, " +
          "DiasHabFaltantes as ColDiasHabFaltantes " +
        "from " +
        "( " +
          "select " +
            "tTotM.Sucursal as NumSucursal, " +
            "tSuc.Nombre as Nombre, " +
            "tTotM.DatosAlDia as DatosAlDia, " +
            "tObjV.Objetivo as ObjetivoSuc, " +
            "(tTotM.vtaNeta / " + iva + ") as VtaNetaAcum, " +
            "if (month(curdate()) = " + mes.to_s + ", " +
               "(tObjV.Objetivo / tTotM.DiasHabDelMes) * (tTotM.DiasHabDelMes - tTotM.DiasHabFaltantes), " +
               "coalesce (tObjV.Objetivo / if(tTotM.DiasHabDelMes > tTotM.DiasTrabajados, " +
                                             "tTotM.DiasHabDelMes, " +
                                             "tTotM.DiasTrabajados) " +
                        ",0 ) * tTotM.DiasTrabajados " +
            ") as ObjPropAcum, " +
            "tTotM.vtaNetaCredito as VentaNetaCred, " +
            "tTotM.cobranza as TotalCobranza, " +
            "tTotM.stockCxC0_60Dias as StockCxC0_60Dias, " +
            "(tTotM.stockCxc - tTotM.stockCxC0_60Dias) as StockCxC61_Dias, " +
            "tTotM.stockMercancia as StockMercancia, " +
            "tTotM.DiasHabFaltantes as DiasHabFaltantes " +
          "from htotalmes as tTotM " +
            "inner join " + @nomDbComun.to_s + "sucursal as tSuc " +
            "on " +
              "tSuc.Num_suc = tTotM.Sucursal " +
            "left join " + @nomDbPdv.to_s + "objventas as tObjV " +
            "on " +
              "tObjV.IdSucursal = tTotM.Sucursal and " +
              "tObjV.IdAno = " + ano.to_s + " and " +
              "tObjV.IdMes = " + mes.to_s + " " +
          "where " +
            "tTotM.Mes = " + @anomes + " and " +
            whereSucursal +
            "tTotM.ZonaAsig = " + @zona + " and " +
#            "(tSuc.TipoSuc = 'S' or tSuc.TipoSuc = 'B') and " +
            wheresolosucsconobj +
            "(tSuc.FechaTerm = '' or " +
            "(tSuc.FechaTerm <> '' and tSuc.FechaTerm >= '" + @anomes + "01')) " +
          "order by " +
            "tTotM.Sucursal " +
        ") qDeriv "
      @objventassuc = @dbEsta.connection.select_all(sql)

      sql = "SELECT NomZona FROM zonas where NumZona = " + @zona
      @nomzona = @dbComun.connection.select_all(sql)
    end

    sql = "SELECT NumZona,NomZona FROM zonas where NumZona "
    @zonas = @dbComun.connection.select_all(sql)

    respond_to do |format|
      format.html
      format.csv do 
        out_arr = []
        if @continua > 0
          out_arr.push("")
          out_arr.push(" , , ,Reporte de, Objetivos")
          out_arr.push("")
          out_arr.push(" ,#{@nommes} de #{params[:periodo].to_s.first(4)}")
          out_arr.push(" ,Zona: #{@zona}-#{@nomzona[0]['NomZona']}")
          out_arr.push("")
          out_arr.push("Sucursal,Nombre,DatosAlDia,Objetivo,VentaNetaAcum,AvancePropor,VentaNetaCred,TotalCobranza,StockCxC 0-60 dias,StockCxC 60+ dias,StockMercancia,DiasHabFalt")
          @objventassuc.each do |m|
            out_arr.push("#{m['ColSucursal']},#{m['ColNombre']},#{m['ColDatosAlDia']},#{number_to_currency(m['ColObjetivo'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['ColVtaNetaAcum'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_percentage(m['ColAvancePropor'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['ColVentaNetaCred'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['ColTotalCobranza'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['ColStockCxC0_60Dias'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['ColStockCxC61_Dias'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['ColStockMercancia'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{m['ColDatosAlDia']}")
          end
        end
        csv_file = "/tmp/objventassuc_#{DateTime.now.to_i}.csv"
        dump_to_file(csv_file,out_arr.join("\n"))
        send_file csv_file
        return
      end
    end

  end

  def repobjetivos_det_suc
    @continua = 0

    @anomesactual = params[:periodo].to_s if params.has_key?(:periodo)
    @anoactual   = params[:periodo].to_s.first(4) if params.has_key?(:periodo)
    mesactual    = params[:periodo].to_s.last(2) if params.has_key?(:periodo)
    @anoanterior = (@anoactual.to_i-1).to_s
    @zona = params[:zona].to_s if params.has_key?(:zona)
    @suc = params[:suc].to_s if params.has_key?(:suc)

# Navegación y seguridad de la página
    user_permisos = { nivel: 0, primerzonaasig: 0, escorrectazonaurl: 0, sucursal: 0 }
    @permisos = Permiso.where("idUsuario = #{current_user.id} and p1 = #{@sitio[0].idEmpresa}").order("p2")
    @permisos.each do |p|
      user_permisos[:nivel] = CatRole.where("nomPermiso = '#{p.permiso}'").first.nivel rescue -1
      if p.p2.to_i > 0
        if user_permisos[:primerzonaasig].to_i == 0
          user_permisos[:primerzonaasig] = p.p2.to_i
        end
        if p.p2.to_i == @zona.to_i
          user_permisos[:escorrectazonaurl] = 1
        end
      else
        user_permisos[:escorrectazonaurl] = 1
      end
      if p.p3.to_i > 0
        user_permisos[:sucursal] = p.p3.to_i
        break
      end
    end
    if @permisos.count == 0
      return redirect_to "/", alert: "No autorizado"
    end

    if (user_permisos[:nivel] <= 10 or user_permisos[:nivel] == 30 or user_permisos[:nivel] == 50)
      if user_permisos[:sucursal] > 0 and user_permisos[:sucursal] != @suc
        params[:zona] = user_permisos[:primerzonaasig]
        params[:sucursal] = user_permisos[:sucursal]
        @zona = params[:zona].to_s
        @suc  = params[:sucursal].to_s
      else
        if user_permisos[:escorrectazonaurl].to_i == 0
          params[:zona] = user_permisos[:primerzonaasig]
          @zona = params[:zona].to_s
        end
      end
    else
      return redirect_to "/", alert: "No autorizado"
    end
###

    if @zona.to_i > 0 && @suc.to_i > 0
      @continua = 1
    end

    if @continua > 0
      case mesactual.to_i
      when 1 
        @nommes = 'ENERO'
      when 2 
        @nommes = 'FEBRERO'
      when 3 
        @nommes = 'MARZO'
      when 4 
        @nommes = 'ABRIL'
      when 5 
        @nommes = 'MAYO'
      when 6 
        @nommes = 'JUNIO'
      when 7 
        @nommes = 'JULIO'
      when 8 
        @nommes = 'AGOSTO'
      when 9 
        @nommes = 'SEPTIEMBRE'
      when 10 
        @nommes = 'OCTUBRE'
      when 11 
        @nommes = 'NOVIEMBRE'
      when 12 
        @nommes = 'DICIEMBRE'
      end

      sql = 
        "select " +
          "tTotM.mes, " +
          "tTotM.vtaNeta, " +
          "tTotM.vtaNetaContGral, " +
          "tTotM.vtaNetaContCliDes, " +
          "tTotM.vtaNetaCredito, " +
          "tTotM.vtaCosto, " +
          "tTotM.vtaCostoContGral, " +
          "tTotM.vtaCostoContCliDes, " +
          "tTotM.vtaCostoCredito, " +
          "((tTotM.vtaNeta - tTotM.vtaCosto) / tTotM.vtaNeta * 100 " +
          ") as mUtil, " +
          "((tTotM.vtaNetaContGral - tTotM.vtaCostoContGral) / tTotM.vtaNetaContGral * 100 " +
          ") as mUtilContGral, " +
          "((tTotM.vtaNetaContCliDes - tTotM.vtaCostoContCliDes) / tTotM.vtaNetaContCliDes * 100 " +
          ") as mUtilContCliDes, " +
          "((tTotM.vtaNetaCredito - tTotM.vtaCostoCredito) / tTotM.vtaNetaCredito * 100 " +
          ") as mUtilCredito, " +
          "tTotM.tickets, " +
          "tTotM.ticketsContGral, " +
          "tTotM.ticketsContCliDes, " +
          "tTotM.ticketsCredito, " +
          "tTotM.renglones, " +
          "tTotM.renglonesContGral, " +
          "tTotM.renglonesContCliDes, " +
          "tTotM.renglonesCredito, " +
          "tTotM.articulos, " +
          "tTotM.articulosContGral, " +
          "tTotM.articulosContCliDes, " +
          "tTotM.articulosCredito " +
        "from htotalmes as tTotM " +
        "where " +
          "(tTotM.mes = " + @anomesactual + " or " +
          " tTotM.mes = " + @anoanterior + mesactual + ") and " +
          "tTotM.sucursal = " + @suc + " and " +
          "tTotM.zonaasig = " + @zona + " " +
        "order by " +
          "tTotM.mes desc "
      @objventasdetsuc = @dbEsta.connection.select_all(sql)

      sql = "SELECT Nombre FROM sucursal where Num_suc = " + @suc
      @nomsuc = @dbComun.connection.select_all(sql)
    end

    respond_to do |format|
      format.html
      format.csv do 
        out_arr = []
        if @continua > 0
          out_arr.push("")
          out_arr.push(" , ,Sucursal:, #{@suc}-#{@nomsuc[0]['Nombre']}")
          out_arr.push("")
          out_arr.push(" , , ,Comparativo")
          out_arr.push(" , , ,de #{@nommes}")
          out_arr.push("")
          out_arr.push(" ,Total,Publico en Gral,Clientes con descto,Credito")
          @objventasdetsuc.each do |m|
            out_arr.push("")
            out_arr.push("Año #{m['mes']}")
            out_arr.push("")
            out_arr.push("Venta Neta,#{number_to_currency(m['vtaNeta'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['vtaNetaContGral'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['vtaNetaContCliDes'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['vtaNetaCredito'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}")
            out_arr.push("Costo,#{number_to_currency(m['vtaCosto'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['vtaCostoContGral'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['vtaCostoContCliDes'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_to_currency(m['vtaCostoCredito'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}")
            out_arr.push("Margen Util,#{number_to_percentage(m['mUtil'], :locale => :mx, :precision => 2)},#{number_to_percentage(m['mUtilContGral'], :locale => :mx, :precision => 2)},#{number_to_percentage(m['mUtilContCliDes'], :locale => :mx, :precision => 2)},#{number_to_percentage(m['mUtilCredito'], :locale => :mx, :precision => 2)}")
            out_arr.push("Tickets,#{number_with_delimiter(m['tickets'], :locale => :mx, :precision => 2).gsub(",","")},#{number_with_delimiter(m['ticketsContGral'], :locale => :mx, :precision => 2).gsub(",","")},#{number_with_delimiter(m['ticketsContCliDes'], :locale => :mx, :precision => 2).gsub(",","")},#{number_with_delimiter(m['ticketsCredito'], :locale => :mx, :precision => 2).gsub(",","")}")
            out_arr.push("Renglones,#{number_with_delimiter(m['renglones'], :locale => :mx, :precision => 2).gsub(",","")},#{number_with_delimiter(m['renglonesContGral'], :locale => :mx, :precision => 2).gsub(",","")},#{number_with_delimiter(m['renglonesContCliDes'], :locale => :mx, :precision => 2).gsub(",","")},#{number_with_delimiter(m['renglonesCredito'], :locale => :mx, :precision => 2).gsub(",","")}")
            out_arr.push("Articulos,#{number_with_delimiter(m['articulos'], :locale => :mx, :precision => 2).gsub(",","")},#{number_with_delimiter(m['articulosContGral'], :locale => :mx, :precision => 2).gsub(",","")},#{number_with_delimiter(m['articulosContCliDes'], :locale => :mx, :precision => 2).gsub(",","")},#{number_with_delimiter(m['articulosCredito'], :locale => :mx, :precision => 2).gsub(",","")}")
          end
        end
        csv_file = "/tmp/objventasdetsuc_#{DateTime.now.to_i}.csv"
        dump_to_file(csv_file,out_arr.join("\n"))
        send_file csv_file
        return
      end
    end

  end

  private

    def dump_to_file(filename,txt,modo="w")
      File.open(filename, modo) {|f| f.write(txt) }
    end
end
