
if exists(select 1 from sys.sysprocedure where proc_name = 'cm_enum_periode_ticket') then
   drop procedure cm_enum_periode_ticket
end if;

CREATE PROCEDURE "omc"."cm_enum_periode_ticket"()

BEGIN
declare dateTicket varchar(19);
declare dateDebut varchar(30);
declare dateFin varchar(19);
declare timeDebut varchar(8);
declare timeFin varchar(8);
declare i INTEGER ;
declare DateTimeResult varchar(19);

declare local temporary table t_result(
    chrono_ticket varchar(30) null,
    count_ticket integer null,
    tic_id t_id null,
    tic_publisher t_publisher null,
    tic_type integer null,
    )on commit delete rows;

SET i = 1;

set dateTicket = DATEFORMAT(current timestamp,'YYYY-MM-dd ');
set timeDebut = '' + convert(varchar(2),i) + ':00:00';
set timeFin = '' + convert(varchar(2),i) + ':59:59';

WHILE i <= 23 LOOP

if i < 10 then
       set timeDebut = '0' + convert(varchar(2),i) + ':00:00';
       set timeFin = '0' + convert(varchar(2),i) + ':59:59';
       set i = '0' + i
else
       set timeDebut = convert(varchar(2),i) + ':00:00';
       set timeFin = convert(varchar(2),i) + ':59:59';
end if;

set dateDebut = dateTicket + timeDebut;
set dateFin = dateTicket + timeFin;
set DateTimeResult = dateFin + convert(varchar(2),i);
insert into t_result
    
    select 
        DateTimeResult,
        count(*),
        ticket.tic_id,
        ticket.tic_publisher,
        ticket.tic_type
    from
        ticket,
        detail_ticket        
    Where
        "ticket"."tic_id" = "detail_ticket"."tic_id" and
        "ticket"."tic_publisher" = "detail_ticket"."tic_publisher" AND
        ticket.tic_chrono >= dateDebut and "ticket"."tic_chrono" <= dateFin     
    group by
        ticket.tic_id,
        ticket.tic_publisher,
        tic_type;
SET i = i + 1;

END LOOP;

select 
    chrono_ticket,
    sum(count_ticket) as Nbr_Ticket,
    coalesce("sum"("detail_ticket"."dtic_ca"),'') as "CA",
    coalesce(sum (detail_ticket.dtic_quantite),'0') as Quantite
from 
    t_result,
    detail_ticket
WHERE 
    t_result.tic_id = detail_ticket.tic_id
    and t_result.tic_publisher = detail_ticket.tic_publisher
    and t_result.tic_type = 1
    and detail_ticket.dtic_type_detail = 1
Group By chrono_ticket;
END;

if exists(select 1 from sys.sysprocedure where proc_name = 'omc_http_get_statistiques') then
   drop procedure omc_http_get_statistiques
end if;

CREATE PROCEDURE "omc"."omc_http_get_statistiques"()

