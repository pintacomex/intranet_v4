class VentasonlineDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "ventasonline"
end