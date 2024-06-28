#!/bin/env ruby
# encoding: utf-8
class SignosVitalesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app
  
  include ActionView::Helpers::NumberHelper

  def signos_vitales_zona
    @continua = 0

    if !params.has_key?(:periodo) || !params[:periodo].to_i
      anoFechaAct = DateTime.now.year.to_s
      mesFechaAct = DateTime.now.month.to_s
      anomesFechaAct = anoFechaAct + mesFechaAct.prepend("00").from(-2)
      params[:periodo] = anomesFechaAct
      params[:tipoclientes] = "0"
    end
    @anomes = params[:periodo].to_s if params.has_key?(:periodo)
    ano = params[:periodo].to_s.first(4) if params.has_key?(:periodo)
    mes = params[:periodo].to_s.last(2) if params.has_key?(:periodo)

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
      user_permisos[:wherezonaasig].prepend(' and (')
      user_permisos[:wherezonaasig] = user_permisos[:wherezonaasig] + ") "
    end
    if (user_permisos[:nivel] <= 10 or user_permisos[:nivel] == 30 or user_permisos[:nivel] == 50)
      if user_permisos[:sucursal] > 0
        return redirect_to "/signos_vitales_suc?periodo=#{@anomes}&tipoclientes=0&sucursal=#{user_permisos[:sucursal]}&zona=#{user_permisos[:primerzonaasig]}"
      end
    else
      return redirect_to "/", alert: "No autorizado"
    end
