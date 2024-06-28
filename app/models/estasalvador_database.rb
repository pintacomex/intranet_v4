class EstasalvadorDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :estasalvador
end