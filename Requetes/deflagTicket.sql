--CodeDeFlag:
--1 = non intégré
--2 = encours d'intégration
--3 = intégré
UPDATE 
      detail_ticket
      set detail_ticket.dtic_facture_1 = "CodeDeFlag" 
 From 
     ticket 
 Where
     ticket.tic_id = detail_ticket.tic_id AND 
     ticket.tic_publisher = detail_ticket.tic_publisher AND 
     ticket.tic_chrono between 'DateDebut' and 'DateFin'
