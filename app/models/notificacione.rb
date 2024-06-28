class Notificacione < ActiveRecord::Base
  attr_accessible :tipo, :destinatario, :texto, :status, :deviceId
  
end
