json.array!(@app_nivels) do |app_nivel|
  json.extract! app_nivel, :id, :app, :nivel, :descripcion
  json.url app_nivel_url(app_nivel, format: :json)
end
