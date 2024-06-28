class TrabadrahcaDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :trabadrahca
end