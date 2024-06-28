ActiveAdmin.register Empresa do
  menu :priority => 5

  index do                            
    column :idEmpresa
    column :nombre                     
    column :email           
    column :idRfc
    actions  
  end  

  filter :idEmpresa
  filter :nombre

  form do |f|
    f.inputs "Detalles Empresa" do
      f.input :idEmpresa
      f.input :nombre
      f.input :idRfc
      f.input :email
      f.input :privacidad
    end
    f.actions
  end

end