BEGIN

    declare ls_type_stat varchar(50);

    set ls_type_stat = HTTP_VARIABLE('statType') ;

    -------------------------------------------------------------------------------
    -- Permet l'affichage du nom, du ca et de la quantité vendu pour la journée
    -------------------------------------------------------------------------------   
    if ls_type_stat = 'CaFamillesJ' then

        Select 
            "famille"."fam_libelle" as "Designation",
            "sum"("detail_ticket"."dtic_ca") as "CA",
            "sum"("detail_ticket"."dtic_quantite") as "Quantite"
        From 
            "ticket",
            detail_ticket left outer join detail_ticket_remise on
                detail_ticket.dtic_id = detail_ticket_remise.dtic_id and
                detail_ticket.dtic_publisher = detail_ticket_remise.dtic_publisher,
            "famille",
             article
        Where 
            "ticket"."tic_id" = "detail_ticket"."tic_id" and 
            "ticket"."tic_publisher" = "detail_ticket"."tic_publisher" and 
            "ticket"."tic_chrono" >= "DATEFORMAT"(current timestamp,'YYYY-MM-dd 00:00:00') and
            "ticket"."tic_chrono" <= "DATEFORMAT"(current timestamp,'YYYY-MM-dd 23:59:59') and
             "detail_ticket"."art_id" = "article"."art_id" and 
            "detail_ticket"."art_publisher" = "article"."art_publisher" and
            "article"."fam_id" = "famille"."fam_id" and
            "article"."fam_publisher" = "famille"."fam_publisher" and
            "ticket"."tic_type" = 1 and
            "detail_ticket"."dtic_type_detail" = 1 and            
            EXISTS 
                (
                    select 1 from ticket, 
                        detail_ticket left outer join detail_ticket_remise on
                            detail_ticket.dtic_id = detail_ticket_remise.dtic_id and
                            detail_ticket.dtic_publisher = detail_ticket_remise.dtic_publisher
                    Where 
                        "ticket"."tic_id" = "detail_ticket"."tic_id" and 
                        "ticket"."tic_publisher" = "detail_ticket"."tic_publisher" and  
                        "ticket"."tic_chrono" >= "DATEFORMAT"(current timestamp,'YYYY-MM-dd 00:00:00') and
                        "ticket"."tic_chrono" <= "DATEFORMAT"(current timestamp,'YYYY-MM-dd 23:59:59')
                )
        Group by 
            Designation          
        Order by 
            "CA" desc
			
    -------------------------------------------------------------------------------
    -- Permet l'affichage des remise effectuées
    -------------------------------------------------------------------------------   
    elseif ls_type_stat = 'DetailRemise' then

        Select 
            "famille"."fam_libelle" as "Designation",
            sum(dticrem_montant_remise) as Montant_Remise,
            "sum"("detail_ticket"."dtic_quantite") as "Quantite",
            detail_ticket_remise.dticrem_taux_remise,
            case dticrem_type_remise
                when 1 then 'Remise Client'
                when 2 then 'Remise Personel'
                when 3 then 'Remise Direction'                
                else 'Autres'
                end as Type_Remise
                    
        From 
            "ticket",
            detail_ticket left outer join detail_ticket_remise on
                detail_ticket.dtic_id = detail_ticket_remise.dtic_id and
                detail_ticket.dtic_publisher = detail_ticket_remise.dtic_publisher,
            "famille",
             article
        Where 
            "ticket"."tic_id" = "detail_ticket"."tic_id" and 
            "ticket"."tic_publisher" = "detail_ticket"."tic_publisher" and 
            "ticket"."tic_chrono" >= "DATEFORMAT"(current timestamp,'YYYY-MM-dd 00:00:00') and
            "ticket"."tic_chrono" <= "DATEFORMAT"(current timestamp,'YYYY-MM-dd 23:59:59') and
             "detail_ticket"."art_id" = "article"."art_id" and 
            "detail_ticket"."art_publisher" = "article"."art_publisher" and
            "article"."fam_id" = "famille"."fam_id" and
            "article"."fam_publisher" = "famille"."fam_publisher" and
            "ticket"."tic_type" = 1 and
            "detail_ticket"."dtic_type_detail" = 1 and            
            detail_ticket_remise.dticrem_taux_remise <> 0
        Group by 
            Designation,
            dticrem_taux_remise,
            dticrem_type_remise     
        Order by 
            Designation asc,
            dticrem_taux_remise desc

    -------------------------------------------------------------------------------
    -- Permet l'affiche des commandes saisie du jours
    -------------------------------------------------------------------------------
    elseif ls_type_stat = 'CommandesJ' then

        Select
            article.art_designation as Designation,
            detail_ticket.dtic_quantite as Quantite,
            tic_date_livraison as date_livraison,
            coalesce(tic_commentaire,'') as Commentaire
        From 
            ticket ,
            detail_ticket,
            article
        Where
            ticket.tic_type = 3 and
            "ticket"."tic_id" = "detail_ticket"."tic_id" and
            "ticket"."tic_publisher" = "detail_ticket"."tic_publisher" AND
            "ticket"."tic_chrono" >= "DATEFORMAT"(current timestamp,'YYYY-MM-dd 00:00:00') and
            "ticket"."tic_chrono" <= "DATEFORMAT"(current timestamp,'YYYY-MM-dd 23:59:59') and
            detail_ticket.art_id = article.art_id and
            detail_ticket.art_publisher = article.art_publisher
        Order By 
            ticket.tic_chrono desc

    ----------------------------------------------------------------
    -- Permet l'affichage du nombre de ticket encaissé dans la journée.
    ----------------------------------------------------------------     
    elseif ls_type_stat = 'CountTicketJ' then

        Select         
            count(*) as nbr_ticket,
            ticket.tic_chrono
        From 
            ticket,
            "detail_ticket"
        Where 
            "ticket"."tic_id" = "detail_ticket"."tic_id" and
            "ticket"."tic_publisher" = "detail_ticket"."tic_publisher" AND
            "ticket"."tic_chrono" >= "DATEFORMAT"(current timestamp,'YYYY-MM-dd 00:00:00') and
            "ticket"."tic_chrono" <= "DATEFORMAT"(current timestamp,'YYYY-MM-dd 23:59:59') and
            "ticket"."tic_type" = 1 and 
            "detail_ticket"."dtic_type_detail" = 1
        Group By
            ticket.tic_chrono
        Order By
            ticket.tic_chrono asc

    -----------------------------------------------------------------------------------
    -- Permet l'affichage du nombre de ticket encaissé dans la journée de l'année dernière.
    -----------------------------------------------------------------------------------
    elseif ls_type_stat = 'CountTicketJN1' then

        Select         
            count(*) as nbr_ticket,
            ticket.tic_chrono
        From 
            ticket,
            "detail_ticket"
        Where 
            "ticket"."tic_id" = "detail_ticket"."tic_id" and
            "ticket"."tic_publisher" = "detail_ticket"."tic_publisher" and
            "ticket"."tic_chrono" >= DATEADD(year, -1, "DATEFORMAT"(current timestamp,'YYYY-MM-dd 00:00:00')) and
            "ticket"."tic_chrono" <= DATEADD(year, -1, "DATEFORMAT"(current timestamp,'YYYY-MM-dd 23:59:59')) and
            "ticket"."tic_type" = 1 and
            "detail_ticket"."dtic_type_detail" = 1
        Group By
            ticket.tic_chrono

    -----------------------------------------------------------------------------------
    -- Permet l'affichage des encaissements de la journée (MRG)
    ------------------------------------------------------------------------------------
    elseif ls_type_stat = 'EncaissementJ' then

        Select
            (convert(decimal(10,2),convert(decimal(13,2),"coalesce"("sum"("omc_f_signe_valeur"("ticket"."tic_type",(case when "detail_ticket"."dtic_type_detail" = 9 then("detail_ticket"."dtic_ca"*-1) else "detail_ticket"."dtic_ca" end))),0)))) as "compute_ca",
          case 
            "detail_ticket"."dtic_type_detail"
            when 4 then "mode_reglement"."mrg_libelle"
            when 5 then "mode_reglement"."mrg_libelle"
            when 6 then "mode_reglement"."mrg_libelle"
            when 7 then "mode_reglement"."mrg_libelle"
            when 8 then "mode_reglement"."mrg_libelle"
            when 9 then "mode_reglement"."mrg_libelle"
            when 10 then "mode_reglement"."mrg_libelle"
            when 25 then 'Avoir Emis'
            when 26 then 'Avoir Utilisé'
            else 'Autre'
          end as "compute_mrg"
        From 
            "detail_ticket" left outer join "mode_reglement" on
                "mode_reglement"."mrg_id" = "detail_ticket"."mrg_id" and 
                "mode_reglement"."mrg_publisher" = "detail_ticket"."mrg_publisher",
            "ticket",
            "compte",
            "terminal",
            "point_vente"
        Where 
            "ticket"."tic_id" = "detail_ticket"."tic_id" and
            "ticket"."tic_publisher" = "detail_ticket"."tic_publisher" and
            "terminal"."ter_id" = "ticket"."ter_id" and
            "terminal"."ter_publisher" = "ticket"."ter_publisher" and
            "terminal"."pdv_id" = "point_vente"."pdv_id" and
            "terminal"."pdv_publisher" = "point_vente"."pdv_publisher" and
            "compte"."com_id" = "ticket"."com_id" and
            "compte"."com_publisher" = "ticket"."com_publisher" and
            "ticket"."tic_type" between 1 and 2 and
            "detail_ticket"."dtic_type_detail" in( 4,6,8,9,25,26 ) and
            "ticket"."tic_chrono" >= "DATEFORMAT"(current timestamp,'YYYY-MM-dd 00:00:00') and
            "ticket"."tic_chrono" <= "DATEFORMAT"(current timestamp,'YYYY-MM-dd 23:59:59') and
            "abs"("detail_ticket"."dtic_acompte") <> 2 and
            "omc_f_autorise_voir"("ticket"."ter_id","ticket"."ter_publisher","ticket"."tic_chrono") = 1
        Group by 
            "detail_ticket"."dtic_type_detail",
            "compute_mrg"
        Having 
            "compute_ca" <> 0
        Order by 
            "compute_ca" desc

    ----------------------------------------------------------------
    -- Permet la récupération des ventes cumuler sur une heure
    ----------------------------------------------------------------
    elseif ls_type_stat = 'PeriodeTicket' then
        select * from "cm_enum_periode_ticket"()

    ----------------------------------------------------------------
    -- Permet la récupération des informations dans le jet
    ----------------------------------------------------------------
    elseif ls_type_stat = 'EventTicketJ' then   
        Select          
            evenement_context,
            evenement_chrono,
            evenement_data_plaintext
        From 
            omc_p_cert_read_journal("adt_chrono_debut" = "DATEFORMAT"(current timestamp,'YYYY-MM-dd 00:00:00'),"adt_chrono_fin" = "DATEFORMAT"(current timestamp,'YYYY-MM-dd 23:59:59')) 
        Where 
            (evenement_context = 'Ouverture Tiroir' or evenement_context = 'Annulation Ticket' or evenement_context = 'Suppression Ligne')
        Order By
            evenement_chrono desc  

    ----------------------------------------------------------------
	-- Permet l'affichage de la date du dernier ticket + le nom du caissier
    ---------------------------------------------------------------- 
    elseif ls_type_stat = 'LastTicketJ' then
  
        Select 
            top 1 coalesce("DATEFORMAT"("max"("ticket"."tic_chrono"),'dd-MM-YYYY HH:mm:SS'),'00-00-0000 00:00:00') as "LastTicket",
            string(utilisateur.uti_raisoc + '  ' + utilisateur.uti_prenom + ' ['+ utilisateur.uti_code +']')
        From 
            ticket,
            utilisateur
        Where 
            ticket.tic_chrono >= DATEFORMAT(current timestamp,'YYYY-MM-dd 00:00:00') and 
            ticket.tic_chrono <= DATEFORMAT(current timestamp,'YYYY-MM-dd 23:59:59') and
            ticket.tic_type = 1 and
            ticket.uti_id = utilisateur.uti_id
        Group by 
            utilisateur.uti_raisoc,
            utilisateur.uti_prenom,
            utilisateur.uti_code

    ----------------------------------------------------------------
    -- Permet l'affichage du panier moyen de la journée
    ----------------------------------------------------------------
    elseif ls_type_stat = 'PannierMoyenJ' then

        Select 
            cast
                (
                    (
                        Select
                            coalesce(sum(detail_ticket.dtic_ca),'0') as CA_Article
                        From
                            ticket,
                            detail_ticket
                        Where
                            ticket.tic_id = detail_ticket.tic_id and
                            ticket.tic_publisher = detail_ticket.tic_publisher and
                            ticket.tic_chrono >= DATEFORMAT(current timestamp,'YYYY-MM-dd 00:00:00') and
                            ticket.tic_chrono <= DATEFORMAT(current timestamp,'YYYY-MM-dd 23:59:59') and
                            ticket.tic_type = 1  and
                            detail_ticket.dtic_type_detail = 1
                    )
                /
                    (
                        Select 
                            coalesce(sum(ticket.tic_guest),'0')
                        From 
                            ticket 
                        Where 
                            ticket.tic_chrono >= DATEFORMAT(current timestamp,'YYYY-MM-dd 00:00:00') and
                            ticket.tic_chrono <= DATEFORMAT(current timestamp,'YYYY-MM-dd 23:59:59') and
                            ticket.tic_type = 1
                    )as t_montant
                ) as total

    ----------------------------------------------------------------
    -- Permet l'affichage du panier moyen de la journée de l'année dernière
    ----------------------------------------------------------------
    elseif ls_type_stat = 'PannierMoyenJN1' then

        Select 
            cast
                (
                    (
                        Select
                            coalesce(sum(detail_ticket.dtic_ca),'0') as CA_Article
                        From
                            ticket,
                            detail_ticket
                        Where
                            ticket.tic_id = detail_ticket.tic_id and
                            ticket.tic_publisher = detail_ticket.tic_publisher and
                            "ticket"."tic_chrono" >= DATEADD(year, -1, "DATEFORMAT"(current timestamp,'YYYY-MM-dd 00:00:00')) and
                            "ticket"."tic_chrono" <= DATEADD(year, -1, "DATEFORMAT"(current timestamp,'YYYY-MM-dd 23:59:59')) and   
                            ticket.tic_type = 1  and
                            detail_ticket.dtic_type_detail = 1
                    )
                /
                    (
                        Select 
                            coalesce(sum(ticket.tic_guest),'0')
                        From 
                            ticket 
                        Where 
                            "ticket"."tic_chrono" >= DATEADD(year, -1, "DATEFORMAT"(current timestamp,'YYYY-MM-dd 00:00:00')) and
                            "ticket"."tic_chrono" <= DATEADD(year, -1, "DATEFORMAT"(current timestamp,'YYYY-MM-dd 23:59:59')) and
                            ticket.tic_type = 1
                    )as t_montant
                ) as total

    ----------------------------------------------------------------
    -- Permet l'affichage de stats en rapport avec les ticket sur la journée
    ----------------------------------------------------------------
    elseif ls_type_stat = 'StatsJ' then

        Select 
            coalesce("sum"("detail_ticket"."dtic_ca"),'') as "CA",
            coalesce(sum (detail_ticket.dtic_quantite),'0') as Quantite,
            count(*) as Nbr_Ticket
        From 
            ticket ,
            detail_ticket
        Where ticket.tic_id = detail_ticket.tic_id and
            ticket.tic_publisher = detail_ticket.tic_publisher AND
        	ticket.tic_chrono >= DATEFORMAT(current timestamp,'YYYY-MM-dd 00:00:00') and
        	ticket.tic_chrono <= DATEFORMAT(current timestamp,'YYYY-MM-dd 23:59:59') and
            ticket.tic_type = 1 and
            detail_ticket.dtic_type_detail = 1

    -------------------------------------------------------------------------------------------------------
    -- Permet l'affichage de stats en rapport avec les ticket sur la journée par rapport à l'année dernière
    -------------------------------------------------------------------------------------------------------
    elseif ls_type_stat = 'StatsJN1' then

        Select 
            coalesce("sum"("detail_ticket"."dtic_ca"),'') as "CA",
            coalesce(sum (detail_ticket.dtic_quantite),'0') as Quantite,
            count(*) as Nbr_Ticket
        From 
            ticket,
            detail_ticket
        Where ticket.tic_id = detail_ticket.tic_id and
            ticket.tic_publisher = detail_ticket.tic_publisher AND
        	"ticket"."tic_chrono" >= DATEADD(year, -1, "DATEFORMAT"(current timestamp,'YYYY-MM-dd 00:00:00')) and
            "ticket"."tic_chrono" <= DATEADD(year, -1, "DATEFORMAT"(current timestamp,'YYYY-MM-dd 23:59:59')) and
            ticket.tic_type = 1 and
            detail_ticket.dtic_type_detail = 1

    ----------------------------------------------------------------
    -- Affichage du top10 des articles vendue
    ---------------------------------------------------------------- 
    elseif ls_type_stat = 'topSellArticles' then   
        Select
            top 10 article.art_designation as Designation_Article,
            sum(detail_ticket.dtic_ca) as CA_Article_TTC,
            sum(detail_ticket.dtic_ca_ht) as CA_Article_HT,
            sum (detail_ticket.dtic_quantite) as Quantite
        From
            ticket,
            detail_ticket,
            article
        Where
            ticket.tic_id = detail_ticket.tic_id and
            ticket.tic_publisher = detail_ticket.tic_publisher and
            "ticket"."tic_chrono" >= "DATEFORMAT"(current timestamp,'YYYY-MM-dd 00:00:00') and
            "ticket"."tic_chrono" <= "DATEFORMAT"(current timestamp,'YYYY-MM-dd 23:59:59') and
            detail_ticket.art_id = article.art_id and    
            detail_ticket.art_publisher = article.art_publisher and    
            ticket.tic_type = 1  and
            detail_ticket.dtic_type_detail = 1                                
        Group By
            Designation_Article
        Order By
            CA_Article_TTC desc

    ----------------------------------------------------------------
    -- Permet de savoir si la sauvegarde date de moins de 7 jour.
    -- 0 NON
    -- 1 OUI
    ---------------------------------------------------------------- 
    elseif ls_type_stat = 'backupIsUpToDate' then   
    select omc_f_is_valide((Select date(cert_parametrage.cpar_chrono_backup) From cert_parametrage),dateadd( day,-7, now() )) as backup_date_is_up_to_date
    end if;
END;


if exists( select 1 from sys.syswebservice where service_name='getStatistics' ) then 
	drop service "getStatistics"
end if;
CREATE SERVICE "getStatistics" TYPE 'JSON' AUTHORIZATION OFF USER "omc" METHODS 'HEAD,GET' AS call "omc_http_get_statistiques"();
commit
