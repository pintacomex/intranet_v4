class NominaadrahcaDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "nominaadrahca"
end