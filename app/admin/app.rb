ActiveAdmin.register App do
  menu :priority => 7

  index do    
    column :nombre
    column :url
    column :bloque
    column :activo do |m|
      name = "#{m.activo == 0 ? "Inactivo" : "Activo"}"
    end     
    actions  
  end  

  filter :nombre
  filter :url
  filter :bloque
  filter :activo

  form do |f|
    f.inputs "Detalles de Aplicacion" do
      f.input :nombre
      f.input :url
      f.input :bloque, as: :select, collection: ["Auditoría", "General", "Operación", "Personal", "Sistemas", "Soporte"].collect{ |c| ["#{c}", c] }, include_blank: false 
      f.input :activo, as: :select, collection: [{ id: 0, nombre: "Inactivo" }, { id: 1, nombre: "Activo" }].collect{ |c| ["#{c[:nombre]}", c[:id]] }, include_blank: false 
    end
    f.actions
  end

end