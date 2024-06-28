class ReportesVendedoresController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app

  def index
    @filter = 1
    @filter = params[:filter].to_i if params.has_key?(:filter)
    @month = Date.today.strftime("%Y%m")
    @month = params[:month].to_i if params.has_key?(:month)
    #1 todos
    if @filter == 1
      sql = "SELECT Sucursal, IdVendedor, ultFechaProcesada, Dias FROM analisisVentasXMes where Mes = '#{@month}'"
      vendedores = @dbEsta.connection.select_all(sql)

      sql = "SELECT * FROM vendexceps where Del like '%#{@month}%' or Al like '%#{@month}%'"
      vendexceps = @dbPdv.connection.select_all(sql)

      sql = "SELECT * FROM catcomisionistas"
      catcomisionistas = @dbPdv.connection.select_all(sql)

      @sellers = Hash.new

      vendedores.each do |vend|
        @sellers[vend['IdVendedor']] = { sucursal: vend['Sucursal'], id_vendedor: vend['IdVendedor'], ult_fecha: vend['ultFechaProcesada'], dias: vend['Dias'], num_incidencias: "#{ vendexceps.select{|vexe| vexe['IdVendedor'] ==  vend['IdVendedor'] }.size rescue 0 }", nombre: "#{ catcomisionistas.select{|vexe| vexe['IdVendedor'] ==  vend['IdVendedor'] }.first['Nombre'] rescue '' }" }
      end
    elsif @filter == 2
      @vendedores_ventas = []
      sql = "SELECT  * FROM vendexceps where (Del like '%#{@month}%' or Al like '%#{@month}%')"
      vendedores_incidencias = @dbPdv.connection.select_all(sql)

      vendedores_incidencias.each do |vendedor|
        sql = "SELECT  * FROM analisisVentasXDia where Idvendedor = #{vendedor['IdVendedor']} and Fecha between '#{vendedor['Del']}' and '#{vendedor['Al']}' "
        vendedor_incidencias = @dbEsta.connection.select_all(sql)

        if vendedor_incidencias.length > 0
          @vendedores_ventas << { IdVendedor: vendedor['IdVendedor'], Sucursal: vendedor['Sucursal'], Nombre: vendedor['Nombre'], SucOrigen: vendedor['SucOrigen'], Del: vendedor['Del'], Al: vendedor['Al'], Dias: vendedor_incidencias.map{|v| "#{v['Fecha']}"}.join(", ") }
        end
      end
    elsif @filter == 3
      sql = "SELECT  catcomisionistas.Nombre, #{@nomDbEsta}analisisVentasXDia.VentaNeta, #{@nomDbEsta}analisisVentasXDia.Fecha, objvtasvend.Sucursal, objvtasvend.Mes, objvtasvend.Idvendedor, round((objvtasvend.ObjNetas/objvtasvend.DiasHabilesSuc), 2) as objetivoVenta, round(((100.00 / (objvtasvend.ObjNetas/objvtasvend.DiasHabilesSuc)) * #{@nomDbEsta}analisisVentasXDia.VentaNeta), 2) as porcentajeVenta FROM #{@nomDbEsta}analisisVentasXDia left join objvtasvend on #{@nomDbEsta}analisisVentasXDia.IdVendedor = objvtasvend.IdVendedor left join catcomisionistas on catcomisionistas.IdVendedor = objvtasvend.IdVendedor where objvtasvend.Mes = '#{@month}' and objvtasvend.ObjNetas > 0 and #{@nomDbEsta}analisisVentasXDia.Fecha like '%#{@month}%'"
      vendedores = @dbPdv.connection.select_all(sql)
      @vendedores_porcentaje_bajo = []
      vendedores.each do |vendedor|
        @vendedores_porcentaje_bajo << vendedor if vendedor['porcentajeVenta'].to_f < 20.0
      end
    elsif @filter == 4
      sql = "SELECT * FROM vendexceps left join catexceps on vendexceps.Excepcion = catexceps.IdExcepcion where Del >= '#{@month}01' and Al <= '0#{@month}31'"
      excepciones = @dbPdv.connection.select_all(sql)
      @excepciones_duplicados = []
      excepciones.each do |excep|
        sql = "SELECT * FROM vendexceps left join catexceps on vendexceps.Excepcion = catexceps.IdExcepcion where IdVendedor = '#{excep['IdVendedor']}' and  Del >= '#{excep['Del']}' and Al <= '#{excep['Al']}'"
        exceps = @dbPdv.connection.select_all(sql)
        @excepciones_duplicados << exceps if exceps.count > 1
      end
    elsif @filter == 5
      sql = "SELECT #{@nomDbEsta}analisisVentasXMes.IdVendedor, #{@nomDbEsta}analisisVentasXMes.Sucursal, #{@nomDbEsta}analisisVentasXMes.Mes, #{@nomDbEsta}analisisVentasXMes.ultFechaProcesada, #{@nomDbEsta}analisisVentasXMes.Dias, #{@nomDbEsta}ComisVtasVend.DiasPorTranscurrir, objvtassuc.DiasHabilesSuc, catcomisionistas.Nombre
      FROM #{@nomDbEsta}analisisVentasXMes
      left join #{@nomDbEsta}ComisVtasVend on #{@nomDbEsta}analisisVentasXMes.IdVendedor = #{@nomDbEsta}ComisVtasVend.IdVendedor and #{@nomDbEsta}analisisVentasXMes.Mes = #{@nomDbEsta}ComisVtasVend.Mes
      left join objvtassuc on objvtassuc.Sucursal= #{@nomDbEsta}analisisVentasXMes.Sucursal and objvtassuc.Mes= #{@nomDbEsta}analisisVentasXMes.Mes
      left join catcomisionistas on catcomisionistas.IdVendedor = #{@nomDbEsta}analisisVentasXMes.IdVendedor
       where #{@nomDbEsta}analisisVentasXMes.Mes = '#{@month}' group by #{@nomDbEsta}analisisVentasXMes.IdVendedor"
      estas = @dbPdv.connection.select_all(sql)

      sql = "SELECT vendexceps.IdVendedor, catcomisionistas.Sucursal, catcomisionistas.Nombre, vendexceps.SucOrigen, sum(vendexceps.DiasHabiles) as DiasIncidencias
      FROM vendexceps
      left join  catcomisionistas on catcomisionistas.IdVendedor = vendexceps.IdVendedor where vendexceps.Del like '%#{@month}%' group by vendexceps.IdVendedor"
      pdvs = @dbPdv.connection.select_all(sql)

      @vendedores_diferencias = []

      estas.each do |vendedor|
        vende = pdvs.select{|vend| vend['IdVendedor'] == vendedor['IdVendedor'] }.first
        dias_incidencias = vende['DiasIncidencias'] rescue 0
        sell = { :IdVendedor => vendedor['IdVendedor'], :Nombre => vendedor['Nombre'], :Sucursal => vendedor['Sucursal'], :Mes => vendedor['Mes'], :ultFechaProcesada => vendedor['ultFechaProcesada'], :Dias => vendedor['Dias'], :DiasIncidencias => dias_incidencias, :DiasPorTranscurrir => vendedor['DiasPorTranscurrir'], :DiasHabilesSuc => vendedor['DiasHabilesSuc'], :Diferencia => vendedor['DiasHabilesSuc'].to_i - (vendedor['Dias'].to_i + dias_incidencias.to_i + vendedor['DiasPorTranscurrir'].to_i)}
        @vendedores_diferencias << sell
      end
    elsif @filter == 6
    end
  end

  def show
    @month = Date.today.strftime("%Y%m")
    @month = params[:month].to_i if params.has_key?(:month)

    #1

    sql = "SELECT vendexceps.Al, vendexceps.Del, vendexceps.Nombre, vendexceps.Sucursal, vendexceps.DiasHabiles, vendexceps.DiasTranscurridos, vendexceps.SucOrigen, vendexceps.Nombre as Excepcion  FROM vendexceps left join catexceps  on catexceps.IdExcepcion = vendexceps.Excepcion where IdVendedor=#{params[:id]} and (Del like '%#{@month}%' or Al like '%#{@month}%')"
    @vendexcepsvend = @dbPdv.connection.select_all(sql)


    #2
    @vendedores_ventas = []
    sql = "SELECT  * FROM vendexceps where IdVendedor=#{params[:id]} and (Del like '%#{@month}%' or Al like '%#{@month}%')"
    vendedores_incidencias = @dbPdv.connection.select_all(sql)
    vendedores_incidencias.each do |vendedor|
      sql = "SELECT  * FROM analisisVentasXDia where Idvendedor = #{vendedor['IdVendedor']} and Fecha between '#{vendedor['Del']}' and '#{vendedor['Al']}'"
      vendedor_incidencias = @dbEsta.connection.select_all(sql)

      if vendedor_incidencias.length > 0
        @vendedores_ventas << { IdVendedor: vendedor['IdVendedor'], Sucursal: vendedor['Sucursal'], Nombre: vendedor['Nombre'], SucOrigen: vendedor['SucOrigen'], Del: vendedor['Del'], Al: vendedor['Al'], Dias: vendedor_incidencias.map{|v| "#{v['Fecha']}"}.join(", ") }
      end
    end
    #3
    sql = "SELECT  catcomisionistas.Nombre, #{@nomDbEsta}analisisVentasXDia.VentaNeta, #{@nomDbEsta}analisisVentasXDia.Fecha, objvtasvend.Sucursal, objvtasvend.Mes, objvtasvend.Idvendedor, round((objvtasvend.ObjNetas/objvtasvend.DiasHabilesSuc), 2) as objetivoVenta, round(((100.00 / (objvtasvend.ObjNetas/objvtasvend.DiasHabilesSuc)) * #{@nomDbEsta}analisisVentasXDia.VentaNeta), 2) as porcentajeVenta FROM #{@nomDbEsta}analisisVentasXDia left join objvtasvend on #{@nomDbEsta}analisisVentasXDia.IdVendedor = objvtasvend.IdVendedor left join catcomisionistas on catcomisionistas.IdVendedor = objvtasvend.IdVendedor where objvtasvend.Mes = '#{@month}' and objvtasvend.ObjNetas > 0 and objvtasvend.IdVendedor=#{params[:id]} and #{@nomDbEsta}analisisVentasXDia.Fecha like '%#{@month}%'"
    vendedores = @dbPdv.connection.select_all(sql)
    @vendedores_porcentaje_bajo = []
    vendedores.each do |vendedor|
      @vendedores_porcentaje_bajo << vendedor if vendedor['porcentajeVenta'].to_f < 20.0
    end

    #5

    sql = "SELECT #{@nomDbEsta}analisisVentasXMes.IdVendedor, #{@nomDbEsta}analisisVentasXMes.Sucursal, #{@nomDbEsta}analisisVentasXMes.Mes, #{@nomDbEsta}analisisVentasXMes.ultFechaProcesada, #{@nomDbEsta}analisisVentasXMes.Dias, #{@nomDbEsta}ComisVtasVend.DiasPorTranscurrir, objvtassuc.DiasHabilesSuc, catcomisionistas.Nombre
      FROM #{@nomDbEsta}analisisVentasXMes
      left join #{@nomDbEsta}ComisVtasVend on #{@nomDbEsta}analisisVentasXMes.IdVendedor = #{@nomDbEsta}ComisVtasVend.IdVendedor and #{@nomDbEsta}analisisVentasXMes.Mes = #{@nomDbEsta}ComisVtasVend.Mes
      left join objvtassuc on objvtassuc.Sucursal= #{@nomDbEsta}analisisVentasXMes.Sucursal and objvtassuc.Mes= #{@nomDbEsta}analisisVentasXMes.Mes
      left join catcomisionistas on catcomisionistas.IdVendedor = #{@nomDbEsta}analisisVentasXMes.IdVendedor
       where #{@nomDbEsta}analisisVentasXMes.IdVendedor=#{params[:id]} and  #{@nomDbEsta}analisisVentasXMes.Mes = '#{@month}' group by #{@nomDbEsta}analisisVentasXMes.IdVendedor"
      estas = @dbPdv.connection.select_all(sql)

      sql = "SELECT vendexceps.IdVendedor, catcomisionistas.Sucursal, catcomisionistas.Nombre, vendexceps.SucOrigen, sum(vendexceps.DiasHabiles) as DiasIncidencias
      FROM vendexceps
      left join  catcomisionistas on catcomisionistas.IdVendedor = vendexceps.IdVendedor where vendexceps.IdVendedor=#{params[:id]} and vendexceps.Del like '%#{@month}%' group by vendexceps.IdVendedor"
      pdvs = @dbPdv.connection.select_all(sql)

      @vendedores_diferencias = []

      estas.each do |vendedor|
        vende = pdvs.select{|vend| vend['IdVendedor'] == vendedor['IdVendedor'] }.first
        dias_incidencias = vende['DiasIncidencias'] rescue 0
        sell = { :IdVendedor => vendedor['IdVendedor'], :Nombre => vendedor['Nombre'], :Sucursal => vendedor['Sucursal'], :Mes => vendedor['Mes'], :ultFechaProcesada => vendedor['ultFechaProcesada'], :Dias => vendedor['Dias'], :DiasIncidencias => dias_incidencias, :DiasPorTranscurrir => vendedor['DiasPorTranscurrir'], :DiasHabilesSuc => vendedor['DiasHabilesSuc'], :Diferencia => vendedor['DiasHabilesSuc'].to_i - (vendedor['Dias'].to_i + dias_incidencias.to_i + vendedor['DiasPorTranscurrir'].to_i)}
        @vendedores_diferencias << sell
      end

    sql = "SELECT * FROM analisisVentasXMes where Mes = '#{@month}' and IdVendedor=#{params[:id]}"
    @vendedor = @dbEsta.connection.select_all(sql).first
    sql = "SELECT * FROM catcomisionistas where IdVendedor=#{params[:id]}"
    @name_vend = @dbPdv.connection.select_all(sql).first


  end

  def print_pdf_vend
    @month = Date.today.strftime("%Y%m")
    @month = params[:month].to_i if params.has_key?(:month)

    #1

    sql = "SELECT vendexceps.Al, vendexceps.Del, vendexceps.Nombre, vendexceps.Sucursal, vendexceps.DiasHabiles, vendexceps.DiasTranscurridos, vendexceps.SucOrigen, vendexceps.Nombre as Excepcion  FROM vendexceps left join catexceps  on catexceps.IdExcepcion = vendexceps.Excepcion where IdVendedor=#{params[:id]} and (Del like '%#{@month}%' or Al like '%#{@month}%')"
    vendexcepsvend = @dbPdv.connection.select_all(sql)


    #2
    vendedores_ventas = []
    sql = "SELECT  * FROM vendexceps where IdVendedor=#{params[:id]} and (Del like '%#{@month}%' or Al like '%#{@month}%')"
    vendedores_incidencias = @dbPdv.connection.select_all(sql)
    vendedores_incidencias.each do |vendedor|
      sql = "SELECT  * FROM analisisVentasXDia where Idvendedor = #{vendedor['IdVendedor']} and Fecha between '#{vendedor['Del']}' and '#{vendedor['Al']}'"
      vendedor_incidencias = @dbEsta.connection.select_all(sql).first
      if !vendedor_incidencias.nil?
        vendedores_ventas << vendedor
      end
    end
    #3
    sql = "SELECT  catcomisionistas.Nombre, #{@nomDbEsta}analisisVentasXDia.VentaNeta, #{@nomDbEsta}analisisVentasXDia.Fecha, objvtasvend.Sucursal, objvtasvend.Mes, objvtasvend.Idvendedor, round((objvtasvend.ObjNetas/objvtasvend.DiasHabilesSuc), 2) as objetivoVenta, round(((100.00 / (objvtasvend.ObjNetas/objvtasvend.DiasHabilesSuc)) * #{@nomDbEsta}analisisVentasXDia.VentaNeta), 2) as porcentajeVenta FROM #{@nomDbEsta}analisisVentasXDia left join objvtasvend on #{@nomDbEsta}analisisVentasXDia.IdVendedor = objvtasvend.IdVendedor left join catcomisionistas on catcomisionistas.IdVendedor = objvtasvend.IdVendedor where objvtasvend.Mes = '#{@month}' and objvtasvend.ObjNetas > 0 and objvtasvend.IdVendedor=#{params[:id]} and #{@nomDbEsta}analisisVentasXDia.Fecha like '%#{@month}%'"
    vendedores = @dbPdv.connection.select_all(sql)
    vendedores_porcentaje_bajo = []
    vendedores.each do |vendedor|
      vendedores_porcentaje_bajo << vendedor if vendedor['porcentajeVenta'].to_f < 20.0
    end

    #5

    sql = "SELECT #{@nomDbEsta}analisisVentasXMes.IdVendedor, #{@nomDbEsta}analisisVentasXMes.Sucursal, #{@nomDbEsta}analisisVentasXMes.Mes, #{@nomDbEsta}analisisVentasXMes.ultFechaProcesada, #{@nomDbEsta}analisisVentasXMes.Dias, #{@nomDbEsta}ComisVtasVend.DiasPorTranscurrir, objvtassuc.DiasHabilesSuc, catcomisionistas.Nombre
      FROM #{@nomDbEsta}analisisVentasXMes
      left join #{@nomDbEsta}ComisVtasVend on #{@nomDbEsta}analisisVentasXMes.IdVendedor = #{@nomDbEsta}ComisVtasVend.IdVendedor and #{@nomDbEsta}analisisVentasXMes.Mes = #{@nomDbEsta}ComisVtasVend.Mes
      left join objvtassuc on objvtassuc.Sucursal= #{@nomDbEsta}analisisVentasXMes.Sucursal and objvtassuc.Mes= #{@nomDbEsta}analisisVentasXMes.Mes
      left join catcomisionistas on catcomisionistas.IdVendedor = #{@nomDbEsta}analisisVentasXMes.IdVendedor
       where #{@nomDbEsta}analisisVentasXMes.IdVendedor=#{params[:id]} and  #{@nomDbEsta}analisisVentasXMes.Mes = '#{@month}' group by #{@nomDbEsta}analisisVentasXMes.IdVendedor"
      estas = @dbPdv.connection.select_all(sql)

      sql = "SELECT vendexceps.IdVendedor, catcomisionistas.Sucursal, catcomisionistas.Nombre, vendexceps.SucOrigen, sum(vendexceps.DiasHabiles) as DiasIncidencias
      FROM vendexceps
      left join  catcomisionistas on catcomisionistas.IdVendedor = vendexceps.IdVendedor where vendexceps.IdVendedor=#{params[:id]} and vendexceps.Del like '%#{@month}%' group by vendexceps.IdVendedor"
      pdvs = @dbPdv.connection.select_all(sql)

      vendedores_diferencias = []

      estas.each do |vendedor|
        vende = pdvs.select{|vend| vend['IdVendedor'] == vendedor['IdVendedor'] }.first
        dias_incidencias = vende['DiasIncidencias'] rescue 0
        sell = { :IdVendedor => vendedor['IdVendedor'], :Nombre => vendedor['Nombre'], :Sucursal => vendedor['Sucursal'], :Mes => vendedor['Mes'], :ultFechaProcesada => vendedor['ultFechaProcesada'], :Dias => vendedor['Dias'], :DiasIncidencias => dias_incidencias, :DiasPorTranscurrir => vendedor['DiasPorTranscurrir'], :DiasHabilesSuc => vendedor['DiasHabilesSuc'], :Diferencia => vendedor['DiasHabilesSuc'].to_i - (vendedor['Dias'].to_i + dias_incidencias.to_i + vendedor['DiasPorTranscurrir'].to_i)}
        vendedores_diferencias << sell
      end

    sql = "SELECT * FROM analisisVentasXMes where Mes = '#{@month}' and IdVendedor=#{params[:id]}"
    @vendedor = @dbEsta.connection.select_all(sql).first
    sql = "SELECT * FROM catcomisionistas where IdVendedor=#{params[:id]}"
    @name_vend = @dbPdv.connection.select_all(sql).first

    respond_to do |format|
      format.html
      format.pdf do
        # Se deben obtener los detalles de los productos para el PDF
        pdf   = ReportesVendedoresPdf.new(@vendedor, @name_vend, vendexcepsvend, vendedores_ventas, vendedores_porcentaje_bajo, vendedores_diferencias)
        send_data pdf.render, filename: "reporte_.pdf", type: "application/pdf", disposition: "inline"
      end
    end

  end

  def exportar_excel
    @month = Date.today.strftime("%Y%m")
    @month = params[:month].to_i if params.has_key?(:month)

    #1
    sql = "SELECT Sucursal, IdVendedor, ultFechaProcesada, Dias FROM analisisVentasXMes where Mes = '#{@month}'"
    vendedores = @dbEsta.connection.select_all(sql)

    sql = "SELECT * FROM vendexceps where Del like '%#{@month}%' or Al like '%#{@month}%'"
    vendexceps = @dbPdv.connection.select_all(sql)

    sql = "SELECT * FROM catcomisionistas"
    catcomisionistas = @dbPdv.connection.select_all(sql)

    @sellers = Hash.new

    vendedores.each do |vend|
      @sellers[vend['IdVendedor']] = { sucursal: vend['Sucursal'], id_vendedor: vend['IdVendedor'], ult_fecha: vend['ultFechaProcesada'], dias: vend['Dias'], num_incidencias: "#{ vendexceps.select{|vexe| vexe['IdVendedor'] ==  vend['IdVendedor'] }.size rescue 0 }", nombre: "#{ catcomisionistas.select{|vexe| vexe['IdVendedor'] ==  vend['IdVendedor'] }.first['Nombre'] rescue '' }" }
    end
    #2
    @vendedores_ventas = []
    sql = "SELECT  * FROM vendexceps where (Del like '%#{@month}%' or Al like '%#{@month}%')"
    vendedores_incidencias = @dbPdv.connection.select_all(sql)
    vendedores_incidencias.each do |vendedor|
      sql = "SELECT  * FROM analisisVentasXDia where Idvendedor = #{vendedor['IdVendedor']} and Fecha between '#{vendedor['Del']}' and '#{vendedor['Al']}' "
      vendedor_incidencias = @dbEsta.connection.select_all(sql).first
      if !vendedor_incidencias.nil?
        @vendedores_ventas << vendedor
      end
    end
    #3
    sql = "SELECT  catcomisionistas.Nombre, #{@nomDbEsta}analisisVentasXDia.VentaNeta, #{@nomDbEsta}analisisVentasXDia.Fecha, objvtasvend.Sucursal, objvtasvend.Mes, objvtasvend.Idvendedor, round((objvtasvend.ObjNetas/objvtasvend.DiasHabilesSuc), 2) as objetivoVenta, round(((100.00 / (objvtasvend.ObjNetas/objvtasvend.DiasHabilesSuc)) * #{@nomDbEsta}analisisVentasXDia.VentaNeta), 2) as porcentajeVenta FROM #{@nomDbEsta}analisisVentasXDia left join objvtasvend on #{@nomDbEsta}analisisVentasXDia.IdVendedor = objvtasvend.IdVendedor left join catcomisionistas on catcomisionistas.IdVendedor = objvtasvend.IdVendedor where objvtasvend.Mes = '#{@month}' and objvtasvend.ObjNetas > 0 and #{@nomDbEsta}analisisVentasXDia.Fecha like '%#{@month}%'"
    vendedores = @dbPdv.connection.select_all(sql)
    @vendedores_porcentaje_bajo = []
    vendedores.each do |vendedor|
      @vendedores_porcentaje_bajo << vendedor if vendedor['porcentajeVenta'].to_f < 20.0
    end
    #4
    sql = "SELECT * FROM vendexceps left join catexceps on vendexceps.Excepcion = catexceps.IdExcepcion where Del >= '#{@month}01' and Al <= '0#{@month}31'"
    excepciones = @dbPdv.connection.select_all(sql)
    @excepciones_duplicados = []
    excepciones.each do |excep|
      sql = "SELECT * FROM vendexceps left join catexceps on vendexceps.Excepcion = catexceps.IdExcepcion where IdVendedor = '#{excep['IdVendedor']}' and  Del >= '#{excep['Del']}' and Al <= '#{excep['Al']}'"
      exceps = @dbPdv.connection.select_all(sql)
      @excepciones_duplicados << exceps if exceps.count > 1
    end

    #5
    sql = "SELECT DISTINCT(objvtasvend.IdVendedor), objvtasvend.Sucursal, vendexceps.Nombre, objvtasvend.Mes, #{@nomDbEsta}analisisVentasXMes.ultFechaProcesada, #{@nomDbEsta}analisisVentasXMes.Dias, vendexceps.DiasHabiles as DiasIncidencias, #{@nomDbEsta}ComisVtasVend.DiasPorTranscurrir, objvtasvend.DiasHabilesSuc,(objvtasvend.DiasHabilesSuc - (#{@nomDbEsta}analisisVentasXMes.Dias + vendexceps.DiasHabiles + #{@nomDbEsta}ComisVtasVend.DiasPorTranscurrir)) as Diferencia FROM #{@nomDbEsta}analisisVentasXMes left join objvtasvend on #{@nomDbEsta}analisisVentasXMes.IdVendedor =  objvtasvend.IdVendedor left join vendexceps on  vendexceps.IdVendedor = #{@nomDbEsta}analisisVentasXMes.IdVendedor  left join #{@nomDbEsta}ComisVtasVend on #{@nomDbEsta}ComisVtasVend.IdVendedor = #{@nomDbEsta}analisisVentasXMes.IdVendedor and #{@nomDbEsta}ComisVtasVend.Mes = #{@nomDbEsta}analisisVentasXMes.Mes where  #{@nomDbEsta}analisisVentasXMes.Mes = '#{@month}' and objvtasvend.Mes = '#{@month}' != 0 and  vendexceps.Del like '%#{@month}%' and pdv.vendexceps.Al like '%#{@month}%' group by vendexceps.IdVendedor"
    diferencias = @dbPdv.connection.select_all(sql)
    @vendedores_diferencias = []
    diferencias.each do |vendedor|
      @vendedores_diferencias << vendedor if vendedor['Diferencia'] != 0
    end

    respond_to do |format|
      format.html
      format.xlsx
    end
  end

end
