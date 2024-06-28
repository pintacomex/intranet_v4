json.array!(@webservices_auths) do |webservices_auth|
  json.extract! webservices_auth, :id, :sucursal, :descripcion, :respuesta, :status, :fechaHora
  json.url webservices_auth_url(webservices_auth, format: :json)
end
