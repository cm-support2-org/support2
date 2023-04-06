//Extraction du montant des remises pour un badge donné.
//Cette requette est pour sortir la conso perso des magasins
//Demande de Mr Depraille le 13-03-2023

select
    ticket.tic_chrono as dateTicket,
    magasin.mag_raisoc as nomMagasin,
    article.art_reference as codeArticle,
    vue_detail_ticket_rem.compute_dticm_montant as montantRemise,
    vue_detail_ticket_art.compute_dtica_quantite as quantiteArticle,
    groupe.gro_libelle as nomGroupe,
    famille.fam_libelle as nomFamille,
    sous_famille.sfa_libelle as nomSousFamille,
    ticket.tic_badge as numeroBadge   
From
    vue_detail_ticket_rem,
    vue_detail_ticket_art,
    ticket,
    sref_article,
    article left outer join sous_famille on
        article.sfa_id = sous_famille.sfa_id and
        article.sfa_publisher = sous_famille.sfa_publisher,
    terminal,
    magasin,
    famille left outer join groupe on
        famille.gro_id = groupe.gro_id and
        famille.gro_publisher = groupe.gro_publisher
Where
    ticket.tic_chrono between '2023-03-01 00:00' and '2023-04-01 23:59' and
    ticket.tic_badge = '11119999' and
    vue_detail_ticket_art.dtica_id = vue_detail_ticket_rem.dtica_id and
    vue_detail_ticket_art.dtica_publisher = vue_detail_ticket_rem.dtica_publisher and
    ticket.tic_id =  vue_detail_ticket_rem.tic_id and
    ticket.tic_publisher =  vue_detail_ticket_rem.tic_publisher and   
    vue_detail_ticket_art.sra_id = sref_article.sra_id and
    sref_article.art_id = article.art_id and
    sref_article.art_publisher = article.art_publisher and
    ticket.ter_id = terminal.ter_id and
    ticket.ter_publisher = terminal.ter_publisher and
    terminal.mag_id = magasin.mag_id and
    terminal.mag_publisher = magasin.mag_publisher and
    article.fam_id = famille.fam_id and
    article.fam_publisher = famille.fam_publisher
Order By
    ticket.tic_chrono asc
