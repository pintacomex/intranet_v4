class NominabeliceDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "nominabelice"
end