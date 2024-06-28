class Ecommerce::PedidosController < ApplicationController
  before_filter :authenticate_user!
  before_filter :tiene_permiso_de_ver_app
  before_filter :obtiene_catalogos
  before_filter :find_pedido, only: [:show, :asignar_sucursal, :cambiar_status]
  before_filter :obtiene_permisos, only: [:show, :asignar_sucursal, :cambiar_status]

  def index
    get_filtros_from_user
    @id = params[:id].to_s if params.has_key?(:id)
    if @id and @id != ""
      @filtros.push("hpedidos.IdPedido = #{User.sanitize(@id)}")
    else
      @ver_todos = params[:ver_todos].to_i if params.has_key?(:ver_todos)
      @filtros.push("hpedidos.idStatusPedido <= 3") unless @ver_todos
      @fuente = params[:fuente].to_i if params.has_key?(:fuente) and params[:fuente].to_i > 0
      @filtros.push("hpedidos.IdEcommerce = #{@fuente}") if @fuente
      @sucursal_asignada = -1
      @sucursal_asignada = params[:sucursal_asignada].to_i if params.has_key?(:sucursal_asignada)
      @filtros.push("hpedidos.SucursalAsignada = #{@sucursal_asignada}") if @sucursal_asignada >= 0
    end
    # sql = "SELECT hpedidos.* FROM hpedidos WHERE ( ( #{@filtros.join(" ) AND ( ")} ) ) ORDER BY FechaPedido DESC, HoraPedido DESC LIMIT 500"
    sql = "SELECT hpedidos.* FROM hpedidos WHERE ( ( #{@filtros.join(" ) AND ( ")} ) ) ORDER BY FechaPedido DESC, HoraPedido DESC LIMIT 500"
    @pedidos = @dbVentasonline.connection.select_all(sql)
  end

  def show
  end

  def asignar_sucursal
    url = "/ecommerce/pedidos/#{@id.first}-#{@id[1]}"
    @sucursal = params[:SucursalAsignada].to_i if params.has_key?(:SucursalAsignada)
    return redirect_to url, alert: "No autorizado" if !@sucursal || !@puede_asignar_sucursal

    sql = "UPDATE hpedidos SET SucursalAsignada = #{User.sanitize(@sucursal)}, idStatusPedido = 1, idUserUltAct = #{current_user.id} WHERE idEcommerce = #{User.sanitize(@id.first)} AND idPedido = #{User.sanitize(@id[1])}"
    begin
      @dbVentasonline.connection.execute(sql)
    rescue Exception => exc
      return redirect_to url, alert: "No se ha podido asignar la sucursal"
    end
    return redirect_to url, notice: "Sucursal asignada exitosamente"
  end

  def cambiar_status
    url = "/ecommerce/pedidos/#{@id.first}-#{@id[1]}"
    @status = params[:idStatusEcommerce].to_i if params.has_key?(:idStatusEcommerce)
    @observaciones = params[:observaciones] if params.has_key?(:observaciones)
    return redirect_to url, alert: "No autorizado" if !@status || !@puede_cambiar_status
    return redirect_to url, alert: "Es necesario agregar observacion para cancelar" if @observaciones && @observaciones == '' && @status == 5

    observacion_update = ""
    observacion_update = ", Observaciones = #{User.sanitize(@observaciones)}" if @observaciones && @status == 5

    sql = "UPDATE hpedidos SET idStatusPedido = #{User.sanitize(@status)}#{observacion_update}, idUserUltAct = #{current_user.id} WHERE idEcommerce = #{User.sanitize(@id.first)} AND idPedido = #{User.sanitize(@id[1])}"
    begin
      @dbVentasonline.connection.execute(sql)
    rescue Exception => exc
      return redirect_to url, alert: "No se ha podido cambiar el status"
    end
    return redirect_to url, notice: "Status guardado exitosamente"
  end

  private

    def find_pedido
      @id = params[:id].to_s.split("-")
      get_filtros_from_user
      sql = "SELECT hpedidos.* FROM hpedidos WHERE ( ( #{@filtros.join(" ) AND ( ")} ) ) AND idEcommerce = #{User.sanitize(@id.first)} AND idPedido = #{User.sanitize(@id[1])} LIMIT 1"
      @pedido = @dbVentasonline.connection.select_all(sql).first rescue false
      return redirect_to '/', alert: 'Pedido no encontrado' unless @pedido
      sql = "SELECT dpedidos.* FROM dpedidos WHERE idEcommerce = #{User.sanitize(@id.first)} AND idPedido = #{User.sanitize(@id[1])} ORDER BY idRenglon"
      @detallesPedido = @dbVentasonline.connection.select_all(sql) rescue false
      return redirect_to '/', alert: 'Detalle de pedido no encontrado' unless @detallesPedido
    end

    def obtiene_catalogos
      @fuentes = @dbVentasonline.connection.select_all("SELECT * FROM catEcommerce ORDER BY idEcommerce").map{|u| [u['Ecommerce'], "#{u['idEcommerce']}"]}.uniq rescue []
      @idStatusEcommerce = @dbVentasonline.connection.select_all("SELECT * FROM catstatuspedido ORDER BY idStatusPedido").map{|u| [u['StatusPedido'], "#{u['idStatusPedido']}"]}.uniq rescue []
      # raise @idStatusEcommerce.inspect
      @statusPago = [["Por Pagar", "0"], ["Validando", "1"], ["Pagado", "2"]]
      @sucursales = @dbComun.connection.select_all("SELECT * FROM sucursal WHERE TipoSuc = 'S' AND subTipoSuc in ('S', 'O') AND FechaTerm = '' ORDER BY Nombre").map{|u| ["#{u['Nombre']}", "#{u['Num_suc']}"]}.unshift(["No asignada", 0]).uniq rescue []
      @usuarios = User.joins("LEFT JOIN permisos ON users.id = permisos.idUsuario").where("permisos.id > 0").order(:name).map{|u| ["#{u.name.to_s.gsub(" - ", " ")}", "#{u.id}"]}.uniq
    end

    def obtiene_permisos
      #       Cambio de status (para la Cuenta de Administrador):
      # Si el status es... --> solo puede cambiarse a ...
      # 6 Validando Pago  --> Cancelado, Nuevo
      # 0 Nuevo     --> Cancelado
      # 5 Cancelado --> Nuevo
      # 1 Asignado  --> Rechazado, Vendido, Cancelado
      # 2 Rechazado --> Cancelado
      # 3 Vendido   --> Entregado, Cancelado
      # 4 Entregado --> Vendido
      # Cambio de status (para la Cuenta de Encargado):
      # Si el status es... --> solo puede cambiarse a ...
      # 6 Validando Pago  -->  No puede cambiarlo
      # 0 Nuevo     --> No puede cambiarlo
      # 5 Cancelado --> No puede cambiarlo
      # 1 Asignado  --> Rechazado, Vendido, Cancelado
      # 2 Rechazado --> No puede cambiarlo
      # 3 Vendido   --> Entregado
      # 4 Entregado --> Vendido
      @puede_cambiar_status = (get_current_user_app_nivel == 2 || get_current_user_app_nivel == 3 || current_user.has_role?(:admin))
      @puede_asignar_sucursal = ((get_current_user_app_nivel == 3 || current_user.has_role?(:admin)) && (@pedido['idStatusPedido'].to_i == 0 || @pedido['idStatusPedido'].to_i == 1 || @pedido['idStatusPedido'].to_i == 2 ))
      @nuevosStatus = []
      if @puede_cambiar_status
        catStatusPedidos = @dbVentasonline.connection.select_all("SELECT * FROM catstatuspedido ORDER BY idStatusPedido")
        catStatusPedidos.each do |status|
          if get_current_user_app_nivel == 2
            next if @pedido['idStatusPedido'].to_i == 0
            next if @pedido['idStatusPedido'].to_i == 1 && (status['idStatusPedido'].to_i != 2 && status['idStatusPedido'].to_i != 3 && status['idStatusPedido'].to_i != 5)
            next if @pedido['idStatusPedido'].to_i == 2
            next if @pedido['idStatusPedido'].to_i == 3 && (status['idStatusPedido'].to_i != 4)
            next if @pedido['idStatusPedido'].to_i == 4 && (status['idStatusPedido'].to_i != 3)
            next if @pedido['idStatusPedido'].to_i == 5
            next if @pedido['idStatusPedido'].to_i == 6
          end
          if get_current_user_app_nivel == 3 || current_user.has_role?(:admin)
            next if @pedido['idStatusPedido'].to_i == 0 && (status['idStatusPedido'].to_i != 5)
            next if @pedido['idStatusPedido'].to_i == 1 && (status['idStatusPedido'].to_i != 2 && status['idStatusPedido'].to_i != 3 && status['idStatusPedido'].to_i != 5)
            next if @pedido['idStatusPedido'].to_i == 2 && (status['idStatusPedido'].to_i != 5)
            next if @pedido['idStatusPedido'].to_i == 3 && (status['idStatusPedido'].to_i != 4 && status['idStatusPedido'].to_i != 5)
            next if @pedido['idStatusPedido'].to_i == 4 && (status['idStatusPedido'].to_i != 3)
            next if @pedido['idStatusPedido'].to_i == 5 && (status['idStatusPedido'].to_i != 0)
            next if @pedido['idStatusPedido'].to_i == 6 && (status['idStatusPedido'].to_i != 5 && status['idStatusPedido'].to_i != 0)
          end
          @nuevosStatus << [status['StatusPedido'], "#{status['idStatusPedido']}"]
        end
      end
    end

    def get_filtros_from_user
      @filtros = []
      @filtros.push("1")
      return if current_user.has_role?(:admin)

      # @puede_ver_sucursales = true
      @permiso = Permiso.joins("LEFT JOIN cat_roles ON permisos.permiso = cat_roles.nomPermiso").where("idUsuario = #{current_user.id} AND p1 = #{@sitio[0].idEmpresa.to_i}").order("cat_roles.nivel").limit(1)
      if @permiso && @permiso.count == 1
        if @permiso[0].p3 != "" && @permiso[0].p3 != "0"
          sucs = @permiso[0].p3.to_s.split(',').map{|i| i.to_i}.sort
          @filtros.push("hpedidos.SucursalAsignada = #{sucs.join(" OR hpedidos.SucursalAsignada = ")}") if sucs.count > 0
          # @puede_ver_sucursales = false
        end
      else
        return redirect_to "/", alert: "No autorizado"
      end
    end
end
