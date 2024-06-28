module Ecommerce::PedidosHelper
  def get_fuente(i)
    return @fuentes.select { |item|  item[1] == i.to_s }.first[0] rescue "No encontrado"
  end

  def get_sucursal(i)
    return "No asignada" if !i.to_i || i.to_i == 0
    return @sucursales.select { |item|  item[1] == i.to_s }.first[0] rescue "Sucursal #{i.to_s}"
  end

  def get_status_pedido(i)
    return @idStatusEcommerce.select { |item|  item[1] == i.to_s }.first[0] rescue "No encontrado"
  end

  def get_status_pago(i)
    return @statusPago.select { |item|  item[1] == i.to_s }.first[0] rescue "No encontrado"
  end

  def get_usuario(i, d = "No encontrado")
    return @usuarios.select { |item|  item[1] == "#{i}" }.first[0] rescue d
  end
end
