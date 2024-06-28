class ChecadoresController < ApplicationController

  def enviar_chequeos
		#Llama al WS
		url = URI("http://nomiprime.com/WebServiceNp/ChecksFileLoader.asmx/PostRecords")
		http = Net::HTTP.new(url.host, url.port)
		request = Net::HTTP::Post.new(url)
		request["content-type"] = 'application/json'
		request["cache-control"] = 'no-cache'

		#Selec de chequeos mayores a la fecha del parametro
		

		sql = "select * from chequeos where EstatusEnvio = 0 and TipoEvento <= 4 order by FechaHora asc" 
		movs = @dbNomina.connection.select_all(sql)
		#'22/04/2019 02:18:00 p.m.'
		now = Time.now.to_s
		checks = ""
		if movs.length == 0
			render status: 200, json: { info: "No hay datos a enviar", status: 1 }
			return
		end

		username = "P1ntac0m3x"
		username = "5P1SOLUC1ON3S" if @sitio[0].baseFacEle == "facelespi"
		
		movs.each_with_index do |m, index|
			fecha = "\"#{m['FechaHora'].to_s[5..6]}/#{m['FechaHora'].to_s[8..9]}/#{m['FechaHora'].to_s[0..3]}\""
			hora = "\"#{m['FechaHora'].strftime("%I:%M:%S %p").to_s}\""
			date_now = now[8..9] + "/" + now[5..6] + "/" + now[0..3]
			if Date.parse("#{m['FechaHora'].to_s[8..9]}/#{m['FechaHora'].to_s[5..6]}/#{m['FechaHora'].to_s[0..3]}") <= Date.parse(date_now) 
				request.body = "{  \"checksFile\": {\"clave\": \"#{username}\", \"checks\": [{\"RegistryId\": #{m['id']}, \"CheckDate\": #{fecha}, \"CheckTime\": #{hora}, \"EmployeeNumber\": \"#{m['IdEmpleado']}\", \"CheckerId\": \"#{m['CheckerId']}\",\"EventType\": #{m['TipoEvento']}}]}}"
				JSON.parse request.body
				response = http.request(request)
				p response.read_body
				if response.read_body.include?("error") || !response.read_body.include?("true")
					sql = "update chequeos set EstatusEnvio = 2, ErrDescrip = '#{response.read_body}' where id = #{m['id']} " 
					@dbNomina.connection.execute(sql)	
				else 					
					sql = "update chequeos set EstatusEnvio = 1 where id = #{m['id']} " 
					@dbNomina.connection.execute(sql)	
				end
			end
		end
    render status: 200, json: { info: "Se enviaron los datos al WS satisfactioramente", status: 1 }
    return
  end

  def index
  end
end
