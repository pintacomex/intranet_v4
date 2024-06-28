class Api::V1::SessionsController < Api::V1::BaseController
  # before_action :authenticate_user!, only: [:destroy, :push_token]
  acts_as_token_authentication_handler_for User, only: [:destroy, :push_token]

  def create
    auth = User.authenticate(create_params[:email], create_params[:password])
    if auth
      render(
        status: 201,
        json: {id: auth.id, email: auth.email, token: auth.authentication_token}
      )
    else
      return api_error(status: 401)
    end
  end

  def destroy
    current_user.authentication_token = ""
    if current_user.save
      render(json: {info: "Logout successful"}, status: 200)
    else
      return api_error(status: 500, errors: "Unable to logout")
    end
  end

  def push_token
    push_token = params[:push_token] if params.has_key?(:push_token)
    deviceId   = params[:deviceId] if params.has_key?(:deviceId)
    deviceName = params[:deviceName] if params.has_key?(:deviceName)
    if push_token
      # You can only have 1 push token per device
      PushToken.where(deviceId: deviceId).destroy_all if deviceId && deviceId != ""
      pt = PushToken.create(user_id: current_user.id, push_token: push_token, deviceId: deviceId, deviceName: deviceName).save 
      if pt
        render(json: {info: "Push token saved successfully"}, status: 200)
      else
        return api_error(status: 500, errors: "Unable to save push token")
      end
    else
      return api_error(status: 500, errors: "Push token not received")
    end
  end

  private
  def create_params
    params.require(:user).permit(:email, :password)
  end
end
