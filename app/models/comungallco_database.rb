class ComungallcoDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :comungallco
end
