class LogUsuario < ActiveRecord::Base
	attr_accessible :id_user, :id_app, :accion, :descripcion, :created_at
	validates :id_user, :id_app, :created_at, presence: true 
end
