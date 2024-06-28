class PdvadrahcaDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :pdvadrahca
end