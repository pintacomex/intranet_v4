class PdvDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "pdv"
end