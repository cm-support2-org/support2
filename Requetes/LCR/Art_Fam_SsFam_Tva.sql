SELECT
    article.art_reference,
    article.art_id,
    article.art_designation,
    article.art_desig_courte,
    article.art_commentaire,
    article.art_tenue_stock, //1 = Gerer en stock 2 = non gerer en stock
    omc_f_axe_list(article.art_id ,'a' ,1,';') AS axe_list, // 1 = libelle -> libelle valeur /// 2 = code -> code valeur
    Groupe.gro_code,
    groupe.gro_libelle,
    famille.fam_code,
    famille.fam_libelle,
    sous_famille.sfa_code,
    sous_famille.sfa_libelle,
    tva.tva_taux,
    tva.tva_libelle
FROM
    (
        (
            article LEFT OUTER JOIN Sous_Famille ON 
                article.sfa_id = sous_famille.sfa_id AND
                article.sfa_publisher = sous_famille.sfa_publisher
        ) LEFT OUTER JOIN Famille ON 
            article.fam_id = famille.fam_id AND
            article.fam_publisher = famille.fam_publisher
      ) LEFT OUTER JOIN Groupe ON 
            famille.gro_id = groupe.gro_id AND
            famille.gro_publisher = groupe.gro_publisher,
      sref_article,
      tva      
WHERE
    article.art_id = sref_article.art_id AND
    article.art_publisher = sref_article.art_publisher AND
    article.regtvaa_vente_id = tva.regtvaa_id and
    article.regtvaa_vente_publisher = tva.regtvaa_publisher and
    sref_article.sra_fin_validite IS NULL           
ORDER BY art_reference
