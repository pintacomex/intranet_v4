class FacelegallcoDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :facelegallco
end
