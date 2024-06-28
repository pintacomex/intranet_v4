class NominapintaDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "nominapinta"
end