class VentasonlinebeliceDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "ventasonlinebelice"
end