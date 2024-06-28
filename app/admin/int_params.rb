ActiveAdmin.register IntParam do
  menu :priority => 11

  index do                           
    column :nombre_param
    column :valor_param                     
    column :desc_param     
    actions  
  end  

  filter :nombre_param
  filter :valor_param
  filter :desc_param

  form do |f|
    f.inputs "Parametro" do
      f.input :nombre_param
      f.input :valor_param
      f.input :desc_param
    end
    f.actions
  end

end