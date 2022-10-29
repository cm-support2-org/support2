
if exists(select 1 from sys.sysprocedure where proc_name = 'cm_enum_periode_ticket') then
   drop procedure cm_enum_periode_ticket
end if;

CREATE PROCEDURE "omc"."cm_enum_periode_ticket"(in dateLastYear t_boolean default null)
    
BEGIN
    declare dateTicket varchar(19);
    declare dateDebut varchar(30);
    declare dateFin varchar(19);
    declare timeDebut varchar(8);
    declare timeFin varchar(8);
    declare i INTEGER ;
    declare DateTimeResult varchar(19);

    declare date1 LONG VARCHAR;
    declare date2 LONG VARCHAR;
    declare dateDiff LONG VARCHAR;

    declare local temporary table t_result(
    chrono_ticket varchar(30) null,
    count_ticket integer null,
    tic_id t_id null,
    tic_publisher t_publisher null,
    tic_type integer null,
    )on commit delete rows;

    set i = 1;

    set date1 = DATEPART( weekday , current date);
    set date2 = DATEPART( weekday , dateadd(year, -1,current date));
    set dateDiff = (date1 - date2) ;

--Est ce que doit prendre la date de l'année dernière ?
if dateLastYear = 0 THEN 
    set dateTicket = DATEFORMAT(current date,'YYYY-MM-dd ');
elseif dateLastYear = 1 then
      --set dateTicket = DATEFORMAT(DATEADD(year, -1, (select DATEADD(day,( DATEPART( Weekday , current date) - DATEPART( Weekday , DATEADD(year, -1, current date))), current date))), 'YYYY-MM-dd ')
      set dateTicket = DATEFORMAT(DATEADD(day,+(select dateDiff from dummy),dateadd(year, -1,current date)), 'YYYY-MM-dd ')
end if;

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
		(Select 
            count(*) as Nbr_Ticket
        From 
            ticket
            
        Where 			
        	ticket.tic_chrono >= dateDebut and "ticket"."tic_chrono" <= dateFin and
            ticket.tic_type = 1) as Nbr_Ticket,
           
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
    case dateLastYear       
        when 0 then DATEFORMAT(chrono_ticket,'YYYY-MM-dd HH:mm:SS')
        --when 1 then dateformat(dateadd(year, +1, dateadd(day, DATEPART( Weekday , DATEADD(year, -1, chrono_ticket)) - DATEPART( Weekday ,( chrono_ticket)),chrono_ticket)),'YYYY-MM-dd HH:mm:SS')
        when 1 then DATEADD(day,-(select dateDiff from dummy),dateadd(year, +1,chrono_ticket))
    else ''
    end as tic_date,
    count_ticket as Nbr_Ticket,
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
Group By chrono_ticket ,Nbr_Ticket;
END;

if exists(select 1 from sys.sysprocedure where proc_name = 'omc_http_get_statistiques') then
   drop procedure omc_http_get_statistiques
end if;

CREATE PROCEDURE "omc"."omc_http_get_statistiques"()

    --------------------------------------------------------------------------
    -- Cette procèdure regroupe plusieurs type de stats
    --------------------------------------------------------------------------
