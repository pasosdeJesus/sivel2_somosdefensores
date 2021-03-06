# encoding: UTF-8

require 'sivel2_gen/concerns/controllers/casos_controller'

module Sivel2Gen
  class CasosController < Heb412Gen::ModelosController

    include Sivel2Gen::Concerns::Controllers::CasosController

    before_action :set_caso, only: [:show, :edit, :update, :destroy]
    load_and_authorize_resource class: Sivel2Gen::Caso, 
      except: [:index, :show, :mapaosm, :update]

    def campoord_inicial
      'fechadesc'
    end

    def inicializa_index
      @plantillas = Heb412Gen::Plantillahcm.where(
        vista: 'Caso').select('nombremenu, id').map { |c| 
          [c.nombremenu, c.id] 
        }
    end

    def update
      if params[:caso] && params[:caso][:victimacolectiva_attributes]
        params[:caso][:victimacolectiva_attributes].each { |i,v|
          if v[:actorsocial_attributes] && 
            v[:actorsocial_attributes][:grupoper_id] &&
            v[:grupoper_attributes] && v[:grupoper_attributes][:id]
            v[:actorsocial_attributes][:grupoper_id]=v[:grupoper_attributes][:id]
          end
        }
      end
      @caso.victimacolectiva.each do |v|
        if !v.grupoper
          puts "Victima colectiva debería tener grupoper"
          exit 1
        end
        if v.grupoper && !v.actorsocial
          v.actorsocial = Sip::Actorsocial.new
        end
        if v.grupoper.id != v.actorsocial.grupoper_id
          v.actorsocial.grupoper_id=v.grupoper.id
          v.save!(validate: false)
        end
      end
      update_gen
    end

    def caso_params
      # Añadimos actorsocial en victima colectiva
      lp = lista_params
      hlp = lp[lp.length - 1] # Los primeros son escalares, el ultimo hash
      vc = hlp[:victimacolectiva_attributes]
      hvc = vc[vc.length - 1]
      hvc[:actorsocial_attributes] = [:id, :grupoper_id, :fechafundacion]
      # Añadimos otraorg y tipoamenza en victima
      v = hlp[:victima_attributes] = [:otraorganizacion, :tipoamenaza_id] + 
        hlp[:victima_attributes]
      # Añadimos actor social en persona
      hv = v[v.length - 1]
      p = hv[:persona_attributes]
      p << { actorsocial_persona_attributes: 
             [:id, :actorsocial_id, :perfilactorsocial_id] }
      params.require(:caso).permit(lp)
    end
       
  end
end
