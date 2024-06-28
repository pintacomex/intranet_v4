class FacelepintaDatabase < ActiveRecord::Base
  self.abstract_class = true
  establish_connection "facelepinta"
end