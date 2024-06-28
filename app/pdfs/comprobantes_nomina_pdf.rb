#!/bin/env ruby
# encoding: utf-8
class ComprobantesNominaPdf < Prawn::Document
	include ActionView::Helpers::NumberHelper
	include ActionView::Helpers::TextHelper

	def initialize(hrecibo)
		require "prawn/measurement_extensions"
		super(page_size: "LETTER", margin: 1)
		font "Helvetica"
		font_size 12

        doc = Nokogiri.XML(hrecibo['ContXML'])

        version = "1.1"
        version = doc.xpath("//cfdi:Complemento").children[0].attribute("Version").value rescue "1.1"
        version_cfdi = doc.xpath("//cfdi:Comprobante").attribute("Version").value rescue "3.2"

	    place_image('Top',7.5,36,198,12)
	    place_image('Middle',7.5,70,199.31,100)
        place_image('Bottom',7.9,187.2,199.81,82.91)

        empNombre = "#{doc.xpath("//cfdi:Emisor").attribute("nombre").value rescue ""}" 
        empNombre = "#{doc.xpath("//cfdi:Emisor").attribute("Nombre").value rescue ""}" if version_cfdi == "3.3"
        empRFC    = "#{doc.xpath("//cfdi:Emisor").attribute("rfc").value rescue ""}"
        empRFC    = "#{doc.xpath("//cfdi:Emisor").attribute("Rfc").value rescue ""}" if version_cfdi == "3.3"

        if version == "1.1"


	        sucDir1 = "#{doc.xpath("//cfdi:Emisor").children[1].attribute("calle").value rescue ""} #{doc.xpath("//cfdi:Emisor").children[1].attribute("noExterior").value rescue ""} #{doc.xpath("//cfdi:Emisor").children[1].attribute("noInterior").value rescue ""}"
	        sucDir2 = "#{doc.xpath("//cfdi:Emisor").children[1].attribute("colonia").value rescue ""}"
	        sucDir3 = "#{doc.xpath("//cfdi:Emisor").children[1].attribute("localidad").value rescue ""}, #{doc.xpath("//cfdi:Emisor").children[1].attribute("estado").value rescue ""}"
			codigoPostalExpedidoEn = "#{doc.xpath("//cfdi:Emisor").children[1].attribute("codigoPostal").value rescue ""}"
	        sucTel = hrecibo['SucTel']

	        if sucDir1.length < 25
	          sucDir1 = "#{sucDir1} CP #{codigoPostalExpedidoEn}"
	        elsif sucDir2.length < 25
	          sucDir2 = "#{sucDir2} CP #{codigoPostalExpedidoEn}"
	        elsif sucTel.length < 25
	          sucTel = "CP #{codigoPostalExpedidoEn} #{sucTel}"
	        elsif sucDir3.length < 25
	          sucDir3 = "#{sucDir3} CP #{codigoPostalExpedidoEn}"
	        end

			place_text("Expedido en:",11,16.5,7,52,3,"","C")
	    	place_text("#{sucDir1}\n#{sucDir2}\n#{sucDir3}",3,19.8,7,68,3.2,"","C")

	        empDir1   = "#{doc.xpath("//cfdi:Emisor").children[0].attribute("calle").value rescue ""} #{doc.xpath("//cfdi:Emisor").children[0].attribute("noExterior").value rescue ""} #{doc.xpath("//cfdi:Emisor").children[0].attribute("noInterior").value rescue ""}"
	        empDir2   = "#{doc.xpath("//cfdi:Emisor").children[0].attribute("colonia").value rescue ""}"
	        empDir3   = "C.P. #{doc.xpath("//cfdi:Emisor").children[0].attribute("codigoPostal").value rescue ""}"
	        empDir4   = "#{doc.xpath("//cfdi:Emisor").children[0].attribute("municipio").value rescue ""}, #{doc.xpath("//cfdi:Emisor").children[0].attribute("estado").value rescue ""} - MEXICO"

	    	place_text("#{empNombre}",47,8,11,119,3,"B","C")
			place_text("RFC: #{empRFC}\n#{empDir1}\n#{empDir2}\n#{empDir3}\n#{empDir4}",73,13,8,65,3.5,"","C")

	        regimen = "#{doc.xpath("//cfdi:Emisor").children[2].attribute("Regimen").value rescue ""}"
	        regimen = "#{doc.xpath("//cfdi:Emisor").attribute("RegimenFiscal").value rescue ""}" if version_cfdi == "3.3"

			place_text("Regimen Fiscal:",64,32,7,50,3,"B","")
			place_text("#{regimen}",84,32,7,50,3,"","")    

			numEmpleado = doc.xpath("//cfdi:Complemento").children[0].attribute("NumEmpleado").value rescue ""
			razonSocial = doc.xpath("//cfdi:Receptor").attribute("nombre").value rescue ""
			razonSocial = doc.xpath("//cfdi:Receptor").attribute("Nombre").value rescue "" if version_cfdi == "3.3"
			rfc         = doc.xpath("//cfdi:Receptor").attribute("rfc").value rescue ""
			rfc         = doc.xpath("//cfdi:Receptor").attribute("Rfc").value rescue "" if version_cfdi == "3.3"
			numSeguridadSocial = doc.xpath("//cfdi:Complemento").children[0].attribute("NumSeguridadSocial").value rescue ""
			departamento = hrecibo['NumDepto']
			puesto = doc.xpath("//cfdi:Complemento").children[0].attribute("Puesto").value rescue ""
			salarioDiarioIntegrado = doc.xpath("//cfdi:Complemento").children[0].attribute("SalarioDiarioIntegrado").value rescue ""
			numPeriodo = hrecibo['NumPeriodo'].to_s
			fechaInicialPago = doc.xpath("//cfdi:Complemento").children[0].attribute("FechaInicialPago").value rescue ""
			fechaFinalPago = doc.xpath("//cfdi:Complemento").children[0].attribute("FechaFinalPago").value rescue ""
			fechaPago = doc.xpath("//cfdi:Complemento").children[0].attribute("FechaPago").value rescue ""
			formaDePago = doc.xpath("//cfdi:Comprobante").attribute("formaDePago").value rescue ""
			formaDePago = doc.xpath("//cfdi:Comprobante").attribute("MetodoPago").value rescue "" if version_cfdi == "3.3"
			fechaDeExhibicion = doc.xpath("//cfdi:Comprobante").attribute("fecha").value rescue ""
			fechaDeExhibicion = doc.xpath("//cfdi:Comprobante").attribute("Fecha").value rescue "" if version_cfdi == "3.3"

			met_pago = "Pago en una sola exhibición"
			met_pago = "Pago en parcialidades o diferido" if formaDePago == "PPD"

	    	place_text("#{numEmpleado != "" ? "Num: #{numEmpleado}  " : ""}#{razonSocial}",11,43.7,8,170,4.9,'','')
	    	place_text("R.F.C.: #{rfc}",11,47.7,8,170,4.9,'','')
	    	place_text("Reg. Imss: #{numSeguridadSocial}",11,51.7,8,170,4.9,'','')
	    	place_text("Departamento: #{departamento}",11,55.7,8,170,4.9,'','')
	    	place_text("Puesto: #{puesto}",11,59.7,8,170,4.9,'','')
	    	place_text("Salario Diario: #{number_to_currency(salarioDiarioIntegrado, :locale => :mx, :precision => 2)}",110,43.7,8,170,4.9,'','')
	    	place_text("Periodo: #{numPeriodo} del #{fechaInicialPago} al #{fechaFinalPago}",110,47.7,8,170,4.9,'','')
	    	place_text("Fecha de Pago: #{fechaPago}",110,51.7,8,170,4.9,'','')
	    	place_text("#{formaDePago}  #{version_cfdi == '3.3' ? met_pago : ''}",110,55.7,8,170,4.9,'','')
	    	place_text("Fecha de Expedición: #{fechaDeExhibicion}",110,59.7,8,170,4.9,'','')

	    else

	    	# Nomina v1.2 no tiene datos de empresa o expedicion

	    	place_text("#{empNombre}",47,15,11,119,3,"B","C")
			place_text("RFC: #{empRFC}",73,20,8,65,3.5,"","C")

	        regimen = "#{doc.xpath("//cfdi:Emisor").children[2].attribute("Regimen").value rescue ""}"
	        regimen = "#{doc.xpath("//cfdi:Emisor").attribute("RegimenFiscal").value rescue ""}" if version_cfdi == "3.3"

			place_text("Regimen Fiscal:",64,32,7,50,3,"B","") if regimen != ""
			place_text("#{regimen}",84,32,7,50,3,"","")       if regimen != ""

			numEmpleado = doc.xpath("//cfdi:Complemento").children[0].children[1].attribute("NumEmpleado").value rescue ""
			razonSocial = doc.xpath("//cfdi:Receptor").attribute("nombre").value rescue ""
			razonSocial = doc.xpath("//cfdi:Receptor").attribute("Nombre").value rescue "" if version_cfdi == "3.3"
			rfc         = doc.xpath("//cfdi:Receptor").attribute("rfc").value rescue ""
			rfc         = doc.xpath("//cfdi:Receptor").attribute("Rfc").value rescue "" if version_cfdi == "3.3"
			numSeguridadSocial = doc.xpath("//cfdi:Complemento").children[0].children[1].attribute("NumSeguridadSocial").value rescue ""
			departamento = hrecibo['NumDepto']
			puesto = doc.xpath("//cfdi:Complemento").children[0].children[1].attribute("Puesto").value rescue ""
			salarioDiarioIntegrado = doc.xpath("//cfdi:Complemento").children[0].children[1].attribute("SalarioDiarioIntegrado").value rescue ""
			numPeriodo = hrecibo['NumPeriodo'].to_s
			fechaInicialPago = doc.xpath("//cfdi:Complemento").children[0].attribute("FechaInicialPago").value rescue ""
			fechaFinalPago = doc.xpath("//cfdi:Complemento").children[0].attribute("FechaFinalPago").value rescue ""
			fechaPago = doc.xpath("//cfdi:Complemento").children[0].attribute("FechaPago").value rescue ""
			formaDePago = doc.xpath("//cfdi:Comprobante").attribute("formaDePago").value rescue ""
			formaDePago = doc.xpath("//cfdi:Comprobante").attribute("MetodoPago").value rescue "" if version_cfdi == "3.3"
			fechaDeExhibicion = doc.xpath("//cfdi:Comprobante").attribute("fecha").value rescue ""
			fechaDeExhibicion = doc.xpath("//cfdi:Comprobante").attribute("Fecha").value rescue "" if version_cfdi == "3.3"

			met_pago = "Pago en una sola exhibición"
			met_pago = "Pago en parcialidades o diferido" if formaDePago == "PPD"

	    	place_text("#{numEmpleado != "" ? "Num: #{numEmpleado}  " : ""}#{razonSocial}",11,43.7,8,170,4.9,'','')
	    	place_text("R.F.C.: #{rfc}",11,47.7,8,170,4.9,'','')
	    	place_text("Reg. Imss: #{numSeguridadSocial}",11,51.7,8,170,4.9,'','')
	    	place_text("Departamento: #{departamento}",11,55.7,8,170,4.9,'','')
	    	place_text("Puesto: #{puesto}",11,59.7,8,170,4.9,'','')
	    	place_text("Salario Diario: #{number_to_currency(salarioDiarioIntegrado, :locale => :mx, :precision => 2)}",110,43.7,8,170,4.9,'','')
	    	place_text("Periodo: #{numPeriodo} del #{fechaInicialPago} al #{fechaFinalPago}",110,47.7,8,170,4.9,'','')
	    	place_text("Fecha de Pago: #{fechaPago}",110,51.7,8,170,4.9,'','')
	    	place_text("#{formaDePago}  #{version_cfdi == '3.3' ? met_pago : ''}",110,55.7,8,170,4.9,'','')
	    	place_text("Fecha de Expedición: #{fechaDeExhibicion}",110,59.7,8,170,4.9,'','')

	    end

    	numCert   = doc.xpath("//cfdi:Comprobante").attribute("noCertificado").value rescue ""
    	numCert   = doc.xpath("//cfdi:Comprobante").attribute("NoCertificado").value rescue "" if version_cfdi == "3.3"
    	tiCertSAT = doc.xpath("//cfdi:Complemento").children[1].attribute("noCertificadoSAT").value rescue ""
    	tiCertSAT = doc.xpath("//cfdi:Complemento").children[1].attribute("NoCertificadoSAT").value rescue "" if version_cfdi == "3.3"
    	tiFecha   = doc.xpath("//cfdi:Complemento").children[1].attribute("FechaTimbrado").value rescue ""
    	tiUuid    = doc.xpath("//cfdi:Complemento").children[1].attribute("UUID").value rescue ""
    	tiSellCFD = doc.xpath("//cfdi:Complemento").children[1].attribute("selloCFD").value rescue ""
    	tiSellCFD = doc.xpath("//cfdi:Complemento").children[1].attribute("SelloCFD").value rescue "" if version_cfdi == "3.3"
    	tiSellSAT = doc.xpath("//cfdi:Complemento").children[1].attribute("selloSAT").value rescue ""
    	tiSellSAT = doc.xpath("//cfdi:Complemento").children[1].attribute("SelloSAT").value rescue ""  if version_cfdi == "3.3"

        place_text("#{numCert}\n#{tiCertSAT}\n#{tiFecha}",141,203.5,7,80,4.4,'','',4.5)
        place_text("#{tiUuid}",111,217.4,7,80,4.4,'','')
        place_text("#{tiSellCFD}",56.3,225.1,6,150,2.9,'','')
        place_text("#{tiSellSAT}",56.3,236.1,6,150,2.9,'','')
        place_text("#{hrecibo['Ti_Cadena']}",56.3,248.5,6,150,2.4,'','')
		
		place_barcode(hrecibo['CBBInfo'],11,208,3,3)

	    i    = 0
	    irow = 0

	    v_offset = 0
	    v_offset = 2 if version != "1.1"

	    percepciones_arr = doc.xpath("//cfdi:Complemento").children[0].children[0 + v_offset].children rescue []
		percepciones_arr.each do |percepciones|
			
			next if percepciones.inspect.include?("Nokogiri::XML::Text") # A veces en el CFD pone textos raros

	        y = 80.1 + (i * 3.8)

			clave = percepciones.attribute("Clave").value rescue ""
			concepto = percepciones.attribute("Concepto").value rescue ""
			importe = percepciones.attribute("ImporteGravado").value rescue 0
			exento = percepciones.attribute("ImporteExento").value rescue 0
			percepcion_total = importe.to_f + exento.to_f rescue 0

			place_text(clave,9,y,8,11,2,'','C')
			place_text(concepto,23,y,8,40,2,'','L')
		    place_text("#{number_to_currency(percepcion_total, :locale => :mx, :precision => 2)}",73,y,8,28,5,'','R') if percepcion_total != 0

		    i = i + 1

		end

		if version == "1.1"

			totalPercepciones = doc.xpath("//cfdi:Complemento").children[0].children[0 + v_offset].attribute("TotalGravado").value rescue 0
			totalExento = doc.xpath("//cfdi:Complemento").children[0].children[0 + v_offset].attribute("TotalExento").value rescue 0
			percepciones_total = totalPercepciones.to_f + totalExento.to_f rescue 0

			place_text("#{number_to_currency(percepciones_total, :locale => :mx, :precision => 2)}",73,135,8,28,5,'','R') if percepciones_total != 0

		else

			otras_percepciones = 0.0
		    otras_percepciones_arr = doc.xpath("//cfdi:Complemento").children[0].children[2 + v_offset].children rescue []
			otras_percepciones_arr.each do |percepciones|
				
				next if percepciones.inspect.include?("Nokogiri::XML::Text") # A veces en el CFD pone textos raros

		        y = 80.1 + (i * 3.8)

				clave = percepciones.attribute("Clave").value rescue ""
				concepto = percepciones.attribute("Concepto").value rescue ""
				importe = percepciones.attribute("Importe").value.to_f rescue 0

				place_text(clave,9,y,8,11,2,'','C')
				place_text(concepto,23,y,8,50,2,'','L',1.4)
				# Se salta una linea en caso de un concepto muy largo
				i = i + 1 if concepto.length >= 40
				i = i + 1 if concepto.length >= 80

			    place_text("#{number_to_currency(importe, :locale => :mx, :precision => 2)}",73,y,8,28,5,'','R') if importe != 0
			    otras_percepciones = otras_percepciones + importe

			    i = i + 1

			end

			totalPercepciones = doc.xpath("//cfdi:Complemento").children[0].children[0 + v_offset].attribute("TotalGravado").value rescue 0
			totalExento = doc.xpath("//cfdi:Complemento").children[0].children[0 + v_offset].attribute("TotalExento").value rescue 0
			percepciones_total = totalPercepciones.to_f + otras_percepciones.to_f + totalExento.to_f rescue 0

			place_text("#{number_to_currency(percepciones_total, :locale => :mx, :precision => 2)}",73,135,8,28,5,'','R') if percepciones_total != 0

		end

	    i    = 0
	    irow = 0
	    total_deducciones = 0

	    deducciones_arr = doc.xpath("//cfdi:Complemento").children[0].children[1 + v_offset].children rescue []
		deducciones_arr.each do |deducciones|
			
			next if deducciones.inspect.include?("Nokogiri::XML::Text") # A veces en el CFD pone textos raros

	        y = 80.1 + (i * 3.8)
			clave = deducciones.attribute("Clave").value rescue ""
			concepto = deducciones.attribute("Concepto").value rescue ""
			importe = deducciones.attribute("ImporteGravado").value rescue 0
			exento = deducciones.attribute("ImporteExento").value rescue 0
			deduccion_total = importe.to_f + exento.to_f rescue 0

			# La estructura de la deduccion cambia en v1.2
			deduccion_total = deducciones.attribute("Importe").value rescue 0 if version != "1.1"
			p "*" * 100
			p total_deducciones = total_deducciones + deduccion_total.to_f
			place_text(clave,109,y,8,11,2,'','C')
			place_text(concepto,123,y,8,40,2,'','L')
		    place_text("#{number_to_currency(deduccion_total, :locale => :mx, :precision => 2)}",174,y,8,28,5,'','R') if deduccion_total != 0

		    i = i + 1

		end		

		totalDeducciones = doc.xpath("//cfdi:Complemento").children[0].children[1 + v_offset].attribute("TotalGravado").value rescue 0
		totalExento = doc.xpath("//cfdi:Complemento").children[0].children[1 + v_offset].attribute("TotalExento").value rescue 0
		deducciones_total = totalDeducciones.to_f + totalExento.to_f rescue 0		

		deducciones_total = doc.xpath("//cfdi:Complemento").children[0].children[1 + v_offset].attribute("TotalOtrasDeducciones").value rescue 0 if version != "1.1"

		place_text("#{number_to_currency(total_deducciones, :locale => :mx, :precision => 2)}",174,135,8,28,5,'','R') if deducciones_total != 0
		total = doc.xpath("//cfdi:Comprobante").attribute("total").value rescue 0
        total = doc.xpath("//cfdi:Comprobante").attribute("Total").value rescue 0 if version_cfdi == "3.3"
		place_text("#{number_to_currency(total, :locale => :mx, :precision => 2)}",174,150,10,28,5,'B','R') if total != 0

	end

	private

		def place_barcode(code,x,y,w,h)
          	begin
		    	barcode = Barby::QrCode.new(code)
		    	barcode.annotate_pdf(self, x: x.send(:mm), y: 786-y.send(:mm)-109, xdim: w, ydim: h)
		    rescue
		    	bcdone = false
		    	(1..6).each do |i|
			    	begin
				    	barcode = Barby::QrCode.new(code, size: i)
				    	barcode.annotate_pdf(self, x: x.send(:mm), y: 786-y.send(:mm)-109, xdim: w, ydim: h)
				    	bcdone = true
				    rescue
				    end
				    break if bcdone
				end
				# return  # Esto lo puse
				raise "No ha podido crearse el código de barras. Favor de reportarlo a repfacturas@pintacomex.com.mx con su numero de empleado" if !bcdone
			end
		end

		def place_rectangle(color,x,y,w,h)
		    stroke_color color
	    	stroke do
				rounded_rectangle [x.send(:mm),786-y.send(:mm)],w.send(:mm),h.send(:mm), 1
			end
		end

		def place_text(txt,x,y,fs,w,h,sty,ali,leading=0)
			style = :normal
			style = :bold   if sty == "B"
			align = :left
			align = :center if ali == "C"
			align = :right  if ali == "R"
			formatted_text_box [ text: txt, styles: [style] ], at: [x.send(:mm),786-y.send(:mm)], size: fs, width: w.send(:mm), heigth: h.send(:mm), align: align, leading: leading
		end

		def place_image(img,x,y,w,h)
			image "public/images_nomina/#{img}.png", at: [x.send(:mm), [790-y.send(:mm)]], width: w.send(:mm), heigth: h.send(:mm)
		end

		def fix_ref(ref)
	        nref = ref.gsub(" ", "").gsub("-", "").gsub("/", "")
			return ref if nref.length != 16
			nref = "#{nref[0..3]}-#{nref[4..7]}-#{nref[8..11]}-#{nref[12..15]}"
			return nref
		end
end
