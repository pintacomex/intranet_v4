class EstadisticasVentasController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app

  include ActionView::Helpers::NumberHelper

  def index
    year_ago = DateTime.now.prev_month(11).strftime('%Y%m')
     permiso = Permiso.where("idUsuario = #{current_user.id}").first
    if permiso.nil?
      redirect_to root_path, notice: "No existe permiso para ver tus datos, comunícate con soporte"
    end

    if get_current_level_app == 60
      num_empleado = current_user[:numEmpleado].to_s[0..-2]
      num_empleado = current_user[:numEmpleado].to_s if current_user[:numEmpleado].to_s[0..-2] != permiso[:p4].to_s
      redirect_to :controller => "estadisticas_ventas", :action => "show_vendedor", :id => "#{num_empleado}", :anio => year_ago
    elsif permiso[:p3].to_i > 0
      redirect_to :controller => "estadisticas_ventas", :action => "sucursal", :id => "#{permiso['p3']}", :anio => year_ago
    elsif permiso[:p2].to_i > 0
      redirect_to :controller => "estadisticas_ventas", :action => "intermedio", :id => "#{permiso['p2']}", :anio => year_ago
    elsif permiso[:p1].to_i > 0
      redirect_to :controller => "estadisticas_ventas", :action => "superior", :id => 10, :anio => year_ago, :nombre_superior => "Sucursales Retail"
    else
      redirect_to root_path, notice: "No existe permiso en tu usuario para visualizar datos, comunícate con soporte"
    end
  end

  #Genera datos del grupo superior
  def superior

    current_month = DateTime.now.strftime('%Y%m')

    #genera el combo de  años
    @anios = []
    year_18 = DateTime.new(2018,1,1)
    (2018.. DateTime.now.to_s[0..3].to_i).each do |y|
      @anios << y
    end

    #se verifica la fecha apartir para mostrar datos
    @anio_selected =  params[:anio]
    @anio_selected =  "#{params[:anio]}01" if @anio_selected.length == 4
    current_month =  "#{params[:anio][0..3]}12"  if @anio_selected[4..5] == "01"
    current_month =  "#{params[:anio][0..3]}#{DateTime.now.strftime('%m')}"  if @anio_selected[-2..-1] == "01" and params[:anio][0..3] == DateTime.now.strftime('%Y')
    limit = 12
    limit = DateTime.now.strftime('%m').to_i if @anio_selected[0..3] == DateTime.now.strftime('%Y')
    #Genera los combos de niveles
    @nombre_superior = "Superior"
    sql = "SELECT IdAgrupa,Nombre FROM agrupa order by NumOrd"
    @superior = @dbComun.connection.select_all(sql)
    @nombre_superior = params["nombre_superior"]
    @nombre_intermedio = "Intermedio"
    @id_superior = params['id']
    sql = "select FechaUltimaVtaSuc as ultFechaProcesada from ComisXVtasAsesor order by FechaUltimaVtaSuc desc limit 1"
    @ult_procesada = @dbEsta.connection.select_all(sql).first
    if @id_superior
      sql = "SELECT IdSubAgrupa,Nombre FROM subagrupa where IdAgrupa = #{params['id'].to_i} order by IdSubAgrupa "
      @subagrupa = @dbComun.connection.select_all(sql)
    end
    @array_superior = []
    @subagrupa.each { |grupo| @array_superior << grupo['Nombre'].to_s }
    sucursales = []
    sql = "SELECT IdSucursal,Nombre FROM agrupasuc where IdAgrupa = #{@id_superior} order by NumOrd"
    grupo_zonas = @dbComun.connection.select_all(sql)
    grupo_zonas.each do |suc|
      sucursales << suc['IdSucursal']
    end

    #genera el opa del mes en curso
    sucursales = sucursales.join(",")
    sql = "select sum(TendenciaNetas) as NetasProyectadas, avg(round(coalesce(tendencianetas / ObjNetas, 0) * 100, 2)) as OpaNetas, avg(round(coalesce(TendenciaTP / ObjTP, 0) * 100, 2)) as OpaTP, avg(round(coalesce(TendenciaNT / ObjNT, 0) * 100, 2)) as OpaNT, avg(round(coalesce(TendenciaAxT / ObjAxT, 0) * 100, 2)) as OpaAxT from ComisXVtasSuc where mes = '#{current_month}' and sucursal in(#{sucursales}) order by mes asc"
    @opa_current_mes = @dbEsta.connection.select_all(sql).first

    #genera los numeros de cada mes
    setted_date = DateTime.new(@anio_selected[0..3].to_i , @anio_selected[4..5].to_i, 1)
    months = []
    (0..limit-1).each { |i|  months << "#{setted_date.next_month(i).to_s[0..3]}#{setted_date.next_month(i).to_s[5..6]}" }

    data_meses = {}
    obj_meses = {}
    sql = "select mes, sum(VentaNetaSucursal) as netas, sum(VentaNetaSucursal)/sum(TicketsSucursal) as tp, sum(TicketsSucursal) as nt, round(avg(AxTSucursal),2) as axt from ComisXVtasSuc where (mes between '#{@anio_selected}' and '#{current_month}') and sucursal in(#{sucursales}) group by mes order by mes asc limit #{limit}"
    data = @dbEsta.connection.select_all(sql)

    #genera los objetivos de cada mes
    sql = "select Mes, sum(ObjNetas) as objNetas, sum(ObjNetas)/sum(ObjNT)  as objTP, sum(ObjNT) as objNT, round(avg(ObjAxt),2) as objAxt from ComisXVtasSuc where (Mes between '#{@anio_selected}' and '#{current_month}') and sucursal in(#{sucursales}) group by mes order by mes asc limit #{limit}"
    meses = @dbEsta.connection.select_all(sql)
    #genera hash de los datos y objetivos de los meses
    months.each_with_index do |m, i|

      d = data.select{|a| a['mes'] == m }[0]
      o = meses.select{|a| a['Mes'] == m }[0]
      d_netas = d['netas'] rescue 0.0
      d_tp    = d['tp'] rescue 0.0
      d_nt    = d['nt'] rescue 0.0
      d_axt   = d['axt'] rescue 0.0
      o_netas = o['objNetas'] rescue 0.0
      o_tp    = o['objTP'] rescue 0.0
      o_nt    = o['objNT'] rescue 0.0
      o_axt   = o['objAxt'] rescue 0.0

      data_meses[m] = Hash["netas", d_netas, "tp", d_tp, "nt", d_nt, "axt", d_axt]
      obj_meses[m] = Hash["objNetas", o_netas, "objTP", o_tp, "objNT", o_nt, "objAxt", o_axt]
    end

    #genera los datos por zona
    @table_zona_netas = []
    @table_zona_tp = []
    @table_zona_nt = []
    @table_zona_axt = []
    @subagrupa.each do |num_zona|
      sql = "SELECT IdSucursal,Nombre FROM agrupasuc where IdAgrupa = #{@id_superior} and IdSubAgrupa = #{num_zona['IdSubAgrupa']} order by NumOrd"
      grupo_zonas = @dbComun.connection.select_all(sql)
      sucursales = []
      grupo_zonas.each do |suc|
        sucursales << suc['IdSucursal']
      end
      sucursales = sucursales.join(",")

      sql = "select mes, avg(round(coalesce(tendencianetas / ObjNetas, 0) * 100, 2)) as OpaNetas, sum(VentaNetaSucursal) as netas, sum(VentaNetaSucursal)/sum(TicketsSucursal) as tp, avg(round(coalesce(TendenciaTP / ObjTP, 0) * 100, 2)) as OpaTP, sum(TicketsSucursal) as nt, avg(round(coalesce(TendenciaNT / ObjNT, 0) * 100, 2)) as OpaNT, round(avg(AxTSucursal),2) as axt, avg(round(coalesce(TendenciaAxT / ObjAxT, 0) * 100, 2)) as OpaAxT from ComisXVtasSuc where (mes between '#{@anio_selected}' and '#{current_month}') and sucursal in(#{sucursales}) group by mes order by mes asc limit #{limit}"
      venta_zona = @dbEsta.connection.select_all(sql)

      sql = "select Mes, sum(ObjNetas) as objNetas, sum(ObjNetas)/sum(ObjNT)  as objTP, sum(ObjNT) as objNT, round(avg(ObjAxt),2) as objAxt from ComisXVtasSuc where (Mes between '#{@anio_selected}' and '#{current_month}') and sucursal in(#{sucursales}) group by mes order by mes asc limit #{limit}"
      meses_zona = @dbEsta.connection.select_all(sql)

      zona_data_meses = {}
      contado = 0
      months.each_with_index do |m, i|
        if i == months.size - 1
          d = venta_zona.select{|a| a['mes'] == m }[0] rescue 0.0
          e = meses_zona.select{|a| a['Mes'] == m }[0] rescue 0.0
          sql = "select sum(TendenciaNetas) as NetasProyectadas, avg(round(coalesce(tendencianetas / ObjNetas, 0) * 100, 2)) as OpaNetas, avg(round(coalesce(TendenciaTP / ObjTP, 0) * 100, 2)) as OpaTP, avg(round(coalesce(TendenciaNT / ObjNT, 0) * 100, 2)) as OpaNT, avg(round(coalesce(TendenciaAxT / ObjAxT, 0) * 100, 2)) as OpaAxT from ComisXVtasSuc where mes = '#{Date.today.strftime("%Y%m")}' and sucursal in(#{sucursales}) order by mes asc"
          opa_current_mes = @dbEsta.connection.select_all(sql).first
          porcentaje = ((100.0 / e['objNetas']) * opa_current_mes['NetasProyectadas']) rescue 0.0
          d_opanetas = porcentaje rescue 0.0
        else
          d = venta_zona.select{|a| a['mes'] == m }[0] rescue 0.0
          e = meses_zona.select{|a| a['Mes'] == m }[0] rescue 0.0
          d_opanetas = (100.0 * (d['netas']/e['objNetas'])) rescue 0.0
        end

        d_netas = d['netas'] rescue 0.0
        d_tp    = d['OpaTP'] rescue 0.0
        d_nt    = d['OpaNT'] rescue 0.0
        d_axt   = d['OpaAxT'] rescue 0.0

        zona_data_meses[m] = Hash["OpaNetas", d_opanetas, "netas", d_netas, "OpaTP", d_tp, "OpaNT", d_nt, "OpaAxT", d_axt]
      end

      array_zona_netas  = []
      array_zona_tp     = []
      array_zona_nt     = []
      array_zona_axt    = []

      zona_data_meses.each_with_index do |zona, index|
        array_zona_netas  << zona[1]['OpaNetas'].round(2) rescue 0.0
        array_zona_tp     << zona[1]['OpaTP'].round(2) rescue 0.0
        array_zona_nt     << zona[1]['OpaNT'].round(2) rescue 0.0
        array_zona_axt    << zona[1]['OpaAxT'].round(2) rescue 0.0
      end

      @table_zona_netas << array_zona_netas
      @table_zona_tp    << array_zona_tp
      @table_zona_nt    << array_zona_nt
      @table_zona_axt   << array_zona_axt
    end

    #genera los arreglegos en la vista
    ventas(data_meses, @opa_current_mes, months)
    obj_ventas(obj_meses, @opa_current_mes, months)
  end

  def intermedio
    current_month = DateTime.now.strftime('%Y%m')
    #genera el combo de  años
    @anios = []
    year_18 = DateTime.new(2018,1,1)
    (2018.. DateTime.now.to_s[0..3].to_i).each do |y|
      @anios << y
    end

    @permiso = Permiso.where("idUsuario = #{current_user.id}").first
    #Genera datos del grupo Intermedio o sucursales del grupo intermedio seleccionado
    # if get_current_level_app <= 30
      @id_vendedor = current_user[:numEmpleado].to_s[0..-2]
      @id_intermedio = params['id']
      @nombre_sucursal = "Selecciona Sucursal"
       #señala la fecha de cual se van a calcular los datos
      @anio_selected = params[:anio]
      @anio_selected =  "#{params[:anio]}01" if @anio_selected.length == 4

        #Si eres > contralor
      if @permiso[:p1].to_i > 0 && @permiso[:p2].to_i == 0 && @permiso[:p3].to_i == 0

        #arma los combos de la zonas, sucursales, etc
        sql = "SELECT IdAgrupa,Nombre FROM agrupa order by NumOrd"
        @superior = @dbComun.connection.select_all(sql)
        @id_intermedio = params['id']
        @id_superior = params['id_superior']
        @nombre_superior = params["nombre_superior"]
        @nombre_intermedio = params["nombre_intermedio"]
        @nombre_sucursal = "Sucursal"

        if @id_intermedio
          sql = "SELECT IdSubAgrupa,Nombre FROM subagrupa where IdAgrupa = #{@id_superior}"
          @subagrupa = @dbComun.connection.select_all(sql)
        end

        sql = "SELECT IdSucursal,Nombre FROM agrupasuc where IdAgrupa = #{@id_superior} and IdSubAgrupa = #{@id_intermedio} order by NumOrd"
        @grupo_sucursales = @dbComun.connection.select_all(sql)
        sucursales = []
        @grupo_sucursales.each do |suc|
          sucursales << suc['IdSucursal'].to_s
        end

      else
        #si eres < contralor
        #arma los combos de la zonas, sucursales, etc
        sql = "SELECT Num_suc,Nombre FROM sucursal where ZonaAsig = #{@id_intermedio} and FechaTerm = '' order by Num_suc"
        @grupo_sucursales = @dbComun.connection.select_all(sql)
        sucursales = []

        @grupo_sucursales.each do |suc|
          sql = "select * from ComisXVtasSuc where (Mes between '#{@anio_selected}' and '#{current_month}') and sucursal = #{suc['Num_suc']}"
          datos = @dbEsta.connection.select_all(sql)
          if !datos.nil?
            sucursales << suc['Num_suc']
          end
        end
      end

      @nombre_superior = "Region #{params[:id]}" if params.length == 3
      sucursales = sucursales.join(",")

      if sucursales == ""
        return redirect_to "/", alert: "No se han encontrado sucursales para la estadistica. Favor de reportar a Soporte."
      end

      limit = 12
      limit = DateTime.now.strftime('%m').to_i if @anio_selected[0..3] == DateTime.now.strftime('%Y')

      #genera los numeros de cada mes
      setted_date = DateTime.new(@anio_selected[0..3].to_i , @anio_selected[4..5].to_i, 1)
      months = []
      (0..limit-1).each { |i|  months << "#{setted_date.next_month(i).to_s[0..3]}#{setted_date.next_month(i).to_s[5..6]}" }
      @mm = months

      data_meses = {}
      obj_meses = {}
      sql = "select avg(round(coalesce(tendencianetas / ObjNetas, 0) * 100, 2)) as OpaNetas, mes, sum(VentaNetaSucursal) as netas, sum(VentaNetaSucursal)/sum(TicketsSucursal) as tp, sum(TicketsSucursal) as nt, round(avg(AxTSucursal),2) as axt from ComisXVtasSuc where (mes between '#{@anio_selected}' and '#{current_month}') and sucursal in(#{sucursales}) group by mes order by mes asc limit #{limit}"
      data = @dbEsta.connection.select_all(sql)

      sql = "select Mes, sum(ObjNetas) as objNetas, sum(ObjNetas)/sum(ObjNT)  as objTP, sum(ObjNT) as objNT, round(avg(ObjAxt),2) as objAxt from ComisXVtasSuc where (Mes between '#{@anio_selected}' and '#{current_month}') and sucursal in(#{sucursales}) group by mes order by mes asc limit #{limit}"
      meses = @dbEsta.connection.select_all(sql)

      #genera hash de los datos y objetivos de los meses
      months.each_with_index do |m, i|
        d = data.select{|a| a['mes'] == m }[0]
        o = meses.select{|a| a['Mes'] == m }[0]
        d_netas = d['netas'] rescue 0.0
        d_tp    = d['tp'] rescue 0.0
        d_nt    = d['nt'] rescue 0.0
        d_axt   = d['axt'] rescue 0.0
        o_netas = o['objNetas'] rescue 0.0
        o_tp    = o['objTP'] rescue 0.0
        o_nt    = o['objNT'] rescue 0.0
        o_axt   = o['objAxt'] rescue 0.0

        data_meses[m] = Hash["netas", d_netas, "tp", d_tp, "nt", d_nt, "axt", d_axt]
        obj_meses[m] = Hash["objNetas", o_netas, "objTP", o_tp, "objNT", o_nt, "objAxt", o_axt]
      end

      sql = "select mes, sucursal, VentaNetaSucursal as netas, TPSucursal as tp, TicketsSucursal as nt, AxTSucursal as axt from ComisXVtasSuc where (Mes between '#{@anio_selected}' and '#{current_month}') and sucursal in(#{sucursales}) order by mes asc"
      @estadisticas_sucursales = @dbEsta.connection.select_all(sql)

      @estadisticas_sucursales = @estadisticas_sucursales.group_by{|i| i['sucursal']}.sort_by{|i| i[0]}
      sql = "select sum(TendenciaNetas) as NetasProyectadas, avg(round(coalesce(tendencianetas / ObjNetas, 0) * 100, 2)) as OpaNetas, avg(round(coalesce(TendenciaTP / ObjTP, 0) * 100, 2)) as OpaTP, avg(round(coalesce(TendenciaNT / ObjNT, 0) * 100, 2)) as OpaNT, avg(round(coalesce(TendenciaAxT / ObjAxT, 0) * 100, 2)) as OpaAxT from ComisXVtasSuc where mes = '#{Date.today.strftime("%Y%m")}' and sucursal in(#{sucursales}) order by mes asc"
      @opa_current_mes = @dbEsta.connection.select_all(sql).first

      ventas(data_meses, @opa_current_mes, months)
      obj_ventas(obj_meses, @opa_current_mes, months)

      contador = 1
      array_suc = []
      @array_table = []
      array_row = []

      @estadisticas_sucursales
      @estadisticas_sucursales.each do |suc|
        array_suc << suc[1]
      end

      @netas_array = []
      @tp_array = []
      @nt_array = []
      @axt_array = []


      array_suc.each do |suc|
        netas_renglon = []
        tp_renglon = []
        nt_renglon = []
        axt_renglon = []
        suc.each do | ventas_mes |
          sql = "select mes, round(coalesce(tendencianetas / ObjNetas, 0) * 100, 2) as OpaNetas, round(coalesce(TendenciaTP / ObjTP, 0) * 100, 2) as OpaTP, round(coalesce(TendenciaNT / ObjNT, 0) * 100, 2) as OpaNT, round(coalesce(TendenciaAxT / ObjAxT, 0) * 100, 2) as OpaAxT from ComisXVtasSuc where sucursal = #{ventas_mes['sucursal']} and mes = #{ventas_mes['mes']}"
          opas = @dbEsta.connection.select_all(sql).first
          netas_renglon << {"#{opas['mes']}" => opas['OpaNetas']}
          tp_renglon << {"#{opas['mes']}" => opas['OpaTP']}
          nt_renglon << {"#{opas['mes']}" => opas['OpaNT']}
          axt_renglon << {"#{opas['mes']}" => opas['OpaAxT']}
        end
        @netas_array << netas_renglon
        @tp_array << tp_renglon
        @nt_array << nt_renglon
        @axt_array << axt_renglon
      end
  end

  def sucursal

    current_month = DateTime.now.strftime('%Y%m')

    #genera el combo de  años
    @anios = []
    year_18 = DateTime.new(2018,1,1)
    (2018.. DateTime.now.to_s[0..3].to_i).each do |y|
      @anios << y
    end

    @permiso = Permiso.where("idUsuario = #{current_user.id}").first
    sql = "select FechaUltimaVtaSuc as ultFechaProcesada from ComisXVtasSuc where sucursal = #{params['id']} order by FechaUltimaVtaSuc desc limit 1"
    @ult_procesada = @dbEsta.connection.select_all(sql).first
    #Muestra datos de la sucursal en el año actual asi como estadisticas de vendedores
      @id_vendedor = current_user[:numEmpleado].to_s[0..-2]
      @id_sucursal = params['id']
      @id_intermedio = params['id_intermedio']
      sql = "SELECT Num_suc,Nombre FROM sucursal where Num_suc = #{@id_sucursal} and FechaTerm = '' and Nombre not like '%Bodega%'"
      suc = @dbComun.connection.select_all(sql).first
      @nombre_sucursal = suc['Nombre']
      @anio_selected =  params[:anio]
      @anio_selected =  "#{params[:anio]}01" if @anio_selected.length == 4
      if @permiso[:p1].to_i > 0 && @permiso[:p2].to_i == 0 && @permiso[:p3].to_i == 0
        sql = "SELECT IdAgrupa,Nombre FROM agrupa order by NumOrd"
        @superior = @dbComun.connection.select_all(sql)
        @id_intermedio = params['id_intermedio']
        @id_superior = params['id_superior']
        @id_sucursal = params['id']
        @nombre_superior = params["nombre_superior"]
        @nombre_intermedio = params["nombre_intermedio"]
        if @id_intermedio
          sql = "SELECT IdSubAgrupa,Nombre FROM subagrupa where IdAgrupa = #{@id_superior.to_i}"
          @subagrupa = @dbComun.connection.select_all(sql)
        end

        sql = "SELECT IdSucursal,Nombre FROM agrupasuc where IdAgrupa = #{@id_superior} and IdSubAgrupa = #{@id_intermedio} order by NumOrd"
        @grupo_sucursales = @dbComun.connection.select_all(sql)
        sucursales = []
        @grupo_sucursales.each do |suc|
          sucursales << suc['IdSucursal']
        end
      end
      limit = 12
      limit = DateTime.now.strftime('%m').to_i if @anio_selected[0..3] == DateTime.now.strftime('%Y')

      #genera los numeros de cada mes
      setted_date = DateTime.new(@anio_selected[0..3].to_i , @anio_selected[4..5].to_i, 1)
      months = []
      (0..limit-1).each { |i|  months << "#{setted_date.next_month(i).to_s[0..3]}#{setted_date.next_month(i).to_s[5..6]}" }

      if @permiso[:p1].to_i > 0 && @permiso[:p2].to_i > 0 && @permiso[:p3].to_i == 0
        @nombre_sucursal = params["nombre_sucursal"]
        sql = "SELECT Num_suc,Nombre FROM sucursal where ZonaAsig = #{@id_intermedio} and FechaTerm = '' and Nombre not like '%Bodega%' order by Num_suc"
        @grupo_sucursales = @dbComun.connection.select_all(sql)

      end

      sql = "select DISTINCT IdVendedor, mes, VentaNetaVend as netas, TPVend as tp, NTVend as nt, AxTVend as axt from ComisXVtasAsesor where (mes between '#{@anio_selected}' and '#{current_month}') and sucursal = #{ @id_sucursal } and IdVendedor <> 0 group by IdVendedor"
      @grupo_vendedores = @dbEsta.connection.select_all(sql)
      @netas_array = []
      @tp_array = []
      @nt_array = []
      @axt_array = []

      @grupo_vendedores.each do |vendedor|
        sql = "select mes, CumplimientoNetasVend as OpaNetas, CumplimientoTPVend as OpaTP, CumplimientoNTVend as OpaNT, CumplimientoAxTVend as OpaAxT from ComisXVtasAsesor where IdVendedor = #{vendedor['IdVendedor']} group by mes order by mes asc"
        opas = @dbEsta.connection.select_all(sql)
        netas_renglon = []
        tp_renglon = []
        nt_renglon = []
        axt_renglon = []
        opas.each do |renglon|
          netas_renglon << renglon['OpaNetas']
          tp_renglon << {"#{renglon['mes']}" => renglon['OpaTP']}
          nt_renglon << {"#{renglon['mes']}" => renglon['OpaNT']}
          axt_renglon << {"#{renglon['mes']}" => renglon['OpaAxT']}
        end
        @netas_array << netas_renglon
        @tp_array << tp_renglon
        @nt_array << nt_renglon
        @axt_array << axt_renglon
      end

      sql = "select * from ComisXVtasSuc where  sucursal = #{@id_sucursal} and mes = '#{Date.today.strftime("%Y%m")}' order by mes asc"
      @opa_current_mes = @dbEsta.connection.select_all(sql).first rescue 0

      sql = "select mes, VentaNetaSucursal as netas, TPSucursal as tp, TicketsSucursal as nt, AxTSucursal as axt from ComisXVtasSuc where (mes between '#{@anio_selected}' and '#{current_month}') and sucursal = #{@id_sucursal} order by Mes asc limit #{limit}"
      data = @dbEsta.connection.select_all(sql)
      @mm = months
      sql = "select Mes, ObjNetas as objNetas, ObjTP as objTP, ObjNT as objNT, ObjAxT as objAxt from ComisXVtasSuc where (Mes between '#{@anio_selected}' and '#{current_month}') and sucursal = #{@id_sucursal} limit #{limit}"
      meses = @dbEsta.connection.select_all(sql)
      sql = "SELECT * FROM sucursal where  Num_suc = #{@id_sucursal}"
      @direccion_suc = @dbComun.connection.select_all(sql).first

      sql = "SELECT * FROM sucfac where Sucursal = #{@id_sucursal}"
      begin
        address_suc = @dbFacEle.connection.select_all(sql).first
      rescue
        redirect_to root_path, notice: "No se encontro la dirección de la sucursal"
      end
      data_meses = {}
      obj_meses = {}
      #genera hash de los datos y objetivos de los meses
      months.each_with_index do |m, i|
        d = data.select{|a| a['mes'] == m }[0]
        o = meses.select{|a| a['Mes'] == m }[0]
        d_netas = d['netas'] rescue 0.0
        d_tp    = d['tp'] rescue 0.0
        d_nt    = d['nt'] rescue 0.0
        d_axt   = d['axt'] rescue 0.0
        o_netas = o['objNetas'] rescue 0.0
        o_tp    = o['objTP'] rescue 0.0
        o_nt    = o['objNT'] rescue 0.0
        o_axt   = o['objAxt'] rescue 0.0

        data_meses[m] = Hash["netas", d_netas, "tp", d_tp, "nt", d_nt, "axt", d_axt]
        obj_meses[m] = Hash["objNetas", o_netas, "objTP", o_tp, "objNT", o_nt, "objAxt", o_axt]
      end
      ventas(data_meses, @opa_current_mes, months)
      obj_ventas(obj_meses, @opa_current_mes, months)
  end

  def show_vendedor

    current_month = DateTime.now.strftime('%Y%m')

    #genera el combo de  años
    @anios = []
    year_18 = DateTime.new(2018,1,1)
    (2018.. DateTime.now.to_s[0..3].to_i).each do |y|
      @anios << y
    end

    @permiso = Permiso.where("idUsuario = #{current_user.id}").first
    @nombre_sucursal = params['nombre_sucursal']
    @id_intermedio = params['id_intermedio']
    @id_vendedor = current_user[:numEmpleado].to_s[0..-2]
    @id_vendedor = current_user[:numEmpleado].to_s if current_user[:numEmpleado].to_s[0..-2] != @permiso[:p4].to_s
    if @permiso[:p1].to_i > 0 && @permiso[:p2].to_i > 0 && @permiso[:p3].to_i == 0
      @id_vendedor = params['id']
    end

    if @permiso[:p1].to_i > 0 && @permiso[:p2].to_i == 0 && @permiso[:p3].to_i == 0  && @permiso[:p4].to_i == 0
      #@vendedor = User.where("numEmpleado [0..-2]= #{params['id']}").first
      sql = "SELECT IdAgrupa,Nombre FROM agrupa order by NumOrd"
      @superior = @dbComun.connection.select_all(sql)
      @id_intermedio = params['id_intermedio']
      @id_superior = params['id_superior']
      @id_sucursal = params['id_sucursal']
      @id_vendedor = params['id']
      @nombre_superior = params["nombre_superior"]
      @nombre_intermedio = params["nombre_intermedio"]
      @nombre_sucursal = params['nombre_sucursal']

      if @id_intermedio
        sql = "SELECT IdSubAgrupa,Nombre FROM subagrupa where IdAgrupa = #{@id_superior.to_i}"
        @subagrupa = @dbComun.connection.select_all(sql)
      end

      sql = "SELECT IdSucursal,Nombre FROM agrupasuc where IdAgrupa = #{@id_superior} and IdSubAgrupa = #{@id_intermedio} order by NumOrd"
      @grupo_sucursales = @dbComun.connection.select_all(sql)
    end

    if @permiso[:p1].to_i > 0 && @permiso[:p2].to_i > 0 && @permiso[:p3].to_i > 0
      sql = "SELECT Num_suc,Nombre FROM sucursal where  ZonaAsig = #{@id_intermedio} and FechaTerm = '' and Nombre not like '%Bodega%' order by Num_suc asc"
      @grupo_sucursales = @dbComun.connection.select_all(sql)

    end

    #Muestra estadisticas del vendedor en el año corriente asi como sus comisiones

    @anio_selected =  params[:anio]
    @anio_selected =  "#{params[:anio]}01" if @anio_selected.length == 4
    @anio_selected
    limit = 12
    limit = DateTime.now.strftime('%m').to_i if @anio_selected[0..3] == DateTime.now.strftime('%Y')

    #genera los numeros de cada mes
    setted_date = DateTime.new(@anio_selected[0..3].to_i , @anio_selected[4..5].to_i, 1)
    months = []
    (0..limit-1).each { |i|  months << "#{setted_date.next_month(i).to_s[0..3]}#{setted_date.next_month(i).to_s[5..6]}" }

    sql = "select sum(TendenciaNetasVend) as NetasProyectadas, avg(CumplimientoNetasVend) as OpaNetas, avg(CumplimientoTPVend) as OpaTP, sum(CumplimientoNTVend) as OpaNT, avg(CumplimientoAxTVend) as OpaAxT from ComisXVtasAsesor where  IdVendedor = #{@id_vendedor} and ObjNetasVend > 0 and mes = '#{Date.today.strftime("%Y%m")}' order by mes asc"
    @opa_current_mes = @dbEsta.connection.select_all(sql).first

    sql = "select mes, sum(VentaNetaVend) as netas, TPVend as tp, NTVend as nt, AxTVend as axt, sucursal as sucursal from ComisXVtasAsesor where (mes between '#{@anio_selected}' and '#{current_month}') and IdVendedor = #{@id_vendedor} group by mes order by mes asc limit #{limit}"
    data = @dbEsta.connection.select_all(sql)

    sql = "select Mes, ObjNetasVend as objNetas, ObjTPVend as objTP, ObjNTVend as objNT, ObjAxTVend as objAxt from ComisXVtasAsesor where (Mes between '#{@anio_selected}' and '#{current_month}') and IdVendedor = #{@id_vendedor} limit #{limit}"
    meses = @dbEsta.connection.select_all(sql)

    data_meses = {}
    obj_meses = {}
    #genera hash de los datos y objetivos de los meses
    months.each_with_index do |m, i|
      d = data.select{|a| a['mes'] == m }[0]
      o = meses.select{|a| a['Mes'] == m }[0]
      d_netas = d['netas'] rescue 0.0
      d_tp    = d['tp'] rescue 0.0
      d_nt    = d['nt'] rescue 0.0
      d_axt   = d['axt'] rescue 0.0
      o_netas = o['objNetas'] rescue 0.0
      o_tp    = o['objTP'] rescue 0.0
      o_nt    = o['objNT'] rescue 0.0
      o_axt   = o['objAxt'] rescue 0.0

      data_meses[m] = Hash["netas", d_netas, "tp", d_tp, "nt", d_nt, "axt", d_axt]
      obj_meses[m] = Hash["objNetas", o_netas, "objTP", o_tp, "objNT", o_nt, "objAxt", o_axt]
    end

    ventas(data_meses, @opa_current_mes, months)
    obj_ventas(obj_meses, @opa_current_mes, months)

    begin
      location_suc = data[-1]['sucursal'] rescue 99
      sql = "SELECT Latitud,Longitud FROM sucursal where  Num_suc = #{location_suc}"
      @direccion_suc = @dbComun.connection.select_all(sql).first

    rescue Exception => exc
      redirect_to root_path, notice: "#{data}Usted no tiene numeros de ventas"
    end
    @an = @anio_selected

  end

  def ver_detalle
    @id_vendedor = params[:id_vendedor]
    sql = "select * from pdv.hmovpdv where sucursal=#{params[:sucursal]} and idvendedor=#{params[:id_vendedor]} and mid(fecha,1,6)=#{DateTime.now.strftime('%Y%m')} and status2='T'"
    @detalle = @dbPdv.connection.select_all(sql)
  end

  def ventas(venta_mes, opa_current_mes, months)
    @month_name = []
    m_name = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
    @ventas = []
    @tp     = []
    @nt     = []
    @axt    = []
    @porcen = []
    months.each_with_index do |month, index|
      @month_name << month[4..5].to_i-1
      mes = venta_mes.select {|m| m == month}.first
      mes = mes[1]
      @porcen   << mes['OpaNetas'].to_f rescue 0
      @ventas   << mes['netas'].to_f rescue 0
      @tp       << mes['tp'].to_f rescue 0
      @nt       << mes['nt'].to_f rescue 0
      @axt      << mes['axt'].to_f rescue 0
    end
    @ventas << opa_current_mes['NetasProyectadas'].to_f rescue 0
    @tp << opa_current_mes['OpaTP'].to_f rescue 0
    @nt << opa_current_mes['OpaNT'].to_f rescue 0
    @axt << opa_current_mes['OpaAxT'].to_f rescue 0

  end


  def obj_ventas(meses, opa_current_mes, months)

    @obj_ventas = []
    @obj_tp     = []
    @obj_nt     = []
    @obj_axt    = []

    months.each_with_index do |month, index|
      mes = meses.select {|m| m == month}.first
      mes = mes[1]
      @obj_ventas   << mes['objNetas'].to_f rescue 0
      @obj_tp       << mes['objTP'].to_f rescue 0
      @obj_nt       << mes['objNT'].to_f rescue 0
      @obj_axt      << mes['objAxt'].to_f rescue 0
    end

    @porc_ventas  = []
    @porc_tp      = []
    @porc_nt      = []
    @porc_axt     = []


    (0..meses.length-1).each do |i|
      if !@obj_ventas[i].nil? || @obj_ventas[i].to_f == 0 then @porc_ventas  << ((100.0 / @obj_ventas[i].to_f) * @ventas[i].to_f) else @porc_ventas  << ((100.0 / 1) * @ventas[i].to_f) end
      if !@obj_tp[i].nil? || @obj_tp[i].to_f == 0 then @porc_tp  << ((100.0 / @obj_tp[i].to_f) * @tp[i].to_f) else @porc_tp  << ((100.0 / 1) * @tp[i].to_f) end
      if !@obj_nt[i].nil? || @obj_nt[i].to_f == 0 then @porc_nt  << ((100.0 / @obj_nt[i].to_f) * @nt[i].to_f) else @porc_nt  << ((100.0 / 1) * @nt[i].to_f) end
      if !@obj_axt[i].nil? || @obj_axt[i].to_f == 0 then @porc_axt   << ((100.0 / @obj_axt[i].to_f) * @axt[i].to_f) else @porc_axt   << ((100.0 / 1) * @axt[i].to_f) end
    end

      @porc_ventas[-1] = (100.0 / @obj_ventas[n_months].to_f) * opa_current_mes['NetasProyectadas'].to_f rescue 0
      @porc_tp[-1] = opa_current_mes['OpaTP'].to_f rescue 0
      @porc_nt[-1] = opa_current_mes['OpaNT'].to_f rescue 0
      @porc_axt[-1] = opa_current_mes['OpaAxT'].to_f rescue 0

  end


  def export_excel

    current_month = DateTime.now.strftime('%Y%m')

    @anio_selected = params['anio']
    @permiso = Permiso.where("idUsuario = #{current_user.id}").first
    @type_export = ""
    @meses_caption = []
    months = ["#{@anio_selected[0..3]}01", "#{@anio_selected[0..3]}02", "#{@anio_selected[0..3]}03", "#{@anio_selected[0..3]}04", "#{@anio_selected[0..3]}05", "#{@anio_selected[0..3]}06", "#{@anio_selected[0..3]}07", "#{@anio_selected[0..3]}08", "#{@anio_selected[0..3]}09", "#{@anio_selected[0..3]}10", "#{@anio_selected[0..3]}11", "#{@anio_selected[0..3]}12"]
    setted_date = DateTime.new(@anio_selected[0..3].to_i , @anio_selected[4..5].to_i, 1)
    meses_dig = []
    (0..11).each { |i|  meses_dig << "#{setted_date.next_month(i).to_s[0..3]}#{setted_date.next_month(i).to_s[5..6]}" }


    if params.has_key?(:id_vendedor)
      @id_vendedor = params[:id_vendedor].to_s
      @meses_caption = ["#Vendedor:#{@id_vendedor}"]
      n_months = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
      meses_dig.each do |c_month|
        @meses_caption << "#{n_months[c_month[-2..-1].to_i-1]}-#{c_month[0..3]}-Objetivo"
        @meses_caption << "#{n_months[c_month[-2..-1].to_i-1]}-#{c_month[0..3]}-Real"
        @meses_caption << "#{n_months[c_month[-2..-1].to_i-1]}-#{c_month[0..3]}-Alcance"
      end
      sql = "select mes, sum(VentaNetaVend) as netas, TPVend as tp, NTVend as nt, AxTVend as axt, sucursal as sucursal from ComisXVtasAsesor where  IdVendedor = #{@id_vendedor} and (Mes between '#{@anio_selected}' and '#{current_month}') group by mes order by mes asc limit 12"
      @data_meses = @dbEsta.connection.select_all(sql)
      sql = "select Mes, ObjNetasVend as objNetas, ObjTPVend as objTP, ObjNTVend as objNT, ObjAxTVend as objAxt from ComisXVtasAsesor where (Mes between '#{@anio_selected}' and '#{current_month}') and IdVendedor = #{@id_vendedor} order by mes asc limit 12"
      @objetivos = @dbEsta.connection.select_all(sql)
      @type_export = "vendedor"

      @netas_vendedor = ["Netas"]
      @tp_vendedor = ["TP"]
      @nt_vendedor = ["NT"]
      @axt_vendedor = ["AxT"]

      meses_dig.each do |num|

        dato = @data_meses.select {|m| m['mes'] == num}.first
        obj = @objetivos.select {|m| m['Mes'] == num}.first

        @netas_vendedor << obj_netas = number_to_currency(obj['objNetas'], :locale => :mx, :precision => 2) rescue 0.0
        @netas_vendedor << real_netas = number_to_currency(dato['netas'], :locale => :mx, :precision => 2)   rescue 0.0
        @netas_vendedor << alc_netas =((100.0/obj['objNetas'].to_f) * dato['netas']).round(2).to_s + "%" rescue "0.0%"
        @tp_vendedor    << obj_tp = number_to_currency(obj['objTP'], :locale => :mx, :precision => 2) rescue 0
        @tp_vendedor    << real_tp = number_to_currency(dato['tp'], :locale => :mx, :precision => 2)  rescue 0
        @tp_vendedor    << alc_tp = ((100.0/obj['objTP'].to_f) * dato['tp']).round(2).to_s + "%"  rescue "0.0%"
        @nt_vendedor    << obj_nt = obj['objNT'].round(0)  rescue 0
        @nt_vendedor    << real_nt = dato['nt'].round(0)  rescue 0
        @nt_vendedor    << alc_nt = ((100.0/obj['objNT'].to_f) * dato['nt']).round(2).to_s + "%" rescue "0.0%"
        @axt_vendedor   << obj_axt = obj['objAxt']  rescue 0
        @axt_vendedor   << real_axt = dato['axt']  rescue 0
        @axt_vendedor   << alc_axt = ((100.0/obj['objAxt'].to_f) * dato['axt']).round(2).to_s + "%" rescue "0.0%"
      end

    elsif params.has_key?(:id_sucursal)

      @id_sucursal = params[:id_sucursal].to_s
      @meses_caption = ["#Sucursal:#{@id_sucursal}"]
      n_months = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
      meses_dig.each do |c_month|
        @meses_caption << "#{n_months[c_month[-2..-1].to_i-1]}-#{c_month[0..3]}-Objetivo"
        @meses_caption << "#{n_months[c_month[-2..-1].to_i-1]}-#{c_month[0..3]}-Real"
        @meses_caption << "#{n_months[c_month[-2..-1].to_i-1]}-#{c_month[0..3]}-Alcance"
      end

      sql = "select mes, VentaNetaSucursal as netas, TPSucursal as tp, TicketsSucursal as nt, AxTSucursal as axt from ComisXVtasSuc where (mes between '#{@anio_selected}' and '#{current_month}')  and sucursal = #{@id_sucursal} order by Mes asc"
      data_meses = @dbEsta.connection.select_all(sql)

      sql = "select Mes, ObjNetas as objNetas, ObjTP as objTP, ObjNT as objNT, ObjAxT as objAxt from ComisXVtasSuc where (Mes between '#{@anio_selected}' and '#{current_month}') and sucursal = #{@id_sucursal} order by Mes asc"
      objetivos = @dbEsta.connection.select_all(sql)

      sql = "select IdVendedor, mes, VentaNetaVend as netas, TPVend as tp, NTVend as nt, AxTVend as axt from ComisXVtasAsesor where (mes between '#{@anio_selected}' and '#{current_month}')  and sucursal = #{@id_sucursal} and IdVendedor<>0 order by Mes asc"
      @data_vendedores = @dbEsta.connection.select_all(sql)
      @data_vendedores = @data_vendedores.group_by{|vendedor| vendedor['IdVendedor']}

      sql = "select IdVendedor, Mes, ObjNetasVend as objNetas, ObjTPVend as objTP, ObjNTVend as objNT, ObjAxTVend as objAxt from ComisXVtasAsesor where (Mes between '#{@anio_selected}' and '#{current_month}') and sucursal = #{@id_sucursal} and IdVendedor<>0 order by Mes asc"
      @objetivos_vendedores = @dbEsta.connection.select_all(sql)
      @objetivos_vendedores = @objetivos_vendedores.group_by{|vendedor| vendedor['IdVendedor']}

      @type_export = "sucursal"

      @netas_sucursal = ["Netas"]
      @tp_sucursal = ["TP"]
      @nt_sucursal = ["NT"]
      @axt_sucursal = ["AxT"]

      meses_dig.each do |num|
        month = num.to_i

        dato = data_meses.select {|m| m['mes'].to_i == month}.first
        obj = objetivos.select {|m| m['Mes'].to_i == month}.first

        @netas_sucursal << obj_netas = number_to_currency(obj['objNetas'], :locale => :mx, :precision => 2) rescue 0.0
        @netas_sucursal << real_netas = number_to_currency(dato['netas'], :locale => :mx, :precision => 2)   rescue 0.0
        @netas_sucursal << alc_netas =((100.0/obj['objNetas'].to_f) * dato['netas']).round(2).to_s + "%" rescue "0.0%"
        @tp_sucursal    << obj_tp = number_to_currency(obj['objTP'], :locale => :mx, :precision => 2) rescue 0
        @tp_sucursal    << real_tp = number_to_currency(dato['tp'], :locale => :mx, :precision => 2)  rescue 0
        @tp_sucursal    << alc_tp = ((100.0/obj['objTP'].to_f) * dato['tp']).round(2).to_s + "%"  rescue "0.0%"
        @nt_sucursal    << obj_nt = obj['objNT'].round(0)  rescue 0
        @nt_sucursal    << real_nt = dato['nt'].round(0)  rescue 0
        @nt_sucursal    << alc_nt = ((100.0/obj['objNT'].to_f) * dato['nt']).round(2).to_s + "%" rescue "0.0%"
        @axt_sucursal   << obj_axt = obj['objAxt']  rescue 0
        @axt_sucursal   << real_axt = dato['axt']  rescue 0
        @axt_sucursal   << alc_axt = ((100.0/obj['objAxt'].to_f) * dato['axt']).round(2).to_s + "%" rescue "0.0%"
      end

      @netas_vendedores = []
      @tp_vendedores = []
      @nt_vendedores = []
      @axt_vendedores = []
      @meses_vendedores = []

      @data_vendedores.each_with_index do |vendedor, index_v|

      vend = @objetivos_vendedores.select{|key, hash| key == vendedor[0]}
      vende = [vend.keys.first.to_s]

      n_months = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
      meses_dig.each do |c_month|
        vende << "#{n_months[c_month[-2..-1].to_i-1]}-#{c_month[0..3]}-Objetivo"
        vende << "#{n_months[c_month[-2..-1].to_i-1]}-#{c_month[0..3]}-Real"
        vende << "#{n_months[c_month[-2..-1].to_i-1]}-#{c_month[0..3]}-Alcance"
      end
      @meses_vendedores << vende
        netas = ["Netas"]
        tp = ["TP"]
        nt = ["NT"]
        axt = ["AXT"]
        meses_dig.each do |mes_index|
          dato = vendedor[1].select {|m| m['mes'].to_i == mes_index.to_i}.first
          obj = vend[vendedor[0]].to_a.select {|m| m['Mes'] == mes_index}.first.to_h

          netas << obj_netas = number_to_currency(obj['objNetas'], :locale => :mx, :precision => 2) rescue 0.0
          netas << real_netas = number_to_currency(dato['netas'], :locale => :mx, :precision => 2) rescue 0.0
          netas << alc_netas = ((100.0/obj['objNetas'].to_f) *  dato['netas'].to_f).to_f.round(2).to_s + "%" rescue "0.0%"

          tp << obj_tp = number_to_currency(obj['objTP'], :locale => :mx, :precision => 2) rescue  0
          tp << real_tp = number_to_currency(dato['tp'], :locale => :mx, :precision => 2) rescue 0
          tp << alc_tp = ((100.0/obj['objTP'].to_f) *  dato['tp']).to_f.round(2).to_s + "%" rescue "0.0%"

          nt << obj_nt = obj['objNT'] rescue 0
          nt << real_nt = dato['nt'] rescue 0
          nt << alc_nt = ((100.0/obj['objNT'].to_f) *  dato['nt']).to_f.round(2).to_s + "%" rescue "0.0%"

          axt << obj_axt = obj['objAxt'] rescue 0
          axt << real_axt = dato['axt'] rescue 0
          axt << alc_axt = ((100.0/obj['objAxt'].to_f) *  dato['axt']).to_f.round(2).to_s + "%" rescue "0.0%"

        end

        @netas_vendedores << netas
        @tp_vendedores << tp
        @nt_vendedores << nt
        @axt_vendedores << axt
      end

    elsif params.has_key?(:id_intermedio) && params.has_key?(:id_superior)

      @id_region = params[:id_intermedio].to_s
      n_months = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
      @meses_caption = [""]
      meses_dig.each do |c_month|
        @meses_caption << "#{n_months[c_month[-2..-1].to_i-1]}-#{c_month[0..3]}-Objetivo"
        @meses_caption << "#{n_months[c_month[-2..-1].to_i-1]}-#{c_month[0..3]}-Real"
        @meses_caption << "#{n_months[c_month[-2..-1].to_i-1]}-#{c_month[0..3]}-Alcance"
      end
      sucursales = []
      if @permiso[:p1].to_i > 0 && @permiso[:p2].to_i == 0 && @permiso[:p3].to_i == 0
        sql = "SELECT IdSucursal as Num_suc,Nombre FROM agrupasuc where IdAgrupa = #{params[:id_superior]} and IdSubAgrupa = #{@id_region} order by NumOrd"
      else
        sql = "SELECT Num_suc,Nombre FROM sucursal where ZonaAsig = #{@id_region} and FechaTerm = '' order by Num_suc"
      end
      @grupo_sucursales = @dbComun.connection.select_all(sql)
      @grupo_sucursales.each do |suc|
        sucursales << suc['Num_suc']
      end
      sucursales = sucursales.join(",")

      sql = "select mes, sum(VentaNetaSucursal) as netas, sum(VentaNetaSucursal)/sum(TicketsSucursal) as tp, sum(TicketsSucursal) as nt, round(avg(AxTSucursal),2) as axt from ComisXVtasSuc where (mes between '#{@anio_selected}' and '#{current_month}') and sucursal in(#{sucursales}) group by mes order by mes asc limit 12"
      @data_meses = @dbEsta.connection.select_all(sql)

      sql = "select Mes, sum(ObjNetas) as objNetas, sum(ObjNetas)/sum(ObjNT)  as objTP, sum(ObjNT) as objNT, round(avg(ObjAxt),2) as objAxt from ComisXVtasSuc where (Mes between '#{@anio_selected}' and '#{current_month}')  and sucursal in(#{sucursales}) group by mes order by mes asc limit 12"
      @objetivos = @dbEsta.connection.select_all(sql)

      sql = "select mes, sucursal, VentaNetaSucursal as netas, TPSucursal as tp, TicketsSucursal as nt, AxTSucursal as axt from ComisXVtasSuc where (mes between '#{@anio_selected}' and '#{current_month}')  and sucursal in(#{sucursales}) order by mes asc"
      @data_sucursales = @dbEsta.connection.select_all(sql)
      @data_sucursales = @data_sucursales.group_by{|i| i['sucursal']}.sort_by{|i| i[0]}

      sql = "select sucursal, Mes, ObjNetas as objNetas, ObjTP as objTP, ObjNT as objNT, ObjAxT as objAxt from ComisXVtasSuc where (Mes between '#{@anio_selected}' and '#{current_month}') and sucursal in(#{sucursales}) order by Mes asc"
      @objetivos_sucursales = @dbEsta.connection.select_all(sql)
      @objetivos_sucursales = @objetivos_sucursales.group_by{|sucursal|sucursal['sucursal']}

      @type_export = "region"

      @netas_zona = ["Netas"]
      @tp_zona = ["TP"]
      @nt_zona = ["NT"]
      @axt_zona = ["AxT"]
      @data_meses.each_with_index do |mes, index|
        @netas_zona << number_to_currency(@objetivos[index]['objNetas'], :locale => :mx, :precision => 2)  rescue 0.0
        @netas_zona << number_to_currency(mes['netas'], :locale => :mx, :precision => 2)    rescue 0.0
        @netas_zona << ((100.0/@objetivos[index]['objNetas'].to_f) * mes['netas']).round(2).to_s + "%" rescue "0.0%"
        @tp_zona    << number_to_currency(@objetivos[index]['objTP'], :locale => :mx, :precision => 2) rescue 0.0
        @tp_zona    << number_to_currency(mes['tp'], :locale => :mx, :precision => 2)  rescue 0.0
        @tp_zona    << ((100.0/@objetivos[index]['objTP'].to_f) * mes['tp']).round(2).to_s + "%"  rescue "0.0%"
        @nt_zona    << @objetivos[index]['objNT'].round(0)  rescue 0.0
        @nt_zona    << mes['nt'].round(0)  rescue 0.0
        @nt_zona    << ((100.0/@objetivos[index]['objNT'].to_f) * mes['nt']).round(2).to_s + "%" rescue "0.0%"
        @axt_zona   << @objetivos[index]['objAxt'] rescue 0.0
        @axt_zona   << mes['axt']  rescue 0.0
        @axt_zona   << ((100.0/@objetivos[index]['objAxt'].to_f) * mes['axt']).round(2).to_s + "%" rescue "0.0%"
      end

      @netas_sucursales = []
      @tp_sucursales = []
      @nt_sucursales = []
      @axt_sucursales = []
      @meses2 = []
      @data_sucursales.each_with_index do |suc, index|
        meses3 = ["#{suc[0]}-#{@grupo_sucursales.select{|s| s['Num_suc'] == suc[0]}[0]['Nombre']}"]
        n_months = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
        meses_dig.each do |c_month|
          meses3 << "#{n_months[c_month[-2..-1].to_i-1]}-#{c_month[0..3]}-Objetivo"
          meses3 << "#{n_months[c_month[-2..-1].to_i-1]}-#{c_month[0..3]}-Alcance"
          meses3 << "#{n_months[c_month[-2..-1].to_i-1]}-#{c_month[0..3]}-Real"
        end
        @meses2 << meses3

        netas = ["Netas"]
        tp = ["TP"]
        nt = ["NT"]
        axt = ["AXT"]

        meses_dig.each do |month|

          dato = suc[1].select {|m| m['mes'].to_i == month.to_i}.first
          obj = @objetivos_sucursales[suc[0]].select {|m| m['Mes'] == month}
          obj = obj[0]
          netas  << obj_netas = number_to_currency(obj['objNetas'], :locale => :mx, :precision => 2) rescue 0.0
          netas  << real_netas = number_to_currency(dato['netas'], :locale => :mx, :precision => 2) rescue 0.0
          netas  << alc_netas = ((100.0/obj['objNetas']) * dato['netas']).round(2).to_s + "%" rescue "0.0%"

          tp << obj_tp = number_to_currency(obj['objTP'], :locale => :mx, :precision => 2) rescue 0.0
          tp << real_tp = number_to_currency(dato['tp'], :locale => :mx, :precision => 2) rescue 0.0
          tp << alc_tp = ((100.0/obj['objTP']) * dato['tp']).round(2).to_s + "%" rescue "0.0%"

          nt << obj_nt = obj['objNT'] rescue 0.0
          nt << real_nt = dato['nt'] rescue 0.0
          nt << alc_nt = ((100.0/obj['objNT']) * dato['nt']).round(2).to_s + "%" rescue "0.0%"

          axt << obj_axt = obj['objAxt'] rescue 0.0
          axt << real_axt = dato['axt'] rescue 0.0
          axt << alc_axt = ((100.0/obj['objAxt']) * dato['axt']).round(2).to_s + "%" rescue "0.0%"

        end
        @netas_sucursales << netas
        @tp_sucursales << tp
        @nt_sucursales << nt
        @axt_sucursales << axt
      end

    elsif params.has_key?(:id_superior)
      date_set = DateTime.new(@anio_selected[0..3].to_i, @anio_selected[4..5].to_i, 1)
      n_months = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
      @meses_caption = [""]
      @meses_caption2 = [""]
      (0..11).each do |m|
        c_month = date_set.next_month(m).to_s[5..6].to_i - 1
        @meses_caption << "#{n_months[c_month]}-Objetivo"
        @meses_caption << "#{n_months[c_month]}-Real"
        @meses_caption << "#{n_months[c_month]}-Alcance"
        @meses_caption2 << "#{n_months[c_month]}-Real"
        @meses_caption2 << "#{n_months[c_month]}-Alcance"
      end

      sql = "SELECT IdSucursal as Num_suc,Nombre FROM agrupasuc where IdAgrupa = #{params[:id_superior]} order by IdSucursal"
      @sucursales = @dbComun.connection.select_all(sql)
      sucs =[]
      @sucursales.each do |suc|
        sucs << suc['Num_suc']
      end
      sucs = sucs.join(",")

      sql = "SELECT IdSubAgrupa,Nombre FROM subagrupa where IdAgrupa = #{params[:id_superior]} order by IdSubAgrupa "
      @subagrupa = @dbComun.connection.select_all(sql)

      sql = "select mes, sum(VentaNetaSucursal) as netas, sum(VentaNetaSucursal)/sum(TicketsSucursal) as tp, sum(TicketsSucursal) as nt, round(avg(AxTSucursal),2) as axt from ComisXVtasSuc where (mes between '#{@anio_selected}' and '#{current_month}') and sucursal in(#{sucs}) group by mes order by mes asc limit 12"
      @data_meses = @dbEsta.connection.select_all(sql)

      sql = "select Mes, sum(ObjNetas) as objNetas, sum(ObjNetas)/sum(ObjNT)  as objTP, sum(ObjNT) as objNT, round(avg(ObjAxt),2) as objAxt from ComisXVtasSuc where (Mes between '#{@anio_selected}' and '#{current_month}')  and sucursal in(#{sucs}) group by mes order by mes asc limit 12"
      @objetivos = @dbEsta.connection.select_all(sql)

      @data_zonas = []
      @subagrupa.each do |num_zona|
        sql = "SELECT IdSucursal,Nombre FROM agrupasuc where IdAgrupa = #{params[:id_superior]} and IdSubAgrupa = #{num_zona['IdSubAgrupa']} order by NumOrd"
        grupo_zonas = @dbComun.connection.select_all(sql)
        sucursales = []
        grupo_zonas.each do |suc|
          sucursales << suc['IdSucursal']
        end
        sucursales = sucursales.join(",")

        sql = "select avg(round(coalesce(tendencianetas / ObjNetas, 0) * 100, 2)) as OpaNetas, mes, sum(VentaNetaSucursal) as netas, sum(VentaNetaSucursal)/sum(TicketsSucursal) as tp, avg(round(coalesce(TendenciaTP / ObjTP, 0) * 100, 2)) as OpaTP, sum(TicketsSucursal) as nt, avg(round(coalesce(TendenciaNT / ObjNT, 0) * 100, 2)) as OpaNT, round(avg(AxTSucursal),2) as axt, avg(round(coalesce(TendenciaAxT / ObjAxT, 0) * 100, 2)) as OpaAxT from ComisXVtasSuc where (mes between '#{@anio_selected}' and '#{current_month}')  and sucursal in(#{sucursales}) group by mes order by mes asc limit 12"
        venta_zona = @dbEsta.connection.select_all(sql)
        @data_zonas << venta_zona
      end

      sql = "select * from ComisXVtasSuc where Mes >= '#{@anio_selected}' order by Sucursal"
      datos = @dbEsta.connection.select_all(sql)
      @data = datos.group_by{|suc|suc['Sucursal']}

      @type_export = "superior"
      @netas_sucursales = []
      @tp_sucursales = []
      @nt_sucursales = []
      @axt_sucursales = []
      date_set = DateTime.new(@anio_selected[0..3].to_i, @anio_selected[4..5].to_i, 1)
      @sucursales.each do |suc|
        netas = ["#{suc['Num_suc']}-#{suc['Nombre']}"]
        tp = ["#{suc['Num_suc']}-#{suc['Nombre']}"]
        nt = ["#{suc['Num_suc']}-#{suc['Nombre']}"]
        axt = ["#{suc['Num_suc']}-#{suc['Nombre']}"]
        sucursal = @data.select{|key, hash| key == suc['Num_suc'] }
        sucursal.each do |row|
          renglon = row[1].sort_by {|r| r['Mes']}
          (0..11).each do |index|
            month = (date_set.next_month(index).to_s[0..3] + date_set.next_month(index).to_s[5..6]).to_i

            dato = row[1].select {|m| m['Mes'].to_i == month}.first

            obj_netas =  number_to_currency(dato['ObjNetas'].to_f, :locale => :mx, :precision => 2)  rescue "$0.00"
            real_netas = number_to_currency(dato['VentaNetaSucursal'].to_f, :locale => :mx, :precision => 2) rescue "$0.00"
            alc_netas = ((dato['TendenciaNetas'].to_f / dato['ObjNetas'].to_f) * 100).round(2).to_s + "%" rescue "0.0%"

            netas << obj_netas
            netas << real_netas
            netas << alc_netas

            tp << obj_tp = number_to_currency(dato['ObjTP'].to_f, :locale => :mx, :precision => 2) rescue 0.0
            tp << real_tp = number_to_currency(dato['TPSucursal'].to_f, :locale => :mx, :precision => 2) rescue 0.0
            tp << alc_tp = ((dato['TendenciaTP'].to_f / dato['ObjTP'].to_f) * 100).round(2).to_s + "%" rescue "0.0%"

            nt << obj_nt = dato['ObjNT'].to_f rescue 0.0
            nt << real_nt = dato['TicketsSucursal'].to_f rescue 0.0
            nt << alc_nt = ((dato['TendenciaNT'].to_f / dato['ObjNT'].to_f) * 100).round(2).to_s + "%" rescue "0.0%"

            axt << obj_axt = dato['ObjAxT'].to_f rescue 0.0
            axt << real_axt = dato['AxTSucursal'].to_f rescue 0.0
            axt << alc_axt = ((dato['TendenciaAxT'].to_f / dato['ObjAxT'].to_f) * 100).round(2).to_s + "%" rescue "0.0%"

          end
        end
        @netas_sucursales << netas
        @tp_sucursales << tp
        @nt_sucursales << nt
        @axt_sucursales << axt
      end
      @netas_gral = ["Netas"]
      @tp_gral = ["TP"]
      @nt_gral = ["NT"]
      @axt_gral = ["AxT"]

      @data_meses.each_with_index do |mes, index|
        @netas_gral << number_to_currency(@objetivos[index]['objNetas'].to_f, :locale => :mx, :precision => 2) rescue 0.0
        @netas_gral << number_to_currency(mes['netas'].to_f, :locale => :mx, :precision => 2) rescue 0.0
        @netas_gral << ((100.0/@objetivos[index]['objNetas'].to_f)* mes['netas'].to_f).round(2).to_s + "%" rescue "0.0%"
        @tp_gral << number_to_currency(@objetivos[index]['objTP'].to_f, :locale => :mx, :precision => 2) rescue 0.0
        @tp_gral << number_to_currency(mes['tp'].to_f, :locale => :mx, :precision => 2) rescue 0.0
        @tp_gral << ((100.0/@objetivos[index]['objTP'].to_f)* mes['tp'].to_f).round(2).to_s + "%"  rescue "0.0%"
        @nt_gral << @objetivos[index]['objNT'].to_f.round(0) rescue 0.0
        @nt_gral << mes['nt'].to_f.round(0) rescue 0.0
        @nt_gral << ((100.0/@objetivos[index]['objNT'].to_f)* mes['nt'].to_f).round(2).to_s + "%"  rescue "0.0%"
        @axt_gral << @objetivos[index]['objAxt'].to_f rescue 0.0
        @axt_gral << mes['axt'].to_f rescue 0.0
        @axt_gral << ((100.0/@objetivos[index]['objAxt'].to_f)* mes['axt'].to_f).round(2).to_s + "%" rescue "0.0%"
      end

      @netas_zona = []
      @tp_zona = []
      @nt_zona = []
      @axt_zona = []

      @subagrupa.each_with_index do |zona, index|
        netas = [zona['Nombre']]
        tp = [zona['Nombre']]
        nt = [zona['Nombre']]
        axt = [zona['Nombre']]
        meses_dig.each_with_index do |zone, i|
          d = @data_zonas[index].select {|m| m['mes'] == zone }
          d = d[0]
          net = d['netas'] rescue 0.0
          onet = d['OpaNetas'].to_f.round(2).to_s + "%" rescue "0.0%"
          t = d['tp'] rescue 0.0
          ot = d['OpaTP'].to_f.round(2).to_s + "%" rescue "0.0%"
          n = d['nt'].to_f.round(0) rescue 0.0
          on = d['OpaNT'].to_f.round(2).to_s + "%" rescue "0.0%"
          a = d['axt'].to_f.round(2) rescue 0.0
          oa = d['OpaAxT'].to_f.round(2).to_s + "%" rescue "0.0%"


          netas << number_to_currency(net, :locale => :mx, :precision => 2)
          netas << onet
          tp << number_to_currency(t, :locale => :mx, :precision => 2)
          tp << ot
          nt << n
          nt << on
          axt << a
          axt << oa
        end
        @netas_zona << netas
        @tp_zona << tp
        @nt_zona << nt
        @axt_zona << axt
      end

    end

    respond_to do |format|
      format.html
      format.xlsx
    end
  end

end
