ALTER PROCEDURE "omc"."export_axe_article_salamarket"( 
in as_code_societe t_code_tiers, 
in as_code_magasin t_code_depot,
in as_code_tarif t_code_classe_tarif,
in as_date_modificcation integer default null
)
BEGIN
	---------------------------------------------------------------------------------------------------------
    -- extraire les tarifs pour les étiquettes électroniques solum
    --Position="1" 	    Length="1"   CREATION MODIFICATION SUPPRESSION 
    --Position="4" 	    Length="13"  CODE EAN 
    --Position="17" 	Length="20"  LIBELLE CAISSE 
    --Position="37" 	Length="3"   CODE FAMILLE 
    --Position="40" 	Length="8"   PRIX DE VENTE
    --Position="48"     Length="15"  RACES
    --Position="63"     Length="15"  ELEVAGES
    --Position="83"     Length="8"   PRIX_VENTE_PROMO
    --Position="91"     Length="8"   PRIX_UNITAIRE_PROMO
    --Position="100" 	Length="8"   CODE INTERNE 
    --Position="113" 	Length="5"   CODE FOURNISSEUR 
    --Position="118" 	Length="8"   CONTENANCE + UNITE 
    --Position="126" 	Length="7"   CONDITIONNEMENT 
    --Position="133" 	Length="30"  LIBELLE LONG 
    --Position="163" 	Length="8"   PRIX UNITAIRE 
    --Position="173" 	Length="2"   UNITE 
    --Position="175" 	Length="1"   INDICATEUR PROMO 
    --Position="176" 	Length="15"  ORIGINE 
    --Position="191" 	Length="15"  CATEGORIE 
    --Position="206" 	Length="15"  CALIBRE 
    --Position="221" 	Length="15"  TRAITEMENT 
    --Position="236" 	Length="15"  VARIETE 
    --Position="251" 	Length="5"   CONDITIONNEMENT A LA VENTE 
    --Position="266" 	Length="4"   QTE VENTES MOYENNES HEBDOMADAIRES 
    --Position="284" 	Length="7"   JOUR DE COMMANDE 
    --Position="291" 	Length="1"   ARTICLE COMMANDABLE 
    --Position="300" 	Length="1"   FLAG ARTICLE TICKET RESTAURANT 
    ---------------------------------------------------------------------------------------------------------
    declare ll_mag_id t_id ;
	declare ls_mag_publisher t_publisher ;
    declare ll_tar_ct_id t_id ;
	declare ls_tar_ct_publisher t_publisher ;
    declare dateArtModification t_date;
    
    -- table temporaire tarif
    declare local temporary table t_tarif_ct(
    tarif_ct_tarct_id T_ID null,
    tarif_ct_tarct_publisher T_PUBLISHER null,
    tarif_ct_mag_id T_ID null,
    tarif_ct_mag_publisher T_PUBLISHER null,
    tarif_ct_art_id T_ID null,
    tarif_ct_art_publisher T_PUBLISHER null,
    ) on commit delete rows;

    -- init
    if as_date_modificcation is not null then
        set dateArtModification = dateadd(day,-as_date_modificcation,dateformat(current timestamp, 'yyyy-mm-dd 00:00:00'));
    elseif  as_date_modificcation = 0 then
        set dateArtModification = dateformat(current timestamp, 'yyyy-mm-dd 23:59:59');
    else
        set dateArtModification = '2000-01-01 00:00:00'
    end if;
    
    -- récupérer id magasin et id classe de tarif
    select
        magasin.mag_id,
        magasin.mag_publisher,
        classe_tarif.ct_id,
        classe_tarif.ct_publisher
    into
        ll_mag_id,
        ls_mag_publisher,
        ll_tar_ct_id,
        ls_tar_ct_publisher
    from
        tiers,
        magasin,
        classe_tarif
    where
        tiers.tie_code = as_code_societe and
        tiers.tie_type_societe = 1 and
        magasin.tie_id = tiers.tie_id and
        magasin.tie_publisher = tiers.tie_publisher and
        magasin.mag_code = as_code_magasin and
        classe_tarif.ct_code = as_code_tarif;
    if sqlcode <> 0 then
      -- erreur
      call "omcmsg"(1,'test_export_axe_article_salamarket : Erreur lors de la recherche magasin et classe de tarif !',0);
    end if;

    -- insertion tarif magasin
    insert into t_tarif_ct
    select
      tarct_id,
      tarct_publisher,
      mag_id,
      mag_publisher,
      art_id,
      art_publisher 
    from
        tarif_ct
    where
        tarif_ct.mag_id = ll_mag_id and
        tarif_ct.mag_publisher = ls_mag_publisher and
        tarif_ct.ct_id = ll_tar_ct_id and
        tarif_ct.ct_publisher = ls_tar_ct_publisher and
        tarif_ct.tarct_prix_1 is not null;
    if sqlcode <> 0 and sqlcode <> 100 then
      -- erreur
      call "omcmsg"(1,'test_export_axe_article_salamarket : Erreur insertion tarif 1 !',0);
    end if;

    -- insertion tarif général si pas de tarif magasin
    insert into t_tarif_ct
    select
      tarct_id,
      tarct_publisher,
      ll_mag_id,
      ls_mag_publisher,
      art_id,
      art_publisher 
    from
        tarif_ct
    where
        tarif_ct.mag_id is null and
        tarif_ct.mag_publisher is null and
        tarif_ct.ct_id = ll_tar_ct_id and
        tarif_ct.ct_publisher = ls_tar_ct_publisher and
        tarif_ct.tarct_prix_1 is not null and 
        not exists( select 1 from t_tarif_ct 
                    where 
                       tarif_ct_mag_id = ll_mag_id and
                       tarif_ct_mag_publisher = ls_mag_publisher and
                       tarif_ct_art_id = art_id and
                       tarif_ct_art_publisher = art_publisher ) ;
    if sqlcode <> 0 and sqlcode <> 100 then
      -- erreur
      call "omcmsg"(1,'test_export_axe_article_salamarket : Erreur insertion tarif 2 !',0);
    end if;

    ------------------------------------------------------------------------------------------------------------------
    -- resultat
 unload       
        select
        space(1) as CREATION_MODIFICATION_SUPPRESSION,
        space(2),                      
        left( cast(code_barre.codbr_codebarre as varchar), 13 ) + coalesce(space( 13 - length(cast (code_barre.codbr_codebarre as varchar))),space(13)) as CODE_EAN,
        upper(left( cast(article.art_desig_courte as varchar), 20 ) + coalesce(space( 20 - length(cast (article.art_desig_courte as varchar))),space(20))) as LIBELLE_CAISSE,
        left( cast(famille.fam_code as varchar), 3 ) + coalesce(space( 3 - length(cast (famille.fam_code as varchar))),'') as CODE_FAMILLE,
        left(omc_f_decimal_to_string(round(tarif_ct.tarct_prix_1,2),2),8) + coalesce(space( 8 - length(cast (omc_f_decimal_to_string(round(tarif_ct.tarct_prix_1,2),2) as varchar))),'') as PRIX_DE_VENTE,               
        upper(left( cast(from_races.Races as varchar ), 15 ) + coalesce(space( 15 - length(cast (from_races.Races as varchar))),space(15))) as RACES, 
        upper(left( cast(from_elevages.Elevages as varchar ), 15 ) + coalesce(space( 15 - length(cast (from_elevages.Elevages as varchar))),space(15))) as ELEVAGES, 
        left(omc_f_decimal_to_string(round(tarif_ct.tarct_prix_promo,2),2),8) + coalesce(space( 8 - length(cast (omc_f_decimal_to_string(round(tarif_ct.tarct_prix_promo,2),2) as varchar))),'') as PRIX_VENTE_PROMO,        
        left( omc_f_decimal_to_string_new(round(tarif_ct.tarct_prix_promo/ coalesce(nullif(sref_article.sra_qte_uni_ref_vente_etiq,''),1),2),2), 8 ) + coalesce(space( 8 - length(omc_f_decimal_to_string_new(round(tarif_ct.tarct_prix_promo / coalesce(nullif(sref_article.sra_qte_uni_ref_vente_etiq,''),1),2),2 ))),space(8)) as PRIX_UNITAIRE_PROMO, 
        space(6),
        upper(left( cast(plu_sref.plusref_plu as varchar), 8 ) + coalesce(space( 8 - length(cast (plu_sref.plusref_plu as varchar))),space(8))) as CODE_INTERNE,
        space(5),
        upper(left( cast(fournisseur_habituel_general.fouhabgen_reference_fou as varchar), 5 ) + coalesce(space( 5 - length(cast (fournisseur_habituel_general.fouhabgen_reference_fou as varchar))),space(5))) as CODE_FOURNISSEUR,
        upper(cast( omc_f_decimal_to_string_new(sref_article.sra_qte_uni_ref_vente_etiq,3)  + ' ' + unite_etiq.uni_code as varchar(8)) + coalesce(space( 8 - length(omc_f_decimal_to_string_new(sref_article.sra_qte_uni_ref_vente_etiq,3) + ' ' + unite_etiq.uni_code)),space(8))) as CONTENANCE_UNITE,               
        space(7),
        upper(left( cast(article.art_desig_courte as varchar), 30 ) + coalesce(space( 30 - length(cast (article.art_desig_courte as varchar))),space(30))) as LIBELLE_LONG,         
        left( omc_f_decimal_to_string_new(round(tarif_ct.tarct_prix_1/ coalesce(nullif(sref_article.sra_qte_uni_ref_vente_etiq,''),1),2),2), 8 ) + coalesce(space( 8 - length(omc_f_decimal_to_string_new(round(tarif_ct.tarct_prix_1 / coalesce(nullif(sref_article.sra_qte_uni_ref_vente_etiq,''),1),2),2 ))),space(8)) as PRIX_UNITAIRE, 
        space(2),
        left( cast(unite_etiq.uni_code as varchar ), 2 ) + coalesce(space( 2 - length(cast (unite_etiq.uni_code as varchar))),space(2)) as UNITE,              
        case 
            when tarif_ct.tarct_debut_prix_promo is null then 'N'  
            when ( tarif_ct.tarct_debut_prix_promo <= dateformat(now(),'yyyy-mm-dd') and (tarif_ct.tarct_fin_prix_promo >= dateformat(now(),'yyyy-mm-dd')) or tarif_ct.tarct_fin_prix_promo is null)  then 'O' 
            else 'N' 
        end as INDICATEUR_PROMO,               
        upper(left( cast(from_origines.Origines  as varchar ), 15 ) + coalesce(space( 15 - length(cast (from_origines.Origines  as varchar))),space(15))) as ORIGINES,                      
        upper(left( cast(classe_produit.clapro_libelle  as varchar ), 15 ) + coalesce(space( 15 - length(cast (classe_produit.clapro_libelle  as varchar))),space(15))) as CATEGORIE,
        upper(left( cast(from_calibres.Calibres  as varchar ), 15 ) + coalesce(space( 15 - length(cast (from_calibres.Calibres  as varchar))),space(15))) as CALIBRES,
        upper(left( cast(from_traitement.traitement  as varchar ), 15 ) + coalesce(space( 15 - length(cast (from_traitement.traitement  as varchar))),space(15))) as Traitement,
        upper(left( cast(from_Varietes.Varietes  as varchar ), 15 ) + coalesce(space( 15 - length(cast (from_Varietes.Varietes  as varchar))),space(15))) as Varietes,
        space(50) 
    From    
        article left outer join 
                                ( select
                                    valeur_axe_article.vaxeart_libelle as 'Origines',
                                    article.art_id as art_id_orignes,
                                    article.art_publisher as art_publisher_orignes
                                 from
                                    article,
                                    axe_article,
                                    axe_article_article,
                                    valeur_axe_article
                                 where
                                    axe_article_article.art_id = article.art_id and
                                    axe_article_article.art_publisher = article.art_publisher and
                                    axe_article.axeart_id = axe_article_article.axeart_id and
                                    axe_article.axeart_publisher = axe_article_article.axeart_publisher and
                                    valeur_axe_article.vaxeart_id = axe_article_article.vaxeart_id and
                                    valeur_axe_article.vaxeart_publisher = axe_article_article.vaxeart_publisher and
                                    axe_article.axeart_code = 'Origines'
                                ) as from_origines ON
                                        from_origines.art_id_orignes = article.art_id and
                                        from_origines.art_publisher_orignes = article.art_publisher
                left outer join 
                                ( select
                                    valeur_axe_article.vaxeart_libelle as 'Varietes',
                                    article.art_id as art_id_varietes,
                                    article.art_publisher as art_publisher_varietes
                                 from
                                    article,
                                    axe_article,
                                    axe_article_article,
                                    valeur_axe_article
                                 where
                                    axe_article_article.art_id = article.art_id and
                                    axe_article_article.art_publisher = article.art_publisher and
                                    axe_article.axeart_id = axe_article_article.axeart_id and
                                    axe_article.axeart_publisher = axe_article_article.axeart_publisher and
                                    valeur_axe_article.vaxeart_id = axe_article_article.vaxeart_id and
                                    valeur_axe_article.vaxeart_publisher = axe_article_article.vaxeart_publisher and
                                    axe_article.axeart_code = 'Varietes'
                                ) as from_varietes ON
                                        from_varietes.art_id_varietes = article.art_id and
                                        from_varietes.art_publisher_varietes = article.art_publisher
                left outer join 
                                ( select
                                    valeur_axe_article.vaxeart_libelle as 'Traitement',
                                    article.art_id as art_id_traitement,
                                    article.art_publisher as art_publisher_traitement
                                 from
                                    article,
                                    axe_article,
                                    axe_article_article,
                                    valeur_axe_article
                                 where
                                    axe_article_article.art_id = article.art_id and
                                    axe_article_article.art_publisher = article.art_publisher and
                                    axe_article.axeart_id = axe_article_article.axeart_id and
                                    axe_article.axeart_publisher = axe_article_article.axeart_publisher and
                                    valeur_axe_article.vaxeart_id = axe_article_article.vaxeart_id and
                                    valeur_axe_article.vaxeart_publisher = axe_article_article.vaxeart_publisher and
                                    axe_article.axeart_code = 'Traitement'
                                ) as from_traitement ON
                                        from_traitement.art_id_traitement = article.art_id and
                                        from_traitement.art_publisher_traitement = article.art_publisher
            left outer join 
                            ( select
                                valeur_axe_article.vaxeart_libelle as 'Calibres',
                                article.art_id as art_id_calibres,
                                article.art_publisher as art_publisher_calibres
                             from
                                article,
                                axe_article,
                                axe_article_article,
                                valeur_axe_article
                             where
                                axe_article_article.art_id = article.art_id and
                                axe_article_article.art_publisher = article.art_publisher and
                                axe_article.axeart_id = axe_article_article.axeart_id and
                                axe_article.axeart_publisher = axe_article_article.axeart_publisher and
                                valeur_axe_article.vaxeart_id = axe_article_article.vaxeart_id and
                                valeur_axe_article.vaxeart_publisher = axe_article_article.vaxeart_publisher and
                                axe_article.axeart_code = 'Calibres'
                            ) as from_calibres ON
                            from_calibres.art_id_calibres  = article.art_id and
                            from_calibres.art_publisher_calibres  = article.art_publisher
               left outer join 
                            ( select
                                valeur_axe_article.vaxeart_libelle as 'Races',
                                article.art_id as art_id_races,
                                article.art_publisher as art_publisher_races
                             from
                                article,
                                axe_article,
                                axe_article_article,
                                valeur_axe_article
                             where
                                axe_article_article.art_id = article.art_id and
                                axe_article_article.art_publisher = article.art_publisher and
                                axe_article.axeart_id = axe_article_article.axeart_id and
                                axe_article.axeart_publisher = axe_article_article.axeart_publisher and
                                valeur_axe_article.vaxeart_id = axe_article_article.vaxeart_id and
                                valeur_axe_article.vaxeart_publisher = axe_article_article.vaxeart_publisher and
                                axe_article.axeart_code = 'Races'
                            ) as from_races ON
                            from_races.art_id_races  = article.art_id and
                            from_races.art_publisher_races  = article.art_publisher
                left outer join 
                            ( select
                                valeur_axe_article.vaxeart_libelle as 'Elevages',
                                article.art_id as art_id_elevages,
                                article.art_publisher as art_publisher_elevages
                             from
                                article,
                                axe_article,
                                axe_article_article,
                                valeur_axe_article
                             where
                                axe_article_article.art_id = article.art_id and
                                axe_article_article.art_publisher = article.art_publisher and
                                axe_article.axeart_id = axe_article_article.axeart_id and
                                axe_article.axeart_publisher = axe_article_article.axeart_publisher and
                                valeur_axe_article.vaxeart_id = axe_article_article.vaxeart_id and
                                valeur_axe_article.vaxeart_publisher = axe_article_article.vaxeart_publisher and
                                axe_article.axeart_code = 'Elevages'
                            ) as from_elevages ON
                            from_elevages.art_id_elevages  = article.art_id and
                            from_elevages.art_publisher_elevages  = article.art_publisher
            left outer join unite ON
                article.uni_ref_id = unite.uni_id and
                article.uni_ref_publisher = unite.uni_publisher
            left outer join classe_produit on
                article.clapro_id = classe_produit.clapro_id and
                article.clapro_publisher = classe_produit.clapro_publisher,
        famille,
        tarif_ct,
        sref_article left outer join unite as unite_etiq ON      
            sref_article.uni_ref_vente_etiq_id = unite_etiq.uni_id and
            sref_article.uni_ref_vente_etiq_publisher = unite_etiq.uni_publisher
                    left outer join code_barre ON        
            sref_article.sra_id = code_barre.sra_id And
            sref_article.sra_publisher = code_barre.sra_publisher and
            code_barre.codbr_principal = 1 
                    left outer join fournisseur_habituel_general on        
            fournisseur_habituel_general.sra_id = sref_article.sra_id and
            fournisseur_habituel_general.sra_publisher = sref_article.sra_publisher,
        t_tarif_ct,
        plu_sref
    Where
        t_tarif_ct.tarif_ct_tarct_id = tarif_ct.tarct_id and        
        t_tarif_ct.tarif_ct_tarct_publisher = tarif_ct.tarct_publisher and
        article.art_id = tarif_ct.art_id and
        article.art_publisher = tarif_ct.art_publisher and
        article.art_id = sref_article.art_id and
        article.art_publisher = sref_article.art_publisher and
        article.fam_id = famille.fam_id and
        article.fam_publisher = famille.fam_publisher AND       
        sref_article.sra_fin_validite is null and
        plu_sref.sra_id = sref_article.sra_id and
        plu_sref.sra_publisher = sref_article.sra_publisher and
        code_barre.codbr_codebarre is not null and
        (article.art_derniere_modif >= dateArtModification or tarif_ct.tarct_debut_prix_promo >= dateArtModification or tarif_ct.tarct_fin_prix_promo <= dateArtModification)
    Order by    
        article.art_id asc
 
   TO 'C:\host\tomajcai.fic' DELIMITED by '' QUOTE '' FORMAT ASCII

   --Si les dates des prix promo (début et fin) sont < à aujourd'hui on clear.
  update tarif_ct
	 set tarif_ct.tarct_debut_prix_promo = null, tarif_ct.tarct_fin_prix_promo = null
	 where ( tarif_ct.tarct_debut_prix_promo < dateformat(now(),'yyyy-mm-dd') and  tarif_ct.tarct_fin_prix_promo < dateformat(now(),'yyyy-mm-dd'));
  commit
END
