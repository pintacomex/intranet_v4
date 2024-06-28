class Api::V1::WelcomeController < Api::V1::BaseController
  acts_as_token_authentication_handler_for User, only: [:auth_alive]

  def alive
    render(
      json: {alive: true}.to_json,
      status: 200
    )
  end

  def auth_alive
  	# obj = current_user
    render(
      json: {alive: true, sitio: @sitio[0].idEmpresa.to_i}.to_json,
      status: 200
    )
  end

end
