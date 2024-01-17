if exists(select 1 from sys.sysprocedure where proc_name = 'alerteTacheNonCloturer') then
   drop procedure alerteTacheNonCloturer
end if;

CREATE PROCEDURE "omc"."alerteTacheNonCloturer"()

BEGIN

    declare ls_smtp_sender           t_texte;
    declare ls_smtp_server           t_texte;
    declare li_smtp_port             integer; 
    declare li_timeout               integer;
    declare ls_smtp_sender_name      t_texte;
    declare ls_smtp_auth_username    t_texte;
    declare ls_smtp_auth_password    t_texte;
    declare ls_trusted_certificates  t_texte;
    declare ls_recipient             t_texte;
    declare ls_bcc_recipient         t_texte;    
    declare ls_subject               t_texte;
    declare Dossier                  t_numero_piece;
    declare customerCode              char(15);
    declare customerName               t_raison_sociale;
    declare firstNameCollab     t_prenom;
    declare email_collaborateur      t_e_mail;
    declare ls_message               t_texte;
    declare li_return_code           integer;
    declare list_regulateur          t_texte;
    declare Note                     t_texte;
    declare numberDaysDelay      integer;
    
      
    declare "cur_col" no scroll cursor for select
        hd_dossier.hddos_dossier as Dossier,
        string (tiers.tie_code + '/' + magasin.mag_code) as customerCode,
        magasin.mag_raisoc as customerName,
        hd_tache.hdtac_note as Note,
        collaborateur.col_prenom as firstNameCollab,
        coalesce(collaborateur.col_email,list_regulateur) as email_collaborateur,
         ( select
            list (collaborateur.col_email, ';') 
          from 
            dep_collab, 
            collaborateur 
          where 
            dep_collab.col_id = collaborateur.col_id and 
            dep_collab.col_publisher = collaborateur.col_publisher and 
            departement.dep_id = dep_collab.dep_id and 
            dep_collab.depcol_regulateur = 1) as list_regulateur,
        DATEDIFF(day, hd_tache.hdtac_date_debut, datetime(now())) AS numberDaysDelay
    From    
        hd_dossier left outer join departement on
            hd_dossier.dep_id = departement.dep_id and
            hd_dossier.dep_publisher = departement.dep_publisher,
        hd_tache left outer join hd_tache_ressource on
             hd_tache_ressource.hdtac_id = hd_tache.hdtac_id and
            hd_tache_ressource.hdtac_publisher = hd_tache.hdtac_publisher
        left outer join collaborateur on
            collaborateur.col_id = hd_tache_ressource.col_id and
            collaborateur.col_publisher = hd_tache_ressource.col_publisher,
        magasin,
        tiers,
        hd_niveau_urgence
    Where
        hd_dossier.hddos_dossier = 3934 and
        hd_dossier.hddos_id = hd_tache.hddos_id and
        hd_dossier.hddos_publisher = hd_tache.hddos_publisher and
        (hd_tache.hdtac_statut = 2 or hd_tache.hdtac_statut = 1) and
        hd_dossier.mag_des_id = magasin.mag_id and
        hd_dossier.mag_des_publisher = magasin.mag_publisher and
        tiers.tie_id = magasin.tie_id and
        tiers.tie_publisher = magasin.tie_publisher and
        hd_tache.hdnu_id = hd_niveau_urgence.hdnu_id and
        hd_tache.hdnu_publisher = hd_niveau_urgence.hdnu_publisher 
    Order By
       hd_tache.hdtac_date_debut asc;

 -- init
    set ls_smtp_sender          = 'facture@cashmag.eu';
    set ls_smtp_server          = 'smtp.gmail.com'; 
    set li_smtp_port            = 587;   
    set li_timeout              = 30;
    set ls_smtp_sender_name     = 'CASHMAG Dossier';
    set ls_smtp_auth_username   = 'facture@cashmag.eu';
    set ls_smtp_auth_password   = 'Cash_Factu83@';
    set ls_trusted_certificates = 'SMTPS=Yes;Secure=1';        
    set ls_subject              = 'Dossier ouvert depuis trop longtemps';
    
    set ls_recipient            = 'l.ryckewaert@cashmag.fr';    
    set ls_bcc_recipient        = 's.luchini@cashmag.fr';  

    set ls_message = '<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"><html xmlns="http://www.w3.org/1999/xhtml" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8"><meta http-equiv="X-UA-Compatible" content="IE=edge"><meta name="format-detection" content="telephone=no"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title></title><style type="text/css" emogrify="no">#outlook a { padding:0; } .ExternalClass { width:100%; } .ExternalClass, .ExternalClass p, .ExternalClass span, .ExternalClass font, .ExternalClass td, .ExternalClass div { line-height: 100%; } table td { border-collapse: collapse; mso-line-height-rule: exactly; } .editable.image { font-size: 0 !important; line-height: 0 !important; } .nl2go_preheader { display: none !important; mso-hide:all !important; mso-line-height-rule: exactly; visibility: hidden !important; line-height: 0px !important; font-size: 0px !important; } body { width:100% !important; -webkit-text-size-adjust:100%; -ms-text-size-adjust:100%; margin:0; padding:0; } img { outline:none; text-decoration:none; -ms-interpolation-mode: bicubic; } a img { border:none; } table { border-collapse:collapse; mso-table-lspace:0pt; mso-table-rspace:0pt; } th { font-weight: normal; text-align: left; } *[class="gmail-fix"] { display: none !important; } </style><style type="text/css" emogrify="no"> @media (max-width: 600px) { .gmx-killpill { content: '' \03D1'';} } </style><style type="text/css" emogrify="no">@media (max-width: 600px) { .gmx-killpill { content: '' \03D1'';} .r0-o { border-style: solid !important; margin: 0 auto 0 auto !important; width: 320px !important } .r1-i { background-color: #ffffff !important } .r2-c { box-sizing: border-box !important; text-align: center !important; valign: top !important; width: 100% !important } .r3-o { border-style: solid !important; margin: 0 auto 0 auto !important; width: 100% !important } .r4-i { padding-bottom: 20px !important; padding-left: 0px !important; padding-right: 0px !important; padding-top: 20px !important } .r5-c { box-sizing: border-box !important; display: block !important; valign: top !important; width: 100% !important } .r6-o { border-style: solid !important; width: 100% !important } .r7-i { padding-left: 0px !important; padding-right: 0px !important } .r8-c { box-sizing: border-box !important; padding-bottom: 15px !important; padding-top: 15px !important; text-align: center !important; valign: top !important; width: 100% !important } .r9-c { box-sizing: border-box !important; text-align: left !important; valign: top !important; width: 100% !important } .r10-o { border-style: solid !important; margin: 0 auto 0 0 !important; width: 100% !important } .r11-i { padding-bottom: 15px !important; padding-top: 15px !important; text-align: center !important } .r12-c { box-sizing: border-box !important; padding-bottom: 30px !important; padding-top: 30px !important; text-align: center !important; width: 100% !important } .r13-i { background-color: #eff2f7 !important; padding-bottom: 20px !important; padding-left: 15px !important; padding-right: 15px !important; padding-top: 20px !important } .r14-i { color: #3b3f44 !important; padding-bottom: 0px !important; padding-top: 15px !important; text-align: center !important } .r15-i { color: #3b3f44 !important; padding-bottom: 0px !important; padding-top: 0px !important; text-align: center !important } .r16-i { background-color: #eff2f7 !important; padding-bottom: 0px !important; padding-left: 15px !important; padding-right: 15px !important; padding-top: 0px !important } .r17-c { box-sizing: border-box !important; text-align: center !important; width: 100% !important } .r18-i { font-size: 0px !important; padding-bottom: 15px !important; padding-left: 65px !important; padding-right: 65px !important; padding-top: 15px !important } .r19-c { box-sizing: border-box !important; width: 32px !important } .r20-o { border-style: solid !important; margin-right: 8px !important; width: 32px !important } .r21-i { padding-bottom: 5px !important; padding-top: 5px !important } .r22-o { border-style: solid !important; margin-right: 0px !important; width: 32px !important } body { -webkit-text-size-adjust: none } .nl2go-responsive-hide { display: none } .nl2go-body-table { min-width: unset !important } .mobshow { height: auto !important; overflow: visible !important; max-height: unset !important; visibility: visible !important; border: none !important } .resp-table { display: inline-table !important } .magic-resp { display: table-cell !important } } </style><!--[if !mso]><!--><style type="text/css" emogrify="no">@import url("https://fonts.googleapis.com/css2?family=Roboto"); </style><!--<![endif]--><style type="text/css">p, h1, h2, h3, h4, ol, ul, li { margin: 0; } a, a:link { color: #75b738; text-decoration: underline } .nl2go-default-textstyle { color: #3b3f44; font-family: verdana, geneva, sans-serif; font-size: 16px; line-height: 1.5; word-break: break-word } .default-button { color: #000000; font-family: verdana, geneva, sans-serif; font-size: 16px; font-style: normal; font-weight: normal; line-height: 1.15; text-decoration: none; word-break: break-word } .default-heading1 { color: #1F2D3D; font-family: verdana, geneva, sans-serif, Arial; font-size: 36px; word-break: break-word } .default-heading2 { color: #1F2D3D; font-family: verdana, geneva, sans-serif, Arial; font-size: 32px; word-break: break-word } .default-heading3 { color: #1F2D3D; font-family: verdana, geneva, sans-serif, Arial; font-size: 24px; word-break: break-word } .default-heading4 { color: #1F2D3D; font-family: verdana, geneva, sans-serif, Arial; font-size: 18px; word-break: break-word } a[x-apple-data-detectors] { color: inherit !important; text-decoration: inherit !important; font-size: inherit !important; font-family: inherit !important; font-weight: inherit !important; line-height: inherit !important; } .no-show-for-you { border: none; display: none; float: none; font-size: 0; height: 0; line-height: 0; max-height: 0; mso-hide: all; overflow: hidden; table-layout: fixed; visibility: hidden; width: 0; } </style><!--[if mso]><xml> <o:OfficeDocumentSettings> <o:AllowPNG/> <o:PixelsPerInch>96</o:PixelsPerInch> </o:OfficeDocumentSettings> </xml><![endif]--><style type="text/css">a:link{color: #75b738; text-decoration: underline;}</style></head><body bgcolor="#ffffff" text="#3b3f44" link="#75b738" yahoo="fix" style="background-color: #ffffff;"> <table cellspacing="0" cellpadding="0" border="0" role="presentation" class="nl2go-body-table" width="100%" style="background-color: #ffffff; width: 100%;"><tr><td> <table cellspacing="0" cellpadding="0" border="0" role="presentation" width="600" align="center" class="r0-o" style="table-layout: fixed; width: 600px;"><tr><td valign="top" class="r1-i" style="background-color: #ffffff;"> <table cellspacing="0" cellpadding="0" border="0" role="presentation" width="100%" align="center" class="r3-o" style="table-layout: fixed; width: 100%;"><tr><td class="r4-i" style="padding-bottom: 20px; padding-top: 20px;"> <table width="100%" cellspacing="0" cellpadding="0" border="0" role="presentation"><tr><th width="100%" valign="top" class="r5-c" style="font-weight: normal;"> <table cellspacing="0" cellpadding="0" border="0" role="presentation" width="100%" class="r6-o" style="table-layout: fixed; width: 100%;"><tr><td valign="top" class="r7-i" style="padding-left: 10px; padding-right: 10px;"> <table width="100%" cellspacing="0" cellpadding="0" border="0" role="presentation"><tr><td class="r8-c" align="center" style="font-size: 0px; line-height: 0px; padding-bottom: 15px; padding-top: 15px; valign: top;"> <img src="https://img.mailinblue.com/2577642/images/content_library/original/61f3eb6074db916d1b465ceb.png" width="580" border="0" style="display: block; width: 100%;"></td> </tr><tr><td class="r9-c" align="left"> <table cellspacing="0" cellpadding="0" border="0" role="presentation" width="100%" class="r10-o" style="table-layout: fixed; width: 100%;"><tr><td align="center" valign="top" class="r11-i nl2go-default-textstyle" style="color: #3b3f44; font-family: verdana,geneva,sans-serif; font-size: 16px; word-break: break-word; line-height: 1.5; padding-bottom: 15px; padding-top: 15px; text-align: center;"> <div><h3 class="default-heading3" style="margin: 0; color: #1f2d3d; font-family: verdana,geneva,sans-serif,Arial; font-size: 24px; word-break: break-word;"><span style="font-family: Verdana; font-size: 24px;">Attention dossier n°{$Dossier} </span></h3><h3 class="default-heading3" style="margin: 0; color: #1f2d3d; font-family: verdana,geneva,sans-serif,Arial; font-size: 24px; word-break: break-word;"><span style="font-family: Verdana; font-size: 24px;">non cloturé !!!</span></h3><p style="margin: 0;"> </p><p style="margin: 0;">Bonjour {$firstNameCollab}, cela fait <span style="color: #FF0808;"><strong>{$day}</strong></span> jours que ton dossier n°{$Dossier} pour le client [{$customerCode}] - {$customerName} est ouvert.</p><p style="margin: 0;">Merci de faire un point sur celui-ci</p><p style="margin: 0;"> </p><p style="margin: 0;">Information sur la tâches:</p><p style="margin: 0;"> </p><p style="margin: 0;"><i>{$Note}</i></p></div> </td> </tr></table></td> </tr><tr><td class="r12-c" align="center" style="padding-bottom: 30px; padding-top: 30px;"> <table width="100%" cellspacing="0" cellpadding="0" border="0" role="presentation" height="1" style="border-top-style: solid; background-clip: border-box; border-top-color: #4A4A4A; border-top-width: 1px; font-size: 1px; line-height: 1px;"><tr><td height="0" style="font-size: 0px; line-height: 0px;">­</td> </tr></table></td> </tr><tr><td class="r9-c" align="left"> <table cellspacing="0" cellpadding="0" border="0" role="presentation" width="100%" class="r10-o" style="table-layout: fixed; width: 100%;"><tr><td align="center" valign="top" class="r11-i nl2go-default-textstyle" style="color: #3b3f44; font-family: verdana,geneva,sans-serif; font-size: 16px; word-break: break-word; line-height: 1.5; padding-bottom: 15px; padding-top: 15px; text-align: center;"> <div><p style="margin: 0;">Si tu as besoin d''un support technique, tu peux contacter :</p><p style="margin: 0;"> </p><p style="margin: 0;">Laurent RYCKEWAERT <a href="mailto:l.ryckewaert@cashmag.fr" style="color: #75b738; text-decoration: underline;">l.ryckewaert@cashmag.fr</a></p><p style="margin: 0;">Laurent LEFEVRE <a href="mailto:l.lefevre@cashmag.fr" style="color: #75b738; text-decoration: underline;">l.lefevre@cashmag.fr</a></p><p style="margin: 0;">Sébastien Luchini <a href="mailto:s.luchini@cashmag.fr" style="color: #75b738; text-decoration: underline;">s.luchini@cashmag.fr</a></p></div> </td> </tr></table></td> </tr></table></td> </tr></table></th> </tr></table></td> </tr></table><table cellspacing="0" cellpadding="0" border="0" role="presentation" width="100%" align="center" class="r3-o" style="table-layout: fixed; width: 100%;"><tr><td class="r13-i" style="background-color: #eff2f7; padding-bottom: 20px; padding-top: 20px;"> <table width="100%" cellspacing="0" cellpadding="0" border="0" role="presentation"><tr><th width="100%" valign="top" class="r5-c" style="font-weight: normal;"> <table cellspacing="0" cellpadding="0" border="0" role="presentation" width="100%" class="r6-o" style="table-layout: fixed; width: 100%;"><tr><td valign="top" class="r7-i" style="padding-left: 15px; padding-right: 15px;"> <table width="100%" cellspacing="0" cellpadding="0" border="0" role="presentation"><tr><td class="r9-c" align="left"> <table cellspacing="0" cellpadding="0" border="0" role="presentation" width="100%" class="r10-o" style="table-layout: fixed; width: 100%;"><tr><td align="center" valign="top" class="r14-i nl2go-default-textstyle" style="font-family: verdana,geneva,sans-serif; word-break: break-word; color: #3b3f44; font-size: 18px; line-height: 1.5; padding-top: 15px; text-align: center;"> <div><p style="margin: 0;"><strong>CASHMAG</strong></p></div> </td> </tr></table></td> </tr><tr><td class="r9-c" align="left"> <table cellspacing="0" cellpadding="0" border="0" role="presentation" width="100%" class="r10-o" style="table-layout: fixed; width: 100%;"><tr><td align="center" valign="top" class="r15-i nl2go-default-textstyle" style="font-family: verdana,geneva,sans-serif; word-break: break-word; color: #3b3f44; font-size: 18px; line-height: 1.5; text-align: center;"> <div><p style="margin: 0; font-size: 14px;">470, Rue de l''Initiative, 83390, Cuers</p></div> </td> </tr></table></td> </tr></table></td> </tr></table></th> </tr></table></td> </tr></table><table cellspacing="0" cellpadding="0" border="0" role="presentation" width="100%" align="center" class="r3-o" style="table-layout: fixed; width: 100%;"><tr><td class="r16-i" style="background-color: #eff2f7;"> <table width="100%" cellspacing="0" cellpadding="0" border="0" role="presentation"><tr><th width="100%" valign="top" class="r5-c" style="font-weight: normal;"> <table cellspacing="0" cellpadding="0" border="0" role="presentation" width="100%" class="r6-o" style="table-layout: fixed; width: 100%;"><tr><td valign="top" class="r7-i" style="padding-left: 15px; padding-right: 15px;"> <table width="100%" cellspacing="0" cellpadding="0" border="0" role="presentation"><tr><td class="r17-c" align="center"> <table cellspacing="0" cellpadding="0" border="0" role="presentation" width="570" align="center" class="r3-o" style="table-layout: fixed; width: 570px;"><tr><td valign="top"> <table width="100%" cellspacing="0" cellpadding="0" border="0" role="presentation"><tr><td class="r17-c" align="center" style="display: inline-block;"> <table cellspacing="0" cellpadding="0" border="0" role="presentation" width="570" align="center" class="r3-o" style="table-layout: fixed; width: 570px;"><tr><td class="r18-i" style="padding-bottom: 15px; padding-left: 209px; padding-right: 209px; padding-top: 15px;"> <table width="100%" cellspacing="0" cellpadding="0" border="0" role="presentation"><tr><th width="40" class="r19-c mobshow resp-table" style="font-weight: normal;"> <table cellspacing="0" cellpadding="0" border="0" role="presentation" width="100%" class="r20-o" style="table-layout: fixed; width: 100%;"><tr><td class="r21-i" style="font-size: 0px; line-height: 0px; padding-bottom: 5px; padding-top: 5px;"> <a href="https://www.instagram.com/cashmag_/?utm_source=brevo&utm_campaign=Email Taches&utm_medium=email&utm_id=443" target="_blank" style="color: #75b738; text-decoration: underline;"> <img src="https://creative-assets.mailinblue.com/editor/social-icons/rounded_colored/instagram_32px.png" width="32" border="0" style="display: block; width: 100%;"></a> </td> <td class="nl2go-responsive-hide" width="8" style="font-size: 0px; line-height: 1px;">­ </td> </tr></table></th> <th width="40" class="r19-c mobshow resp-table" style="font-weight: normal;"> <table cellspacing="0" cellpadding="0" border="0" role="presentation" width="100%" class="r20-o" style="table-layout: fixed; width: 100%;"><tr><td class="r21-i" style="font-size: 0px; line-height: 0px; padding-bottom: 5px; padding-top: 5px;"> <a href="https://www.linkedin.com/company/cashmag/?utm_source=brevo&utm_campaign=Email Taches&utm_medium=email&utm_id=443" target="_blank" style="color: #75b738; text-decoration: underline;"> <img src="https://creative-assets.mailinblue.com/editor/social-icons/rounded_colored/linkedin_32px.png" width="32" border="0" style="display: block; width: 100%;"></a> </td> <td class="nl2go-responsive-hide" width="8" style="font-size: 0px; line-height: 1px;">­ </td> </tr></table></th> <th width="40" class="r19-c mobshow resp-table" style="font-weight: normal;"> <table cellspacing="0" cellpadding="0" border="0" role="presentation" width="100%" class="r20-o" style="table-layout: fixed; width: 100%;"><tr><td class="r21-i" style="font-size: 0px; line-height: 0px; padding-bottom: 5px; padding-top: 5px;"> <a href="https://www.youtube.com/@CashMag?utm_source=brevo&utm_campaign=Email Taches&utm_medium=email&utm_id=443" target="_blank" style="color: #75b738; text-decoration: underline;"> <img src="https://creative-assets.mailinblue.com/editor/social-icons/rounded_colored/youtube_32px.png" width="32" border="0" style="display: block; width: 100%;"></a> </td> <td class="nl2go-responsive-hide" width="8" style="font-size: 0px; line-height: 1px;">­ </td> </tr></table></th> <th width="32" class="r19-c mobshow resp-table" style="font-weight: normal;"> <table cellspacing="0" cellpadding="0" border="0" role="presentation" width="100%" class="r22-o" style="table-layout: fixed; width: 100%;"><tr><td class="r21-i" style="font-size: 0px; line-height: 0px; padding-bottom: 5px; padding-top: 5px;"> <a href="https://www.facebook.com/Groupe.CashMag?utm_source=brevo&utm_campaign=Email Taches&utm_medium=email&utm_id=443" target="_blank" style="color: #75b738; text-decoration: underline;"> <img src="https://creative-assets.mailinblue.com/editor/social-icons/rounded_colored/facebook_32px.png" width="32" border="0" style="display: block; width: 100%;"></a> </td> </tr></table></th> </tr></table></td> </tr></table></td> </tr></table></td> </tr></table></td> </tr></table></td> </tr></table></th> </tr></table></td> </tr></table></td> </tr></table></td> </tr></table></body></html>';
    
    set li_return_code          = -99;

    -- démarrer la session SMTP 
        li_return_code = call xp_startsmtp(    smtp_sender          = ls_smtp_sender,  
                                               smtp_server          = ls_smtp_server,  
                                               smtp_port            = li_smtp_port,  
                                               timeout              = li_timeout,
                                               smtp_sender_name     = ls_smtp_sender_name,
                                               smtp_auth_username   = ls_smtp_auth_username, 
                                               smtp_auth_password   = ls_smtp_auth_password,                                                   
                                               trusted_certificates = ls_trusted_certificates );   
     open "cur_col";
     "bou_cur_col": loop
    
    fetch next "cur_col" into Dossier,customerCode,customerName,Note,firstNameCollab,email_collaborateur,list_regulateur,numberDaysDelay;
    
    if sqlcode = 0 then

        if numberDaysDelay >= 45 then
            set ls_message = replace( ls_message, '{$Dossier}', Dossier );
            set ls_message = replace( ls_message, '{$customerCode}', customerCode );
            set ls_message = replace( ls_message, '{$customerName}', customerName );
            set ls_message = replace( ls_message, '{$Note}', Note );
            set ls_message = replace( ls_message, '{$day}', numberDaysDelay );
            set ls_message = replace( ls_message, '{$firstNameCollab}', firstNameCollab );
            set email_collaborateur = email_collaborateur;
            set ls_bcc_recipient = list_regulateur;
            
            -- envoyer le message
                        li_return_code = call xp_sendmail(  recipient= email_collaborateur, 
                                                            bcc_recipient = ls_bcc_recipient, 
                                                            subject = ls_subject, 
                                                            "message" = ls_message,
                                                            content_type = 'text/html', );    
        end if;

    elseif sqlcode = 100 then
        
        leave "bou_cur_col";
    
    else
    
        call "omcmsg"(1,'omc_f_get_col_hdtacres : erreur fetch !',1);
        leave "bou_cur_col";

    end if;

    -- arrêter la session smtp
    CALL xp_stopsmtp();
    end loop "bou_cur_col"; -- fin curseur
    close "cur_col";

END;
COMMENT ON PROCEDURE "omc"."alerteTacheNonCloturer" IS '
';
