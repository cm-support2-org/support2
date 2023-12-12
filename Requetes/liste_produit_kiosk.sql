select
   *
from
  vue_product as prod
where               
  prod.ter_id = 1 and prod.ter_publisher = 'a' and
  omc_f_is_valide_periode( prod.art_debut_validite, prod.art_fin_validite, Today() ) = 1 and
  prod.art_kiosk = 1 and
  code_famille = 107
