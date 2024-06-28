class PushToken < ActiveRecord::Base
	attr_accessible :user_id, :push_token, :deviceId, :deviceName

	belongs_to :user
end