###

    @continua = 1   #Se puede eliminar pues siempre se reciben parámetros ya validados.

    if @continua > 0

      @tipoclientes = params[:tipoclientes].to_i if params.has_key?(:tipoclientes)
      @descriptipoclientes = ""
      case @tipoclientes
      when 0
        @descriptipoclientes = "Todos los Clientes"
        ticketsdia = "round( " +
                       "sum(tTotM.tickets) / " +
                       "sum( " +
                         "(select " +
                            "if (count(*)>0, count(*), 1) " +
                          "from htotaldia as tTotD " +
                          "where " +
                            "tTotD.Mes = tTotM.Mes and " +
                            "tTotD.sucursal = tTotM.sucursal and " +
                            "tTotD.tickets > 0 " +
                         ") " +
                       ") " +
                       ", 2) "
        ticketpromedio = "round(sum(tTotM.vtaNeta) / sum(tTotM.tickets), 2) "
        articulosticket = "round(sum(tTotM.articulos) / sum(tTotM.tickets), 2) "
        renglonesticket = "round(sum(tTotM.renglones) / sum(tTotM.tickets), 2) "
      when 1
        @descriptipoclientes = "Público en General"
        ticketsdia = "round( " +
                       "sum(tTotM.ticketsContGral) / " +
                       "sum( " +
                         "(select " +
                            "if (count(*)>0, count(*), 1) " +
                          "from htotaldia as tTotD " +
                          "where " +
                            "tTotD.Mes = tTotM.Mes and " +
                            "tTotD.sucursal = tTotM.sucursal and " +
                            "tTotD.ticketsContGral > 0 " +
                         ") " +
                       ") " +
                       ", 2) "
        ticketpromedio = "round(sum(tTotM.vtaNetaContGral) / sum(tTotM.ticketsContGral), 2) "
        articulosticket = "round(sum(tTotM.articulosContGral) / sum(tTotM.ticketsContGral), 2) "
        renglonesticket = "round(sum(tTotM.renglonesContGral) / sum(tTotM.ticketsContGral), 2) "
      when 2
        @descriptipoclientes = "Clientes Conocidos"
        ticketsdia = "round( " +
                       "sum(tTotM.ticketsCredito + tTotM.ticketsContCliDes) / " +
                       "sum( " +
                         "(select " +
                            "if (count(*)>0, count(*), 1) " +
                          "from htotaldia as tTotD " +
                          "where " +
                            "tTotD.Mes = tTotM.Mes and " +
                            "tTotD.sucursal = tTotM.sucursal and " +
                            "(tTotD.ticketsCredito + tTotD.ticketsContCliDes) > 0 " +
                         ") " +
                       ") " +
                       ", 2) "
        ticketpromedio = "round( " +
                            "sum(tTotM.vtaNetaCredito + tTotM.vtaNetaContCliDes) / " +
                            "sum(tTotM.ticketsCredito + tTotM.ticketsContCliDes) " +
                            ", 2) "
        articulosticket = "round( " +
                            "sum(tTotM.articulosCredito + tTotM.articulosContCliDes) / " +
                            "sum(tTotM.ticketsCredito + tTotM.ticketsContCliDes) " +
                            ", 2) "
        renglonesticket = "round( " +
                            "sum(tTotM.renglonesCredito + tTotM.renglonesContCliDes) / " +
                            "sum(tTotM.ticketsCredito + tTotM.ticketsContCliDes) " +
                            ", 2) "
      end

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

      sql = "select " +
          "tTotM.ZonaAsig as ColZona, " +
          "tZon.NomZona as ColNombre, " +
          ticketsdia + " as ColTicketsDia, " +
          ticketpromedio + " as ColTicketPromedio, " +
          articulosticket + " as ColArticulosTicket, " +
          renglonesticket + " as ColRenglonesTicket " +
        "from htotalmes as tTotM " +
          "inner join " + @nomDbComun.to_s + "zonas as tZon " +
          "on " +
            "tZon.NumZona = tTotM.ZonaAsig " +
          "inner join " + @nomDbComun.to_s + "sucursal as tSuc " +
          "on " +
            "tSuc.Num_suc = tTotM.Sucursal " +
          "where " +
          "tTotM.Mes = " + @anomes + " and " +
          "tSuc.TipoSuc='S' and tSuc.Inventario=1 and tSuc.FechaTerm='' and tSuc.StockCero=0 and tSuc.SucCXCVencidas=0 and " +
          "tTotM.ZonaAsig " +
          user_permisos[:wherezonaasig] +
        "group by " +
          "tTotM.ZonaAsig " +
        "order by " +
          "tTotM.ZonaAsig "
      @signosvitaleszona = @dbEsta.connection.select_all(sql)
    end

    respond_to do |format|
      format.html
      format.csv do 
        out_arr = []
        if @continua > 0
          out_arr.push("")
          out_arr.push(" , ,Reporte de, Signos Vitales, por Zona")
          out_arr.push("")
          out_arr.push(" ,#{@descriptipoclientes} ")
          out_arr.push(" ,#{@nommes} de #{params[:periodo].to_s.first(4)}")
          out_arr.push("")
          out_arr.push("Zona,Nombre,Tickets/Dia,Ticket Promedio,Articulos/Ticket,Renglones/Ticket")
          @signosvitaleszona.each do |m|
            out_arr.push("#{m['ColZona']},#{m['ColNombre']},#{number_with_delimiter(m['ColTicketsDia'], :locale => :mx, :precision => 2).gsub(",","")},#{number_to_currency(m['ColTicketPromedio'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_with_delimiter(m['ColArticulosTicket'], :locale => :mx, :precision => 2).gsub(",","")},#{number_with_delimiter(m['ColRenglonesTicket'], :locale => :mx, :precision => 2).gsub(",","")}")
          end
        end
        csv_file = "/tmp/signosvitaleszona_#{DateTime.now.to_i}.csv"
        dump_to_file(csv_file,out_arr.join("\n"))
        send_file csv_file
        return
      end
    end

  end

  def signos_vitales_suc
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
        params[:tipoclientes] = "0" if !params.has_key?(:tipoclientes)
        @zona = params[:zona].to_s
        @suc  = params[:sucursal].to_s
      else
        if user_permisos[:escorrectazonaurl].to_i == 0
          params[:zona] = user_permisos[:primerzonaasig]
          @zona = params[:zona].to_s
          params[:tipoclientes] = "0"
        end
      end
    else
      return redirect_to "/", alert: "No autorizado"
    end
