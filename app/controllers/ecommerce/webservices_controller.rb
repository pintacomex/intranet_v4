class Ecommerce::WebservicesController < ApplicationController
  before_filter :authenticate_user!
  before_filter :admin_only
  before_filter :find_pedido, only: [:show]

  def index
    sql = "SELECT wsContextusPedidos.* FROM wsContextusPedidos ORDER BY updated_at DESC LIMIT 500"
    @pedidos = @dbVentasonline.connection.select_all(sql)
  end

  def show
  end
  # CREATE TABLE `wsContextusPedidos` (
  #   `operacion` varchar(20) NOT NULL DEFAULT '',
  #   `idPedido` varchar(20) NOT NULL DEFAULT '',
  #   `request` text,
  #   `status` int(4) NOT NULL DEFAULT '0',
  #   `created_at` datetime NOT NULL,
  #   `updated_at` datetime NOT NULL
  # ) ENGINE=InnoDB DEFAULT CHARSET=latin1;
  # TBD:
  # Robot

  private

  def find_pedido
    @id = params[:idPedido].to_s
    sql = "SELECT wsContextusPedidos.* FROM wsContextusPedidos WHERE idPedido = #{User.sanitize(@id)} ORDER BY created_at DESC LIMIT 1"
    @pedido = @dbVentasonline.connection.select_all(sql).first rescue false
    return redirect_to '/', alert: 'Pedido no encontrado' unless @pedido
  end
end
