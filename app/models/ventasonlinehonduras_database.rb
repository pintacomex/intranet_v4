class VentasonlinehondurasDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "ventasonlinehonduras"
end