###

    if @zona.to_i > 0 && @anomes.to_i > 0
      @continua = 1
    end

    if @continua > 0

      whereSucursal = ""
      if @suc.to_i > 0 
        whereSucursal = "tTotM.sucursal = " + @suc + " and "
      end
      @tipoclientes = params[:tipoclientes].to_i if params.has_key?(:tipoclientes)
      @descriptipoclientes = ""
      case @tipoclientes
      when 0
        @descriptipoclientes = "Todos los Clientes"
        ticketsdia = "round( " +
                       "tTotM.tickets / " +
                       "(select " +
                          "if (count(*)>0, count(*), 1) " +
                        "from htotaldia as tTotD " +
                        "where " +
                          "tTotD.Mes = tTotM.Mes and " +
                          "tTotD.sucursal = tTotM.sucursal and " +
                          "tTotD.tickets > 0 " +
                       ") " +
                       ", 2) "
        ticketpromedio = "round(coalesce(tTotM.vtaNeta / tTotM.tickets,0), 2) "
        articulosticket = "round(coalesce(tTotM.articulos / tTotM.tickets,0), 2) "
        renglonesticket = "round(coalesce(tTotM.renglones / tTotM.tickets,0), 2) "
      when 1
        @descriptipoclientes = "Público en General"
        ticketsdia = "round( " +
                       "tTotM.ticketsContGral / " +
                       "(select " +
                          "if (count(*)>0, count(*), 1) " +
                        "from htotaldia as tTotD " +
                        "where " +
                          "tTotD.Mes = tTotM.Mes and " +
                          "tTotD.sucursal = tTotM.sucursal and " +
                          "tTotD.ticketsContGral > 0 " +
                       ") " +
                       ", 2) "
        ticketpromedio = "round(coalesce(tTotM.vtaNetaContGral / tTotM.ticketsContGral,0), 2) "
        articulosticket = "round(coalesce(tTotM.articulosContGral / tTotM.ticketsContGral,0), 2) "
        renglonesticket = "round(coalesce(tTotM.renglonesContGral / tTotM.ticketsContGral,0), 2) "
      when 2
        @descriptipoclientes = "Clientes Conocidos"
        ticketsdia = "round( " +
                       "(tTotM.ticketsCredito + tTotM.ticketsContCliDes) / " +
                       "(select " +
                          "if (count(*)>0, count(*), 1) " +
                        "from htotaldia as tTotD " +
                        "where " +
                          "tTotD.Mes = tTotM.Mes and " +
                          "tTotD.sucursal = tTotM.sucursal and " +
                          "(tTotD.ticketsCredito + tTotD.ticketsContCliDes) > 0 " +
                       ") " +
                       ", 2) "
        ticketpromedio = "round(coalesce( " +
                           "(tTotM.vtaNetaCredito + tTotM.vtaNetaContCliDes) / " +
                           "(tTotM.ticketsCredito + tTotM.ticketsContCliDes) " +
                         ",0), 2) "
        articulosticket = "round(coalesce( " +
                            "(tTotM.articulosCredito + tTotM.articulosContCliDes) / " +
                            "(tTotM.ticketsCredito + tTotM.ticketsContCliDes) " +
                          ",0), 2) "
        renglonesticket = "round(coalesce( " +
                            "(tTotM.renglonesCredito + tTotM.renglonesContCliDes) / " +
                            "(tTotM.ticketsCredito + tTotM.ticketsContCliDes) " +
                          ",0), 2) "
      end

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

      sql = 
        "select " +
          "tTotM.sucursal as ColSucursal, " +
          "tSuc.Nombre as ColNombre, " +
          ticketsdia + " as ColTicketsDia, " +
          ticketpromedio + " as ColTicketPromedio, " +
          articulosticket + " as ColArticulosTicket, " +
          renglonesticket + " as ColRenglonesTicket " +
        "from htotalmes as tTotM " +
          "inner join " + @nomDbComun.to_s + "sucursal as tSuc " +
          "on " +
            "tSuc.Num_suc = tTotM.Sucursal " +
        "where " +
          "tTotM.Mes = " + @anomes + " and " +
          "tSuc.TipoSuc='S' and tSuc.Inventario=1 and tSuc.FechaTerm='' and tSuc.StockCero=0 and tSuc.SucCXCVencidas=0 and " +
          whereSucursal +
          "tTotM.ZonaAsig = " + @zona + " " +
        "order by " +
          "tTotM.Sucursal "
      @signosvitalessuc = @dbEsta.connection.select_all(sql)

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
          out_arr.push(" , ,Reporte de, Signos Vitales")
          out_arr.push("")
          out_arr.push(" ,#{@descriptipoclientes} ")
          out_arr.push(" ,#{@nommes} de #{params[:periodo].to_s.first(4)}")
          out_arr.push(" ,Zona: #{@zona}-#{@nomzona[0]['NomZona']}")
          out_arr.push("")
          out_arr.push("Sucursal,Nombre,Tickets/Dia,Ticket Promedio,Articulos/Ticket,Renglones/Ticket")
          @signosvitalessuc.each do |m|
            out_arr.push("#{m['ColSucursal']},#{m['ColNombre']},#{number_with_delimiter(m['ColTicketsDia'], :locale => :mx, :precision => 2).gsub(",","")},#{number_to_currency(m['ColTicketPromedio'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{number_with_delimiter(m['ColArticulosTicket'], :locale => :mx, :precision => 2).gsub(",","")},#{number_with_delimiter(m['ColRenglonesTicket'], :locale => :mx, :precision => 2).gsub(",","")}")
          end
        end
        csv_file = "/tmp/signosvitalessuc_#{DateTime.now.to_i}.csv"
        dump_to_file(csv_file,out_arr.join("\n"))
        send_file csv_file
        return
      end
    end

  end

  def signos_vitales_graf
    @continua = 0

    @zona = params[:zona].to_s if params.has_key?(:zona)
    @suc = params[:suc].to_s if params.has_key?(:suc)
    @signovit = params[:signovit].to_s if params.has_key?(:signovit)
    @tipoclientes = params[:tipoclientes].to_s if params.has_key?(:tipoclientes)

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
      if @zona.to_i>0
        if user_permisos[:escorrectazonaurl].to_i == 0
          params[:zona] = user_permisos[:primerzonaasig]
          @zona = params[:zona].to_s
          if user_permisos[:sucursal] > 0
            params[:sucursal] = user_permisos[:sucursal]
            @suc  = params[:sucursal].to_s
          else
            params[:sucursal] = 0
            @suc  = params[:sucursal].to_s
          end
        else
          if @suc.to_i>0
            if user_permisos[:sucursal] > 0 and user_permisos[:sucursal] != @suc
              params[:sucursal] = user_permisos[:sucursal]
              @suc  = params[:sucursal].to_s
            end
          end
        end
      end
    else
      return redirect_to "/", alert: "No autorizado"
    end
