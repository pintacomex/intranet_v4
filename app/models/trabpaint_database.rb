class TrabpaintDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "trabpaint"
end