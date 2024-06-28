class VentasonlinepintaDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "ventasonlinepinta"
end