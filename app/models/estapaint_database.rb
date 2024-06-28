class EstapaintDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "estapaint"
end