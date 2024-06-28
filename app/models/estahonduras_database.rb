class EstahondurasDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "estahonduras"
end