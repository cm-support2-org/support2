//Mettre en commentaire la ligne 106 (call omcmsg(1,'tub_trace_ligne_piece : changement du parent ( trace_ligne_piece ) interdit !',0)) de tub_trace_ligne_piece dans la table trace_ligne_piece

if exists(select 1 from sys.sysprocedure where proc_name = 'omc_p_mouline_clear_tlp_pere') then
   drop procedure omc_p_mouline_clear_tlp_pere
end if;

ALTER PROCEDURE "omc"."omc_p_mouline_clear_tlp_pere"( in al_pie_id t_id, in as_publisher t_publisher )
BEGIN    
    -------------------------------------------------
    -- suppression liaison tlp : fils  ->  parent 
    ------------------------------------------------- 
    update
      trace_ligne_piece
    set 
      tlp_pere_id = null,
      tlp_pere_publisher = null
     where
      trace_ligne_piece.pie_id = al_pie_id and 
      trace_ligne_piece.pie_publisher = as_publisher;    
    -- resultat
    if sqlcode <> 0 and sqlcode <> 100 then
      -- erreur
      call omcmsg( 1, 'omc_p_mouline_clear_tlp_pere : suppression liaison pere/fils de tlp !', 0 ) ;
    end if ;   
    
   -- piece inverse
   update
      trace_ligne_piece
    set 
      tlp_pere_id = null,
      tlp_pere_publisher = null
    from
      omc_p_enum_piece_lies( al_pie_id, as_publisher, 3 ) as xxx 
    where
      trace_ligne_piece.pie_id = xxx.pie_id and 
      trace_ligne_piece.pie_publisher = xxx.pie_publisher;    
    -- resultat
    if sqlcode <> 0 and sqlcode <> 100 then
      -- erreur
      call omcmsg( 1, 'omc_p_mouline_clear_tlp_pere : suppression liaison pere/fils de tlp !', 0 ) ;
    end if ;

    -- mise à jour pour les statuts
    call omc_p_maj_totaux_memo_piece();  
END
