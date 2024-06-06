select
    vue_tiers.tie_code as Code_Client_Cashmag,
    tiers.tie_badge as Numero_Badge,
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
    contrat.cont_libelle as nom_contrat,
    case contrat.cont_statut 
        when 2 then 'CONTRAT ACTIF'
        when 3 then 'CONTRAT INACTIF'
    else
        'Autre'
    end as status_contrat,
    contrat.cont_date_fin_prevue as Date_fin_prevue,
    contrat.cont_date_fin_reelle as Date_fin_reel,
    case contrat.cont_periodicite_fac
        when 0 then 'Jamais'
        when 1 then 'Mensuel'
        When 2 then 'Bimestrielle'
        When 3 then 'Trimestrielle'
        When 4 then 'Semestrielle'
        When 5 then 'Annuelle' 
        When 6 then 'Manuelle'
    else 'Autre'
    end as periodicite_contrat,
    contrat.cont_jour_facturation as jour_facturation,
    ( select max( piece.pie_date ) from piece where piece.tie_des_id = vue_tiers.tie_id and piece.pie_type = 5 ) as date_derniere_facture,
    piece.pie_ca_ht,
    coalesce(encours_tiers.enct_encours,0,00) as encours,
    encours_tiers.enct_encours_liv as encours_livraison
from
    vue_tiers 
            left outer join contrat on
            contrat.tie_des_id = vue_tiers.tie_id and
            contrat.tie_des_publisher = vue_tiers.tie_publisher
            left outer join encours_tiers on 
                vue_tiers.tie_id = encours_tiers.tie_des_id and
                vue_tiers.tie_publisher = encours_tiers.tie_des_publisher,
    vue_dirigeant,
    magasin,
    contrat left outer join piece on
        contrat.pie_id = piece.pie_id and
        contrat.pie_publisher = piece.pie_publisher,
    tiers          
Where
    vue_tiers.tie_id = vue_dirigeant.tie_id and
    vue_tiers.tie_publisher = vue_dirigeant.tie_publisher and
    vue_tiers.tie_type_client = 1 and
    vue_tiers.tie_code <> '50' and
    magasin.mag_id = vue_tiers.mag_id and
    magasin.mag_publisher = vue_tiers.mag_publisher and
    omc_f_is_valide (magasin.mag_fin_validite, current timestamp) = 1 and
    vue_tiers.tie_code like '25%' and
    encours_tiers.enct_type_tiers_des = 1 and
    vue_tiers.tie_id = tiers.tie_id and
    vue_tiers.tie_publisher = tiers.tie_publisher
Order by
    Code_Client_Cashmag asc;
OUTPUT TO 'D:\Export_Client_Hairnet.csv' DELIMITED by '\x09' QUOTE ''
