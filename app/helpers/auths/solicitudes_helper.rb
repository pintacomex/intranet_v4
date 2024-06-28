module Auths::SolicitudesHelper
  def get_usuario(i, d = "No encontrado")
    return @usuarios.select { |item|  item[1] == "#{i}" }.first[0] rescue d
  end

  def get_tipo_solicitud(i)
    return @tipo_solicitudes.select { |item|  item[1] == i.to_s }.first[0] rescue "No encontrado"
  end

  def get_nivel(i)
    return @niveles.select { |item|  item[1] == i.to_s }.first[0] rescue "No encontrado"
  end

  def get_email(i)
    return @emails.select { |item|  item[1] == "#{i}" }.first[0] rescue "No encontrado"
  end
end