BEGIN

    declare ls_type_stat varchar(50);
    declare ls_time_to varchar(500);
    declare ls_time_from varchar(500);
    declare CA_N decimal;
    declare CA_N1 decimal;

    declare date1 LONG VARCHAR;
    declare date2 LONG VARCHAR;
    declare dateDiff LONG VARCHAR;
    declare dateDebut long varchar;
    declare dateFin long varchar;

    set date1 = DATEPART( weekday , current date);
    set date2 = DATEPART( weekday , dateadd(year, -1,current date));
    set dateDiff = (date1 - date2) ;
    set dateDebut = DATEFORMAT(current timestamp,'YYYY-MM-dd 00:00:00');
    set dateFin = DATEFORMAT(current timestamp,'YYYY-MM-dd 23:59:59');

    set ls_type_stat = HTTP_VARIABLE('statType') ;
    set ls_time_from = DATEFORMAT(dateadd( hour, +2 , HTTP_VARIABLE('time_from')),'YYYY-mm-dd HH:MM:SS');    
    set ls_time_to = DATEFORMAT(dateadd( hour, +2 , HTTP_VARIABLE('time_to')),'YYYY-mm-dd HH:MM:SS');    

    ----------------------------------------------------------------------------------------------------
    -- Permet l'affichage du nom, du ca et de la quantitée vendu pour la journée en cours par familles
    ----------------------------------------------------------------------------------------------------
    if ls_type_stat = 'CaFamillesJ' then

        Select 
            famille.fam_libelle as Designation,
            sum(detail_ticket.dtic_ca) as CA,
            sum(detail_ticket.dtic_quantite) as Quantite
        From 
            ticket,
            detail_ticket left outer join detail_ticket_remise on
                detail_ticket.dtic_id = detail_ticket_remise.dtic_id and
                detail_ticket.dtic_publisher = detail_ticket_remise.dtic_publisher,
            famille,
            article
        Where 
            ticket.tic_id = detail_ticket.tic_id and 
            ticket.tic_publisher = detail_ticket.tic_publisher and 
            ticket.tic_chrono >= dateDebut and
            ticket.tic_chrono <= dateFin and
            detail_ticket.art_id = article.art_id and 
            detail_ticket.art_publisher = article.art_publisher and
            article.fam_id = famille.fam_id and
            article.fam_publisher = famille.fam_publisher and
            ticket.tic_type = 1 and
            detail_ticket.dtic_type_detail = 1 and            
            EXISTS 
                (
                    select 1 from ticket, 
                        detail_ticket left outer join detail_ticket_remise on
                            detail_ticket.dtic_id = detail_ticket_remise.dtic_id and
                            detail_ticket.dtic_publisher = detail_ticket_remise.dtic_publisher
                    Where 
                        ticket.tic_id = detail_ticket.tic_id and 
                        ticket.tic_publisher = detail_ticket.tic_publisher and  
                        ticket.tic_chrono >= dateDebut and
                        ticket.tic_chrono <= dateFin
                )
        Group by 
            Designation          
        Order by 
            CA desc
			
    -------------------------------------------------------------------------------
    -- Permet l'affichage des remise effectuées pour la journée en cours
    -------------------------------------------------------------------------------   
    elseif ls_type_stat = 'DetailRemise' then

        Select 
            article.art_designation as Designation,
            sum(dticrem_montant_remise) as Montant_Remise,
            sum(detail_ticket.dtic_quantite) as Quantite,
            detail_ticket_remise.dticrem_taux_remise,
            case dticrem_type_remise
                when 1 then 'Remise Client'
                when 2 then 'Remise Personel'
                when 3 then 'Remise Direction'                
                else 'Autres'
                end as Type_Remise                   
        From 
            ticket,
            detail_ticket left outer join detail_ticket_remise on
                detail_ticket.dtic_id = detail_ticket_remise.dtic_id and
                detail_ticket.dtic_publisher = detail_ticket_remise.dtic_publisher,           
            article
        Where 
            ticket.tic_id = detail_ticket.tic_id and 
            ticket.tic_publisher = detail_ticket.tic_publisher and 
            ticket.tic_chrono >= dateDebut and
            ticket.tic_chrono <= dateFin and
            detail_ticket.art_id = article.art_id and 
            detail_ticket.art_publisher = article.art_publisher and
            ticket.tic_type = 1 and
            detail_ticket.dtic_type_detail = 1 and            
            detail_ticket_remise.dticrem_taux_remise <> 0
        Group by 
            Designation,
            dticrem_taux_remise,
            dticrem_type_remise     
        Order by 
            dticrem_taux_remise desc,
            Designation desc

    -------------------------------------------------------------------------------
    -- Permet l'affiche des commandes saisie du jours
    -------------------------------------------------------------------------------
    elseif ls_type_stat = 'CommandesJ' then

        Select
            article.art_designation as Designation,
            detail_ticket.dtic_quantite as Quantite,
            tic_date_livraison as date_livraison,
            coalesce(tic_commentaire,'') as Commentaire,
            sum(detail_ticket.dtic_ca) as CA
        From 
            ticket ,
            detail_ticket,
            article
        Where
            ticket.tic_type = 3 and
            ticket.tic_id = detail_ticket.tic_id and
            ticket.tic_publisher = detail_ticket.tic_publisher AND
            ticket.tic_chrono >= dateDebut and
            ticket.tic_chrono <= dateFin and
            detail_ticket.art_id = article.art_id and
            detail_ticket.art_publisher = article.art_publisher
         Group By
            tic_chrono,
            Designation,
            Quantite,
            date_livraison,
            Commentaire
        Order By 
            ticket.tic_chrono desc   

    -----------------------------------------------------------------------------------
    -- Permet l'affichage des encaissements de la journée (MRG)
    ------------------------------------------------------------------------------------
    elseif ls_type_stat = 'EncaissementJ' then

        SELECT
			( convert( decimal( 10,2 ),convert( decimal( 13,2 ),coalesce(sum( omc_f_signe_valeur ( ticket.tic_type, ( case when detail_ticket.dtic_type_detail = 9 then ( detail_ticket.dtic_ca * -1 ) else detail_ticket.dtic_ca end ) ) ) , 0 ) ) ) )  as compute_ca, 
			case detail_ticket.dtic_type_detail
				When 4 then mode_reglement.mrg_libelle
				When 5 then mode_reglement.mrg_libelle
				When 6 then mode_reglement.mrg_libelle
				When 7 then mode_reglement.mrg_libelle
				When 8 then mode_reglement.mrg_libelle
				When 9 then mode_reglement.mrg_libelle
				When 10 then mode_reglement.mrg_libelle 
				When 25 then 'Avoir Emis'                         
				When 26 then 'Avoir Utilisé'
			else 'Autre'
			end as compute_mrg,
			count(*) as Nbr_Ticket
		FROM 
			detail_ticket left outer join mode_reglement on 
				mode_reglement.mrg_id = detail_ticket.mrg_id and 
				mode_reglement.mrg_publisher = detail_ticket.mrg_publisher,
			ticket,
			terminal, point_vente
		WHERE 
			ticket.tic_id = detail_ticket.tic_id and  
			ticket.tic_publisher = detail_ticket.tic_publisher and  
			terminal.ter_id = ticket.ter_id and  
			terminal.ter_publisher = ticket.ter_publisher and
			terminal.pdv_id = point_vente.pdv_id and
			terminal.pdv_publisher = point_vente.pdv_publisher and
			ticket.tic_type between 1 and 2 and			
			detail_ticket.dtic_type_detail in ( 4, 6, 8, 9,25,26 ) and 
			ticket.tic_chrono >= dateDebut and
			ticket.tic_chrono <= dateFin and
			abs(detail_ticket.dtic_acompte) <> 2 and
			omc_f_autorise_voir( ticket.ter_id, ticket.ter_publisher, ticket.tic_chrono ) = 1
		GROUP BY 
			mode_reglement.mrg_libelle,
			compute_mrg
		HAVING 
			compute_ca <> 0
		Order By
			compute_ca desc 

    -------------------------------------------------------------------------------------
    -- Permet la récupération des ventes cumuler sur une heure pour la journée en cours
    -------------------------------------------------------------------------------------
    elseif ls_type_stat = 'PeriodeTicket' then
        call cm_enum_periode_ticket(dateLastYear = 0)
		
	-------------------------------------------------------------------------------------
    -- Permet la récupération des ventes cumuler sur une heure de l'année dernière
    -------------------------------------------------------------------------------------
    elseif ls_type_stat = 'PeriodeTicketN1' then
        call cm_enum_periode_ticket(dateLastYear = 1)

    ----------------------------------------------------------------
    -- Permet la récupération des informations du jet
    ----------------------------------------------------------------
    elseif ls_type_stat = 'EventTicketJ' then   
        Select          
            evenement_context,
            dateformat(evenement_chrono, 'HH:mm:SS') as chrono,
            evenement_utilisateur,
            evenement_data_plaintext
        From 
            omc_p_cert_read_journal(adt_chrono_debut = dateDebut,adt_chrono_fin = dateFin) 
        Where 
            (evenement_context = 'Ouverture Tiroir' or evenement_context = 'Annulation Ticket' or evenement_context = 'Suppression Ligne')
        Order By
            chrono desc  

    ----------------------------------------------------------------------------------
	-- Permet l'affichage de la date + le nom du caissier du dernier ticket effectuée
    ---------------------------------------------------------------------------------- 
    elseif ls_type_stat = 'LastTicketJ' then
  
        Select 
           top 1 max(ticket.tic_chrono) as tic_chrono,
           string(DATEFORMAT(max(ticket.tic_chrono),'dd-MM-YYYY HH:mm:SS')+ ' / ' + utilisateur.uti_raisoc + '  ' + utilisateur.uti_prenom + ' ['+ utilisateur.uti_code +']' ) as Ticket           
        From 
            ticket,
            utilisateur
        Where 
            ticket.tic_chrono >= dateDebut and 
            ticket.tic_chrono <= dateFin and
            ticket.tic_type = 1 and
            ticket.uti_id = utilisateur.uti_id and
            ticket.uti_publisher = utilisateur.uti_publisher
        Group by 
            utilisateur.uti_raisoc,
            utilisateur.uti_prenom,
            utilisateur.uti_code
        Order by
            tic_chrono desc

    ----------------------------------------------------------------
    -- Permet l'affichage du panier moyen de la journée en cours
    ----------------------------------------------------------------
    elseif ls_type_stat = 'PannierMoyenJ' then

        Select 
            cast
                (
                    (
                        Select
                            coalesce(sum(detail_ticket.dtic_ca),0) as CA_Article
                        From
                            ticket,
                            detail_ticket
                        Where
                            ticket.tic_id = detail_ticket.tic_id and
                            ticket.tic_publisher = detail_ticket.tic_publisher and
                            ticket.tic_chrono >= dateDebut and
                            ticket.tic_chrono <= dateFin and
                            ticket.tic_type = 1  and
                            detail_ticket.dtic_type_detail = 1
                    )
                /
                    (
                        Select 
                            coalesce(sum(ticket.tic_guest),0)
                        From 
                            ticket 
                        Where 
                            ticket.tic_chrono >= dateDebut and
                            ticket.tic_chrono <= dateFin and
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
                            coalesce(sum(detail_ticket.dtic_ca),0) as CA_Article
                        From
                            ticket,
                            detail_ticket
                        Where
                            ticket.tic_id = detail_ticket.tic_id and
                            ticket.tic_publisher = detail_ticket.tic_publisher and
                            ticket.tic_chrono >= DATEADD(year, -1, dateDebut) and
                            ticket.tic_chrono <= DATEADD(year, -1, DATEFORMAT(current timestamp,'YYYY-MM-dd ' + cast(current time as varchar(8)))) and  
                            ticket.tic_type = 1 and
                            detail_ticket.dtic_type_detail = 1
                    )
                /
                    (
                        Select 
                            coalesce(sum(ticket.tic_guest),0)
                        From 
                            ticket 
                        Where 
                            ticket.tic_chrono >= DATEADD(year, -1, dateDebut) and
                            ticket.tic_chrono <= DATEADD(year, -1, DATEFORMAT(current timestamp,'YYYY-MM-dd ' + cast(current time as varchar(8)))) and
                            ticket.tic_type = 1
                    )as t_montant
                ) as total

    ----------------------------------------------------------------
    -- Permet l'affichage de stats en rapport avec les ticket sur la journée
    ----------------------------------------------------------------
    elseif ls_type_stat = 'StatsJ' then

        Select 
            coalesce(sum(detail_ticket.dtic_ca),0) as CA,
            coalesce(sum (detail_ticket.dtic_quantite),0) as Quantite,
            (
                Select 
                    count(*)
                From 
                    ticket                  
               Where 
                	ticket.tic_chrono >= dateDebut and
                	ticket.tic_chrono <= dateFin and
                    ticket.tic_type = 1
            ) as Nbr_Ticket
        From 
            ticket,
            detail_ticket
        Where 
			ticket.tic_id = detail_ticket.tic_id and
            ticket.tic_publisher = detail_ticket.tic_publisher AND
        	ticket.tic_chrono >= dateDebut and
        	ticket.tic_chrono <= dateFin and
            ticket.tic_type = 1 and
            detail_ticket.dtic_type_detail = 1

    -------------------------------------------------------------------------------------------------------
    -- Permet l'affichage de stats en rapport avec les ticket sur la journée par rapport à l'année dernière
    -------------------------------------------------------------------------------------------------------
    elseif ls_type_stat = 'StatsJN1' then

        Select 
            coalesce(sum(detail_ticket.dtic_ca),0) as CA,
            coalesce(sum (detail_ticket.dtic_quantite),0) as Quantite,
            (
                Select 
                    count(*)
                From 
                    ticket                  
                Where 
                	ticket.tic_chrono >= DATEFORMAT(DATEADD(day,+(select dateDiff from dummy),dateadd(year, -1,current date)), 'YYYY-MM-dd 00:00:00') and 
                    ticket.tic_chrono <=DATEFORMAT(DATEADD(day,+(select dateDiff from dummy),dateadd(year, -1,current date)), 'YYYY-MM-dd ' + cast(current time as varchar(8))) and
                    ticket.tic_type = 1
            ) as Nbr_Ticket
        From 
            ticket,
            detail_ticket
        Where ticket.tic_id = detail_ticket.tic_id and
            ticket.tic_publisher = detail_ticket.tic_publisher AND
            ticket.tic_chrono >= DATEFORMAT(DATEADD(day,+(select dateDiff from dummy),dateadd(year, -1,current date)), 'YYYY-MM-dd 00:00:00') and               
            ticket.tic_chrono <= DATEFORMAT(DATEADD(day,+(select dateDiff from dummy),dateadd(year, -1,current date)), 'YYYY-MM-dd ' + cast(current time as varchar(8))) and
            ticket.tic_type = 1 and
            detail_ticket.dtic_type_detail = 1

    -------------------------------------------------------------------------------------------------------
    -- Permet l'affichage la progression du CA
    -------------------------------------------------------------------------------------------------------
    elseif ls_type_stat = 'Progression' then
    select ((  Select 
            coalesce(sum(detail_ticket.dtic_ca),'') as CA       
        From 
            ticket,
            detail_ticket
        Where 
			ticket.tic_id = detail_ticket.tic_id and
            ticket.tic_publisher = detail_ticket.tic_publisher AND
        	ticket.tic_chrono >= dateDebut and
        	ticket.tic_chrono <= dateFin and
            ticket.tic_type = 1 and
            detail_ticket.dtic_type_detail = 1)
 -  (Select 
            coalesce(sum(detail_ticket.dtic_ca),0) as CA          
        From 
            ticket,
            detail_ticket
        Where ticket.tic_id = detail_ticket.tic_id and
            ticket.tic_publisher = detail_ticket.tic_publisher AND
            ticket.tic_chrono >= DATEFORMAT(DATEADD(day,+(select dateDiff from dummy),dateadd(year, -1,current date)), 'YYYY-MM-dd 00:00:00') and               
            ticket.tic_chrono <= DATEFORMAT(DATEADD(day,+(select dateDiff from dummy),dateadd(year, -1,current date)), 'YYYY-MM-dd ' + cast(current time as varchar(8))) and
            ticket.tic_type = 1 and
            detail_ticket.dtic_type_detail = 1
        )) *100 / (Select 
            coalesce(sum(detail_ticket.dtic_ca),0) as CA          
        From 
            ticket,
            detail_ticket
        Where ticket.tic_id = detail_ticket.tic_id and
            ticket.tic_publisher = detail_ticket.tic_publisher AND
            ticket.tic_chrono >= DATEFORMAT(DATEADD(day,+(select dateDiff from dummy),dateadd(year, -1,current date)), 'YYYY-MM-dd 00:00:00') and               
            ticket.tic_chrono <= DATEFORMAT(DATEADD(day,+(select dateDiff from dummy),dateadd(year, -1,current date)), 'YYYY-MM-dd ' + cast(current time as varchar(8))) and
            ticket.tic_type = 1 and
            detail_ticket.dtic_type_detail = 1) as Progression

	-------------------------------------------------------------------------------------------------------
    -- Permet l'affichage les encaissements par caissiers
    -------------------------------------------------------------------------------------------------------
    elseif ls_type_stat = 'sellVendor' then

          Select 
            string(utilisateur.uti_raisoc + '  ' + utilisateur.uti_prenom + ' ['+ utilisateur.uti_code +']') as Caissier,
            sum(detail_ticket.dtic_ca) as CA,
            sum(detail_ticket.dtic_quantite) as Quantite
        From 
            ticket,
            detail_ticket left outer join detail_ticket_remise on
                detail_ticket.dtic_id = detail_ticket_remise.dtic_id and
                detail_ticket.dtic_publisher = detail_ticket_remise.dtic_publisher,
            utilisateur,
             article
        Where 
            ticket.tic_id = detail_ticket.tic_id and 
            ticket.tic_publisher = detail_ticket.tic_publisher and 
            ticket.tic_chrono >= dateDebut and
            ticket.tic_chrono <= dateFin and
             detail_ticket.art_id = article.art_id and 
            detail_ticket.art_publisher = article.art_publisher and
            utilisateur.uti_id = ticket.uti_id and
            utilisateur.uti_publisher = ticket.uti_publisher and
            ticket.tic_type = 1 and
            detail_ticket.dtic_type_detail = 1 and           
            EXISTS 
                (
                    select 1 from ticket, 
                        detail_ticket left outer join detail_ticket_remise on
                            detail_ticket.dtic_id = detail_ticket_remise.dtic_id and
                            detail_ticket.dtic_publisher = detail_ticket_remise.dtic_publisher
                    Where 
                        ticket.tic_id = detail_ticket.tic_id and 
                        ticket.tic_publisher = detail_ticket.tic_publisher and  
                        ticket.tic_chrono >= dateDebut and
                        ticket.tic_chrono <= dateFin
                )
        Group by 
            utilisateur.uti_raisoc,
            utilisateur.uti_code,  
            utilisateur.uti_prenom       
        Order by 
            CA desc

    ----------------------------------------------------------------
    -- Affichage du top10 des articles vendue
    ---------------------------------------------------------------- 
    elseif ls_type_stat = 'topSellArticles' then   

        Select
            top 10 article.art_designation as Designation_Article,
            sum(detail_ticket.dtic_ca) as CA_Article_TTC,          
            sum (detail_ticket.dtic_quantite) as Quantite
        From
            ticket,
            detail_ticket,
            article
        Where
            ticket.tic_id = detail_ticket.tic_id and
            ticket.tic_publisher = detail_ticket.tic_publisher and
            ticket.tic_chrono > dateDebut and           
            detail_ticket.art_id = article.art_id and    
            detail_ticket.art_publisher = article.art_publisher and    
            ticket.tic_type = 1  and
            detail_ticket.dtic_type_detail = 1                                
        Group By
            Designation_Article
        Order By
            CA_Article_TTC desc
    ----------------------------------------------------------------
    -- Affichage du CA mois par mois sur l'année en cours
    ---------------------------------------------------------------- 
    elseif ls_type_stat = 'CaMonth' then   

    select 
        DATEFORMAT(ticket.tic_chrono, 'MM') as chrono,
        sum(detail_ticket.dtic_ca) as CA
    From 
        ticket,
        detail_ticket
    Where 
        ticket.tic_id = detail_ticket.tic_id
        and ticket.tic_publisher = detail_ticket.tic_publisher
        and ticket.tic_type = 1
        and detail_ticket.dtic_type_detail = 1 and
        ticket.tic_chrono >= DATEFORMAT(current timestamp,'YYYY-01-01 00:00:00') and
        ticket.tic_chrono <= DATEFORMAT(current timestamp,'YYYY-12-31 23:59:59')
    Group by 
        chrono
    Order by
        chrono asc
	
    ----------------------------------------------------------------
    -- Affichage du CA années par années 
    ---------------------------------------------------------------- 
    elseif ls_type_stat = 'CaYears' then   

    select 
        DATEFORMAT(ticket.tic_chrono, 'YYYY') as chrono,
        sum(detail_ticket.dtic_ca) as CA
    From 
        ticket,
        detail_ticket
    Where 
        ticket.tic_id = detail_ticket.tic_id
        and ticket.tic_publisher = detail_ticket.tic_publisher
        and ticket.tic_type = 1
        and detail_ticket.dtic_type_detail = 1 and
        ticket.tic_chrono >= '2000-01-01 00:00:00' and
        ticket.tic_chrono <= DATEFORMAT(current timestamp,'YYYY-12-31 23:59:59')
    Group by 
        chrono
    Order by
        chrono asc

    ----------------------------------------------------------------
    -- Affichage des démarques
    ---------------------------------------------------------------- 
    elseif ls_type_stat = 'Demarques' then   
    select 
        dateformat(ticket.tic_chrono, 'HH:mm:SS') as chrono,
        article.art_designation as Designation,
        detail_ticket.dtic_quantite as Quantite,
        sum(detail_ticket.dtic_ca) as CA
    from 
        ticket, 
        detail_ticket,
        article
    where 
        ticket.tic_id = detail_ticket.tic_id and 
        ticket.tic_publisher = detail_ticket.tic_publisher and 
        ticket.tic_chrono >= dateDebut and 
        ticket.tic_chrono <= datefin and
        article.art_id = detail_ticket.art_id and
        article.art_publisher = detail_ticket.art_publisher and
        dtic_type_detail = 14
    Group by
        chrono,
        Designation,
        Quantite
    Order By      
        CA desc,
        Quantite desc

    ----------------------------------------------------------------
    -- Permet de savoir si la sauvegarde date de moins de 7 jour.
    -- 0 NON
    -- 1 OUI
    ---------------------------------------------------------------- 
    elseif ls_type_stat = 'backupIsUpToDate' then   
    select omc_f_is_valide((Select date(cert_parametrage.cpar_chrono_backup) From cert_parametrage),dateadd( day,-7, now() )) as backup_date_is_up_to_date
    end if;
