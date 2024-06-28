class Calificacionreporte < ActiveRecord::Base
	attr_accessible :fecha, :user_id, :rating
	validates :fecha, :user_id, :rating,  presence: true 
end
