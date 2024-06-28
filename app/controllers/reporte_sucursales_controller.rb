class ReporteSucursalesController < ApplicationController
	before_filter :authenticate_user!
	before_filter :tiene_permiso_de_ver_app

  def index
  	@type = ""
  	if params.has_key?(:type)
  		@type = "dia" if params[:type] == "dia"
  		@type = "mes" if params[:type] == "mes"
  	end
  	@objetivo = "withobj"
  	@order = "sucursal"
  	@order_type = "asc"
  	@type = "mes" if @type == ""
  	@number = 4
  	@number = 3 if params.has_key?(:type) && params[:type] == "dia"
  	@textos = ["Obj", "AxT", "TP", "NT"]
  	@textos = ["AxT", "TP", "NT"] if params.has_key?(:type) && params[:type] == "dia"
  	obj = "and ObjNetasmes <> 0"

  	if params.has_key?(:order_type)
  		if params[:order_type] == "desc"
  			 @order_type = "desc"
			else
				@order_type = "asc"
			end
		end

		if params.has_key?(:objetivo)
			obj = "" if params[:objetivo] == "todos"
			obj = "and ObjNetasmes <> 0" if params[:objetivo] == "withobj"
			obj = "and ObjNetasmes = 0" if params[:objetivo] == "withoutobj"
			@objetivo = params[:objetivo]
		end

  	if params.has_key?(:order)
  		if @type == "mes"
				@order = "sucursal" 				if params[:order] == "sucursal"
        @order = "IdVendedor"         if params[:order] == "vendedor"
				@order = "PorcOpaNetasMes" if params[:order] == "objetivo" || params[:order] == "PorcOpaNetasMes"
  			@order = "PorcAxTmes" 			if params[:order] == "axt" || params[:order] == "PorcAxTmes"
  			@order = "PorcNTmes" 			if params[:order] == "nt" || params[:order] == "PorcNTmes"
  			@order = "PorcTPmes" 			if params[:order] == "tp" || params[:order] == "PorcTPmes"
			else
				@order = "sucursal" 				if params[:order] == "sucursal"
        @order = "IdVendedor"         if params[:order] == "vendedor"
				@order = "PorcAxTdia" 			if params[:order] == "axt" || params[:order] == "PorcAxTdia"
				@order = "PorcNTdia" 			if params[:order] == "nt" || params[:order] == "PorcNTdia"
				@order = "PorcTPdia" 			if params[:order] == "tp" || params[:order] == "PorcTPdia"
			end
		end
		permisos = Permiso.where("idUsuario = #{current_user.id}")
    sucursales = []
    permisos.each do |permiso|
  		if permiso[:p1].to_i > 0 && permiso[:p3].to_i > 0
  	  	sql = "SELECT Num_suc,Nombre FROM sucursal where Num_suc = #{permiso[:p3]}"
  	    sucursal = @dbComun.connection.select_all(sql).first
  	  	sucursales << sucursal['Num_suc'].to_s
      elsif permiso[:p1].to_i > 0 && permiso[:p2].to_i > 0
        sql = "SELECT Num_suc,Nombre FROM sucursal where ZonaAsig = #{permiso[:p2]} order by Num_suc"
        grupo_sucursales = @dbComun.connection.select_all(sql)
        grupo_sucursales.each do |suc|
          sucursales << suc['Num_suc'].to_s
        end
      elsif permiso[:p1].to_i > 0
        sql = "SELECT Num_suc,Nombre FROM sucursal"
        grupo_sucursales = @dbComun.connection.select_all(sql)
        grupo_sucursales.each do |suc|
          sucursales << suc['Num_suc'].to_s
        end
  	  end

    end
    sucursales = sucursales.join(",")

  	if params.has_key?(:vendedores) && params[:vendedores] == "true"
  		@vendedores = params[:vendedores]
  		sql = "select * from signosVitales where IdVendedor <> 0 and sucursal in(#{sucursales}) and Mes = #{DateTime.now.strftime('%Y%m')} #{obj} order by #{@order} #{@order_type}"
  		if params.has_key?(:type)
  			@type = params[:type]
  			if @type == "mes"
  				@number = 4
  				@textos = ["Obj", "AxT", "TP", "NT"]
  			end
  		end
  	else
  		if params.has_key?(:type)
  			@type = params[:type]
  			if @type == "mes"
  				@number = 4
  				@textos = ["Obj", "AxT", "TP", "NT"]
  			end
  		end
  		sql = "select * from signosVitales where IdVendedor = 0 and sucursal in(#{sucursales}) and Mes = #{DateTime.now.strftime('%Y%m')} #{obj} order by #{@order} #{@order_type}"
  	end
  	@sucursales =  @dbEsta.connection.select_all(sql)
  	sql = "select Num_suc, Nombre from sucursal "
    @sucs = @dbComun.connection.select_all(sql)
    sql = "select IdVendedor, Nombre from vendedores "
    @vends = @dbComun.connection.select_all(sql)
    sql = "select * from catcomisionistas where FechaTerm = ' '"
    @employees =  @dbPdv.connection.select_all(sql)
    sql = "select * from vendexceps where Del like '%#{DateTime.now.strftime('%Y%m')}%'"
    @incidencias =  @dbPdv.connection.select_all(sql)
    sql = "select * from catexceps"
    @cat_incidencias =  @dbPdv.connection.select_all(sql)

  end

  def show
  	@type = ""
  	@number = 3
  	@number = 4 if params.has_key?(:type) && params[:type] == "mes"
  	@textos = ["AxT", "TP", "NT"]
  	@textos = ["Obj", "AxT", "TP", "NT"] if @number == 4
  	@type = "mes" if @number == 4
    sql = "select * from vendexceps where del like '%#{DateTime.now.strftime('%Y%m')}%'"
    @incidencias =  @dbPdv.connection.select_all(sql)
    sql = "select * from catexceps"
    @cat_incidencias =  @dbPdv.connection.select_all(sql)
  	begin
  		sql = "select * from signosVitales where Sucursal = #{params[:id]} and Mes = #{DateTime.now.strftime('%Y%m')} order by ObjNetasmes desc "
  		@sucursal =  @dbEsta.connection.select_all(sql)
  	rescue Exception => exc
  		redirect_to controller: "reporte_sucursales", action: "index", notice: "Sucursal y/o vendedor sin objetivos"
    end
    begin
      sql = "select IdEncargado from objvtassuc where Sucursal = #{params[:id]} and Mes = #{DateTime.now.strftime('%Y%m')} order by sucursal "
      @encargado =  @dbPdv.connection.select_all(sql).first
    rescue Exception => exc
      redirect_to controller: "reporte_sucursales", action: "index", notice: "Sucursal y/o vendedor sin objetivos"
    end
    begin
      sql = "select * from catcomisionistas where FechaTerm = ''"
      @employees =  @dbPdv.connection.select_all(sql)
    rescue Exception => exc
      redirect_to controller: "reporte_sucursales", action: "index", notice: "Sucursal y/o vendedor sin objetivos"
    end
  	begin
  		sql = "select Num_suc, Nombre from sucursal "
    	@sucs = @dbComun.connection.select_all(sql)
    rescue Exception => exc
    	redirect_to controller: "reporte_sucursales", action: "index", notice: "Sucursal y/o vendedor sin objetivos"
    end
    begin
    	sql = "select IdVendedor, Nombre from vendedores "
    	@vends = @dbComun.connection.select_all(sql)
    rescue Exception => exc
    	redirect_to controller: "reporte_sucursales", action: "index", notice: "Sucursal y/o vendedor sin objetivos"
		end
		if @sucursal[0].nil? == true
			redirect_to controller: "reporte_sucursales", action: "index", notice: "Sucursal y/o vendedor sin objetivos"
		end
  end
end
