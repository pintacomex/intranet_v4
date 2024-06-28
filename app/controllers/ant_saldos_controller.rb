class AntSaldosController < ApplicationController
  before_filter :authenticate_user!, except: [:enviar_mails_de_aclaracion_robot, :enviar_mails_de_aclaracion_robot_index]
  before_filter :admin_only, only: [:ant_saldos_mails, :ant_saldos_mails_new, :ant_saldos_mails_create, :ant_saldos_mails_delete]
  before_filter :tiene_permiso_de_ver_app, except: [:enviar_mails_de_aclaracion_robot, :enviar_mails_de_aclaracion_robot_index]

  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper

  def ant_saldos
    @ver_sin_aclarar = false
    @ver_sin_aclarar = true if params.has_key?(:sin_aclarar) && params[:sin_aclarar].to_i == 1
    @ver_dias = 0
    @ver_dias = params[:ver_dias].to_i if params.has_key?(:ver_dias) && ( params[:ver_dias].to_i == 30 or params[:ver_dias].to_i == 60 or params[:ver_dias].to_i == 90 or params[:ver_dias].to_i == 120 )
    @ver_saldos = 1
    @ver_saldos = params[:ver_saldos].to_i if params.has_key?(:ver_saldos) &&  ( params[:ver_saldos].to_i == 0 or params[:ver_saldos].to_i == 1 or params[:ver_saldos].to_i == 2 or params[:ver_saldos].to_i == 3 )
    get_filtros_from_user
    return if @filtros == []
    get_filtros_from_dias
    get_filtros_from_saldos
    @filtros.push("s.SucCXCVencidas = 0") if !params.has_key?(:incluir_sucvencidas)
    sql = "SELECT *, sum(Ventas) as sumVentas, sum(Pagos) as sumPagos, sum(Ventas0_30) as sumVentas0_30, sum(Ventas31_60) as sumVentas31_60, sum(Ventas61_90) as sumVentas61_90, sum(Ventas91_120) as sumVentas91_120, sum(Ventas121_) as sumVentas121_ FROM AntSaldos LEFT JOIN #{@nomDbComun}sucursal as s ON s.Num_suc = Sucursal WHERE ( ( #{@filtros.join(" ) AND ( ")} ) ) GROUP BY sucursal HAVING ( ( #{@having.join(" ) AND ( ")} ) ) ORDER BY AntSaldos.zonaasig, sucursal"
    sql = "SELECT AntSaldos.*, sum(Ventas) as sumVentas, sum(Pagos) as sumPagos, sum(Ventas0_30) as sumVentas0_30, sum(Ventas31_60) as sumVentas31_60, sum(Ventas61_90) as sumVentas61_90, sum(Ventas91_120) as sumVentas91_120, sum(Ventas121_) as sumVentas121_ FROM #{@nomDbEsta}AntSaldos LEFT JOIN AntSaldosFecAcl ON AntSaldosFecAcl.SucOrigen = AntSaldos.SucOrigen and AntSaldosFecAcl.ControlFac = AntSaldos.ControlFac LEFT JOIN #{@nomDbComun}sucursal as s ON s.Num_suc = Sucursal WHERE ( AntSaldosFecAcl.FechaAcl is null OR AntSaldosFecAcl.FechaAcl < curdate() ) and ( ( #{@filtros.join(" ) and ( ")} ) ) GROUP BY sucursal HAVING ( ( #{@having.join(" ) AND ( ")} ) ) ORDER BY zonaasig, sucursal" if @ver_sin_aclarar
    @antsaldos = @dbEsta.connection.select_all(sql)
    @ultimaAct = Date.parse(@antsaldos[0]['FechaProc']) rescue nil
    Rails.logger.info 'Respond to'
    respond_to do |format|
        format.html
        format.csv do
            out_arr = []
            out_arr.push("Zona-Suc,Sucursal,Saldo#{@ver_dias > 0 ? "" : ",En Plazo"}#{@ver_dias > 30 ? "" : ",1-30d"}#{@ver_dias > 60 ? "" : ",31-60"}#{@ver_dias > 90 ? "" : ",61-90"},90+")
            @antsaldos.each do |m|
                out_arr.push("#{m['ZonaAsig']}-#{m['Sucursal'].to_s.rjust(3,'0')},#{m['NombreSuc']},#{m['sumVentas'] - m['sumPagos'] > 0 ? number_to_currency(m['sumVentas'] - m['sumPagos'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","") : ""}#{@ver_dias > 0 ? "" : m['sumVentas0_30'] > 0 ? ",#{number_to_currency(m['sumVentas0_30'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}#{@ver_dias > 30 ? "" : m['sumVentas31_60'] > 0 ? ",#{number_to_currency(m['sumVentas31_60'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}#{@ver_dias > 60 ? "" : m['sumVentas61_90'] > 0 ? ",#{number_to_currency(m['sumVentas61_90'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}#{@ver_dias > 90 ? "" : m['sumVentas91_120'] > 0 ? ",#{number_to_currency(m['sumVentas91_120'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}#{m['sumVentas121_'] > 0 ? ",#{number_to_currency(m['sumVentas121_'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}")
            end
            csv_file = "/tmp/ant_saldos_#{@ultimaAct.to_s}_#{DateTime.now.to_i}.csv"
            csv_file = "/tmp/ant_saldos_sin_aclarar_#{@ultimaAct.to_s}_#{DateTime.now.to_i}.csv" if @ver_sin_aclarar
            dump_to_file(csv_file,out_arr.join("\n"))
            send_file csv_file
            return
        end
    end
  end

  def ant_saldos_clientes
    suc = params[:suc].to_i if params.has_key?(:suc)
    if suc && suc > 0
        @ver_sin_aclarar = false
        @ver_sin_aclarar = true if params.has_key?(:sin_aclarar) && params[:sin_aclarar].to_i == 1
        @ver_dias = 0
        @ver_dias = params[:ver_dias].to_i if params.has_key?(:ver_dias) && ( params[:ver_dias].to_i == 30 or params[:ver_dias].to_i == 60 or params[:ver_dias].to_i == 90 or params[:ver_dias].to_i == 120 )
        @ver_saldos = 1
        @ver_saldos = params[:ver_saldos].to_i if params.has_key?(:ver_saldos) &&  ( params[:ver_saldos].to_i == 0 or params[:ver_saldos].to_i == 1 or params[:ver_saldos].to_i == 2 or params[:ver_saldos].to_i == 3 )
        get_filtros_from_user
        get_filtros_from_dias
        get_filtros_from_saldos
        sql = "SELECT AntSaldos.*, c.Alias, sum(Ventas) as sumVentas, sum(Pagos) as sumPagos, sum(Ventas0_30) as sumVentas0_30, sum(Ventas31_60) as sumVentas31_60, sum(Ventas61_90) as sumVentas61_90, sum(Ventas91_120) as sumVentas91_120, sum(Ventas121_) as sumVentas121_ FROM AntSaldos LEFT JOIN #{@nomDbPdv}clientes AS c ON AntSaldos.SucOrigen = c.Sucursal AND AntSaldos.Idcliente = c.Idcliente where AntSaldos.sucursal = #{suc} and ( ( #{@filtros.join(" ) and ( ")} ) ) GROUP BY AntSaldos.Idcliente HAVING ( ( #{@having.join(" ) AND ( ")} ) ) ORDER BY AntSaldos.Idcliente, ControlFac"
        sql = "SELECT AntSaldos.*, c.Alias, sum(Ventas) as sumVentas, sum(Pagos) as sumPagos, sum(Ventas0_30) as sumVentas0_30, sum(Ventas31_60) as sumVentas31_60, sum(Ventas61_90) as sumVentas61_90, sum(Ventas91_120) as sumVentas91_120, sum(Ventas121_) as sumVentas121_ FROM AntSaldos LEFT JOIN AntSaldosFecAcl ON AntSaldosFecAcl.SucOrigen = AntSaldos.SucOrigen and AntSaldosFecAcl.ControlFac = AntSaldos.ControlFac LEFT JOIN #{@nomDbPdv}clientes AS c ON AntSaldos.SucOrigen = c.Sucursal AND AntSaldos.Idcliente = c.Idcliente WHERE ( AntSaldosFecAcl.FechaAcl is null OR AntSaldosFecAcl.FechaAcl < curdate() ) and AntSaldos.sucursal = #{suc} and ( ( #{@filtros.join(" ) and ( ")} ) ) GROUP BY Idcliente HAVING ( ( #{@having.join(" ) AND ( ")} ) ) ORDER BY Idcliente, ControlFac" if @ver_sin_aclarar
        @antsaldos = @dbEsta.connection.select_all(sql)
        @ultimaAct = Date.parse(@antsaldos[0]['FechaProc']) rescue nil
        return redirect_to ant_saldos_path, alert: "No se han encontrado datos"  if !@ultimaAct
        sql = "SELECT *, sum(Ventas) as sumVentas, sum(Pagos) as sumPagos, sum(Ventas0_30) as sumVentas0_30, sum(Ventas31_60) as sumVentas31_60, sum(Ventas61_90) as sumVentas61_90, sum(Ventas91_120) as sumVentas91_120, sum(Ventas121_) as sumVentas121_ FROM AntSaldos where sucursal = #{suc} and ( ( #{@filtros.join(" ) and ( ")} ) ) GROUP BY sucursal HAVING ( ( #{@having.join(" ) AND ( ")} ) ) ORDER BY zonaasig, sucursal"
        sql = "SELECT AntSaldos.*, sum(Ventas) as sumVentas, sum(Pagos) as sumPagos, sum(Ventas0_30) as sumVentas0_30, sum(Ventas31_60) as sumVentas31_60, sum(Ventas61_90) as sumVentas61_90, sum(Ventas91_120) as sumVentas91_120, sum(Ventas121_) as sumVentas121_ FROM AntSaldos LEFT JOIN AntSaldosFecAcl ON AntSaldosFecAcl.SucOrigen = AntSaldos.SucOrigen and AntSaldosFecAcl.ControlFac = AntSaldos.ControlFac WHERE ( AntSaldosFecAcl.FechaAcl is null OR AntSaldosFecAcl.FechaAcl < curdate() ) and sucursal = #{suc} and ( ( #{@filtros.join(" ) and ( ")} ) ) GROUP BY sucursal HAVING ( ( #{@having.join(" ) AND ( ")} ) ) ORDER BY zonaasig, sucursal" if @ver_sin_aclarar
        @antsaldos_suc = @dbEsta.connection.select_all(sql)
        respond_to do |format|
            format.html
            format.csv do
                out_arr = []
                out_arr.push("IdCliente,Cliente,Saldo#{@ver_dias > 0 ? "" : ",En Plazo"}#{@ver_dias > 30 ? "" : ",1-30d"}#{@ver_dias > 60 ? "" : ",31-60"}#{@ver_dias > 90 ? "" : ",61-90"},90+")
                @antsaldos.each do |m|
                    out_arr.push("#{m['Idcliente']},#{m['NombreCli'].gsub(",","")},#{m['sumVentas'] - m['sumPagos'] > 0 ? number_to_currency(m['sumVentas'] - m['sumPagos'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","") : ""}#{@ver_dias > 0 ? "" : m['sumVentas0_30'] > 0 ? ",#{number_to_currency(m['sumVentas0_30'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}#{@ver_dias > 30 ? "" : m['sumVentas31_60'] > 0 ? ",#{number_to_currency(m['sumVentas31_60'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}#{@ver_dias > 60 ? "" : m['sumVentas61_90'] > 0 ? ",#{number_to_currency(m['sumVentas61_90'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}#{@ver_dias > 90 ? "" : m['sumVentas91_120'] > 0 ? ",#{number_to_currency(m['sumVentas91_120'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}#{m['sumVentas121_'] > 0 ? ",#{number_to_currency(m['sumVentas121_'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}")
                end
                @antsaldos_suc.each do |m|
                    out_arr.push(",Total,#{m['sumVentas'] - m['sumPagos'] > 0 ? number_to_currency(m['sumVentas'] - m['sumPagos'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","") : ""}#{@ver_dias > 0 ? "" : m['sumVentas0_30'] > 0 ? ",#{number_to_currency(m['sumVentas0_30'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}#{@ver_dias > 30 ? "" : m['sumVentas31_60'] > 0 ? ",#{number_to_currency(m['sumVentas31_60'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}#{@ver_dias > 60 ? "" : m['sumVentas61_90'] > 0 ? ",#{number_to_currency(m['sumVentas61_90'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}#{@ver_dias > 90 ? "" : m['sumVentas91_120'] > 0 ? ",#{number_to_currency(m['sumVentas91_120'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}#{m['sumVentas121_'] > 0 ? ",#{number_to_currency(m['sumVentas121_'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}")
                end
                csv_file = "/tmp/ant_saldos_clientes_#{@antsaldos[0]['Sucursal']}_#{@ultimaAct.to_s}_#{DateTime.now.to_i}.csv"
                csv_file = "/tmp/ant_saldos_clientes_sin_aclarar_#{@antsaldos[0]['Sucursal']}_#{@ultimaAct.to_s}_#{DateTime.now.to_i}.csv" if @ver_sin_aclarar
                dump_to_file(csv_file,out_arr.join("\n"))
                send_file csv_file
                return
            end
        end
    else
        return redirect_to ant_saldos_path
    end
  end

  def ant_saldos_clientes_nombre_rfc
    @nombre = params[:nombre].to_s.strip if params.has_key?(:nombre)
    @rfc = params[:rfc].to_s.strip if params.has_key?(:rfc)
    if @nombre && @rfc && ( @nombre.to_s.length > 0 || @rfc.to_s.length > 0 )
        @ver_sin_aclarar = false
        @ver_sin_aclarar = true if params.has_key?(:sin_aclarar) && params[:sin_aclarar].to_i == 1
        @ver_dias = 0
        @ver_dias = params[:ver_dias].to_i if params.has_key?(:ver_dias) && ( params[:ver_dias].to_i == 30 or params[:ver_dias].to_i == 60 or params[:ver_dias].to_i == 90 or params[:ver_dias].to_i == 120 )
        get_filtros_from_user
        get_filtros_from_dias
        get_filtros_from_nombre_rfc
        sql = "SELECT AntSaldos.*, c.Alias, sum(Ventas) as sumVentas, sum(Pagos) as sumPagos, sum(Ventas0_30) as sumVentas0_30, sum(Ventas31_60) as sumVentas31_60, sum(Ventas61_90) as sumVentas61_90, sum(Ventas91_120) as sumVentas91_120, sum(Ventas121_) as sumVentas121_ FROM AntSaldos LEFT JOIN #{@nomDbPdv}clientes AS c ON AntSaldos.Sucursal = c.Sucursal AND AntSaldos.Idcliente = c.Idcliente where ( ( #{@filtros.join(" ) and ( ")} ) ) GROUP BY AntSaldos.Sucursal, AntSaldos.Idcliente ORDER BY AntSaldos.Idcliente, ControlFac"
        sql = "SELECT AntSaldos.*, c.Alias, sum(Ventas) as sumVentas, sum(Pagos) as sumPagos, sum(Ventas0_30) as sumVentas0_30, sum(Ventas31_60) as sumVentas31_60, sum(Ventas61_90) as sumVentas61_90, sum(Ventas91_120) as sumVentas91_120, sum(Ventas121_) as sumVentas121_ FROM AntSaldos LEFT JOIN AntSaldosFecAcl ON AntSaldosFecAcl.SucOrigen = AntSaldos.SucOrigen and AntSaldosFecAcl.ControlFac = AntSaldos.ControlFac LEFT JOIN #{@nomDbPdv}clientes AS c ON AntSaldos.SucOrigen = c.Sucursal AND AntSaldos.Idcliente = c.Idcliente WHERE ( AntSaldosFecAcl.FechaAcl is null OR AntSaldosFecAcl.FechaAcl < curdate() ) and ( ( #{@filtros.join(" ) and ( ")} ) ) GROUP BY AntSaldos.Sucursal, AntSaldos.Idcliente ORDER BY Idcliente, ControlFac" if @ver_sin_aclarar
        @antsaldos = @dbEsta.connection.select_all(sql)
        @ultimaAct = Date.parse(@antsaldos[0]['FechaProc']) rescue nil
        return redirect_to ant_saldos_path, alert: "No se han encontrado datos" if !@ultimaAct
        respond_to do |format|
            format.html
        end
    else
        return redirect_to ant_saldos_path
    end
  end

  def ant_saldos_cliente
    @suc = params[:suc].to_i if params.has_key?(:suc)
    @idc = params[:idc].to_i if params.has_key?(:idc)
    if @suc && @suc > 0 && @idc && @idc > 0
        @ver_sin_aclarar = false
        @ver_sin_aclarar = true if params.has_key?(:sin_aclarar) && params[:sin_aclarar].to_i == 1
        @ver_dias = 0
        @ver_dias = params[:ver_dias].to_i if params.has_key?(:ver_dias) && ( params[:ver_dias].to_i == 30 or params[:ver_dias].to_i == 60 or params[:ver_dias].to_i == 90 or params[:ver_dias].to_i == 120 )
        @ver_saldos = 1
        @ver_saldos = params[:ver_saldos].to_i if params.has_key?(:ver_saldos) &&  ( params[:ver_saldos].to_i == 0 or params[:ver_saldos].to_i == 1 or params[:ver_saldos].to_i == 2 or params[:ver_saldos].to_i == 3 )
        get_filtros_from_user
        get_filtros_from_dias
        get_filtros_from_saldos
        order = "ORDER BY Idcliente, ControlFac"
        order = "ORDER BY AntSaldos.FechaFac DESC, Idcliente, ControlFac" if @ver_saldos == 0
        sql = "SELECT AntSaldos.*, AntSaldosFecAcl.FechaAcl, AntSaldosChat.FechaHora as ascFechaHora FROM AntSaldos LEFT JOIN AntSaldosFecAcl ON AntSaldos.SucOrigen = AntSaldosFecAcl.SucOrigen AND AntSaldos.ControlFac = AntSaldosFecAcl.ControlFac LEFT JOIN AntSaldosChat ON AntSaldos.SucOrigen = AntSaldosChat.SucOrigen AND AntSaldos.ControlFac = AntSaldosChat.ControlFac WHERE sucursal = #{@suc} and Idcliente = #{@idc} and ( ( #{@filtros.join(" ) and ( ")} ) ) GROUP BY ControlFac HAVING ( ( #{@having.join(" ) AND ( ")} ) ) #{order}"
        sql = "SELECT AntSaldos.*, AntSaldosFecAcl.FechaAcl, AntSaldosChat.FechaHora as ascFechaHora FROM AntSaldos LEFT JOIN AntSaldosFecAcl ON AntSaldos.SucOrigen = AntSaldosFecAcl.SucOrigen AND AntSaldos.ControlFac = AntSaldosFecAcl.ControlFac LEFT JOIN AntSaldosChat ON AntSaldos.SucOrigen = AntSaldosChat.SucOrigen AND AntSaldos.ControlFac = AntSaldosChat.ControlFac WHERE sucursal = #{@suc} and Idcliente = #{@idc} and ( AntSaldosFecAcl.FechaAcl is null OR AntSaldosFecAcl.FechaAcl < curdate() ) and ( ( #{@filtros.join(" ) and ( ")} ) ) GROUP BY ControlFac HAVING ( ( #{@having.join(" ) AND ( ")} ) ) #{order}" if @ver_sin_aclarar
        @antsaldos = @dbEsta.connection.select_all(sql)
        @ultimaAct = Date.parse(@antsaldos[0]['FechaProc']) rescue ''
        # return redirect_to ant_saldos_path, alert: "No se han encontrado datos" if !@ultimaAct
        # Este otro query es para sacar el saldo
        sql = "SELECT *, sum(Ventas) as sumVentas, sum(Pagos) as sumPagos FROM AntSaldos where sucursal = #{@suc} and Idcliente = #{@idc} and ( ( #{@filtros.join(" ) and ( ")} ) ) GROUP BY Idcliente ORDER BY Idcliente, ControlFac"
        sql = "SELECT AntSaldos.*, sum(Ventas) as sumVentas, sum(Pagos) as sumPagos FROM AntSaldos LEFT JOIN AntSaldosFecAcl ON AntSaldosFecAcl.SucOrigen = AntSaldos.SucOrigen and AntSaldosFecAcl.ControlFac = AntSaldos.ControlFac WHERE ( AntSaldosFecAcl.FechaAcl is null OR AntSaldosFecAcl.FechaAcl < curdate() ) and sucursal = #{@suc} and Idcliente = #{@idc} and ( ( #{@filtros.join(" ) and ( ")} ) ) GROUP BY Idcliente ORDER BY Idcliente, ControlFac" if @ver_sin_aclarar
        datos_saldo = @dbEsta.connection.select_all(sql)
        @saldo = datos_saldo[0]['sumVentas'] - datos_saldo[0]['sumPagos'] if datos_saldo.count > 0
        @datos_cliente     = get_datos_cliente(@suc, @idc)
        # HACER UN SELECT DISTINCT FROM EL QUE VIENE PARA UN ARREGLO CON SUC ORIGEN EN GET_HISTORIAL_CLIENTE

        @historial_cliente = get_historial_cliente(@suc, @idc, "IdSucursal")
        respond_to do |format|
            format.html
            format.csv do
                out_arr = []
                out_arr.push("IdCliente,Cliente,Fecha,FechaEst,Control,Ventas,Pagos,FechaPago#{@ver_dias > 0 ? "" : ",En Plazo"}#{@ver_dias > 30 ? "" : ",1-30d"}#{@ver_dias > 60 ? "" : ",31-60"}#{@ver_dias > 90 ? "" : ",61-90"},90+")
                @antsaldos.each do |m|
                    out_arr.push("#{m['Idcliente']},#{m['NombreCli'].gsub(",","")},#{fix_show_date(m['FechaFac'])},#{fix_show_date( ( m['FechaAcl'].to_s.length > 0 ? m['FechaAcl'] : m['FechaEstPago'] ) )},#{m['ControlFac']},#{m['Ventas'] > 0 ? number_to_currency(m['Ventas'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","") : ""},#{m['Pagos'] > 0 ? number_to_currency(m['Pagos'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","") : ""},#{fix_show_date( m['FechaPago'].to_s.length > 3 ? m['FechaPago'].to_s : "" )}#{@ver_dias > 0 ? "" : m['Ventas0_30'] > 0 ? ",#{number_to_currency(m['Ventas0_30'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}#{@ver_dias > 30 ? "" : m['Ventas31_60'] > 0 ? ",#{number_to_currency(m['Ventas31_60'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}#{@ver_dias > 60 ? "" : m['Ventas61_90'] > 0 ? ",#{number_to_currency(m['Ventas61_90'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}#{@ver_dias > 90 ? "" : m['Ventas91_120'] > 0 ? ",#{number_to_currency(m['Ventas91_120'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}#{m['Ventas121_'] > 0 ? ",#{number_to_currency(m['Ventas121_'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}")
                end
                csv_file = "/tmp/ant_saldos_clientes_#{@suc}_#{@ultimaAct.to_s}_#{DateTime.now.to_i}.csv"
                csv_file = "/tmp/ant_saldos_clientes_sin_aclarar_#{@suc}_#{@ultimaAct.to_s}_#{DateTime.now.to_i}.csv" if @ver_sin_aclarar
                dump_to_file(csv_file,out_arr.join("\n"))
                send_file csv_file
                return
            end
        end
    else
        return redirect_to ant_saldos_path
    end
  end

  def ant_saldos_cliente_anyo
    # Aqui solo se muestra el historial del cliente ese año con llamada de jQuery
    @suc  = params[:suc].to_i  if params.has_key?(:suc)
    @idc  = params[:idc].to_i  if params.has_key?(:idc)
    @year = params[:year].to_i if params.has_key?(:year)
    @nomcliente = ""
    @nomcliente = params[:nomcliente] if params.has_key?(:nomcliente)
    if @suc && @suc > 0 && @idc && @idc > 0 && @year && @year > 2000
        sql = "SELECT hCreditos.*, min(Fecha) as minFecha, sum(Ventas) as sumVentas, sum(Pagos) as sumPagos from hCreditos WHERE Idsucursal = #{@suc} AND Idcliente = #{@idc} AND Fecha > #{@year}0000 AND Fecha < #{@year}9999 GROUP BY Controlfac"
        @historial = @dbEsta.connection.select_all(sql)
    else
        return redirect_to ant_saldos_path
    end
  end

  def ant_saldos_cliente_hist1
    # Aqui solo se muestra el historial del cliente con llamada de jQuery
    @suc  = params[:suc].to_i  if params.has_key?(:suc)
    @idc  = params[:idc].to_i  if params.has_key?(:idc)
    @s_i  = params[:s_i]       if params.has_key?(:s_i)
    @nomcliente = ""
    @nomcliente = params[:nomcliente] if params.has_key?(:nomcliente)
    if @suc && @suc > 0 && @idc && @idc > 0 && @s_i && (@s_i == "Sucursal" || @s_i == "IdSucursal")
        # Emula Antsaldos para no hacer un query
        @antsaldos = []
        @antsaldos[0] = {}
        @antsaldos[0]['Sucursal'] = @suc
        @antsaldos[0]['Idcliente'] = @idc
        @antsaldos[0]['NombreCli'] = @nomcliente
        @historial_cliente = get_historial_cliente(@suc, @idc, "IdSucursal")
    else
        return redirect_to ant_saldos_path
    end
  end

  def ant_saldos_cliente_datos
    suc = params[:suc].to_i if params.has_key?(:suc)
    idc = params[:idc].to_i if params.has_key?(:idc)
    if suc && suc > 0 && idc && idc > 0
        @puede_editar_fecha_acl = false
        get_filtros_from_user
        @puede_editar_fecha_acl = true if get_current_user_app_nivel == 2
        sql = "SELECT AntSaldos.*, AntSaldosFecAcl.FechaAcl, AntSaldosChat.FechaHora as ascFechaHora FROM AntSaldos LEFT JOIN AntSaldosFecAcl ON AntSaldos.SucOrigen = AntSaldosFecAcl.SucOrigen AND AntSaldos.ControlFac = AntSaldosFecAcl.ControlFac LEFT JOIN AntSaldosChat ON AntSaldos.SucOrigen = AntSaldosChat.SucOrigen AND AntSaldos.ControlFac = AntSaldosChat.ControlFac WHERE sucursal = #{suc} and Idcliente = #{idc} and ( ( #{@filtros.join(" ) and ( ")} ) ) GROUP BY ControlFac ORDER BY Idcliente, ControlFac"
        @antsaldos = @dbEsta.connection.select_all(sql)
        @ultimaAct = Date.parse(@antsaldos[0]['FechaProc']) rescue nil
        return redirect_to ant_saldos_path, alert: "No se han encontrado datos" if !@ultimaAct
        # Se sacan los datos del cliente
        sql = "SELECT clientes.*, sucursal.Nombre as Sucnom FROM clientes LEFT JOIN #{@nomDbComun}sucursal ON Num_suc = sucursal WHERE Sucursal = #{suc} AND Idcliente = #{idc}"
        @datos_cliente = @dbPdv.connection.select_all(sql)
        respond_to do |format|
            format.html
        end
    else
        return redirect_to ant_saldos_path
    end
  end

  def ant_saldos_cliente_editar
    suc = params[:suc].to_i if params.has_key?(:suc)
    idc = params[:idc].to_i if params.has_key?(:idc)
    if suc && suc > 0 && idc && idc > 0
        @puede_editar_fecha_acl = false
        get_filtros_from_user
        @puede_editar_fecha_acl = true if get_current_user_app_nivel == 2
        if @puede_editar_fecha_acl
            credito = -1
            credito = params[:credito].to_f if params.has_key?(:credito)
            plazo = -1
            plazo = params[:plazo].to_i if params.has_key?(:plazo)
            return redirect_to ant_saldos_path if credito == -1 and plazo == -1
            url = "/ant_saldos_cliente_datos?suc=#{suc}&idc=#{idc}"
            if credito >= 0
                return redirect_to url, alert: "El crédito máximo es de $1,000,000.00" if credito > 1000000
                sql = "UPDATE clientes SET Credito = #{User.sanitize(credito)} WHERE Sucursal = #{suc} AND Idcliente = #{idc}"
                begin
                  @dbPdv.connection.execute(sql)
                rescue Exception => exc
                  return redirect_to url, alert: "No se ha podido guardar el Credito"
                end
                return redirect_to url, notice: "Credito guardado exitosamente"
            elsif plazo >= 0
                return redirect_to url, alert: "El plazo máximo es de 90 días" if plazo > 90
                sql = "UPDATE clientes SET Plazo = #{User.sanitize(plazo)} WHERE Sucursal = #{suc} AND Idcliente = #{idc}"
                begin
                  @dbPdv.connection.execute(sql)
                rescue Exception => exc
                  return redirect_to url, alert: "No se ha podido guardar el Plazo"
                end
                return redirect_to url, notice: "Plazo guardado exitosamente"
            else
                return redirect_to ant_saldos_path
            end
        else
            return redirect_to ant_saldos_path
        end
    else
        return redirect_to ant_saldos_path
    end
  end


  def ant_saldos_sucursal
    suc = params[:suc].to_i if params.has_key?(:suc)
    if suc && suc > 0
        @ver_sin_aclarar = false
        @ver_sin_aclarar = true if params.has_key?(:sin_aclarar) && params[:sin_aclarar].to_i == 1
        @ver_dias = 0
        @ver_dias = params[:ver_dias].to_i if params.has_key?(:ver_dias) && ( params[:ver_dias].to_i == 30 or params[:ver_dias].to_i == 60 or params[:ver_dias].to_i == 90 or params[:ver_dias].to_i == 120 )
        get_filtros_from_user
        get_filtros_from_dias
        sql = "SELECT AntSaldos.*, AntSaldosFecAcl.FechaAcl, AntSaldosChat.FechaHora as ascFechaHora FROM AntSaldos LEFT JOIN AntSaldosFecAcl ON AntSaldos.SucOrigen = AntSaldosFecAcl.SucOrigen AND AntSaldos.ControlFac = AntSaldosFecAcl.ControlFac LEFT JOIN AntSaldosChat ON AntSaldos.SucOrigen = AntSaldosChat.SucOrigen AND AntSaldos.ControlFac = AntSaldosChat.ControlFac WHERE sucursal = #{suc} and ( ( #{@filtros.join(" ) and ( ")} ) ) GROUP BY ControlFac ORDER BY Idcliente, ControlFac"
        sql = "SELECT AntSaldos.*, AntSaldosFecAcl.FechaAcl, AntSaldosChat.FechaHora as ascFechaHora FROM AntSaldos LEFT JOIN AntSaldosFecAcl ON AntSaldos.SucOrigen = AntSaldosFecAcl.SucOrigen AND AntSaldos.ControlFac = AntSaldosFecAcl.ControlFac LEFT JOIN AntSaldosChat ON AntSaldos.SucOrigen = AntSaldosChat.SucOrigen AND AntSaldos.ControlFac = AntSaldosChat.ControlFac WHERE sucursal = #{suc} and ( AntSaldosFecAcl.FechaAcl is null OR AntSaldosFecAcl.FechaAcl < curdate() ) and ( ( #{@filtros.join(" ) and ( ")} ) ) GROUP BY ControlFac ORDER BY Idcliente, ControlFac" if @ver_sin_aclarar
        @antsaldos = @dbEsta.connection.select_all(sql)
        @ultimaAct = Date.parse(@antsaldos[0]['FechaProc']) rescue nil
        return redirect_to ant_saldos_path, alert: "No se han encontrado datos" if !@ultimaAct
        respond_to do |format|
            format.html
            format.csv do
                out_arr = []
                out_arr.push("IdCliente,Cliente,Fecha,FechaEst,Control,Ventas,Pagos#{@ver_dias > 0 ? "" : ",En Plazo"}#{@ver_dias > 30 ? "" : ",1-30d"}#{@ver_dias > 60 ? "" : ",31-60"}#{@ver_dias > 90 ? "" : ",61-90"},90+")
                @antsaldos.each do |m|
                    out_arr.push("#{m['Idcliente']},#{m['NombreCli'].gsub(",","")},#{fix_show_date(m['FechaFac'])},#{fix_show_date( ( m['FechaAcl'].to_s.length > 0 ? m['FechaAcl'] : m['FechaEstPago'] ) )},#{m['ControlFac']},#{m['Ventas'] > 0 ? number_to_currency(m['Ventas'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","") : ""},#{m['Pagos'] > 0 ? number_to_currency(m['Pagos'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","") : ""}#{@ver_dias > 0 ? "" : m['Ventas0_30'] > 0 ? ",#{number_to_currency(m['Ventas0_30'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}#{@ver_dias > 30 ? "" : m['Ventas31_60'] > 0 ? ",#{number_to_currency(m['Ventas31_60'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}#{@ver_dias > 60 ? "" : m['Ventas61_90'] > 0 ? ",#{number_to_currency(m['Ventas61_90'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}#{@ver_dias > 90 ? "" : m['Ventas91_120'] > 0 ? ",#{number_to_currency(m['Ventas91_120'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}#{m['Ventas121_'] > 0 ? ",#{number_to_currency(m['Ventas121_'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","}")
                end
                csv_file = "/tmp/antsaldos_suc_#{@antsaldos[0]['Sucursal']}_#{@ultimaAct.to_s}_#{DateTime.now.to_i}.csv"
                csv_file = "/tmp/antsaldos_suc_sin_aclarar_#{@antsaldos[0]['Sucursal']}_#{@ultimaAct.to_s}_#{DateTime.now.to_i}.csv" if @ver_sin_aclarar
                dump_to_file(csv_file,out_arr.join("\n"))
                send_file csv_file
                return
            end
        end
    else
        return redirect_to ant_saldos_path
    end
  end

  def ant_saldos_detalle
    @suc_origen  = params[:suc_origen].to_i if params.has_key?(:suc_origen)
    @control_fac = params[:control_fac].to_i if params.has_key?(:control_fac)
    if @suc_origen && @suc_origen > 0 && @control_fac && @control_fac > 0
        @puede_editar_fecha_acl = false
        get_modulos_usuario
        @puede_editar_fecha_acl = true if get_current_user_app_nivel == 2
        if @puede_editar_fecha_acl
            #Aqui ve si se mando un FecAcl y Comentario para guardarlos
            @fecha_acl  = params[:fecha_acl]  if params.has_key?(:fecha_acl)
            @comentario = params[:comentario] if params.has_key?(:comentario)
            @fecha_acl = Date.strptime(@fecha_acl, "%m/%d/%Y") rescue 0
            if @fecha_acl != 0 && @comentario
                sql = "INSERT INTO AntSaldosFecAcl ( SucOrigen, ControlFac, FechaHora, IdUser, FechaAcl, Comentario ) VALUES ( #{ User.sanitize(@suc_origen) }, #{ User.sanitize(@control_fac) }, now(),  #{ User.sanitize(current_user.id) }, #{ User.sanitize(@fecha_acl) }, #{ User.sanitize(@comentario) } ) ON DUPLICATE KEY UPDATE FechaHora = now(), IdUser = #{ User.sanitize(current_user.id) }, FechaAcl = #{ User.sanitize(@fecha_acl) }, Comentario = #{ User.sanitize(@comentario) }"
                begin
                  @dbEsta.connection.execute(sql)
                rescue Exception => exc
                  return redirect_to "/ant_saldos_detalle?suc_origen=#{@suc_origen}&control_fac=#{@control_fac}", alert: "No se ha podido guardar la Fecha de Aclaracion"
                end
                begin
                  @dbPdv.connection.execute(sql)
                rescue Exception => exc
                  return redirect_to "/ant_saldos_detalle?suc_origen=#{@suc_origen}&control_fac=#{@control_fac}", alert: "No se ha podido guardar la Fecha de Aclaracion"
                end
                # AQUI DEBE GENERARSE UN COMENTARIO CON LA FECHA DE ACLARACION
                @nuevo_comentario = "Fecha Límite Aclaración: #{@fecha_acl} #{@comentario}"
                sql = "INSERT INTO AntSaldosChat ( SucOrigen, ControlFac, FechaHora, IdUser, Comentario ) VALUES ( #{ User.sanitize(@suc_origen) }, #{ User.sanitize(@control_fac) }, now(), #{ User.sanitize(current_user.id) }, #{ User.sanitize(@nuevo_comentario) } )"
                begin
                  @dbEsta.connection.execute(sql)
                rescue Exception => exc
                  return redirect_to "/ant_saldos_detalle?suc_origen=#{@suc_origen}&control_fac=#{@control_fac}", alert: "No se ha podido guardar el comentario despues de agregar la fecha de aclaracion"
                end
                # Se escribe por duplicado en Esta y Pdv
                begin
                  @dbPdv.connection.execute(sql)
                rescue Exception => exc
                  return redirect_to "/ant_saldos_detalle?suc_origen=#{@suc_origen}&control_fac=#{@control_fac}", alert: "No se ha podido guardar el comentario en PDV despues de agregar la fecha de aclaracion"
                end
                # Aqui se manda un mail de los comentarios
                enviar_mails_comentarios(@suc_origen, @control_fac, current_user.id, @nuevo_comentario)
                return redirect_to "/ant_saldos_detalle?suc_origen=#{@suc_origen}&control_fac=#{@control_fac}", notice: "Fecha de Aclaracion guardada exitosamente"
            end
            # Aqui se ve si se mando un borrar_fecha_acl para borrarlo
            @borrar_fecha_acl = params[:borrar_fecha_acl].to_i if params.has_key?(:borrar_fecha_acl)
            if @borrar_fecha_acl == 1
                sql = "DELETE FROM AntSaldosFecAcl WHERE SucOrigen = #{ User.sanitize(@suc_origen) } AND ControlFac = #{ User.sanitize(@control_fac) }"
                begin
                  @dbEsta.connection.execute(sql)
                rescue Exception => exc
                  return redirect_to "/ant_saldos_detalle?suc_origen=#{@suc_origen}&control_fac=#{@control_fac}", alert: "No se ha podido borrar la Fecha de Aclaracion"
                end
                begin
                  @dbPdv.connection.execute(sql)
                rescue Exception => exc
                  return redirect_to "/ant_saldos_detalle?suc_origen=#{@suc_origen}&control_fac=#{@control_fac}", alert: "No se ha podido borrar la Fecha de Aclaracion"
                end
                return redirect_to "/ant_saldos_detalle?suc_origen=#{@suc_origen}&control_fac=#{@control_fac}", notice: "Fecha de Aclaracion borrada exitosamente"
            end
        end
        # Aqui se ve si se mando un nuevo comentario al Chat
        @nuevo_comentario = params[:nuevo_comentario] if params.has_key?(:nuevo_comentario)
        if @nuevo_comentario && @nuevo_comentario.to_s.length > 0
            sql = "INSERT INTO AntSaldosChat ( SucOrigen, ControlFac, FechaHora, IdUser, Comentario ) VALUES ( #{ User.sanitize(@suc_origen) }, #{ User.sanitize(@control_fac) }, now(), #{ User.sanitize(current_user.id) }, #{ User.sanitize(@nuevo_comentario) } )"
            begin
              @dbEsta.connection.execute(sql)
            rescue Exception => exc
              return redirect_to "/ant_saldos_detalle?suc_origen=#{@suc_origen}&control_fac=#{@control_fac}", alert: "No se ha podido guardar el comentario"
            end
            # Se escribe por duplicado en Esta y Pdv
            begin
              @dbPdv.connection.execute(sql)
            rescue Exception => exc
              return redirect_to "/ant_saldos_detalle?suc_origen=#{@suc_origen}&control_fac=#{@control_fac}", alert: "No se ha podido guardar el comentario en PDV"
            end
            # Aqui se manda un mail de los comentarios
            enviar_mails_comentarios(@suc_origen, @control_fac, current_user.id, @nuevo_comentario)
            return redirect_to "/ant_saldos_detalle?suc_origen=#{@suc_origen}&control_fac=#{@control_fac}", notice: "Comentario guardado exitosamente"
        end
        get_filtros_from_user
        sql = "SELECT AntSaldos.*, AntSaldosFecAcl.FechaHora as faFechaHora, AntSaldosFecAcl.IdUser as faIdUser, AntSaldosFecAcl.FechaAcl as faFechaAcl, AntSaldosFecAcl.Comentario as faComentario, '' as userEmail, '' as userName FROM AntSaldos LEFT JOIN AntSaldosFecAcl ON AntSaldosFecAcl.SucOrigen = AntSaldos.SucOrigen and AntSaldosFecAcl.ControlFac = AntSaldos.ControlFac WHERE AntSaldos.SucOrigen = #{@suc_origen} and AntSaldos.ControlFac = #{@control_fac} and ( ( #{@filtros.join(" ) and ( ")} ) ) ORDER BY Idcliente, AntSaldos.ControlFac"
        @antsaldos = @dbEsta.connection.select_all(sql)
        @ultimaAct = Date.parse(@antsaldos[0]['FechaProc']) rescue nil
        return redirect_to ant_saldos_path, alert: "No se han encontrado datos" if !@ultimaAct
        # Populate data from intranet.users as it's in other server
        @antsaldos.each do |a|
            if a['faIdUser'].to_i > 0
                u = User.where("id = #{a['faIdUser']}").first
                a['userEmail'] = u.email rescue ''
                a['userName']  = u.name rescue ''
            end
        end
        sql = "SELECT AntSaldosChat.*, '' as userEmail, '' as userName FROM AntSaldosChat WHERE SucOrigen = #{@suc_origen} and ControlFac = #{@control_fac} ORDER BY FechaHora"
        @chat_comments = @dbEsta.connection.select_all(sql)
        @chat_comments.each do |a|
            if a['IdUser'].to_i > 0
                u = User.where("id = #{a['IdUser']}").first
                a['userEmail'] = u.email rescue ''
                a['userName']  = u.name rescue ''
            end
        end
        # Se buscan los datos de Hmovpdv sobre el ControlFac en el 14 para que carguen mas rapido
        # Ahora esos datos se buscan de Hcredito
        sql = "SELECT Fecha, Nummov, Controlfac, Tipo_subt, Total, Ventas, Pagos, tipomov.NomTipoSubTipo FROM hCreditos LEFT JOIN #{@nomDbPdv}tipomov ON Tipo_subt = TipoSubTipo WHERE Sucursal = #{@suc_origen} AND ControlFac = '#{@control_fac}' ORDER BY Fecha"
        @hcred = @dbEsta.connection.select_all(sql)
        # sql = "SELECT Fecha, Nummov, Controlfac, Tipo_subt, Total, Totvaluado, Observac, tipomov.NomTipoSubTipo FROM #{@nomDbPdv}hmovpdv LEFT JOIN #{@nomDbPdv}tipomov ON Tipo_subt = TipoSubTipo WHERE ( ( Tipo_subt = '#{["V$", "v$", "VC", "vC", "fC", "f$"].join("' ) OR ( Tipo_subt = '")}' ) ) AND hmovpdv.Sucursal = #{@suc_origen} AND hmovpdv.ControlFac = '#{@control_fac}' AND Status2 = 'T' UNION SELECT Fecha, Nummov, Controlfac, Tipo_subt, 0 as Total, Importe as Totvaluado, '' as Observac, tipomov.NomTipoSubTipo FROM #{@nomDbPdv}dcredito LEFT JOIN #{@nomDbPdv}tipomov ON Tipo_subt = TipoSubTipo WHERE dcredito.Sucursal = #{@suc_origen} AND dcredito.ControlFac = '#{@control_fac}' AND Status2 = 'T'"
        sql = "SELECT Fecha, Nummov, Controlfac, Tipo_subt, Total, Totvaluado, Observac, tipomov.NomTipoSubTipo FROM #{@nomDbPdv}hmovpdv LEFT JOIN #{@nomDbPdv}tipomov ON Tipo_subt = TipoSubTipo WHERE ( ( Tipo_subt = '#{["V$", "v$", "VC", "vC", "fC", "f$"].join("' ) OR ( Tipo_subt = '")}' ) ) AND hmovpdv.Sucursal = #{@suc_origen} AND hmovpdv.ControlFac = '#{@control_fac}' AND Status2 = 'T' ORDER BY sucursal, fecha, nummov"
        @hmov = @dbEsta.connection.select_all(sql)
    else
        return redirect_to ant_saldos_path
    end
  end

  def ant_saldos_vencidas
    @ver_sin_aclarar = false
    @ver_sin_aclarar = true if params.has_key?(:sin_aclarar) && params[:sin_aclarar].to_i == 1
    @dias = 0
    @dias = params[:dias].to_i if params.has_key?(:dias)
    get_filtros_from_user
    @filtros.push("s.SucCXCVencidas = 0") if !params.has_key?(:incluir_sucvencidas)

    sql = "SELECT AntSaldos.*, AntSaldosFecAcl.FechaAcl, AntSaldosFecAcl.Comentario, #{@nomDbComun}zonas.NomZona, '' as ultFactura, '' as ultComentario, '' as dias FROM AntSaldos LEFT JOIN AntSaldosFecAcl ON AntSaldos.SucOrigen = AntSaldosFecAcl.SucOrigen AND AntSaldos.ControlFac = AntSaldosFecAcl.ControlFac LEFT JOIN #{@nomDbComun}zonas ON #{@nomDbComun}zonas.NumZona = ZonaAsig LEFT JOIN #{@nomDbComun}sucursal as s ON s.Num_suc = Sucursal WHERE ( ( #{@filtros.join(" ) and ( ")} ) ) ORDER BY AntSaldos.ZonaAsig, AntSaldos.Sucursal, Idcliente"

    @antsaldos_q = @dbEsta.connection.select_all(sql)
    @antsaldos = []
    @ultimaAct = ""
    @antsaldos_q.each do |m|
        @ultimaAct = Date.parse(m['FechaProc']) rescue "" if @ultimaAct == ""
        fechaPago = m['FechaEstPago']
        # fechaPago = m['FechaAcl'] if m['FechaAcl'].to_s.length > 0 if @ver_sin_aclarar
        # raise fechaPago.inspect if fechaPago.to_s.length > 0
        fechaPago = Date.parse(fechaPago.to_s) rescue 0
        fechaFac  = m['FechaFac']
        fechaFac  = Date.parse(fechaFac.to_s) rescue 0

        fechaAcl = Date.yesterday.to_s
        fechaAcl = m['FechaAcl'] if m['FechaAcl'].to_s.length > 0 if @ver_sin_aclarar
        fechaAcl = Date.parse(fechaAcl.to_s) rescue 0

        # FechaAcl:  lo correcto es que: Los días de vencida SIEMPRE se calculan como: fecha actual – (fecha de la venta+plazo) , y cuando se selecciona “sin aclarar” el filtro es que NO ponga aquellas que su fecha de aclaración >= fecha actual

        if fechaPago > 0 && fechaPago <= Date.today - @dias.days && fechaAcl < Date.today

            # AQUI SE AGREGAN LOS COMENTARIOS DE LA FACTURA
            sql = "SELECT AntSaldosChat.*, '' as userEmail, '' as userName FROM AntSaldosChat WHERE SucOrigen = #{m['SucOrigen']} and ControlFac = #{m['ControlFac']} ORDER BY FechaHora DESC limit 1"
            @chat_comments = @dbEsta.connection.select_all(sql)
            comentarios = []
            @chat_comments.each do |a|
                if a['IdUser'].to_i > 0
                    u = User.where("id = #{a['IdUser']}").first
                    a['userName']  = u.name rescue ''
                end
                comentarios.push("#{a['Comentario'].to_s.strip.gsub("\n"," ").gsub("\r"," ")} (#{a['userName']} - #{a['FechaHora'].to_s(:db)[0..19]})")
            end
            sql = "SELECT hCreditos.* from hCreditos WHERE Idsucursal = #{m['SucOrigen']} AND Idcliente = #{m['Idcliente']} ORDER BY Fecha DESC limit 1"
            ultFactura = @dbEsta.connection.select_all(sql)

            # leyenda_dias = "#{(Date.today - fechaFac).to_i} DIAS:"
            # leyenda_dias = "<FONT style=\"BACKGROUND-COLOR: #DFD400\">#{leyenda_dias}</FONT>" if ( fechaFac <= Date.today - 61.days and fechaFac >= Date.today - 90.days )
            # leyenda_dias = "<FONT style=\"BACKGROUND-COLOR: #FFA430\">#{leyenda_dias}</FONT>" if ( fechaFac <= Date.today - 91.days and fechaFac >= Date.today - 120.days )
            # leyenda_dias = "<FONT style=\"BACKGROUND-COLOR: #ED7E7F\">#{leyenda_dias}</FONT>" if ( fechaFac <= Date.today - 121.days )

            m['ultFactura'] = ultFactura.first['Fecha'] if ultFactura.count > 0
            m['ultComentario'] = comentarios.first if comentarios.count > 0
            m['dias'] = "#{(Date.today - fechaPago).to_i}"
            # raise m.inspect
            @antsaldos.push(m)

            # linea = "<FONT color=#3D00FF>Región: #{m['ZonaAsig']} - #{m['NomZona']} - Sucursal: #{m['Sucursal']} - #{m['NombreSuc']}</FONT>\n<FONT color=#B200D6>&nbsp;#{m['Idcliente']} - #{m['NombreCli']}</FONT>\n&nbsp;&nbsp;#{leyenda_dias} Control #{m['ControlFac']} de #{view_context.fix_show_date(m['FechaFac'])} por #{number_to_currency(m['Ventas'], :locale => :mx, :precision => 2)}#{ m['Pagos'].to_i > 0 ? " con saldo #{number_to_currency(m['Ventas'] - m['Pagos'], :locale => :mx, :precision => 2)}" : ""}#{comentarios.length > 0 ? "\n#{comentarios.join("\n")}" : ""}"
            # @email_hoy.push(linea) if fechaPago == Date.today
            # @email_1_30_dias.push(linea) if ( fechaFac <= Date.today - 1.days and fechaFac >= Date.today - 30.days )
            # @email_31_60_dias.push(linea) if ( fechaFac <= Date.today - 31.days and fechaFac >= Date.today - 60.days )
            # @email_61_90_dias.push(linea) if ( fechaFac <= Date.today - 61.days and fechaFac >= Date.today - 90.days )
            # @email_91_120_dias.push(linea) if ( fechaFac <= Date.today - 91.days and fechaFac >= Date.today - 120.days )
            # @email_121_dias.push(linea) if ( fechaFac <= Date.today - 121.days )
        end
    end
    respond_to do |format|
        format.html
        format.csv do
            out_arr = []
            out_arr.push("Zona-Suc,Sucursal,IdCliente,Cliente,Fecha,Control,Venta,Saldo,FechaEst,UltFactura,UltComentario,Días")
            @antsaldos.each do |m|
                out_arr.push("#{m['ZonaAsig']}-#{m['Sucursal'].to_s.rjust(3,'0')},#{m['NombreSuc']},#{m['Idcliente']},#{m['NombreCli'].gsub(",","")},#{fix_show_date(m['FechaFac'])},#{m['ControlFac']},#{m['Ventas'] > 0 ? "#{number_to_currency(m['Ventas'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")}" : ","},#{number_to_currency(m['Ventas'] - m['Pagos'], :locale => :mx, :precision => 2).gsub(",","").gsub("$","")},#{fix_show_date( ( m['FechaAcl'].to_s.length > 0 ? m['FechaAcl'] : m['FechaEstPago'] ) )},#{fix_show_date( m['ultFactura'].to_s )},#{m['ultComentario'].gsub(",","")},#{ m['dias']}")
            end

            csv_file = "/tmp/ant_saldos_vencidas_#{@ultimaAct.to_s}_#{DateTime.now.to_i}.csv"
            csv_file = "/tmp/ant_saldos_vencidas_sin_aclarar_#{@ultimaAct.to_s}_#{DateTime.now.to_i}.csv" if @ver_sin_aclarar
            dump_to_file(csv_file,out_arr.join("\n"))
            send_file csv_file
            return
        end
    end
  end

  def ant_saldos_comentarios
    @ver_dias_comentarios = 7
    @ver_dias_comentarios = params[:ver_dias_comentarios].to_i if params.has_key?(:ver_dias_comentarios) && ( params[:ver_dias_comentarios].to_i == 30 or params[:ver_dias_comentarios].to_i == 90 or params[:ver_dias_comentarios].to_i == 365 )
    get_filtros_from_user

    sql = "SELECT *, AntSaldos.ZonaAsig, AntSaldos.Sucursal, AntSaldos.SucOrigen FROM AntSaldosChat LEFT JOIN AntSaldos ON AntSaldosChat.SucOrigen = AntSaldos.SucOrigen AND AntSaldosChat.ControlFac = AntSaldos.ControlFac WHERE AntSaldosChat.FechaHora >= '#{( DateTime.now.beginning_of_day - @ver_dias_comentarios.days ).to_s[0..18]}' and ( ( #{@filtros.join(" ) and ( ")} ) ) GROUP BY AntSaldosChat.ControlFac"
    @comentarios = @dbEsta.connection.select_all(sql)
    @filtros_comentarios = ["1"]
    @comentarios.each do |c|
        # Se hace un arreglo con las SucOrigen y ControlFac
        @filtros_comentarios.push("AntSaldos.SucOrigen = #{c['SucOrigen']} AND AntSaldos.ControlFac = #{c['ControlFac']}")
    end
    @filtros.push("( #{@filtros_comentarios.join(" ) OR ( ")} )")
    sql = "SELECT AntSaldos.*, AntSaldosFecAcl.FechaAcl, AntSaldosChat.FechaHora as ascFechaHora, AntSaldosChat.IdUser as ascIdUser, AntSaldosChat.Comentario as ascComentario, '' as userEmail, '' as userName FROM AntSaldos LEFT JOIN AntSaldosFecAcl ON AntSaldos.SucOrigen = AntSaldosFecAcl.SucOrigen AND AntSaldos.ControlFac = AntSaldosFecAcl.ControlFac LEFT JOIN AntSaldosChat ON AntSaldos.SucOrigen = AntSaldosChat.SucOrigen AND AntSaldos.ControlFac = AntSaldosChat.ControlFac WHERE AntSaldosChat.FechaHora and ( ( #{@filtros.join(" ) and ( ")} ) ) ORDER BY Idcliente, AntSaldos.ControlFac, AntSaldosChat.FechaHora limit 100"
    @antsaldos = @dbEsta.connection.select_all(sql)
    # Se populan los Emails y Names de los Usuarios que pusieron los comentarios (que estan en otra base en otro servidor)
    @antsaldos.each do |a|
        if a['ascIdUser'].to_i > 0
            u = User.where("id = #{a['ascIdUser']}").first
            a['userEmail'] = u.email rescue ''
            a['userName']  = u.name rescue ''
        end
    end
  end

  def ant_saldos_mails
    # http://rahca.com.mx:3000/ant_saldos_mails?Email=lola%40lola.com&Empresa=4&Sucursal=0&TipoMail=1&Zona=0
    if params.has_key?(:Email) && params.has_key?(:Sucursal) && params.has_key?(:TipoMail) && params.has_key?(:Zona)
        # Editar Renglon
        sql = "SELECT * from AntSaldosMail WHERE TipoMail = #{User.sanitize(params[:TipoMail].to_i)} AND Email = #{User.sanitize(params[:Email])} AND Zona = #{User.sanitize(params[:Zona].to_i)} AND Sucursal = #{User.sanitize(params[:Sucursal].to_i)}"
        @antsaldosmails = @dbEsta.connection.select_all(sql)
        if @antsaldosmails and @antsaldosmails.count == 1
            # Se debe mostrar el formulario
            @antsaldosmail = @antsaldosmails[0]
            render 'ant_saldos_mails_edit'
            # raise @antsaldosmails.inspect
        end
    end
    # Ver todo
    sql = "SELECT AntSaldosMail.*, '' as nomTipoMail, '' as nomZona, '' as nomSucursal from AntSaldosMail"
    @antsaldosmails = @dbEsta.connection.select_all(sql)
    @antsaldosmails.each do |a|
        a['nomTipoMail'] = "Todos"
        a['nomTipoMail'] = "Fecha Estimada" if a['TipoMail'] == 1
        a['nomTipoMail'] = "Comentarios Nuevos" if a['TipoMail'] == 2
        a['nomZona'] = "Todas"
        a['nomZona'] = @dbComun.connection.select_all("SELECT * FROM zonas WHERE NumZona = #{a['Zona']} LIMIT 1")[0]['NomZona'] rescue 'Sin Zona' if a['Zona'] != -1
        a['nomSucursal'] = "Todas"
        a['nomSucursal'] = @dbComun.connection.select_all("SELECT * FROM sucursal WHERE Num_suc = #{a['Sucursal']} LIMIT 1")[0]['Nombre'] rescue 'Sin Sucursal' if a['Sucursal'] != -1
    end
  end

  def ant_saldos_mails_new
    render 'ant_saldos_mails_new'
  end

  def ant_saldos_mails_create
    # Aqui se crea o actualiza el antsaldosmail
    if params.has_key?(:Email) && params.has_key?(:Sucursal) && params.has_key?(:TipoMail) && params.has_key?(:Zona) && params.has_key?(:Frecuencia)
        return redirect_to '/ant_saldos_mails_new', alert: "Favor de ingresar un Email valido" if ! params[:Email].to_s.include?("@")
        sql = "INSERT IGNORE INTO AntSaldosMail (TipoMail, Email, Zona, Sucursal, Frecuencia) VALUES (#{User.sanitize(params[:TipoMail].to_i)}, #{User.sanitize(params[:Email])}, #{User.sanitize(params[:Zona].to_i)}, #{User.sanitize(params[:Sucursal].to_i)}, #{User.sanitize(params[:Frecuencia].to_i)})"
        begin
            @dbEsta.connection.execute(sql)
        rescue Exception => exc
            return redirect_to '/ant_saldos_mails', alert: "Ha ocurrido un error: #{exc.message}"
        end
        begin
            @dbPdv.connection.execute(sql)
        rescue Exception => exc
            return redirect_to '/ant_saldos_mails', alert: "Ha ocurrido un error al escribir en Pdv: #{exc.message}"
        end
        return redirect_to '/ant_saldos_mails', notice: "Email guardado exitosamente"
    end
    return redirect_to '/ant_saldos_mails', alert: "Favor de revisar sus datos"
  end

  def ant_saldos_mails_delete
    # Aqui se crea o actualiza el antsaldosmail
    if params.has_key?(:Email) && params.has_key?(:Sucursal) && params.has_key?(:TipoMail) && params.has_key?(:Zona) && params.has_key?(:Frecuencia)
        sql = "DELETE FROM AntSaldosMail WHERE TipoMail = #{User.sanitize(params[:TipoMail].to_i)} and Email = #{User.sanitize(params[:Email])} and Zona = #{User.sanitize(params[:Zona].to_i)} and Sucursal = #{User.sanitize(params[:Sucursal].to_i)} and Frecuencia = #{User.sanitize(params[:Frecuencia].to_i)}"
        begin
            @dbEsta.connection.execute(sql)
        rescue Exception => exc
            return redirect_to '/ant_saldos_mails', alert: "Ha ocurrido un error: #{exc.message}"
        end
        begin
            @dbPdv.connection.execute(sql)
        rescue Exception => exc
            return redirect_to '/ant_saldos_mails', alert: "Ha ocurrido un error: #{exc.message}"
        end
        return redirect_to '/ant_saldos_mails', notice: "Datos modificados"
    end
    return redirect_to '/ant_saldos_mails'
  end

  def enviar_mails_de_aclaracion_robot
    # Esta funcion deberia ejecutarse con un cron para enviar todos los mails de aclaracion
    # Se puede enviar un mail de prueba agregando el parametro email: /enviar_mails_de_aclaracion_robot/?email=fernandoc@pintacomex.mx
    index = -1
    index = params[:index].to_i if params.has_key?(:index)
    sql = "SELECT * from AntSaldosMail"
    sql = "SELECT * from AntSaldosMail WHERE (TipoMail = 0 or TipoMail = 1) and Email = #{User.sanitize(params[:email])}" if params.has_key?(:email)
    @emails_enviados = []
    @emails_comentarios = @dbEsta.connection.select_all(sql)
    @emails_comentarios.each_with_index do |e, email_index|
        next if index > -1 && index != email_index
        next if !e['Email'].to_s.include?("@")
        next if !debe_enviar_email(e)
        @filtros           = []
        @email_hoy         = []
        @email_1_30_dias   = []
        @email_31_60_dias  = []
        @email_61_90_dias  = []
        @email_91_120_dias = []
        @email_121_dias    = []
        @ultimaAct         = ""
        @nom_zona          = ""
        @nom_suc           = ""
        @sucOrigenAnterior = ""
        @chat_comments     = []

        @nom_zona = @dbComun.connection.select_all("SELECT * FROM zonas WHERE NumZona = #{e['Zona']} LIMIT 1")[0]['NomZona'] rescue "" if e['Zona'] != -1
        @num_suc  = @dbComun.connection.select_all("SELECT * FROM sucursal WHERE Num_suc = #{e['Sucursal']} LIMIT 1")[0]['Nombre'] rescue "" if e['Sucursal'] != -1

        @filtros.push("1")
        @filtros.push("AntSaldos.ZonaAsig = #{e['Zona'].to_i}") if e['Zona'].to_i != -1
        @filtros.push("AntSaldos.Sucursal = #{e['Sucursal'].to_i}") if e['Sucursal'].to_i != -1
        @filtros.push("s.SucCXCVencidas = 0")
        @filtros.push("abs(ventas-pagos) <> 0")

        sql = "SELECT AntSaldos.*, AntSaldosFecAcl.FechaAcl, AntSaldosFecAcl.Comentario, #{@nomDbComun}zonas.NomZona FROM AntSaldos LEFT JOIN AntSaldosFecAcl ON AntSaldos.SucOrigen = AntSaldosFecAcl.SucOrigen AND AntSaldos.ControlFac = AntSaldosFecAcl.ControlFac LEFT JOIN #{@nomDbComun}zonas ON #{@nomDbComun}zonas.NumZona = ZonaAsig LEFT JOIN #{@nomDbComun}sucursal as s ON s.Num_suc = Sucursal WHERE ( ( #{@filtros.join(" ) and ( ")} ) ) ORDER BY AntSaldos.ZonaAsig, AntSaldos.Sucursal, Idcliente, FechaFac"
        @antsaldos = @dbEsta.connection.select_all(sql)
        @antsaldos.each do |m|
            @ultimaAct = Date.parse(m['FechaProc']) rescue "" if @ultimaAct == ""
            fechaPago = m['FechaEstPago']
            fechaPago = m['FechaAcl'] if m['FechaAcl'].to_s.length > 0
            # raise fechaPago.inspect if fechaPago.to_s.length > 0
            fechaPago = Date.parse(fechaPago.to_s) rescue 0
            fechaFac  = m['FechaFac']
            fechaFac  = Date.parse(fechaFac.to_s) rescue 0
            # Ya no se van a usar las fechas sino el campo diasVencido
            diasVencido = m['diasVencido'].to_i rescue 0
            if @sucOrigenAnterior != m['SucOrigen']
                sql = "SELECT AntSaldosChat.*, '' as userEmail, '' as userName FROM AntSaldosChat WHERE SucOrigen = #{m['SucOrigen']} and Controlfac = #{m['ControlFac']} ORDER BY FechaHora"
                @chat_comments = @dbEsta.connection.select_all(sql)
                @sucOrigenAnterior = m['SucOrigen']
            end
            # if fechaPago > 0 && fechaPago <= Date.today
            if diasVencido > 0
                # AQUI SE AGREGAN LOS COMENTARIOS DE LA FACTURA
                sql = "SELECT AntSaldosChat.*, '' as userEmail, '' as userName FROM AntSaldosChat WHERE SucOrigen = #{m['SucOrigen']} and Controlfac = #{m['ControlFac']} ORDER BY FechaHora"
                @chat_comments = @dbEsta.connection.select_all(sql)
                comentarios = []
                @chat_comments.each do |a|
                    next if m['ControlFac'].to_s != a['ControlFac'].to_s
                    if a['IdUser'].to_i > 0
                        u = User.where("id = #{a['IdUser']}").first
                        a['userName']  = u.name rescue ''
                    end
                    comentarios.push("&nbsp;&nbsp;&nbsp;&nbsp;#{a['Comentario'].to_s.strip.gsub("\n"," ").gsub("\r"," ")} (#{a['userName']} - #{a['FechaHora'].to_s(:db)[0..19]})")
                end
                leyenda_dias = "#{diasVencido} DIAS:"
                # leyenda_dias = "<FONT style=\"BACKGROUND-COLOR: #DFD400\">#{leyenda_dias}</FONT>" if ( fechaFac <= Date.today - 61.days and fechaFac >= Date.today - 90.days ).
                # leyenda_dias = "<FONT style=\"BACKGROUND-COLOR: #FFA430\">#{leyenda_dias}</FONT>" if ( fechaFac <= Date.today - 91.days and fechaFac >= Date.today - 120.days )
                # leyenda_dias = "<FONT style=\"BACKGROUND-COLOR: #ED7E7F\">#{leyenda_dias}</FONT>" if ( fechaFac <= Date.today - 121.days )
                leyenda_dias = "<FONT style=\"BACKGROUND-COLOR: #FFFF02\">#{leyenda_dias}</FONT>" if ( diasVencido >= 1 and diasVencido <= 30 )
                leyenda_dias = "<FONT style=\"BACKGROUND-COLOR: #FFA430\">#{leyenda_dias}</FONT>" if ( diasVencido >= 31 and diasVencido <= 60 )
                leyenda_dias = "<FONT style=\"BACKGROUND-COLOR: #ED7E7f\">#{leyenda_dias}</FONT>" if ( diasVencido >= 61 and diasVencido <= 90 )
                leyenda_dias = "<FONT style=\"BACKGROUND-COLOR: #FF0000\">#{leyenda_dias}</FONT>" if ( diasVencido >= 91 )
                # leyenda_dias = "<FONT style=\"BACKGROUND-COLOR: #ED7E7F\">#{leyenda_dias}</FONT>" if ( diasVencido >= 121 )

                comentarios_str = ''
                if comentarios.length > 0 and e['TipoMail'] != 1
                  comentarios_str = "\n#{comentarios.join("\n")}"
                end

                linea = "<FONT color=#3D00FF>Región: #{m['ZonaAsig']} - #{m['NomZona']} - Sucursal: #{m['Sucursal']} - #{m['NombreSuc']}</FONT>\n<FONT color=#B200D6>&nbsp;#{m['Idcliente']} - #{m['NombreCli']}</FONT>\n&nbsp;&nbsp;#{leyenda_dias} Control #{m['ControlFac']} de #{view_context.fix_show_date(m['FechaFac'])} por #{number_to_currency(m['Ventas'], :locale => :mx, :precision => 2)}#{ m['Pagos'].to_i > 0 ? " con saldo #{number_to_currency(m['Ventas'] - m['Pagos'], :locale => :mx, :precision => 2)}" : ""}#{comentarios_str}"

                # @email_hoy.push(linea) if fechaPago == Date.today
                # @email_1_30_dias.push(linea) if ( fechaFac <= Date.today - 1.days and fechaFac >= Date.today - 30.days )
                # @email_31_60_dias.push(linea) if ( fechaFac <= Date.today - 31.days and fechaFac >= Date.today - 60.days )
                # @email_61_90_dias.push(linea) if ( fechaFac <= Date.today - 61.days and fechaFac >= Date.today - 90.days )
                # @email_91_120_dias.push(linea) if ( fechaFac <= Date.today - 91.days and fechaFac >= Date.today - 120.days )
                # @email_121_dias.push(linea) if ( fechaFac <= Date.today - 121.days )
                @email_hoy.push(linea) if diasVencido == 1
                @email_1_30_dias.push(linea) if ( diasVencido >= 1 and diasVencido <= 30 )
                @email_31_60_dias.push(linea) if ( diasVencido >= 31 and diasVencido <= 60 )
                @email_61_90_dias.push(linea) if ( diasVencido >= 61 and diasVencido <= 90 )
                @email_91_120_dias.push(linea) if ( diasVencido >= 91 )
                # @email_121_dias.push(linea) if ( diasVencido >= 121 )
            end
        end

        # las facturas que “Vencen Hoy” solo salen para los usuarios que solamente vean una sucursal
        @email_hoy = [] if e['Sucursal'].to_i == -1
        # Ya no se envian las facturas de 1-30 o 31-60
        # @email_1_30_dias  = []
        # @email_31_60_dias = []
        if @email_hoy.count > 0 || @email_1_30_dias.count  > 0 || @email_31_60_dias.count > 0 || @email_61_90_dias.count > 0 || @email_91_120_dias.count > 0 || @email_121_dias.count > 0
            # Debe enviarse el email
            AntSaldosEmailsEnviado.create(email: e.to_s, fecha: Date.today)
            mail_to      = e['Email'].to_s.gsub(" ", "")
            mail_subject = "Facturas Vencidas de Antiguedad de Saldos #{DateTime.now.to_s} #{" Región: #{@nom_zona}" if @nom_zona != ""}#{" Sucursal: #{@nom_suc}" if @nom_suc != ""}#{" al #{@ultimaAct.to_s}" if @ultimaAct}"
            mail_body    = "Estas son las facturas vencidas por aclarar#{" Región: #{@nom_zona}" if @nom_zona != ""}#{" Sucursal: #{@nom_suc}" if @nom_suc != ""}#{" al #{@ultimaAct.to_s}" if @ultimaAct}:<br />#{hacer_mail_dias( [ ["<STRONG>Vencen Hoy:</STRONG>", @email_hoy], ["<STRONG>Facturas vencidas más de 120 días:</STRONG>", @email_121_dias], ["<STRONG>Facturas vencidas más de 90 días:</STRONG>", @email_91_120_dias], ["<STRONG>Facturas vencidas entre 61 y 90 días:</STRONG>", @email_61_90_dias], ["<STRONG>Facturas vencidas entre 31 y 60 días:</STRONG>", @email_31_60_dias], ["<STRONG>Facturas vencidas entre 1 y 30 días:</STRONG>", @email_1_30_dias] ] ) }"
            mail_body = simple_format(mail_body, {}, sanitize: false, wrapper_tag: "div")
            mail_body = "<HTML><HEAD></HEAD><BODY><DIV style=\"FONT-SIZE: 12pt; FONT-FAMILY: 'Calibri'; COLOR: #000000\">#{mail_body}</DIV></BODY></HTML>"
            # mail_body = "<HTML><HEAD></HEAD><BODY><DIV style=\"FONT-SIZE: 12pt; FONT-FAMILY: 'Calibri'; COLOR: #000000\">#{mail_body}</DIV></BODY></HTML>"
            if modo_local?
              puts "Se iba a enviar el siguiente email pero manda localmente a la consola:\n  mail_to: #{mail_to}\n  mail_subject: #{mail_subject}\n  mail_body: #{mail_body}\n"
            else
              JustMailer.email_something_html(mail_to, mail_subject, mail_body).deliver_later
            end
            @emails_enviados.push({ index: index, email: e })
            # p "Enviando email: #{mail_to}, #{mail_subject}, #{mail_body}"
        end
    end
    render status: 200, json: { info: "Tarea ejecutada exitosamente. Modo Local: #{modo_local?}. Emails enviados: #{@emails_enviados.count}: #{@emails_enviados.to_json}" }
    return
  end

  def enviar_mails_de_aclaracion_robot_index
    # Esta funcion regresa los mails q se deberian enviar como un json
    sql = "SELECT * from AntSaldosMail"
    @emails_comentarios = @dbEsta.connection.select_all(sql)
    render status: 200, json: { emails: @emails_comentarios.to_json }
  end

  private

    def get_filtros_from_user
        @filtros = []
        @filtros.push("1")
        @permiso = Permiso.joins("LEFT JOIN cat_roles ON permisos.permiso = cat_roles.nomPermiso").where("idUsuario = #{current_user.id} AND p1 = #{@sitio[0].idEmpresa.to_i}").order("cat_roles.nivel").limit(1)
        if @permiso && @permiso.count == 1
            if @permiso[0].p2 != "" && @permiso[0].p2 != "0"
                @zonas = @permiso[0].p2.to_s.split(',').map{|i| i.to_i}.sort
                @filtros.push("AntSaldos.ZonaAsig = #{@zonas.join(" OR AntSaldos.ZonaAsig = ")}") if @zonas.count > 0
            end
            if @permiso[0].p3 != "" && @permiso[0].p3 != "0"
                @sucursales = @permiso[0].p3.to_s.split(',').map{|i| i.to_i}.sort
                @filtros.push("AntSaldos.Sucursal = #{@sucursales.join(" OR AntSaldos.Sucursal = ")}") if @sucursales.count > 0
            end
        else
            @filtros = []
            Rails.logger.info 'Going to redirect from get_filtros_from_user'
            redirect_to "/", alert: "No autorizado en los permisos para los usuarios" and return
        end
        return @filtros
    end

    def get_filtros_from_dias
        @filtros.push("Ventas31_60 > 0 OR Ventas61_90 > 0 OR Ventas91_120 > 0 OR Ventas121_ > 0")  if @ver_dias == 30
        @filtros.push("Ventas61_90 > 0 OR Ventas91_120 > 0 OR Ventas121_ > 0")  if @ver_dias == 60
        @filtros.push("Ventas91_120 > 0 OR Ventas121_ > 0") if @ver_dias == 90
        @filtros.push("Ventas121_ > 0")   if @ver_dias == 120
    end

    def get_filtros_from_saldos
        # Saldos: 0 ver todo, 1 ver con saldo 2 ver sin saldo 3 ver con saldo negativo
        @having = []
        @having.push("1")
        return if @ver_saldos < 1
        if action_name != "ant_saldos_cliente"
            @having.push("sumVentas - sumPagos > 0")  if @ver_saldos == 1
            @having.push("sum(Ventas) - sum(Pagos) = 0")  if @ver_saldos == 2
            @having.push("sumVentas - sumPagos < 0")  if @ver_saldos == 3
        else
            @having.push("Ventas - Pagos > 0")  if @ver_saldos == 1
            @having.push("Ventas - Pagos = 0")  if @ver_saldos == 2
            @having.push("Ventas - Pagos < 0")  if @ver_saldos == 3
        end
    end

    def get_filtros_from_nombre_rfc
        if @nombre.to_s.length > 0
            @filtros.push("concat(AntSaldos.NombreCli, ' ', c.Alias) like '%#{User.sanitize(@nombre.to_s.upcase)[1..-2]}%'")
        end
        if @rfc.to_s.length > 0
            # Aqui se hace un query para obtener los sucursales y idclientes de pdv.clientes
            sql = "SELECT * FROM #{@nomDbPdv}clientes as c WHERE Rfc = #{User.sanitize(@rfc.upcase)}"
            rfcs = @dbEsta.connection.select_all(sql)
            if rfcs.count > 0
                suc_idcs = []
                rfcs.each do |rfc|
                    suc_idcs.push("AntSaldos.Sucursal = #{rfc['Sucursal']} AND AntSaldos.Idcliente = #{rfc['Idcliente']}")
                end
                @filtros.push("( ( #{suc_idcs.join(" ) OR ( ")} ) )")
            else
                @filtros.push("0")
            end
        end
    end

    def dump_to_file(filename,txt,modo="w")
      File.open(filename, modo) {|f| f.write(txt) }
    end

    def enviar_mails_comentarios(suc_origen, control_fac, user_id, nuevo_comentario)
        # Esta funcion manda los mails a todos los que deben recibir un mail por el nuevo comentario
        sql = "SELECT * from AntSaldosMail WHERE TipoMail = 0 or TipoMail = 2"
        emails_comentarios = @dbEsta.connection.select_all(sql)
        emails_comentarios.each do |e|
            next if !e['Email'].to_s.include?("@")
            # Si yo puse un comentario, no es necesario que yo reciba notificacion
            user = User.find(user_id)
            next if e['Email'].to_s.downcase == user.email.to_s.downcase
            if e['Zona'].to_i != -1 or e['Sucursal'].to_i != -1
                # Hay que revisar la zona y sucursal de la factura
                zona_de_factura = @dbComun.connection.select_all("SELECT ZonaAsig from sucursal where num_suc = #{suc_origen}")[0]['ZonaAsig'] rescue 0
                next if zona_de_factura.to_i != e['Zona'].to_i && suc_origen.to_i != e['Sucursal'].to_i
            end
            # Debe enviarse el email
            # Se toman los datos necesarios:
            sql = "SELECT AntSaldos.*, AntSaldosFecAcl.FechaHora as faFechaHora, AntSaldosFecAcl.IdUser as faIdUser, AntSaldosFecAcl.FechaAcl as faFechaAcl, AntSaldosFecAcl.Comentario as faComentario, '' as userEmail, '' as userName FROM AntSaldos LEFT JOIN AntSaldosFecAcl ON AntSaldosFecAcl.SucOrigen = AntSaldos.SucOrigen and AntSaldosFecAcl.ControlFac = AntSaldos.ControlFac WHERE AntSaldos.SucOrigen = #{suc_origen} and AntSaldos.ControlFac = #{control_fac} ORDER BY Idcliente, AntSaldos.ControlFac"
            @antsaldos = @dbEsta.connection.select_all(sql)
            @antsaldos.each do |a|
                if a['faIdUser'].to_i > 0
                    u = User.where("id = #{a['faIdUser']}").first
                    a['userEmail'] = u.email rescue ''
                    a['userName']  = u.name rescue ''
                end
            end
            sql = "SELECT AntSaldosChat.*, '' as userEmail, '' as userName FROM AntSaldosChat WHERE SucOrigen = #{suc_origen} and ControlFac = #{control_fac} ORDER BY FechaHora"
            @chat_comments = @dbEsta.connection.select_all(sql)
            @chat_comments.each do |a|
                if a['IdUser'].to_i > 0
                    u = User.where("id = #{a['IdUser']}").first
                    a['userEmail'] = u.email rescue ''
                    a['userName']  = u.name rescue ''
                end
            end
            mail_chats = ""
            if @chat_comments.count > 1
                mail_chats = "\n\nHistorial de Comentarios:\n\n"
                @chat_comments.each do |comment|
                    mail_chats = "#{mail_chats}#{comment['userName'].to_s.gsub(" - ", " ")} (#{comment['userEmail']} - #{comment['FechaHora'].to_s(:db)[0..19]}): #{comment['Comentario']}\n"
                end
            end
            mail_to      = e['Email']
            mail_subject = "Nuevo Comentario: Sucursal #{suc_origen} - ControlFac: #{control_fac}"
            mail_body    = "Hay un Nuevo Comentario de #{user.name} (#{user.email}) para siguiente factura:\n\nSucursal: #{@antsaldos[0]['Sucursal']} - #{@antsaldos[0]['NombreSuc']}\nCliente: #{@antsaldos[0]['Idcliente']} - #{@antsaldos[0]['NombreCli']}\nFactura: Control #{control_fac} de #{view_context.fix_show_date(@antsaldos[0]['FechaFac'])} por #{number_to_currency(@antsaldos[0]['Ventas'], :locale => :mx, :precision => 2)} con Fecha Límite: #{view_context.fix_show_date( ( @antsaldos[0]['faFechaAcl'].to_s.length > 0 ? @antsaldos[0]['faFechaAcl'] : @antsaldos[0]['FechaEstPago'] ) ) }\n\nComentario Nuevo: #{nuevo_comentario}#{mail_chats}"
            # JustMailer.email_something(mail_to, mail_subject, mail_body).deliver_later
            p "Enviando email: #{mail_to}, #{mail_subject}, #{mail_body}"
        end
    end

    def hacer_mail_dias(arr)
        ret = []
        arr.each do |a|
            if a[1].count > 0
                ret.push("<br />")
                ret.push("\n#{a[0]}\n")
                # Esto es para hacer un encabezado por sucursal y otro para cliente
                ult_sucursal = ""
                ult_cliente = ""
                a[1].each do |linea|
                    if ult_sucursal != linea.split("\n")[0]
                        ult_sucursal = linea.split("\n")[0]
                        ult_cliente  = linea.split("\n")[1]
                        ret.push(" ")
                        ret.push(linea.split("\n")[0]+"\n")
                        ret.push(linea.split("\n")[1..-1])
                    else
                        if ult_cliente != linea.split("\n")[1]
                            ult_cliente = linea.split("\n")[1]
                            ret.push(" ")
                            ret.push(linea.split("\n")[1..-1])
                        else
                            ret.push(linea.split("\n")[2..-1])
                        end
                    end
                end
            end
        end
        return ret.join("\n")
    end

    def debe_enviar_email(email)
        # Aqui se decide si debe enviar el mail o no, dependiendo si es semanal o mensual
        return true if email['Frecuencia'] == 0
        return true if email['Frecuencia'] == 1 and Date.today.monday? # Lunes
        return true if email['Frecuencia'] == 2 and Date.today.mday == 1 # Primero de mes

        fecha_limite = Date.today - 7.days
        fecha_limite = Date.today - 1.month if email['Frecuencia'] == 2
        enviados = AntSaldosEmailsEnviado.where("email = #{User.sanitize(email.to_s)} and fecha >= #{fecha_limite}")

        return false if enviados.count > 0
        return true
    end

    def get_datos_cliente(sucursal, idcliente)
        # Regresa un string con datos del cliente, como alias y descuentos
        ret = ""
        sql = "SELECT Sucursal, Idcliente, Nombre, Alias, l.NomLista as Lista, Descuento, Credito, Plazo FROM #{@nomDbPdv}clientes as c left join #{@nomDbPub}catlista as l on (l.IdLista=c.TipoPrecio) WHERE sucursal = #{User.sanitize(sucursal)} and idcliente = #{User.sanitize(idcliente)}"
        datos = @dbEsta.connection.select_all(sql)
        if datos.count > 0
            ret = "#{datos[0]['Alias'].to_s.length > 0 ? "Alias: #{datos[0]['Alias']} " : ""}Precio de Lista: #{datos[0]['Lista']} #{datos[0]['Descuento'].to_i > 0 ? "- #{datos[0]['Descuento']}%" : "" }<br>Crédito: #{number_to_currency(datos[0]['Credito'], :locale => :mx, :precision => 2)} - Plazo: #{datos[0]['Plazo']} Días"
        end
        return ret
    end

    def get_historial_cliente(sucursal, idcliente, sucursal_idsucursal)
        # Regresa un arreglo con el historial del cliente
        ret = []
        sql = "SELECT idsucursal, Idcliente, anio as Año, NumVtas as Num_Ventas, Ventas + Devoluciones as Imp_Ventas, round(Descuentos/(Ventas+Devoluciones+Descuentos)*100,2) as Porc_Desc_Real, NumPagos as Num_Pagos, Pagos as Imp_Pagos, SaldoProm as Saldo_Promedio, SaldoMax as Saldo_Maximo, PlazoProm as Plazo_Promedio FROM hCliCred where #{sucursal_idsucursal} = #{User.sanitize(sucursal)} and Idcliente = #{User.sanitize(idcliente)} and anio >= #{(Date.today - 5.years).year} ORDER BY anio;"        #IdSucursal
        ret = @dbEsta.connection.select_all(sql)
        @sucursal_idsucursal = "Sucursal"   if sucursal_idsucursal == "IdSucursal"
        @sucursal_idsucursal = "IdSucursal" if sucursal_idsucursal == "Sucursal"
        return ret
    end

    def modo_local?
        sending_host = request.host.gsub("www.","").gsub(".com","").gsub(".mx","").gsub(".dyndns.org","").gsub(".dyndns.biz","").gsub("intranet","").gsub("comex","").gsub("bajapaint","").gsub("pintacomex","")
        return true if sending_host == "localhost"
        false
    end
end
