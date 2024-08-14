class TrabgallcoDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :trabgallco
end
