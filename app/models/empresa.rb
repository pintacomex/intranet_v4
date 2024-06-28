class Empresa < ActiveRecord::Base
  attr_accessible :email, :idEmpresa, :idRfc, :nombre, :privacidad
end
