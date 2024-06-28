module MedidoresHelper
  def get_tipo_medidor(i)
    return @tipos.select { |item|  item[1] == i }.first[0] rescue "No encontrado"
  end

  def get_activado_medidor(i)
    return @activados.select { |item|  item[1] == i }.first[0] rescue "No encontrado"
  end
end
