class FacelepaintDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "facelepaint"
end