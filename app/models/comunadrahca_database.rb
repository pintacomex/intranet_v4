class ComunadrahcaDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :comunadrahca
end