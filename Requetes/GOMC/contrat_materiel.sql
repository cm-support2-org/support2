//Information
//Permet d'exporter pour chaque client si un contrat et actif, non actif,
select
    vue_tiers.tie_code as Code_Client,
    vue_dirigeant.col_nom +' '+ vue_dirigeant.col_prenom as Nom_Prenom_Dirigeant,
    vue_tiers.mag_raisoc as Raison_Social,
    magasin.mag_denom_commer as Denomination_Commercial,
    vue_tiers.mag_adresse as Adresse,
    vue_tiers.mag_codepostal as Code_Postal,
    vue_tiers.mag_ville as Ville,
    vue_tiers.mag_telephone_1 as Teplephone_1,
    vue_tiers.mag_telephone_2 as Telephone_2,
    vue_tiers.mag_telephone_p as Telephone_Portable,
    vue_tiers.mag_fax as Fax,
    vue_tiers.mag_email as Email,
    case 
        when not exists( select 1 from contrat where contrat.tie_des_id = vue_tiers.tie_id ) then 'JAMAIS'
        when exists( select 
    1
from 
    contrat,
    contrat_materiel,        
    stock left outer join sref_article on
        stock.sra_id = sref_article.sra_id,
    article
where 
    contrat.tie_des_id = vue_tiers.tie_id and
    contrat.cont_statut = 2 and
    contrat_materiel.cont_id = contrat.cont_id and
    contrat_materiel.sto_id = stock.sto_id and
    sref_article.art_id = article.art_id and
article.art_reference in ('GPOS PREM', 'GOMC-POS', 'GPOS ACCES', 'GOMC-POSLIGHT' )

)
then 'CONTRAT ACTIF'
    when EXISTS (SELECT 
                    1
                from
                    contrat left outer join contrat_materiel ON 
                        contrat.cont_id = contrat_materiel.cont_id and
                        contrat.cont_publisher = contrat_materiel.cont_publisher  
                where
                    contrat.tie_des_id = vue_tiers.tie_id and
                    contrat.cont_statut = 2 and
                    contrat_materiel.cont_id is null) then 'CONTRAT SS MATOS'
    else 'CONTRATS INACTIF'
    end as statut
from
    vue_tiers,
    vue_dirigeant,
    magasin
Where
    vue_tiers.tie_id = vue_dirigeant.tie_id and
    vue_tiers.tie_publisher = vue_dirigeant.tie_publisher and
    vue_tiers.tie_type_client = 1 and
    vue_tiers.tie_code <> '50' and
    magasin.mag_id = vue_tiers.mag_id and
    magasin.mag_publisher = vue_tiers.mag_publisher and
    omc_f_is_valide (magasin.mag_fin_validite, current timestamp) = 1

Order by
    cast ( ( case when isnumeric( Code_Client ) = 1 then Code_Client else 0 end ) as integer)
