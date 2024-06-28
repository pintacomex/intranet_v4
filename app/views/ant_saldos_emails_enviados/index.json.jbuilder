json.array!(@ant_saldos_emails_enviados) do |ant_saldos_emails_enviado|
  json.extract! ant_saldos_emails_enviado, :id, :email, :fecha
  json.url ant_saldos_emails_enviado_url(ant_saldos_emails_enviado, format: :json)
end
