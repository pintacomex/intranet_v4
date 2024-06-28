class FaceleadrahcaDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :faceleadrahca
end