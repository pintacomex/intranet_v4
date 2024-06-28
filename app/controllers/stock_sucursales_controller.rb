class StockSucursalesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app

  include ActionView::Helpers::NumberHelper

  def stock_sucursales
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
    end
    if @permisos.count == 0
      return redirect_to "/", alert: "No autorizado"
    end

    if (user_permisos[:nivel] <= 10)
      if user_permisos[:escorrectazonaurl].to_i == 0
        params[:zona] = user_permisos[:primerzonaasig]
        @zona = params[:zona].to_s
      end
    else
      return redirect_to "/", alert: "No autorizado"
    end

    if params.has_key?(:procesar) && params[:procesar] == "1"
      sql = "call proc.StockEnSucursalesCompPinta(@x)"
      @dbEsta.connection.execute(sql)
    end

    sql = "SELECT Fechan as FechaProc,Nummovn as HoraProc, CONCAT(DATE(Fechan),' ',TIME(Nummovn)) as HoraTxt from #{@nomDbPdv}stockbmov where Sucursal = 0 "
    proceso = @dbEsta.connection.select_all(sql)
    @fechaProc = proceso[0]['FechaProc'].to_s
    @horaProc = proceso[0]['HoraProc'].to_s
    @horaTxt = proceso[0]['HoraTxt'].to_s

    cveant = "***"
    @cveant_r = ""
    continua = "1"

    if params.has_key?(:regreso) && params[:regreso] == "1"
      sql = "SELECT CveAnt,Clave FROM #{@nomDbPub}prodtree where Clave = '#{params[:cveant]}'"
      @regreso = @dbEsta.connection.select_all(sql)
      @cveant_r = @regreso[0]['CveAnt'] if (params[:cveant] != "" or params[:cveant] != "***")
      continua = "0" if @cveant_r == "***" or params[:cveant] == ""
    end

    if params.has_key?(:cveant) && continua == "1"
      cveant = params[:cveant] 
      cveant = @regreso[0]['CveAnt'] if params.has_key?(:regreso) && params[:regreso] == "1"
    end

    if params.has_key?(:cveant) && params[:cveant].to_s.length == 17 
      cveant = "***"
      @cveant_r = "***"
      sql = "SELECT CveAsoc,DescripLar,Clave from #{@nomDbPub}producto WHERE IdCanRefLista = 0 and Clave = '#{params[:cveant]}'"
      @productos = @dbEsta.connection.select_all(sql)
    end

    if params.has_key?(:q) && params[:q].to_s.length > 0 
      @sanitized = User.sanitize(params[:q])
      sql = "SELECT CveAsoc,DescripLar,Clave from #{@nomDbPub}producto "
      sql += "WHERE IdCanRefLista = 0 "
      sql += "and Clave not like '11%'"
      sql += "and Clave not like '70%'"
      sql += "and Clave not like '75%'"
      sql += "and Clave not like '80%'"
      sql += "and CveAsoc = '#{ @sanitized[1..-2] }'"
      @productos = @dbEsta.connection.select_all(sql)
      if @productos && @productos.count == 0
        sql = "SELECT CveAsoc,DescripLar,Clave from #{@nomDbPub}producto "
        sql += "WHERE IdCanRefLista = 0 "
        sql += "and Clave not like '11%'"
        sql += "and Clave not like '70%'"
        sql += "and Clave not like '75%'"
        sql += "and Clave not like '80%'"
        sql += "and DescripLar like '%#{ @sanitized[1..-2] }%' LIMIT 100"
        @productos = @dbEsta.connection.select_all(sql)
        if @productos && @productos.count == 0
          return redirect_to "/stock_sucursales", alert: "No existen producto con esa Clave ó Descripción"
        end
      end
    end

    sql = "SELECT CveAnt,Clave,Descp1,Descp2 FROM #{@nomDbPub}prodtree where IdCanRefLista = 0 and CveAnt = '#{cveant}' order by NumOrd"
    @prodtree = @dbEsta.connection.select_all(sql)

    sql = "SELECT NomZona FROM #{@nomDbComun}zonas where NumZona = #{@zona.to_i}"
    @zonaSel = @dbEsta.connection.select_all(sql)
    @nomZona = @zonaSel[0]['NomZona']

    respond_to do |format|
        format.html
    end        
  end

  def stock_sucursales_existencias
    @clave = params[:clave].to_s if params.has_key?(:clave) && params[:clave].to_s.length == 17
    @opc = params[:opc].to_s if params.has_key?(:opc)
    @zona = params[:zona].to_s if params.has_key?(:zona)
    @nomZona = params[:nomZona].to_s if params.has_key?(:nomZona)

    if @clave.to_i > 0
      sql = "SELECT (DATE_SUB(curdate(),INTERVAL 1 YEAR) + 0) as FechaIni,(DATE_SUB(FechaFin,INTERVAL 1 YEAR) + 0) as FechaFin,FechaIni as FechaIniTemp,FechaFin as FechaFinTemp,curdate() + 0 as FechaHoy from #{@nomDbComun}parampedido "
      fechas = @dbEsta.connection.select_all(sql)
      fechaIni = fechas[0]['FechaIni']
      fechaFin = fechas[0]['FechaFin']
      @fechaIniTemp = fechas[0]['FechaIniTemp']
      @fechaFinTemp = fechas[0]['FechaFinTemp']
      @fechaHoy = fechas[0]['FechaHoy']

      sql = "SELECT suc.ZonaAsig as Zona,s.Sucursal,suc.Nombre,s.Acordado,s.Teorico as Existencia,s.Teorico-s.acordado as Sobran,s.Temporada "
      sql +="from #{@nomDbPdv}stockb as s inner join #{@nomDbComun}sucursal as suc "
      sql +="on s.sucursal = suc.num_suc "
      sql +="where "
      sql +="s.clave = '#{@clave}'"
      if @zona.to_i > 0
        sql +="and suc.ZonaAsig = #{@zona.to_i} "
      end
      sql +="and (suc.TipoSuc = 'S' or suc.TipoSuc = 'B') "
      sql +="and suc.FechaTerm = '' "
      sql +="and suc.StockCero = 0 "
      sql +="order by suc.ZonaAsig,s.Sucursal"
      @acordado = @dbEsta.connection.select_all(sql)
    end
  end

  private 

    def get_filtros_from_user
        @filtros = []
        @filtros.push("1")
#        @permiso = Permiso.joins("LEFT JOIN cat_roles ON permisos.permiso = cat_roles.nomPermiso").where("idUsuario = #{current_user.id} AND p1 = #{@sitio[0].idEmpresa.to_i}").order("cat_roles.nivel").limit(1)
#        if @permiso && @permiso.count == 1
#            if @permiso[0].p2 != "" && @permiso[0].p2 != "0"
#                @zonas = @permiso[0].p2.to_s.split(',').map{|i| i.to_i}.sort
#                @filtros.push("Documentos.ZonaAsig = #{@zonas.join(" OR Documentos.ZonaAsig = ")}") if @zonas.count > 0
#            end
#            if @permiso[0].p3 != "" && @permiso[0].p3 != "0"
#                @sucursales = @permiso[0].p3.to_s.split(',').map{|i| i.to_i}.sort
#                @filtros.push("Sucursal = #{@sucursales.join(" OR Sucursal = ")}") if @sucursales.count > 0
#            end
#        else
#            return redirect_to "/", alert: "No autorizado"
#        end
        return @filtros
    end
end
