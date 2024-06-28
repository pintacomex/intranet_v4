module TicketsHelper

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

  def getTipoGrupo(i)
    return @grupos.select { |item|  item[1].to_i == i.to_i }.first[0] rescue "No encontrado"
  end

  def getSucursal(i)
    return @sucursales.select { |item|  item[1] == "#{i}" }.first[0] rescue "No encontrada"
  end

  def sanitize_link(l)
    return l.to_s.downcase.gsub(" ", "_")
  end

  def fecha_ticket_programado(ticket)
    if ticket['DiaDeMes'].to_i > 0
      "Día #{ticket['DiaDeMes']} del Mes"
    else
      "#{ticket['FechaProgramada']}"
    end
  end

  def dias_limite(ticket)
    if ticket['DiasFechaLimite'].to_i > 0
      "#{ticket['DiasFechaLimite']} Días"
    else
      "Ninguno"
    end
  end

  def fechas_futuras
    (Date.tomorrow..1.year.from_now.to_date).map{ |date| date.to_s[0..10] }
  end

  def fecha_o_dia_a_string(ticket)
    if ticket && ticket['DiaDeMes'].to_i > 0
      "DIA"
    else
      "FECHA"
    end
  end

  def fecha_o_dia_a_active(ticket, fecha_o_dia)
    if ticket && ticket['DiaDeMes'].to_i > 0
      "DIA" == fecha_o_dia.upcase ? "active" : ""
    else
      "FECHA" == fecha_o_dia.upcase ? "active" : ""
    end
  end
end