END;

if exists(select 1 from sys.sysprocedure where proc_name = 'omc_http_get') then
   drop procedure omc_http_get
end if;

CREATE PROCEDURE "omc"."omc_http_get"( in "httpUrl" long varchar ) 
result( 
  "http_column" long varchar,
  "http_value" long varchar,
  "http_instance" integer ) 
url '!httpUrl'
type 'HTTP:GET'
header 'User-Agent:SATest';

if exists(select 1 from sys.sysprocedure where proc_name = 'omc_http_get_weather') then
   drop procedure omc_http_get_weather
end if;

CREATE PROCEDURE "omc"."omc_http_get_weather"()

BEGIN

    //Récupération des info météo via le code postal de la société
    declare chrono t_date;
    declare urlForWeather varchar(2000);   
    declare ls_type_stat varchar(50);
    declare postalCode varchar(5);

    set ls_type_stat = HTTP_VARIABLE('statType') ;   
    --set urlForWeather = 'http://api.open-meteo.com/v1/forecast?latitude=43.23&longitude=6.08&daily=weathercode&timezone=Europe%2FLondon&start_date=' + dateformat(chrono , 'YYYY-mm-DD')+ '&end_date=' + dateformat(chrono , 'YYYY-mm-DD') + '';
    set postalCode = (select omc.societe.soc_codepostal from societe);    
    set urlForWeather = 'https://api.openweathermap.org/data/2.5/weather?zip=' + postalCode + ',FR&appid=4829467b995488ac55585ae94e7845ad&units=metric&lang=fr';    
    set chrono =  current timestamp;

    if not exists ( select 1 from weather where wt_chrono = dateformat(chrono , 'YYYY-mm-DD')) then
        INSERT INTO weather
        (wt_id, wt_publisher, wt_chrono, wt_json)
        VALUES(null ,'a',dateformat(chrono , 'YYYY-mm-DD'),(select http_value from omc_http_get(urlForWeather) Where http_column = 'Body'));
        commit      
    end if;

    -------------------------------------------------------------------------------------
    -- Permet la récupération des informations météo de l'annnée en cours
    -- Avec la procèdure omc_http_get_weather on vérifié qu'une ligne de météo est présente.
    -------------------------------------------------------------------------------------
    if ls_type_stat = 'weatherJ' then
        
        select wt_json from weather where dateformat(wt_chrono,'YYYY-MM-dd') = DATEFORMAT(current timestamp,'YYYY-MM-dd')

    -------------------------------------------------------------------------------------
    -- Permet la récupération des informations météo de l'annnée dernière
    -------------------------------------------------------------------------------------
    elseif ls_type_stat = 'weatherJN1' then
        select wt_json from weather where dateformat(wt_chrono,'YYYY-MM-dd') = dateadd(year, -1,DATEFORMAT(current timestamp,'YYYY-MM-dd'))
    end if;    

