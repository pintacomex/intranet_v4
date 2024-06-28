module Supervisiones::ChecklistsHelper

  def getSubTipoSuc(i)
    return @subtiposucs.select { |item|  item[1] == "#{i}" }.first[0] rescue "No encontrado"
  end

end
