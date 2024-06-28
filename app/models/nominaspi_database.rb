class NominaspiDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "nominaspi"
end