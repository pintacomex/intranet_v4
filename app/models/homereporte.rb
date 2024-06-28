class Homereporte < ActiveRecord::Base
	attr_accessible :user_id, :fecha, :start, :finish, :descripcion
	validates :fecha, :descripcion, presence: true 
end
