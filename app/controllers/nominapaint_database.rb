class NominapaintDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "nominapaint"
end