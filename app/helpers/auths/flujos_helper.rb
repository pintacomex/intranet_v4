module Auths::FlujosHelper
  def get_tipo_solicitud(i)
    return @tipo_solicitudes.select { |item|  item[1] == i.to_s }.first[0] rescue "No encontrado"
  end

  def get_nivel(i)
    return @niveles.select { |item|  item[1] == i.to_s }.first[0] rescue "No encontrado"
  end
end