###

    if ((@zona.to_i>0 && @suc.to_i==0) || 
        (@zona.to_i>0 && @suc.to_i>0)) && 
        @tipoclientes.to_i<3 && @signovit.to_i>0
      @continua = 1
    end

    if @continua > 0

      case @tipoclientes.to_i
      when 0 
        @descriptipoclientes = 'Todos los Clientes'
      when 1 
        @descriptipoclientes = 'Público en General'
      when 2 
        @descriptipoclientes = 'Clientes Conocidos'
      end

      if @zona.to_i>0 && @suc.to_i==0
        whereSucZonaTotMes = "tTotM.zonaAsig = " + @zona + " and tSuc.TipoSuc='S' and tSuc.Inventario=1 and tSuc.FechaTerm='' and tSuc.StockCero=0 and tSuc.SucCXCVencidas=0 "
        whereSucZonaAno = "zonaAsig = " + @zona
        leftJoin = "inner join " + @nomDbComun.to_s + "sucursal as tSuc " +
                   "on " +
                   "tSuc.Num_suc = tTotM.Sucursal "

        case @tipoclientes.to_i
        when 0 
          case @signovit.to_i
          when 1 
            campossignovit =
                         "sum(tTotM.tickets) / " +
                         "sum( " +
                           "(select " +
                              "if (count(*)>0, count(*), 1) " +
                            "from htotaldia as tTotD " +
                            "where " +
                              "tTotD.Mes = tTotM.Mes and " +
                              "tTotD.sucursal = tTotM.sucursal and " +
                              "tTotD.tickets > 0 " +
                           ") " +
                         ") "
          when 2 
            campossignovit = "sum(tTotM.vtaNeta) / sum(tTotM.tickets) "
          when 3 
            campossignovit = "sum(tTotM.articulos) / sum(tTotM.tickets) "
          when 4 
            campossignovit = "sum(tTotM.renglones) / sum(tTotM.tickets) "
          end
        when 1 
          case @signovit.to_i
          when 1 
            campossignovit =
                         "sum(tTotM.ticketsContGral) / " +
                         "sum( " +
                           "(select " +
                              "if (count(*)>0, count(*), 1) " +
                            "from htotaldia as tTotD " +
                            "where " +
                              "tTotD.Mes = tTotM.Mes and " +
                              "tTotD.sucursal = tTotM.sucursal and " +
                              "tTotD.ticketsContGral > 0 " +
                           ") " +
                         ") "
          when 2 
            campossignovit = "sum(tTotM.vtaNetaContGral) / sum(tTotM.ticketsContGral) "
          when 3 
            campossignovit = "sum(tTotM.articulosContGral) / sum(tTotM.ticketsContGral) "
          when 4 
            campossignovit = "sum(tTotM.renglonesContGral) / sum(tTotM.ticketsContGral) "
          end
        when 2 
          case @signovit.to_i
          when 1 
            campossignovit =
                         "sum(tTotM.ticketsCredito + tTotM.ticketsContCliDes) / " +
                         "sum( " +
                           "(select " +
                              "if (count(*)>0, count(*), 1) " +
                            "from htotaldia as tTotD " +
                            "where " +
                              "tTotD.Mes = tTotM.Mes and " +
                              "tTotD.sucursal = tTotM.sucursal and " +
                              "(tTotD.ticketsCredito + tTotD.ticketsContCliDes) > 0 " +
                           ") " +
                         ") "
          when 2 
            campossignovit =
                           "sum(tTotM.vtaNetaCredito + tTotM.vtaNetaContCliDes) / " +
                           "sum(tTotM.ticketsCredito + tTotM.ticketsContCliDes) "
          when 3 
            campossignovit =
                           "sum(tTotM.articulosCredito + tTotM.articulosContCliDes) / " +
                           "sum(tTotM.ticketsCredito + tTotM.ticketsContCliDes) "
          when 4 
            campossignovit =
                           "sum(tTotM.renglonesCredito + tTotM.renglonesContCliDes) / " +
                           "sum(tTotM.ticketsCredito + tTotM.ticketsContCliDes) "
          end
        end
      end

      if @zona.to_i>0 && @suc.to_i>0
        whereSucZonaTotMes = "tTotM.sucursal = " + @suc + " and tTotM.zonaAsig = " + @zona + " "
        whereSucZonaAno = "sucursal = " + @suc + " and zonaAsig = " + @zona + " "
        leftJoin = ""

        case @tipoclientes.to_i
        when 0 
          case @signovit.to_i
          when 1 
            campossignovit =
                         "(tTotM.tickets / " +
                          "(select " +
                             "if (count(*)>0, count(*), 1) " +
                           "from htotaldia as tTotD " +
                           "where " +
                             "tTotD.Mes = tTotM.Mes and " +
                             "tTotD.sucursal = tTotM.sucursal and " +
                             "tTotD.tickets > 0 " +
                          ") " +
                         ") "
          when 2 
            campossignovit = "coalesce(tTotM.vtaNeta / tTotM.tickets, 0)"
          when 3 
            campossignovit = "coalesce(tTotM.articulos / tTotM.tickets, 0) "
          when 4 
            campossignovit = "coalesce(tTotM.renglones / tTotM.tickets, 0) "
          end
        when 1 
          case @signovit.to_i
          when 1 
            campossignovit =
                         "(tTotM.ticketsContGral / " +
                          "(select " +
                             "if (count(*)>0, count(*), 1) " +
                           "from htotaldia as tTotD " +
                           "where " +
                             "tTotD.Mes = tTotM.Mes and " +
                             "tTotD.sucursal = tTotM.sucursal and " +
                             "tTotD.ticketsContGral > 0 " +
                          ") " +
                         ") "
          when 2 
            campossignovit = "coalesce(tTotM.vtaNetaContGral / tTotM.ticketsContGral, 0) "
          when 3 
            campossignovit = "coalesce(tTotM.articulosContGral / tTotM.ticketsContGral, 0) "
          when 4 
            campossignovit = "coalesce(tTotM.renglonesContGral / tTotM.ticketsContGral, 0) "
          end
        when 2 
          case @signovit.to_i
          when 1 
            campossignovit =
                         "((tTotM.ticketsCredito + tTotM.ticketsContCliDes) / " +
                           "(select " +
                              "if (count(*)>0, count(*), 1) " +
                            "from htotaldia as tTotD " +
                            "where " +
                              "tTotD.Mes = tTotM.Mes and " +
                              "tTotD.sucursal = tTotM.sucursal and " +
                              "(tTotD.ticketsCredito + tTotD.ticketsContCliDes) > 0 " +
                           ") " +
                         ") "
          when 2 
            campossignovit =
                         "coalesce(" +
                           "(tTotM.vtaNetaCredito + tTotM.vtaNetaContCliDes) / " +
                           "(tTotM.ticketsCredito + tTotM.ticketsContCliDes) " +
                         ", 0) "
          when 3 
            campossignovit =
                         "coalesce(" +
                           "(tTotM.articulosCredito + tTotM.articulosContCliDes) / " +
                           "(tTotM.ticketsCredito + tTotM.ticketsContCliDes) " +
                         ", 0) "
          when 4 
            campossignovit =
                         "coalesce(" +
                           "(tTotM.renglonesCredito + tTotM.renglonesContCliDes) / " +
                           "(tTotM.ticketsCredito + tTotM.ticketsContCliDes) " +
                         ", 0) "
          end
        end
      end

      sql = "SELECT Año," 
      sql += "(SELECT ROUND(" + campossignovit + ",2) from htotalmes as tTotM " + leftJoin + "Where tTotM.mes = concat(Año,'01') and " + whereSucZonaTotMes + ") as Enero,"
      sql += "(SELECT ROUND(" + campossignovit + ",2) from htotalmes as tTotM " + leftJoin + "Where tTotM.mes = concat(Año,'02') and " + whereSucZonaTotMes + ") as Febrero,"
      sql += "(SELECT ROUND(" + campossignovit + ",2) from htotalmes as tTotM " + leftJoin + "Where tTotM.mes = concat(Año,'03') and " + whereSucZonaTotMes + ") as Marzo,"
      sql += "(SELECT ROUND(" + campossignovit + ",2) from htotalmes as tTotM " + leftJoin + "Where tTotM.mes = concat(Año,'04') and " + whereSucZonaTotMes + ") as Abril,"
      sql += "(SELECT ROUND(" + campossignovit + ",2) from htotalmes as tTotM " + leftJoin + "Where tTotM.mes = concat(Año,'05') and " + whereSucZonaTotMes + ") as Mayo,"
      sql += "(SELECT ROUND(" + campossignovit + ",2) from htotalmes as tTotM " + leftJoin + "Where tTotM.mes = concat(Año,'06') and " + whereSucZonaTotMes + ") as Junio,"
      sql += "(SELECT ROUND(" + campossignovit + ",2) from htotalmes as tTotM " + leftJoin + "Where tTotM.mes = concat(Año,'07') and " + whereSucZonaTotMes + ") as Julio,"
      sql += "(SELECT ROUND(" + campossignovit + ",2) from htotalmes as tTotM " + leftJoin + "Where tTotM.mes = concat(Año,'08') and " + whereSucZonaTotMes + ") as Agosto,"
      sql += "(SELECT ROUND(" + campossignovit + ",2) from htotalmes as tTotM " + leftJoin + "Where tTotM.mes = concat(Año,'09') and " + whereSucZonaTotMes + ") as Septiembre,"
      sql += "(SELECT ROUND(" + campossignovit + ",2) from htotalmes as tTotM " + leftJoin + "Where tTotM.mes = concat(Año,'10') and " + whereSucZonaTotMes + ") as Octubre,"
      sql += "(SELECT ROUND(" + campossignovit + ",2) from htotalmes as tTotM " + leftJoin + "Where tTotM.mes = concat(Año,'11') and " + whereSucZonaTotMes + ") as Noviembre,"
      sql += "(SELECT ROUND(" + campossignovit + ",2) from htotalmes as tTotM " + leftJoin + "Where tTotM.mes = concat(Año,'12') and " + whereSucZonaTotMes + ") as Diciembre "
      sql += "FROM "
      sql += "( "
      sql += " SELECT DISTINCT left(mes,4) as Año FROM htotalmes where left(mes,4) >= 2005 and " + whereSucZonaAno + " order by left(mes,4) DESC limit 10 "
      sql += ") tmp"
      @signosvitalesgraf = @dbEsta.connection.select_all(sql)

      nomcia = ""
      case @sitio[0].idEmpresa.to_i
      when 1
        @nomcia = "Pintacomex S.A de C.V."
      when 2
        @nomcia = "Baja Paint S.A de C.V."
      when 3
        @nomcia = "Administraciones Rahca S.A. de C.V."
      when 4
        @nomcia = "SPI S.A. de C.V."
      end

      @categorias = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic']
      case @signovit.to_i
      when 1 
        @tituloGrafica = "Ticket / Dia"
        @ytituloGrafica = "Tickets"
      when 2 
        @tituloGrafica = "Ticket / Promedio"
        @ytituloGrafica = "Venta Neta ($)"
      when 3 
        @tituloGrafica = "Articulos / Ticket"
        @ytituloGrafica = "Articulos"
      when 4 
        @tituloGrafica = "Renglones / Ticket"
        @ytituloGrafica = "Renglones"
      end
      @tultip = ""

      @series = []
      numgraficas=0;
      @signosvitalesgraf.each do |m|
        numgraficas+=1
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
        @series.push( { name: m['Año'], data: datos, visible: numgraficas<6 } )
      end

      sql = "SELECT NomZona FROM zonas where NumZona = " + @zona
      @nomzona = @dbComun.connection.select_all(sql)

      if @suc.to_i>0 
        sql = "SELECT Nombre FROM sucursal where Num_suc = " + @suc
        @nomsuc = @dbComun.connection.select_all(sql)
      end

    end

  end

  private 

    def dump_to_file(filename,txt,modo="w")
      File.open(filename, modo) {|f| f.write(txt) }
    end
end
