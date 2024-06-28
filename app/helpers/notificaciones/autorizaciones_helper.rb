module Notificaciones::AutorizacionesHelper

  def getStatus(i)
    return @status.select { |item|  item[1] == i }.first[0] rescue "No encontrado"
  end

end
