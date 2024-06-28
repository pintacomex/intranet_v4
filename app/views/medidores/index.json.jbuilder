json.array!(@medidores) do |medidore|
  json.extract! medidore, :id, :tipo, :valor, :minimo, :maximo, :simbolo, :opciones, :activado, :roles
  json.url medidore_url(medidore, format: :json)
end
