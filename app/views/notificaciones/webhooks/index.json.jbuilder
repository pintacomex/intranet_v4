json.array!(@webhooks) do |webhook|
  json.extract! webhook, :id, :name, :value
  json.url webhook_url(webhook, format: :json)
end
