// Si un marché est validé sans aucune modification la saisie du fournisseur sera historisé.
// Les tarifs appliqué au marché sera cela de l'année précédente.
// Cette procédure permet de réactiver la dernière saisi des fournisseurs.
// Il faut saisir le numéro du marché en ligne 34 (gm_marche.gmmar_numero).


if exists(select 1 from sys.sysprocedure where proc_name = 'omc_p_mouline_marche') then
   drop procedure omc_p_mouline_marche
end if;

CREATE PROCEDURE "omc"."omc_p_mouline_marche"()

BEGIN
	
    declare ll_gmpr_id t_id;
    declare ls_gmpr_publisher t_publisher;      
    declare ll_gmfm_id t_id;
    declare ls_gmfm_publisher t_publisher;
    declare ll_gmart_id t_id;
    declare ls_gmart_publisher t_publisher;
    declare ls_gmpr_axe_hash t_hash;


    declare cur_gm_prix no scroll cursor for 
    SELECT 
			gm_prix.gmpr_id,
			gm_prix.gmpr_publisher,
            gm_prix.gmfm_id,
            gm_prix.gmfm_publisher,
            gm_prix.gmart_id,
            gm_prix.gmart_publisher,
            gm_prix.gmpr_axe_hash

    FROM    gm_article_marche,			
			gm_prix,
			gm_fournisseur_marche,			
			gm_marche		

   WHERE 
            --gm_marche.gmmar_numero = 131  and 

            gm_marche.gmmar_id = gm_article_marche.gmmar_id and
			gm_marche.gmmar_publisher = gm_article_marche.gmmar_publisher and            

			gm_fournisseur_marche.gmmar_id = gm_marche.gmmar_id and
			gm_fournisseur_marche.gmmar_publisher = gm_marche.gmmar_publisher and

			gm_prix.gmfm_id = gm_fournisseur_marche.gmfm_id and	
			gm_prix.gmfm_publisher = gm_fournisseur_marche.gmfm_publisher and

			gm_prix.gmart_id = gm_article_marche.gmart_id and
			gm_prix.gmart_publisher = gm_article_marche.gmart_publisher and

            date( gm_prix.gmpr_date_historisation ) >= '2022-11-29' ;

    -- 
  open cur_gm_prix;
  bou_gm_prix: loop
    fetch next cur_gm_prix into
      ll_gmpr_id,
      ls_gmpr_publisher,
      ll_gmfm_id,
      ls_gmfm_publisher,
      ll_gmart_id,
      ls_gmart_publisher,
      ls_gmpr_axe_hash;
    if sqlcode = 0 then
   
      -- traiter      
      update gm_prix set gm_prix.gmpr_date_historisation = current timestamp
      where
        gm_prix.gmfm_id = al_gmfm_id and
        gm_prix.gmfm_publisher = as_gmfm_publisher and
        gm_prix.gmart_id = al_gmart_id and
        gm_prix.gmart_publisher = as_gmart_publisher and
        gm_prix.gmpr_axe_hash = as_gmpr_axe_hash and
        gm_prix.gmpr_date_historisation is null;
    

    update gm_prix set gm_prix.gmpr_date_historisation = null
    where
        gm_prix.gmpr_id = ll_gmpr_id and
	    gm_prix.gmpr_publisher = ls_gmpr_publisher;

    elseif sqlcode = 100 then
      -- fin
      leave bou_gm_prix
    else
      -- erreur
      call omcmsg(1,'omc_p_mouline_marche_131 : erreur fetch!',0)
    end if
  end loop bou_gm_prix;
  close cur_gm_prix;

END
