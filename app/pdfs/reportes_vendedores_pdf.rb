class ReportesVendedoresPdf < Prawn::Document
	include ActionView::Helpers::NumberHelper
	include ActionView::Helpers::TextHelper
	def initialize(vendedor, name_vend, vendexcepsvend, vendedores_ventas, vendedores_porcentaje_bajo , vendedores_diferencias)
		require "prawn/measurement_extensions"
		super(page_size: "LETTER", margin: 1)
		font "Helvetica"
		font_size 12
		place_text("Reporte de ventas de #{name_vend['Nombre']}",60, 7,18,120,5,'B','C',4)
		
		array_vendedor = [["Nombre Campo", "Valor", "Nombre Campo", "Valor", "Nombre Campo", "Valor"	], ['Sucursal', vendedor['Sucursal'], 'Mes', vendedor['Mes'], 'Idvendedor', vendedor['Idvendedor']], ['ultFechaProcesada', vendedor['ultFechaProcesada'], 'Dias', vendedor['Dias'],'Tickets', vendedor['Tickets']],
		['Piezas', vendedor['Piezas'], 'Renglones', vendedor['Renglones'],
		'RenglonesRegalo', vendedor['RenglonesRegalo']],
		['TicketsContado', vendedor['TicketsContado'], 'PiezasContado', vendedor['PiezasContado'] , 'RenglonesContado', vendedor['RenglonesContado']],
		['RenglonesRegaloContado', vendedor['RenglonesRegaloContado'], 'TicketsCredito', vendedor['TicketsCredito'], 'PiezasCredito', vendedor['PiezasCredito']],
		['RenglonesCredito', vendedor['RenglonesCredito'], 'RenglonesRegaloCredito', vendedor['RenglonesRegaloCredito'], 'VentaBruta', number_to_currency(vendedor['VentaBruta'], :locale => :mx, :precision => 2)],
		['Descuento', number_to_currency(vendedor['Descuento'], :locale => :mx, :precision => 2), 'VentaNeta', number_to_currency(vendedor['VentaNeta'], :locale => :mx, :precision => 2), 'CostoDeVenta', number_to_currency(vendedor['CostoDeVenta'], :locale => :mx, :precision => 2)],
		['VentaBrutaContado', number_to_currency(vendedor['VentaBrutaContado'], :locale => :mx, :precision => 2), 'DescuentoContado', number_to_currency(vendedor['DescuentoContado'], :locale => :mx, :precision => 2), 'VentaNetaContado', number_to_currency(vendedor['VentaNetaContado'], :locale => :mx, :precision => 2)],
		['CostoDeVentaContado', number_to_currency(vendedor['CostoDeVentaContado'], :locale => :mx, :precision => 2), 'VentaBrutaCredito', number_to_currency(vendedor['VentaBrutaCredito'], :locale => :mx, :precision => 2) , 'DescuentoCredito', number_to_currency(vendedor['DescuentoCredito'], :locale => :mx, :precision => 2)],
		['VentaNetaCredito', number_to_currency(vendedor['VentaNetaCredito'], :locale => :mx, :precision => 2), 'CostoDeVentaCredito', number_to_currency(vendedor['CostoDeVentaCredito'], :locale => :mx, :precision => 2), 'VentaNetaRegalos', number_to_currency(vendedor['VentaNetaRegalos'], :locale => :mx, :precision => 2)],
		['VentaNetaPromocion', number_to_currency(vendedor['VentaNetaPromocion'], :locale => :mx, :precision => 2), 'VentaNetaManual', number_to_currency(vendedor['VentaNetaManual'], :locale => :mx, :precision => 2), 'VentaNetaClientehastaDF', number_to_currency(vendedor['VentaNetaClientehastaDF'], :locale => :mx, :precision => 2)],
		['VentaNetaClienteMayoreo', number_to_currency(vendedor['VentaNetaClienteMayoreo'], :locale => :mx, :precision => 2), 'VentaNetaConvenio', number_to_currency(vendedor['VentaNetaConvenio'], :locale => :mx, :precision => 2), 'VentaNetaEmpleadoaCosto', number_to_currency(vendedor['VentaNetaEmpleadoaCosto'], :locale => :mx, :precision => 2)],
		['DescRegalos', number_to_currency(vendedor['DescRegalos'], :locale => :mx, :precision => 2), 'DescPromocion', number_to_currency(vendedor['DescPromocion'], :locale => :mx, :precision => 2),'DescManual', number_to_currency(vendedor['DescManual'], :locale => :mx, :precision => 2)],
		['DescClientehastaDF', number_to_currency(vendedor['DescClientehastaDF'], :locale => :mx, :precision => 2), 'DescClienteMayoreo', number_to_currency(vendedor['DescClienteMayoreo'], :locale => :mx, :precision => 2), 'DescConvenio', number_to_currency(vendedor['DescConvenio'], :locale => :mx, :precision => 2)],
		['DescEmpleadoaCosto', number_to_currency(vendedor['DescEmpleadoaCosto'], :locale => :mx, :precision => 2), 'Replicado', vendedor['Replicado']]]

		move_down 100
		
		place_image('logo_pintacomex',5,3,50,25)	
		bold = 6
		table(array_vendedor, :row_colors => ["ffffff"],:position => :center, :cell_style => {:size => 9,:background_color => "f5f5f5", :border_color => "ffffff"})do
		  row(0).font_style = :bold
		  row(0).align = :center
		  column(0..7).width = 90
		end

		move_down 50 
		

		table(generate_array_vendexcepsvend(vendexcepsvend), :row_colors => ["ffffff"],:position => :center, :cell_style => {:size => 9,:background_color => "f5f5f5", :border_color => "ffffff"})do
		  row(0).font_style = :bold
		  row(0).align = :center
		  column(0..7).width = 60
		end

		place_text("Todas las excepciones",50, 185, 18,120,5,'B','C',4)

		start_new_page

		move_down 130
		place_text("Ventas fechas con excepción",50, 25, 18,120,5,'B','C',4)

		table(generate_array_vendedores_ventas(vendedores_ventas), :row_colors => ["ffffff"],:position => :center, :cell_style => {:size => 9,:background_color => "f5f5f5", :border_color => "ffffff"})do
		  row(0).font_style = :bold
		  row(0).align = :center
		  column(0..7).width = 75
		end

		move_down 200

		place_text("Vendedores con menos del 20% de las ventas ",50, 100, 18,120,5,'B','C',4)

		table(generate_array_vendedores_porcentaje_bajo(vendedores_porcentaje_bajo), :row_colors => ["ffffff"],:position => :center, :cell_style => {:size => 9,:background_color => "f5f5f5", :border_color => "ffffff"})do
		  row(0).font_style = :bold
		  row(0).align = :center
		  column(0..7).width = 75
		end

		move_down 150

		place_text("Días de venta teoricos vs reales",50, 200, 18,120,5,'B','C',4)

		table(generate_array_vendedores_diferencias(vendedores_diferencias), :row_colors => ["ffffff"],:position => :center, :cell_style => {:size => 9,:background_color => "f5f5f5", :border_color => "ffffff"})do
		  row(0).font_style = :bold
		  row(0).align = :center
		  column(0..7).width = 60
		end
		

		place_image('logo_pintacomex',5,3,50,25)	

	

	end

	private

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

