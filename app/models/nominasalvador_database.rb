class NominasalvadorDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "nominasalvador"
end