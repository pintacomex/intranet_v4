ActiveAdmin.register CatRole do
  menu :priority => 9

  index do                            
    column :nomPermiso
    column :nivel
    column :nomP1
    column :nomP2
    column :nomP3
    column :nomP4
    actions  
  end  

  filter :nomPermiso

  form do |f|
    f.inputs "Detalles Catalogo Roles" do
      f.input :nomPermiso
      f.input :nivel
      f.input :nomP1
      f.input :nomP2
      f.input :nomP3
      f.input :nomP4
    end
    f.actions
  end

end