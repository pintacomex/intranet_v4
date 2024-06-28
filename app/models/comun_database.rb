class ComunDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "comun"
end