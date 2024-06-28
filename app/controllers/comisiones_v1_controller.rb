class ComisionesV1Controller < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app

	include ActionView::Helpers::NumberHelper

  def index
    # si el numero de empleado[0..-2] es != de idVendedor uso num_empleado
    permiso = Permiso.where("idUsuario = #{current_user.id}").first
    num_empleado = current_user[:numEmpleado].to_s[0..-2]
    num_empleado = current_user[:numEmpleado].to_s if current_user[:numEmpleado].to_s[0..-2] != permiso[:p4].to_s
    # num_empleado = current_user[:numEmpleado].to_s[0..-2] if permiso[:permiso] == "Supervisor" || permiso[:permiso] == "Regional"
    num_empleado = params[:id_vendedor].to_s[0..-1] if params.has_key?("id_vendedor")
    sql = "select Categoria from catcomisionistas where NumEmpleado = #{User.sanitize(num_empleado)}"
    @categoria = @dbPdv.connection.select_all(sql).first['Categoria'] rescue ''
    @current_vendedor_name = current_user[:name]
    @level = get_current_level_app
    if params.has_key?("id_vendedor")
      sql = "select * from catcomisionistas where IdVendedor=#{User.sanitize(params[:id_vendedor])}"
      vendedor_name = @dbPdv.connection.select_all(sql).first
      @current_vendedor_name = vendedor_name['Nombre']
    end
    @sql = ""
    @num_empleado = params
    if @categoria == 5
      sql = "select Mes, Sucursal, ultFechaProcesada, DiasOperados, (IdVendedor) as IdEmpleado, 'Vendedor' as Tipo from ComisVtasVend WHERE IdVendedor = #{User.sanitize(num_empleado)} order by mes  desc"
      @meses_vendedor = @dbEsta.connection.select_all(sql)
    elsif !params.has_key?("id_vendedor") and @level <= 5
      sql = "select DISTINCT a.IdVendedor, b.Nombre from #{@nomDbEsta}ComisVtasVend as a inner join #{@nomDbPdv}catcomisionistas as b on a.IdVendedor = b.IdVendedor where a.IdVendedor > 0 order by a.IdVendedor"
      catcomisionistass = @dbEsta.connection.select_all(sql)
      @cat_catcomisionistass = []
      catcomisionistass.map { |vendedor| @cat_catcomisionistass << ["#{vendedor['IdVendedor']}-#{vendedor['Nombre']}", vendedor['IdVendedor']] }
      catcomisionistass = @dbEsta.connection.select_all(sql)
      @cat_sucursales = []
      catcomisionistass.map { |vendedor| @cat_sucursales << ["#{vendedor['IdEncargado']}-#{vendedor['Nombre']}", vendedor['IdEncargado']] }
      catcomisionistass = @dbEsta.connection.select_all(sql)
      @cat_subzona = []
      catcomisionistass.map { |vendedor| @cat_subzona << ["#{vendedor['IdEmpleado']}-#{vendedor['Nombre']}", vendedor['IdEmpleado']] }
    else
      sql = "(select Mes, Sucursal, ultFechaProcesada, DiasOperados, (IdVendedor) as IdEmpleado, 'Vendedor' as Tipo from ComisVtasVend WHERE IdVendedor = #{User.sanitize(num_empleado)}) union (select Mes, Sucursal, ultFechaProcesada, DiasOperados, (IdEncargado) as IdEmpleado, 'Encargado' as Tipo from ComisVtasSuc where IdEncargado = #{User.sanitize(num_empleado)}) union (select Mes, Zona as Sucursal, UltFechaProcesada as ultFechaProcesada, DiasOperados, (IdEmpleado) as IdEmpleado, 'Regional' as Tipo from ComisVtasSubZona where IdEmpleado = #{User.sanitize(num_empleado)}) order by mes desc"
      @meses_vendedor = @dbEsta.connection.select_all(sql)
      @sql = sql
    end
  end

  def search_empleado
    redirect_to :controller => "comisiones", :action => "index", :id_vendedor => "#{params['id_vendedor']}"
  end

  def show_report
    @categoria = params[:categoria]
    tipo =  params[:tipo]
    @t_permiso = tipo
    permiso = Permiso.where("idUsuario = #{current_user.id}").first
    num_empleado = current_user[:numEmpleado].to_s[0..-2]
    num_empleado = current_user[:numEmpleado].to_s if current_user[:numEmpleado].to_s[0..-2] != permiso[:p4].to_s
    # num_empleado = current_user[:numEmpleado].to_s[0..-2] if permiso[:permiso] == "Supervisor" || permiso[:permiso] == "Regional"
    num_empleado = params[:id_vendedor].to_s[0..-1] if params.has_key?("id_vendedor")
    @num_empleado = num_empleado
    @level = get_current_level_app
    if params.has_key?("id_vendedor")
      sql = "select * from catcomisionistas where IdVendedor=#{User.sanitize(params[:id_vendedor])}"
      vendedor_name = @dbPdv.connection.select_all(sql).first
      @current_vendedor_name = vendedor_name['Nombre']
    end
    @suc = false
    @anio = params[:mes][0..3]
    mes = params[:mes][4..-1]
    @params_mes = params[:mes]
    month_name = {"01" => "Enero", "02" => "Febrero", "03" => "Marzo", "04" => "Abril", "05" => "Mayo", "06" => "Junio", "07" => "Julio", "08" => "Agosto", "09" => "Septiembre", "10" => "Octubre", "11" => "Noviembre", "12" => "Diciembre"}
    @mes_name = month_name[mes]
    if @categoria == '5' || tipo == "Vendedor"
      sql = "select * from ComisVtasVend where IdVendedor = #{User.sanitize(num_empleado)} and mes = #{User.sanitize(params[:mes])} and Sucursal = #{User.sanitize(params[:sucursal])} "
      @comision_mes = @dbEsta.connection.select_all(sql).first
      sql = "select * from sucursal where Num_suc = #{User.sanitize(@comision_mes['Sucursal'])}"
      @nombre_suc = @dbComun.connection.select_all(sql).first
      sql = "select sum(DiasTranscurridos) from vendexceps where IdVendedor = #{User.sanitize(num_empleado)} and Excepcion = 1 and Sucursal= #{User.sanitize(params[:sucursal])} and (Del like '%#{params[:mes]}%' or Al like '%#{params[:mes]}%')"
      @dias_transcurridos = @dbPdv.connection.select_all(sql).first
    elsif tipo == "VendedorV2"
      sql = "select *, (FechaUltimaVtaSuc) as ultFechaProcesada, diasVenta as DiasOperados, diasFaltantes as DiasPorTranscurrir from ComisXVtasAsesor where Idvendedor = #{User.sanitize(num_empleado)} and mes = #{User.sanitize(params[:mes])} and Sucursal = #{User.sanitize(params[:sucursal])} "
      @comision_mes = @dbEsta.connection.select_all(sql).first
      sql = "select * from sucursal where Num_suc = #{User.sanitize(@comision_mes['Sucursal'])}"
      @nombre_suc = @dbComun.connection.select_all(sql).first
      sql = "select sum(DiasTranscurridos) from vendexceps where IdVendedor = #{User.sanitize(num_empleado)} and Excepcion = 1 and Sucursal= #{User.sanitize(params[:sucursal])} and (Del like '%#{params[:mes]}%' or Al like '%#{params[:mes]}%')"
      @dias_transcurridos = @dbPdv.connection.select_all(sql).first
    elsif tipo == "Encargado"
      sql = "select * from ComisVtasSuc where IdEncargado = #{User.sanitize(num_empleado)} and mes = #{User.sanitize(params[:mes])}"
      @comision_mes = @dbEsta.connection.select_all(sql).first
      sql = "select * from objvtassuc where sucursal = #{User.sanitize(params[:sucursal])} and mes = #{User.sanitize(params[:mes])}"
      @objetivos_mes = @dbPdv.connection.select_all(sql).first
      sql = "select * from sucursal where Num_suc = #{User.sanitize(@comision_mes['Sucursal'])}"
      @nombre_suc = @dbComun.connection.select_all(sql).first
      @suc = true
      if @objetivos_mes.nil?
        redirect_to root_path, notice: "No hay objetivos de mes"
      end
    elsif tipo == "EncargadoV2"
      sql = "select *, (FechaUltimaVtaSuc) as ultFechaProcesada, diasVenta as DiasOperados, diasFaltantes as DiasPorTranscurrir from ComisXVtasEncargado where Idvendedor = #{User.sanitize(num_empleado)} and mes = #{User.sanitize(params[:mes])}"
      @comision_mes = @dbEsta.connection.select_all(sql).first
      sql = "select * from objvtassuc where sucursal = #{User.sanitize(params[:sucursal])} and mes = #{User.sanitize(params[:mes])}"
      @objetivos_mes = @dbPdv.connection.select_all(sql).first
      sql = "select * from sucursal where Num_suc = #{User.sanitize(@comision_mes['Sucursal'])}"
      @nombre_suc = @dbComun.connection.select_all(sql).first
      @suc = true
      if @objetivos_mes.nil?
        redirect_to root_path, notice: "No hay objetivos de mes"
      end
    elsif tipo == "RegionalV2"
      @suc = true
      sql = "select *, (FechaUltimaVta) as UltFechaProcesada, diasVenta as DiasOperados, diasFaltantes as DiasPorTranscurrir from ComisXVtasRegional where Idvendedor = #{num_empleado} and mes = #{params[:mes]}"
      @comision_mes = @dbEsta.connection.select_all(sql).first
    elsif tipo == "Regional" || tipo == "Supervisor"
      @suc = true
      sql = "select * from ComisVtasSubZona where IdEmpleado = #{num_empleado} and mes = #{params[:mes]}"
      @comision_mes = @dbEsta.connection.select_all(sql).first
    else
      redirect_to root_path
    end
    if tipo == "Regional" || tipo == "Supervisor"
      @comision_total = @comision_mes['ComisNetas'].to_f + @comision_mes['ComisAxT'].to_f + @comision_mes['ComisTP'].to_f + @comision_mes['ComisNT'].to_f + @comision_mes['ComisSucNetas'].to_f + @comision_mes['ComisNetasExOp'].to_f + @comision_mes['ComisRentabilidad'].to_f + @comision_mes['ComisCxC'].to_f
    elsif tipo == "Vendedor"
      @comision_total = @comision_mes['ComisNetas'].to_f + @comision_mes['ComisAxT'].to_f + @comision_mes['ComisTP'].to_f + @comision_mes['ComisNT'].to_f + @comision_mes['ComisSucNetas'].to_f + @comision_mes['ComisNetasExOp'].to_f + @comision_mes['ComisCubreEncargado'].to_f
    else
      @comision_total = @comision_mes['ComisNetas'].to_f + @comision_mes['ComisAxT'].to_f + @comision_mes['ComisTP'].to_f + @comision_mes['ComisNT'].to_f + @comision_mes['ComisSucNetas'].to_f + @comision_mes['ComisNetasExOp'].to_f
    end
    @tipo = ""
    if tipo == "Encargado" || @categoria == '5' then @tipo = 2 elsif tipo == "Vendedor" then @tipo = 1 elsif tipo == "EncargadoV2" then @tipo = 12 elsif tipo == "VendedorV2" then @tipo = 11 elsif tipo == "Regional" || tipo == "Supervisor" then @tipo = 3 elsif tipo == "RegionalV2" then @tipo = 13 else @tipo = "" end
  end

  def print_pdf
    tipo = params[:id].to_s.split("-")[4]
    tipo_vista = params[:id].to_s.split("-")[5].to_i
    categoria = params[:id].to_s.split("-")[-1].to_i
    num_empleado = params[:id].to_s.split("-")[0].to_i
    #Genera el PDF de las comisiones
    permiso = Permiso.where("idUsuario = #{current_user.id}").first
    sql = "select * from catcomisionistas where IdVendedor=#{User.sanitize(num_empleado)}"
    vendedor_name = @dbPdv.connection.select_all(sql).first
    @current_vendedor_name = vendedor_name['Nombre']
    # num_empleado = current_user[:numEmpleado].to_s[0..-2] if permiso[:permiso] == "Supervisor" || permiso[:permiso] == "Regional"

    array_params = params["id"].split('-')
    mes = array_params[1]
    sucursal = array_params[2]
    id_vendedor = array_params[3]
    objetivos = ""
    if tipo == "Vendedor"
      sql = "select * from ComisVtasVend where Sucursal = #{User.sanitize(sucursal)} and IdVendedor = #{User.sanitize(num_empleado)} and mes = #{User.sanitize(mes)}"
      vendedor = @dbEsta.connection.select_all(sql).first

      sql = "select * from sucursal where Num_suc = #{User.sanitize(sucursal)}"
      nombre_suc = @dbComun.connection.select_all(sql).first

      sql = "select DiasTranscurridos from vendexceps where IdVendedor = #{User.sanitize(num_empleado)} and Del like '%#{params[:mes]}%'"
      dias_transcurridos = @dbPdv.connection.select_all(sql).first
      tipo = 1
    elsif tipo == "Encargado"
      sql = "select * from ComisVtasSuc where mes = #{User.sanitize(mes)} and IdEncargado = #{User.sanitize(num_empleado)}"
      vendedor = @dbEsta.connection.select_all(sql).first
      sql = "select * from objvtassuc where IdEncargado = #{User.sanitize(num_empleado)} and mes = #{User.sanitize(mes)}"
      objetivos = @dbPdv.connection.select_all(sql).first

      sql = "select * from sucursal where Num_suc = #{User.sanitize(sucursal)}"
      nombre_suc = @dbComun.connection.select_all(sql).first
      tipo = 2
    elsif tipo == "Regional" || tipo == "Supervisor"
      sql = "select * from ComisVtasSubZona where IdEmpleado = #{num_empleado} and mes = #{User.sanitize(mes)}"
      vendedor = @dbEsta.connection.select_all(sql).first
      objetivos = 0
      nombre_suc = ""
      tipo = 3
    end

    month_name = {"01" => "Enero", "02" => "Febrero", "03" => "Marzo", "04" => "Abril", "05" => "Mayo", "06" => "Junio", "07" => "Julio", "08" => "Agosto", "09" => "Septiembre", "10" => "Octubre", "11" => "Noviembre", "12" => "Diciembre"}

    mes = month_name[vendedor['Mes'][-2..-1]]

    respond_to do |format|
      format.html
      format.pdf do
        # Se deben obtener los detalles de los productos para el PDF
        pdf = ComisionesV1Pdf.new(vendedor, @current_vendedor_name, mes, tipo_vista, nombre_suc, objetivos, dias_transcurridos, categoria)
        send_data pdf.render, filename: "comisiones_#{@current_vendedor_name}.pdf", type: "application/pdf", disposition: "inline"
      end
    end
  end
end
