module HomeHelper
  def get_url(u)
  	# Esto es para regresar la url completa si es a http:// o https://
  	url = "/#{u}/"
  	url = u if u.to_s.include?("://")
    return url
  end
end
