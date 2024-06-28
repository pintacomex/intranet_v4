class EstabeliceDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "estabelice"
end