class EstagallcoDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :estagallco
end