END;

if exists(select 1 from sys.sysprocedure where proc_name = 'omc_p_every_1_hour') then
   drop procedure omc_p_every_1_hour
end if;

CREATE PROCEDURE "omc"."omc_p_every_1_hour"()
begin
  -------------------------------------------------------
  -- execution toutes les heures
  -------------------------------------------------------

  -- epuration histo badge
  call omc_p_epure_histo_borne() ;

  -- epuration pesees non rattachées à des lignes plus vieilles de 30 jours
  call omc_p_scale_epure_pesee() ;

  -- suppression des coupon d'avoir libres depuis plus de 7 jours afin de laisser le temps a omc_p_epure_ticket
  delete from coupon_avoir
  where coupon_avoir.copa_statut = 0 
    and ( coalesce( coupon_avoir.copa_chrono_m, coupon_avoir.copa_chrono_c ) is null
          OR
          datediff( day, coalesce( coupon_avoir.copa_chrono_m, coupon_avoir.copa_chrono_c ), current timestamp ) > 7 ) ;

  -- epuration des marquages des tickets (commandes client archivées 1003) dont le statut de préparation est passé en '+$' ou '-$' , supérieur à 15 jours car il ne seront jamais lu
  call omc_p_epure_external_statut_preparation();

  -- epuration des données météo. On garde 1 an d'historique
   delete from weather where weather.wt_chrono < dateadd(year, -1,DATEFORMAT(current timestamp,'YYYY-MM-dd'))
end;

if exists( select 1 from sys.syswebservice where service_name='getStatistics' ) then 
	drop service "getStatistics"
end if;
CREATE SERVICE "getStatistics" TYPE 'JSON' AUTHORIZATION OFF USER "omc" METHODS 'HEAD,GET' AS call "omc_http_get_statistiques"();

if exists( select 1 from sys.syswebservice where service_name='getWeather' ) then 
	drop service "getWeather"
end if;
CREATE SERVICE "getWeather" TYPE 'RAW' AUTHORIZATION OFF USER "omc" METHODS 'HEAD,GET' AS call "omc_http_get_weather"();

-------------------------------------------------------------------------------------
-- Création de la table météo. On stock la météo du jour.
-------------------------------------------------------------------------------------
if not exists( select * from sys.SYSTABLE where table_name='weather') then 
CREATE TABLE "omc"."weather" (
	"wt_id" "t_id" NOT NULL DEFAULT AUTOINCREMENT,
	"wt_publisher" "t_publisher" NOT NULL,
	"wt_chrono" "t_date" NOT NULL UNIQUE,
	"wt_json" "t_texte" NOT NULL,
	PRIMARY KEY ( "wt_id" ASC, "wt_publisher" ASC )
) IN "system";
end if;

commit
