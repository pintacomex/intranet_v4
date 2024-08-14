class NominagallcoDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "nominagallco"
end