def generate_array_vendexcepsvend(vendexcepsvend)
	# Todas

	array_vendexcepsvend = [["Del", "Al", "Nombre", "Excepcion", "Sucursal", "SucOrigen", "DiasHabiles", "DiasTranscurridos"]]
	vendexcepsvend.each_with_index do |seller, i|
		array_vendexcepsvend << [seller['Del'], seller['Al'], seller['Nombre'], seller['Excepcion'], seller['Sucursal'], seller['SucOrigen'], seller['DiasHabiles'], seller['DiasTranscurridos']]
	end 
	array_vendexcepsvend
end

def generate_array_vendedores_ventas(vendedores_ventas)
	# Ventas fechas con excepción
	array_vendedores_ventas = [["IdVendedor", "Nombre", "Sucursal", "SucOrigen", "Del", "Al"]]

	vendedores_ventas.each_with_index do |seller, i| 
		array_vendedores_ventas<< [seller['IdVendedor'], seller['Nombre'], seller['Sucursal'], seller['SucOrigen'], "#{seller['Del'][0..3]}-#{seller['Del'][4..5]}-#{seller['Del'][6..7]}", "#{seller['Al'][0..3]}-#{seller['Al'][4..5]}-#{seller['Al'][6..7]}"]
	end 
	array_vendedores_ventas
end

def generate_array_vendedores_porcentaje_bajo(vendedores_porcentaje_bajo)
	# Vendedores con menos del 20% de las ventas 
	array_vendedores_porcentaje_bajo = [["IdVendedor", "Fecha", "Nombre", "Sucursal", "Mes", "Obj.Venta", "Venta Neta", "Porc.Venta"]]
	
	vendedores_porcentaje_bajo.each_with_index do |seller, i|
		array_vendedores_porcentaje_bajo << [seller['Idvendedor'], "#{seller['Fecha'][0..3]}-#{seller['Fecha'][4..5]}-#{seller['Fecha'][-2..-1]}", seller['Nombre'], seller['Sucursal'], seller['Mes'], number_to_currency(seller['objetivoVenta'], :locale => :mx, :precision => 2),	number_to_currency(seller['VentaNeta'], :locale => :mx, :precision => 2), seller['porcentajeVenta']]
	end 
	array_vendedores_porcentaje_bajo
end

def generate_array_vendedores_diferencias(vendedores_diferencias)
	# Días de venta teoricos vs reales
	array_vendedores_diferencias = [["IdVendedor", "Nombre", "Sucursal", "Mes", "Dias Operados", "Dias con incidencias", "Dias Por Transcurrir", "Dias Habiles Suc", "Dias de Diferencia"]]

	vendedores_diferencias.each_with_index do |seller, i| 
		array_vendedores_diferencias << [seller[:IdVendedor], seller[:Nombre], seller[:Sucursal], seller[:Mes], seller[:Dias], seller[:DiasIncidencias], seller[:DiasPorTranscurrir], seller[:DiasHabilesSuc], seller[:Diferencia]]
	end 
array_vendedores_diferencias
end
