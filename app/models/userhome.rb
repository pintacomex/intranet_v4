class Userhome < ActiveRecord::Base
	validates :user_id, uniqueness: true
	attr_accessible :user_id, :id_token ,:fecha_start
end
