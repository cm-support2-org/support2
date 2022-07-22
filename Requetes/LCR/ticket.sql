SELECT
  vue_ticket.tic_id AS ET_tic_id,
  //*************  
  //En tete  
  //*************
  vue_ticket.tic_chrono AS ET_tic_chrono, //Date du ticket d'enregistrement du ticket dans la caisse.
  vue_ticket.tic_piece AS ET_tic_piece, //Numero du ticket du ticket emis par la caisse.
  //vue_ticket.compute_societe_id AS ET_compute_societe_id, //ID de la societe dans la BDD.
  vue_ticket.compute_magasin_id AS ET_compute_magasin_id, //ID du magasin dans la BDD.
  vue_ticket.compute_terminal_id AS ET_compute_terminal_id, //ID du terminal dans la BDD.
  vue_ticket.compute_terminal AS ET_compute_terminal, //Nom de la societe, du magasin et du terminal.
  vue_ticket.tic_annule AS ET_tic_annule, //Flag qui indique si le ticket est annulé ou non. Deux valeurs possible (oui / non)
  vue_ticket.col_code AS ET_col_code, //Code du caissier. Code attribué dans l'interfarce GOMC.
  vue_ticket.col_nom AS ET_col_nom, //Nom du caissier. Nom du caissier attribué dans l'interface GOMC.
  vue_ticket.col_prenom AS ET_col_prenom, //Prenom du caissier. Prénom du caissier attrivué dans l'interface GOMC.
  //vue_ticket.col_id AS ET_col_id, //ID du caissier dans la BDD.
  vue_ticket.compute_client_raisoc AS ET_compute_client_raisoc, //Nom du client.
  vue_ticket.tic_badge AS ET_tic_badge, //Numero du badge du client
  vue_ticket.tic_chgt_tva AS ET_tic_chgt_tva, //Changement de TVA dans le ticket OUI / NON (sur place ou emporter)
  (SELECT
      SUM(vue_ticket_sum.compute_ca)
   FROM
      ticket,
      vue_ticket AS vue_ticket_sum
   WHERE
      (vue_ticket_sum.compute_mrg_id IS NOT NULL OR vue_ticket_sum.compute_type_detail = 213) AND
      //vue_ticket.tic_chrono BETWEEN '2021-01-01 00:00:00' AND '2021-01-01 23:59:59'
      //vue_ticket.tic_chrono >= {ParamDate_Debut_1}//'2021-01-01 00:00'
      vue_ticket.tic_chrono BETWEEN {ParamDate_Debut_1} AND {ParamDate_Fin_1}//'2021-01-01 00:00'
      AND ticket.tic_id = vue_ticket_sum.tic_id AND
      ticket.tic_publisher = vue_ticket_sum.tic_publisher AND
      ticket.led_id IS NULL AND //Ticket sans aucun lot ratache
      ticket.led_publisher IS NULL  //Ticket sans aucun lot ratache 
      AND vue_ticket_sum.tic_id = vue_ticket.tic_id
   ) AS ET_total_ticket, //Total du ticket. Addition des lignes avec un mode de reglement ou d'un type de ligne 213 = reglement en compte
  //*************
  //Detail Ticket
  //*************
    vue_ticket.compute_no_ligne AS DT_compute_no_ligne, //Numero de la ligne du ticket. Permet de recontruire le ticket dans l'ordre.  
    vue_ticket.compute_libelle AS DT_compute_libelle, //Libelle de la ligne (Ex: Croissant, pain chocolat, carte bleu, especes...)
    vue_ticket.compute_quantite AS DT_compute_quantite, //Quantite vendu
    vue_ticket.compute_ca AS DT_compute_ca, //Chiffre de la ligne ou du ticket. Le montant afficher sur une ligne de reglement sera la totalite du ticket (si plusieurs reglement) il faut cumuller toutes les lignes de reglements). Le montant est TTC pour les lignes articles.
    omc_f_calcul_ht(vue_ticket.compute_ca,0,0,0,DT_Taux_TVA,0,0,0,0,0,0,2) AS DT_CA_HT, //Montant HT
    ( CONVERT( DECIMAL( 5,2 ),CONVERT( DECIMAL( 7,2 ),COALESCE( detail_ticket_art.dtica_tva, 0 ) ) / 100 ) ) AS DT_Taux_TVA, //Taux de TVA
    //vue_ticket.compute_article_id AS DT_compute_article_id, //ID de l'article dans la BDD. Si vide la ligne ne contient pas d'articles (ex: ligne d'encaissement).
    article.art_reference AS DT_art_reference, // référence de l'article
    vue_ticket.compute_mrg_id AS DT_compute_mrg_id, //ID du mode de reglement dans la BDD. Si vide la ligne ne contient pas de reglement (ex: ligne d'article).
    mode_reglement.mrg_code AS DT_mrg_code, //Code du mode de reglement
    vue_ticket.compute_type_detail AS DT_compute_type_detail //Detail de la ligne voir complement dans le mail   
FROM
  ticket,
  vue_ticket LEFT OUTER JOIN detail_ticket_art ON
       vue_ticket.compute_id = detail_ticket_art.dtica_id AND
        vue_ticket.compute_publisher = detail_ticket_art.dtica_publisher AND
        vue_ticket.compute_article_id IS NOT NULL
        LEFT OUTER JOIN sref_article ON
         sref_article.sra_id = detail_ticket_art.sra_id AND
         sref_article.sra_publisher = detail_ticket_art.sra_publisher
        LEFT OUTER JOIN article ON
          article.art_id = sref_article.art_id AND
          article.art_publisher = sref_article.art_publisher,
vue_ticket LEFT OUTER JOIN detail_ticket_reg ON
        vue_ticket.compute_id = detail_ticket_reg.dticr_id AND
        vue_ticket.compute_publisher = detail_ticket_reg.dticr_publisher AND
        vue_ticket.compute_mrg_id IS NOT NULL,
    detail_ticket_reg LEFT OUTER JOIN mode_reglement ON
        detail_ticket_reg.mrg_id = mode_reglement.mrg_id AND
        detail_ticket_reg.mrg_publisher = mode_reglement.mrg_publisher
WHERE
  ticket.tic_id = vue_ticket.tic_id AND
  ticket.tic_publisher = vue_ticket.tic_publisher AND
  //vue_ticket.tic_chrono BETWEEN '2021-01-01 00:00:00' AND '2021-01-01 23:59:59'
  //vue_ticket.tic_chrono >= {ParamDate_Debut_2}  //Tous les tickets à partir de
  vue_ticket.tic_chrono BETWEEN {ParamDate_Debut_2} AND {ParamDate_Fin_2}  //Tous les tickets à partir de
  AND ticket.led_id IS NULL AND //Ticket sans aucun lot ratache
  ticket.led_publisher IS NULL  //Ticket sans aucun lot ratache 
  --AND ET_compute_terminal_id = {ParamTerminal}
  --and vue_ticket.tic_piece = 1 //Filtre sur le numero de ticket
  --and vue_ticket.compute_terminal = '' //Filtre sur le nom de la sociéte, magasin et terminal
  --and vue_ticket.compute_type_detail = 301 //Filtre sur le type de ligne
ORDER BY
  vue_ticket.tic_chrono ASC,
  vue_ticket.compute_terminal ASC,
  vue_ticket.tic_piece ASC,
  vue_ticket.compute_no_ligne ASC
