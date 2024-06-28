class PdvsalvadorDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection 'pdvsalvador'
end