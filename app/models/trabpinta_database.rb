class TrabpintaDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "trabpinta"
end