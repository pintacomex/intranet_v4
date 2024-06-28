class ReportesBiController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app
  before_filter :admin_only, only: [:reportes]

  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper
  include ApplicationHelper

  def index
    get_filtros_from_user
    if params.has_key?(:seccion)
      @seccion = params[:seccion]
      @filtros.append("seccion = #{User.sanitize(params[:seccion])}")
    end
    sql = "SELECT * from reportesBI WHERE rolPermitido >= #{@user_permisos[:nivel]} AND ( ( #{@filtros.join(" ) AND ( ")} ) ) order by seccion ASC, ordenVista ASC limit 500"
    @reportes = @dbEsta.connection.select_all(sql)
  end

  def reportes
    sql = "SELECT * from reportesBI order by seccion ASC, ordenVista ASC"
    @reportes = @dbEsta.connection.select_all(sql)
  end

  private

  def get_filtros_from_user
    @filtros = []
    @filtros.push("1")
    # return if current_user.has_role?(:admin)

    @permiso = Permiso.joins("LEFT JOIN cat_roles ON permisos.permiso = cat_roles.nomPermiso").where("idUsuario = #{current_user.id} AND p1 = #{@sitio[0].idEmpresa.to_i}").order("cat_roles.nivel").limit(1)
    if @permiso && @permiso.count == 1
      # if @permiso[0].p3 != "" && @permiso[0].p3 != "0"
      #   sucs = @permiso[0].p3.to_s.split(',').map{|i| i.to_i}.sort
      #   @filtros.push("hpedidos.SucursalAsignada = #{sucs.join(" OR hpedidos.SucursalAsignada = ")}") if sucs.count > 0
      # end
    else
      return redirect_to "/", alert: "No autorizado"
    end
  end
end
