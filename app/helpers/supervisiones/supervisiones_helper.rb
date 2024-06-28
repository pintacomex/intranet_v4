module Supervisiones::SupervisionesHelper

  def getTodos(i)
    return i.split(",").map{ |t| getTodo(t) }.join(" ")
  end

  def getTodo(i)
    return "<a href='/todos_show?id=#{i}'>##{i}</a>"
  end

  def getUser(i)
    return @users.select { |item|  item[1] == "#{i}" }.first[0] rescue "No encontrado"
  end

  def getEmail(i)
    return @emails.select { |item|  item[1] == "#{i}" }.first[0] rescue "No encontrado"
  end

end
