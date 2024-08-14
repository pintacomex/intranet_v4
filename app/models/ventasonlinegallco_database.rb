class VentasonlinegallcoDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "ventasonlinegallco"
end
