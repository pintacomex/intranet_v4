module AppNivelsHelper
  def get_app_nombre(i)
    return @apps.select { |item|  item[1] == i }.first[0] rescue "No encontrada"
  end
end
