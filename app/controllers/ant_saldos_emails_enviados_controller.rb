class AntSaldosEmailsEnviadosController < InheritedResources::Base

  private

    def ant_saldos_emails_enviado_params
      params.require(:ant_saldos_emails_enviado).permit(:email, :fecha)
    end
end

