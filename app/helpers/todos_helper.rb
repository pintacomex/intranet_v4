module TodosHelper

  def getPrioridad(i)
    return @prioridades.select { |item|  item[1] == i }.first[0] rescue "No encontrada"
  end

  def getStatus(i)
    return @status.select { |item|  item[1] == i }.first[0] rescue "No encontrado"
  end

  def getUser(i, d = "No encontrado")
    return @users.select { |item|  item[1] == "#{i}" }.first[0] rescue d
  end

  def getEmail(i)
    return @emails.select { |item|  item[1] == "#{i}" }.first[0] rescue "No encontrado"
  end

  def getTipo(i)
    return @tipos.select { |item|  item[1] == i }.first[0] rescue "No encontrado"
  end

  def getSucursal(i)
    return @sucursales.select { |item|  item[1] == "#{i}" }.first[0] rescue "No encontrada"
  end

  def sanitize_link(l)
    return l.to_s.downcase.gsub(" ", "_")
  end

end
