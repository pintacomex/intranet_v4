class VentasonlinesalvadorDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "ventasonlinesalvador"
end