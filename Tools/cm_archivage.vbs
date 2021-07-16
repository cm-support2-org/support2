' VB Script Document
' Description  : Réalise une copie des archives vers une destination locale (xcopy)
' Version : OMC20210611
'
'    - 20210611 Le choix de la sauvegarde NF ou Non Nf par l'utilisateur n'était pas utiliser du coup cela cherche une base non nf #slu. 
'    - 20200421 prise en compte des version de val/prod dans les version Gomc + Ajout choix base NF ou Non
'    - 20191215 correction statut final
'    - 20191022 correction test "lbOK"   + troncate
'    - 20190828 correction traitement control bases
'                gestion erreur envoi mail'
'    - 20190821 Ajout compte mail rapport
'               envoi mail sur adrresse mail magasin GOMC'
'								archivages BDC'
'    - 20181012 Amélioration Nettoyage des répertoires Hebdomadaire'
'    - 20180928 Amélioration gestion manipulation fichier (copie)'
'               Ajout archivage bases compressées de GOMC'
'    - 20170803 Trocature fichier transaction'
'    - 20170710 Version initiale (copy archives fiscales ,JET et base restau  certifié)
'option explicit

'Contantes
 
Const CM_VERSION="20200421"
Const CM_REG_PRG_X86="HKLM\SOFTWARE\OMC Gervais\Logiciels OMC Gervais" 'Cle OMC Gervais'
Const CM_REG_PRG_X64="HKLM\SOFTWARE\Wow6432Node\OMC Gervais\Logiciels OMC Gervais"   


Const OMC_DATA_DIR_KEY="install.datadir"                                'cle répertoire donnée'
Const OMC_GOMCPOS_INSTAL_KEY="product.RESTAU.installed"                 'cle Install GOMC-POS' 
Const OMC_GOMC_INSTAL_KEY="product.GESCOM.installed"                    'cle Install GOMC'
Const OMC_GOMCPOS_MODEL_KEY="product.RESTAU.DBModel"                    'cle base model'  

Const CM_ET_FILE_PATTERN="ET124747_JOURNAL.*\.xml"
'paterm a 7 groupes : 3 dates + 3 heure + 1 nom base'
Const CM_DB_GOMCPOS_FILES_PATTERN_NF        = "([0-9]+)_([0-9]+)_([0-9]+)_([0-9-]+)_([0-9-]+)_([0-9-]+)[\w_]+_(GOMCPOS)\.NF525.*\.backup"              'BDD NF525
Const CM_DB_GOMCPOS_FILES_PATTERN_STANDARD  = "([0-9]+)_([0-9]+)_([0-9]+)_([0-9-]+)_([0-9-]+)_([0-9-]+)[\w_]+_(GOMCPOS)\.STANDARD.*\.backup"           'BDD Non NF Ex: Serveur de compte'
Const CM_DB_GOMC_FILES_PATTERN              = "[A-Z]+ ([0-9]+)-([0-9]+)-([0-9]+) ([0-9]+)-([0-9]+)-([0-9]+) [\w\s*.]+\.([\w]+)\.cdb\.7z"

Const CM_ARCH_DIR="\GOMCPos-NF525-ArchivesFiscales"
Const CM_DB_GOMCPOS_DIR="\Bases de Données\Restau"
Const CM_DB_GOMC_DIR="\Bases de Données\Gescom"
Const CM_BDC_DIR="\Commun\MIP\bdc"
Const CM_LIC_DIRS="C:\ProgramData\Cashmag\GOMC-POS,C:\ProgramData\Cashmag\GOMC"
 
Const CM_JET_OUT_DIR="\GOMCPos-JET"
Const CM_ET_OUT_DIR="\GOMCPos-ET12474"
Const CM_DB_GOMCPOS_OUT_DIR="\GOMCPos-Bases"
Const CM_DB_GOMC_OUT_DIR="\GOMC-Bases"


Const CM_RESTAU_CS="Data Source=OMC_RESTAU;Password=sql;User ID=dba"
Const CM_GOMC_CS="Data Source=OMC_GESCOM;Password=sql;User ID=dba"

Const CM_MAIL_ACCOUNT="rapportgomc@gmail.com"
Const CM_MAIL_PWD="rapportgomc#123"
Const CM_MAIL_SRV="smtp.gmail.com"
Const CM_MAIL_PORT=465
Const CM_DEFAULT_BDC_PATH="%yyyy%\%mm% %mmm%\%soc% - %mag%\"

'variables  GLOBALES   

Dim fso       	'System de fichiers
Dim WshShell  	'shell de comande
Dim OutDir    	'Répertoire de destinations des copies
Dim SaveDir   	'Repertoire de sauvegardes Restau certifiées'
Dim DataDir   	'Répertoire des données Application'

Dim NoMail    	'Indicateur pour ne pas envoyer de mail'
Dim NoPrint   	'Indicateur pour ne pas imprimer de rapport'
Dim NoBDC     	'Indicateur pour ne pas  Archiver les BDC'	
Dim CodeClient  'code du client CashMag'
Dim MailSupport 'email support CashMag a prevenir en cas d'erreur'
Dim BDCPath		'Format repertoire BDC'
Dim noDataBaseNf 

Dim Rapport     'Rapport d'execution'
Dim Mail        'outil d'envois mail'                

Function getRestauIni()
 Dim ls_file
  getRestauIni=""
  'profil user'
   ls_file=WshShell.ExpandEnvironmentStrings("%USERPROFILE%")&"\WINDOWS\restau.ini"
      If fso.FileExists(ls_file ) then
            getRestauIni=ls_file
      End IF
  'windows'
  
  If getRestauIni = "" then
  ls_file=WshShell.ExpandEnvironmentStrings("%windir%")&"\restau.ini"
      If fso.FileExists(ls_file ) then
            getRestauIni=ls_file
      End IF
  End If
End Function

function getTicketPrinter(as_inifile)
dim lo_stream
dim ls_line
dim lb_inSection
       getTicketPrinter=""
      lb_inSection=false
       set lo_stream=fso.OpenTextFile(as_inifile,1, False)
      If  not  lo_stream is Nothing   Then
      
        Do while lo_stream.AtEndOfStream <>True     
          ls_line = lo_stream.ReadLine
          
           'recherche :   Imprimante=
          If   lb_inSection  and inStr(ls_line,"Imprimante=") >0 then
                  getTicketPrinter=Mid(ls_line,inStr(ls_line,"=")+1)
                  lb_inSection=false
          End if
          'recherche : [ImprimanteTicket]'
           IF inStr(ls_line,"[ImprimanteTicket]") >0 Then
                    lb_inSection=true
           End If
          
        Loop
       lo_stream.close
      End If
End Function

function getRestauPDV(as_inifile)
 dim lo_stream
dim ls_line
dim lb_inSection
       getRestauPDV=""
      lb_inSection=false
      
      set lo_stream=fso.OpenTextFile(as_inifile,1, False)
      If  not  lo_stream is Nothing   Then
      
        Do while lo_stream.AtEndOfStream <>True     
          ls_line = lo_stream.ReadLine
          
           'recherche :   terminal=
          If   lb_inSection  and inStr(ls_line,"terminal=") >0 then
                  getRestauPDV=Mid(ls_line,inStr(ls_line,"=")+1)
                  lb_inSection=false
          End if
          'recherche : [saisieticket]'
           IF inStr(ls_line,"[saisieticket]") >0 Then
                    lb_inSection=true
           End If
          
        Loop
       lo_stream.close
      End If
End Function
 
   
'mots de passe encript" dans la base -> on peut plus le lire'
function getDefautSMTP(ByRef ao_mail)
          ao_mail.setHost CM_MAIL_SRV, CM_MAIL_PORT,1 ,1
End function 


Function sendToRestauUsers(ByRef ao_mail,as_subject,as_txtMsg)
dim lo_sqlCon,lo_rs
dim ls_login,ls_pwd,ls_email

  set  lo_sqlCon=CreateObject("ADODB.Connection")
  set lo_rs=CreateObject("ADODB.Recordset")

  lo_sqlCon.open CM_RESTAU_CS

	  lo_rs.open "SELECT 'Responsable magasin'+upper(societe.soc_raisoc)+'<'+uti_email+'>' "& _
						" FROM utilisateur,societe "&_
						" WHERE uti_email is not null and uti_cai_superviseur=1"&_
						" AND utilisateur.soc_id=societe.soc_id "&_
						" AND utilisateur.soc_publisher=societe.soc_publisher",lo_sqlCon
    
     ls_email=""
     sendToRestauUsers=false
     While Not lo_rs.EOF 
  
           If  ls_email="" Then
              ls_email=lo_rs.Fields.Item(0).value
           Else
               ls_email=ls_email&","&lo_rs.Fields.Item(0).value
					End If
        lo_rs.MoveNext
      Wend
      
    If  ls_email <> "" Then    
      sendToRestauUsers=  ao_mail.sendMail(as_subject,as_txtMsg,ls_email)   
    End If
    lo_rs.Close
    set lo_sqlCmd=Nothing     
End Function 

  
Function sendToGomcUsers(ByRef ao_mail,as_subject,as_txtMsg)
dim lo_sqlCon,lo_rs
dim ls_login,ls_pwd,ls_email

  set  lo_sqlCon=CreateObject("ADODB.Connection")
  set lo_rs=CreateObject("ADODB.Recordset")

  lo_sqlCon.open CM_GOMC_CS

  lo_rs.open 	"SELECT "&_ 
   						"  'magasin '+upper(mag_raisoc)+'<'+magasin.mag_email+'>' "&_ 
   						" FROM                  "&_ 
   						"     magasin,         "&_ 
   						"     tiers           "&_ 
   						" WHERE                  "&_ 
   						"     magasin.tie_id=tiers.tie_id    "&_ 
   						"     and magasin.tie_publisher=tiers.tie_publisher       "&_ 
   						"     and tie_type_societe=1       "&_ 
   						"     and magasin.mag_email is not null     "&_ 
   						"     and magasin.mag_fin_validite is null   "&_ 
   						" UNION ALL                           "&_ 
   						" SELECT                         "&_ 
   						"     'collaborateur principal de '+upper(mag_raisoc)+'<'+ collaborateur.col_email+'>'  "&_ 
   						" FROM                                         "&_ 
   						"     collaborateur,                           "&_ 
   						"     magasin,                                  "&_ 
   						"     tiers                                    "&_ 
   						" WHERE                                      "&_ 
   						"     collaborateur.tie_id=tiers.tie_id  "&_ 
   						"     and collaborateur.tie_publisher=tiers.tie_publisher "&_
   						"     and magasin.tie_id=tiers.tie_id   "&_ 
   						"     and magasin.tie_publisher=tiers.tie_publisher   "&_ 
   						"     and magasin.mag_principal=1    "&_ 
   						"     and tie_type_societe=1       "&_ 
   						"     and collaborateur.col_principal=1   "&_ 
   						"     and collaborateur.col_email is not null   "&_ 
   						"     and (magasin.mag_email <> collaborateur.col_email   "&_
						"     or  magasin.mag_email is Null ) "&_  
   						"     and collaborateur.col_fin_validite is null     "&_ 
   						"     and magasin.mag_fin_validite is null",lo_sqlCon
    
     ls_email=""
     sendToGomcUsers=false
     While Not lo_rs.EOF 
  
           If  ls_email="" Then
              ls_email=lo_rs.Fields.Item(0).value
           Else
               ls_email=ls_email&","&lo_rs.Fields.Item(0).value
           End IF
        lo_rs.MoveNext
      Wend
      
    If  ls_email <> "" Then
      sendToGomcUsers=  ao_mail.sendMail(as_subject,as_txtMsg,ls_email)   
    End If
    lo_rs.Close
    set lo_sqlCmd=Nothing     
End Function 

'Envoi du rapport si erreur au support
function  sendToSupport(ByRef ao_mail,as_subject,as_txtMsg) 
			if MailSupport <> "" then
	    	sendToSupport =  ao_mail.sendMail(as_subject,as_txtMsg,MailSupport) 
	    End If
End Function	 

'------------------- Classe mail---------------------'
Class CMMail
    Private pMail

     Private Sub Class_Initialize()
        set pMail=CreateObject("CDO.Message") 
     End Sub
     
       Public sub setHost(as_host, ai_port,ab_ssl,ab_auth)
        With pMail
              .Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpusessl") = ab_ssl
              .Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpauthenticate") = ab_auth
              .Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/sendusing") = 2 
		          .Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpserver") = as_host
		          .Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpserverport") = ai_port 
              .Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/smtpconnectiontimeout") = 60
              .Configuration.Fields.Update 
          End With 
       End Sub

       Public Sub setAccount(as_login,as_pwd,as_email)
          With pMail
          .Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/sendusername")=as_login
          .Configuration.Fields.Item ("http://schemas.microsoft.com/cdo/configuration/sendpassword")=as_pwd
          .From=as_email
          .Configuration.Fields.Update
          End With 
       End Sub
       
       Public function sendMail(as_suject,as_txtMsg,as_dest)
   
          With pMail
		           .To=as_dest
        		   .Subject=as_suject
        		   .TextBody=as_txtMsg
        		   .HtmlBody="<pre>"&as_txtMsg&"</pre>"
          End With 
        	On Error Resume Next   'mode gestion erreur perso ...'
       	sendMail=pMail.Send
			  
        sendMail=0
         WScript.Echo  "mail to :"& as_dest
         WScript.Echo  "subject :"&as_suject
       End Function
                                          
End Class                                        

'------------------- Classe Printer---------------------'
 Class CMPrinter
       Private pPrinterName
       
       
       Public Sub SelectPrinter(as_printerName)
           pPrinterName=as_printerName    
       End Sub
 
      Public Sub printFile(as_file)
           WshShell.Run "notepad.exe /pt """&as_file &""" """&pPrinterName&"""",0,True
      End Sub
      
      Public Sub printTxt(as_txt)
       Dim ls_temp
       Dim lo_stream
        ls_temp= WshShell.ExpandEnvironmentStrings("%TEMP%")&"\"&fso.GetTempName
         
         set lo_stream=fso.OpenTextFile(ls_temp,2, true)
          lo_stream.write(as_txt)
          lo_stream.close
             printFile  ls_temp
          fso.deleteFile ls_temp,True
      End Sub
 
 End Class
                                   
 '------------------- Classe Rapport---------------------'
 Const CM_LINE_SIZE=28
 
 Class CMRapport
    Private pTitle
    Private pMessage
    
    Private Sub Class_Initialize()
            pTitle=""
            pMessage=""
    End Sub
    
    Private function centerTxt(as_txt,ai_size)
    Dim   ai_nbspace
    
           centerTxt=mid(as_txt,1,ai_size)        'tronque'
           
        
           ai_nbspace=(ai_size-len(centerTxt))\2

           centerTxt=string(ai_nbspace," ")&centerTxt  'blanc a gauche'
    
           centerTxt=centerTxt&string(ai_size-len(centerTxt)," ")     'blanc a droite'
    End function
    
    Private Function titleToString()
    Dim  la_title
    Dim ls_titleLigne
                       titleToString="----------------------------"&vbLf
          
                  la_title=split(pTitle,vbLf)  
                  For each ls_titleLigne in    la_title
     
                     ls_titleLigne=centerTxt(ls_titleLigne,CM_LINE_SIZE-4)
          
                     titleToString=titleToString&"--"&ls_titleLigne&"--"&vbLf    
                  Next
         titleToString=titleToString&"----------------------------"&vbLf
    End Function
    
    Private Function msgToString()                  
         msgToString= pMessage&vbLf
    End Function
    
    Private Function footerToString()
          footerToString="----------------------------"&vbLf
        footerToString=footerToString+"CM Report version "&CM_VERSION    
    End Function
    
    Public Property Let Title  (as_title)
            pTitle=as_title
    End Property
    
    Public Property Get Title  ()
          Title=pTitle
    End Property
   
    Public  Sub appendMsg(as_message)
          pMessage=pMessage&vbLf&as_message
    End Sub 
    
    Public default Function toString()
          toString=titleToString()
          toString=toString+msgToString()
          toString=toString+footerToString()
    End Function
    
 End Class
 
'------------------- Classe BDCFileInfo ---------------------'
Class CMBDCFileInfo
		Private mFilePath
		
		Public Sub setFile(asFilepath)
		     mFilePath=asFilepath
	
		End Sub
		
		Private Function extratFromPath(asPattern)
		Dim loRegExp 
		Dim loMatch 

			 set loRegExp = New RegExp
      	loRegExp.Pattern= asPattern
      	
      	set loMatch =loRegExp.Execute(mFilePath)
      	If loMatch.Count > 0 Then
      		 extratFromPath = loMatch(0)
				Else
      	  extratFromPath = Null
				End If
		End Function
		
		Private Function extratPeriod(asPattern,idxY,idxM)
		Dim lsMatch
		
					lsMatch=extratFromPath(asPattern)
					If not isNull(lsMatch)  Then
					   	extratPeriod =mid(lsMatch,idxY,4)&"-"&mid(lsMatch,idxM,2)
					Else
					 	extratPeriod = Null
					End If
			
		End Function
		
		Public Property Get Societe()
		Dim lsMatch

    	'code Societe ( Soc MMM )'
      lsMatch=extratFromPath(" Soc [0-9]+")            
      Societe= Mid(lsMatch,2)
		End Property
		
		Public Property Get Magasin()
		Dim lsMatch
		
      'code Magasin ( Mag MMM )'
      lsMatch=extratFromPath(" Mag [0-9]+| PdV [0-9]+" )
      Magasin= Mid(lsMatch,2)
		  Magasin= Replace(Magasin,"PdV ","Mag ")
		End Property
		
		'année mois: yyyy-mm'
		Public Property Get Periode()

		  	Periode=extratPeriod("\([0-9]{4}-[0-9]{2}-[0-9]{2}\)",2,7)       'date RESTAU (AAAA-MM-JJ)'
		  	
				If isNull(Periode)  Then		
							Periode=extratPeriod("\([0-9]{2}-[0-9]{2}-[0-9]{4}\)",8,5) 'date GOMC-POS V12 (JJ-MM-AAAA)'
				End If
		  	
		  	If isNull(Periode)  Then
		  	      lsMatch=extratPeriod("[0-9]{2}-[0-9]{2}-[0-9]{4}",7,4)     'date autres caisse JJ-MM-AAAA'
		  	End If
		  	If isNull(Periode)  Then
		  	      Periode=extratPeriod("[0-9]{4}-[0-9]{2}-[0-9]{2}",1,6)     'date autres caisse AAAA-MM-JJ'
		  	End If	       
		  	
		End Property 
End Class
 
'------------------- Classe Synchronizer ---------------------'
Class CMSynchronizer
  	Private mSynchroStrategie
  	Private mReport
  	
  	Private Sub Class_Initialize()
    	set  mSynchroStrategie = Nothing
    	set mRepport           = Nothing
    End Sub
  	
  	Public Sub setStrategie(ByRef aoStrategie)
  	    set mSynchroStrategie=aoStrategie
  	End Sub
  	
  Public  Sub setReport(aoReport)
			set mReport = aoReport
	 End Sub
	 
		Public Function synchronize()
		Dim lsMessage
		Dim lsDetail
		
			lsDetail=""
			If not  mSynchroStrategie is Nothing Then
				lsMessage=mSynchroStrategie.Name&"                   " 
				lsMessage=mid(lsMessage,1,21)        'length 21
		    synchronize = mSynchroStrategie.synchronize(lsDetail)
		    
		    'ajout retour synchro au rapport
		    If not  mReport  is Nothing Then
					If synchronize Then   
			    	mReport.appendMsg(vbLf&lsMessage&"    OK")     'length 27
	        Else
	          mReport.appendMsg(vbLf&lsMessage&"Erreur")   'length 27
	        End If
			    mReport.appendMsg(lsDetail)    
			  End If
		  End If
		End Function

End Class

'------------------- Classes Synchronizer  Strategies ---------------------'

'-----------------------   Dir Strategie'
Class CMSynchronizeDirStrategie
	Private mName
	Private mSrcDir
	Private mDestDir
	
	Public Property Let Name  (asName)
	       mName = asName
	End Property 
	
	Public Property Get Name  ()
	     Name = mName
	End Property 
	
	Public Property Let SrcDir  (asSrcDir)
	       mSrcDir = asSrcDir
	End Property 
	
	Public Property Let DestDir  (asDestDir)
	       mDestDir = asDestDir
	End Property 
	
	Private Function RecusiveSynchronize(as_srcDir,as_destDir,ByRef as_detail)
	dim lo_folderSrc
	dim lo_folderDest
	dim li_err
	
	dim li_cpt
	dim li_minDate
	dim li_maxDate
	dim ls_detail
	dim la_detail	
	
	  If as_detail = "" Then
	    ls_detail="0,01/01/1900,01/01/1900"
	  Else
	    ls_detail=as_detail
	  End if
	  
	  la_detail=split(ls_detail,",")
	  li_cpt=CInt(la_detail(0) )
	  li_minDate=CDate(la_detail(1))
	  li_maxDate=CDate(la_detail(2))
	  
	  RecusiveSynchronize=1
	  If not fso.FolderExists(as_destDir) Then
	    fso.CreateFolder(as_destDir)
	  End IF
	  
	  set lo_folderSrc = fso.getFolder(as_srcDir)
	  set lo_folderDest = fso.getFolder(as_destDir)
	  
	  'If lo_folderDest.DateLastModified <  lo_folderSrc.DateLastModified  or lo_folderDest.DateCreated = lo_folderDest.DateLastModified Then
	    'synchro'
        
	    For  each lo_folder in  lo_folderSrc.SubFolders
	    
	      ls_detail=CStr(li_cpt)&","&CStr(li_minDate)&","&CStr(li_maxDate)
	      
	      If RecusiveSynchronize( as_srcDir&"\"&lo_folder.Name,as_destDir&"\"&lo_folder.Name ,ls_detail ) = 0 then
	        RecusiveSynchronize = 0
	      End if
	      
	      la_detail=split(ls_detail,",")
	      li_cpt=CInt(la_detail(0)   )
	      li_minDate=CDate(la_detail(1))
	      li_maxDate=CDate(la_detail(2))
	    Next
	  
	  
	    For  each lo_file in  lo_folderSrc.Files
	      If not fso.FileExists(as_destDir&"\"&lo_file.Name) Then
	      
	        If fso.CopyFile(lo_file.Path , as_destDir&"\"&lo_file.Name  )   Then
	          RecusiveSynchronize=0            
	        End If
	        
	        If   li_cpt  =0 or   li_minDate> lo_file.DateLastModified then
	          li_minDate= lo_file. DateLastModified
	        End If
	        
	        If   li_cpt  =0 or   li_maxDate< lo_file.DateLastModified then
	          li_maxDate= lo_file. DateLastModified
	        End If
	        
	        li_cpt   = li_cpt+1 
	      End If
	    Next	  
	  
	  'End IF  'lo_folderDest.DateLastModified ...'
	  
	  If as_detail = "" Then
	    as_detail = "  "&CStr(li_cpt)& " Nouveau(x) Fichier(s)" 
	    If li_cpt > 0Then
	      as_detail =as_detail &vbLf&"  du "&CStr(li_minDate)& vbLf
	      as_detail =as_detail &"  au "&CStr(li_maxDate)
	    End IF
	  Else
	    as_detail=CStr(li_cpt)&","&CStr(li_minDate)&","&CStr(li_maxDate)
	  End If
	End Function
	
	'synchronise les repertoire (uniquement si source > destination
	'Retourne 1 si OK  ,0 sinon'
	Public Function synchronize(ByRef asDetail)
	Dim lsSrcDir
	Dim lsDetail
			
	    synchronize=1
			For each lsSrcDir in split(mSrcDir,",") 
					lsDetail=""
	        synchronize=synchronize and RecusiveSynchronize(lsSrcDir,mDestDir,lsDetail)
	        asDetail=asDetail&vbLf&lsDetail
	    Next
	End Function
	
End Class

'-----------------------   DBFile  Strategie'
Class CMSynchronizeDBFileStrategie
	Private mName
	Private mSrcDir
	Private mDestDir
	Private mPattern
	Private mConnectString
	
	Private Sub Class_Initialize()
          mConnectString = null
  End Sub
	
	Public Property Let Name  (asName)
	       mName = asName
	End Property 
	
	Public Property Get Name  ()
	     Name = mName
	End Property 
	
	Public Property Let SrcDir  (asSrcDir)
	       mSrcDir = asSrcDir
	End Property 
	
	Public Property Let DestDir  (asDestDir)
	       mDestDir = asDestDir
	End Property

	Public Property Let Pattern  (asPattern)
	       mPattern = asPattern
	End Property
	
	Public Property Let ConnectString  (asConnectString)
	       mConnectString = asConnectString
	End Property
	
	Private Sub troncateLog()
	Dim lsConnectString
		
		 
			If not isNull(mConnectString) Then
			
					 'hot corection : shoud be set in a sybase strategy'                            	
						lsConnectString = replace(mConnectString,"User ID","UID")	
			      lsConnectString = replace(lsConnectString,"Password","PWD")	
	       WshShell.run "dbbackup -c """&lsConnectString&"""  -xo",10,true     	 
			End If  
	End Sub
	
	'synchronise l'Archive de laBase de Données (uniquement si source > destination
	'Retourne 1 si OK  ,0 sinon'
	Private Function synchronizeDBFile(aoSrcFile,ByRef asDetail)
	dim ls_jour
	dim ls_date
	dim lo_dateRef
	dim lo_folderDest
	dim ls_fileSrc
	
	dim ls_patern
	dim lo_reDate
	dim lo_matches
	
	dim lo_archFile
	dim lo_archDate
	dim lb_needSync
	dim ls_DBName

	
	
	  SynchronizeDBFile=1
	  
	
	  set lo_archFile =  Nothing  
	
	
	  'Extraction date sauvegarde'
	  set lo_reDate = new  RegExp
	  lo_reDate.Pattern= mPattern 
	    
	 set   lo_matches = lo_reDate.Execute(aoSrcFile.Name )
	  If lo_matches.Count >0   Then
	     lo_dateRef=DateSerial(lo_matches(0).submatches(0),lo_matches(0).submatches(1),lo_matches(0).submatches(2))+ TimeSerial(lo_matches(0).submatches(3),lo_matches(0).submatches(4),lo_matches(0).submatches(5))
	  Else
	     asDetail=asDetail&vbcrlf&"  Erreur identification date fichier"
	     li_err=1
	      SynchronizeDBFile=0
	  End If
	  
	  'Determitaion info destination'
	  ls_jour=DoWtoStr(Weekday(lo_dateRef))   
	    
	  If not fso.FolderExists(mDestDir&"\"& ls_jour) then
	    fso.CreateFolder(mDestDir&"\"& ls_jour)
	  End If     
	    
	  set lo_folderDest = fso.getFolder( mDestDir&"\"& ls_jour)
	  
	  'Sauf Erreur on synchronise par défaut'
	  lb_needSync = 1 - li_err 
	 
	
	 
	   If  li_err = 0 Then
	    'Recherche precedante archive DB' 
	    ls_DBName=lo_matches(0).submatches(6)
	     For each lo_archFile in lo_folderDest.Files
	        set lo_matches = lo_reDate.Execute(lo_archFile.Name)
	        If lo_matches.Count > 0   Then
	             'Candidat potentiel'
	              If  ls_DBName =  lo_matches(0).submatches(6) and Right(lo_archFile.Name,4) = Right(aoSrcFile.Name,4)  Then
	                  'precedente archive trouvéé'
	                  lo_archDate=DateSerial(lo_matches(0).submatches(0),lo_matches(0).submatches(1),lo_matches(0).submatches(2))+ TimeSerial(lo_matches(0).submatches(3),lo_matches(0).submatches(4),lo_matches(0).submatches(5)) 
	                  If lo_archDate >  lo_dateRef then
	                    'trouvé Archive plus récente'                
	                     asDetail =asDetail&vbcrlf&"   Arhive plus ancienne que"&vbLf&"  la destination"&vbLf&"  "&aoSrcFile.DateLastModified&vbLF
	                     lb_needSync = 0
			              Else
	                     'Archive actuelle a remplacer -> effacement
	    		              li_err= li_err + fso.DeleteFile( lo_folderDest.Path&"\"&lo_archFile.Name ,true  )
			                  If  li_err> 0 then
			                    asDetail=asDetail&vbcrlf&"  Erreur ancienne archive du" &vbLf&"  "&lo_archFile.DateLastModified&vbLF
			                  End If
	                  End If 
	              End IF
	        End If  
	     Next
	  End IF 
	  
	  If  lb_needSync > 0  and li_err = 0 Then
	    'Synchro
	   
	     'troncature fichier transaction'
	      If  inStr(mName,ls_DBName) > 0 Then      
			    If DateDiff("m",lo_dateRef,Now )< 1  Then
			           'c'est un sauvegarde récente < 1 minute '
			           troncateLog
			    Else
			     	asDetail=asDetail&vbcrlf&"  Sauvegarde y a +1 minute"&vbcrlf&"  conservation Logs!"		
			    End If 
        End If 
	    
	    'Déplace la nouvelle archive vers le repertoire de sortie'
	    ls_fileSrc= aoSrcFile.Path 
	    li_err=li_err+fso.MoveFile(ls_fileSrc , lo_folderDest.Path&"\" )    
	       
	    If  li_err> 0 then
	      SynchronizeDBFile=0
	      asDetail=asDetail&vbcrlf&"  Erreur copie archive du" &vbLf&"  "&ao_srcFile.DateLastModified&vbLF
	    End If
End If

	End Function       	
	
	'synchronise l'Archives des Bases de Données d'une Application
	'Retourne 1 si OK  ,0 sinon'
	Function Synchronize(ByRef asDetail  )
	 Dim liNbFile
	
			
			'5> Synchro  Archive 
			liNbFile=0
	    If  fso.FolderExists( mSrcDir) Then
	      dim li_err
	      dim  li_ret
	      
	      
	      set lo_folder=fso.getFolder(mSrcDir)
	      set lo_re =new  RegExp
	      li_sync=0
	      lo_re.Pattern=mPattern 
	      
	      set lo_files =lo_folder.Files
	      li_err=0
	      ls_detail=""
	     
	     'creation réperoire sortie bases' 
	      If not fso.FolderExists( mDestDir) then
	        fso.CreateFolder( mDestDir)
	      End If
	      
	      For   each lo_file in lo_files
	      
	        If lo_re.test(lo_file.Name)    Then
	           liNbFile = liNbFile + 1
	          if SynchronizeDBFile( lo_file,asDetail )   =0   then
	            li_err=1
	          End If
	        End If
	      Next

	    End If  ' fso.FolderExists(SaveDir)'
	    
	    If  liNbFile = 0  Then
	         asDetail=asDetail+"  {Pas de fichier copié !}"
	         li_err = 1
	    
	    End If
	     Synchronize =  1 -  li_err    
	 End Function 
	 
	 Public Function getCtrlArch()
	 Dim lsDetail
	 Dim liIdx
	 Dim loFolder
	 Dim loFiles 
	 Dim loRegExp    
	 Dim loMinDate
	    
	    set loRegExp  =new  RegExp
	    loRegExp.Pattern=mPattern
	    lsDetail=""
	    
			For liIdx=1 To 7
      Dim lsJour
          
					lsJour=DoWtoStr(liIdx)
 
          If fso.FolderExists(mDestDir&"\"&lsJour)  Then
          set loFolder=fso.getFolder(mDestDir&"\"&lsJour )

          loMinDate=Null
            set loFiles =loFolder.Files
            For   each loFile in loFiles
                If loRegExp.test(loFile.Name)    Then
                			If isNull(loMinDate) or loMinDate >  loFile.DateLastModified Then
                			         loMinDate =  loFile.DateLastModified
                			End If
                End If
            Next  
						 
						 If not isNull(loMinDate) Then
						 			If lsDetail <> "" Then
						 				lsDetail=lsDetail&vbLF
						 			End If
						      lsDetail=lsDetail&"  "&lsJour&String(15-len(lsJour)," ")&FormatDateTime(loMinDate,2)
						 End If  
          End If
       Next
       getCtrlArch=lsDetail
	  End Function 
	
End Class

'-----------------------   Archives Strategie'
Class   CMSynchronizeArchivesStrategie
	Private mName
	Private mSrcDir
	Private mDestDir
	
	Public Property Let Name  (asName)
	       mName = asName
	End Property 
	
	Public Property Get Name  ()
	     Name = mName
	End Property 
	
	Public Property Let SrcDir  (asSrcDir)
	       mSrcDir = asSrcDir
	End Property 
	
	Public Property Let DestDir  (asDestDir)
	       mDestDir = asDestDir
	End Property 	
	
		
	Public Function synchronize(ByRef asDetail)
  dim lo_folder
  dim li_idx
  dim lo_re
  dim lb_cpoy
  dim li_sync
  dim lo_files
  dim lo_file
  dim li_cpt
  dim li_minDate
  dim li_maxDate
  
    li_cpt=0
    li_minDate=0
    li_maxDate=0    
    
    
   
    set lo_folder=fso.getFolder(mSrcDir)
    set lo_re =new  RegExp
    li_sync=0
    lo_re.Pattern=CM_ET_FILE_PATTERN
    
    set lo_files =lo_folder.Files
  
    If not fso.FolderExists(mDestDir) Then
    	'création répertoire de sortie'
      fso.CreateFolder(mDestDir)
    End If
    
    ls_detail="" 
    For   each lo_file in lo_files
    
      
      If lo_re.test(lo_file.Name) and not fso.FileExists(mDestDirR&"\"&lo_file.Name) Then
        'le fichier source n'existe pas dans la destination -> copie' 
        fso.CopyFile   lo_file.Path , mDestDir&"\"&lo_file.Name  
        If   li_cpt  =0 or   li_minDate> lo_file. DateLastModified then
          li_minDate= lo_file. DateLastModified
        End If
        If   li_cpt  =0 or   li_maxDate< lo_file. DateLastModified then
          li_maxDate= lo_file. DateLastModified
        End If
        li_cpt   = li_cpt+1
      
      End If
    Next
    
    If   li_cpt > 0 Then
      asDetail = "  "&CStr(li_cpt)& " Fichier(s) copié(s)" &vbLf
      asDetail = asDetail+"  du "&CStr(li_minDate)& vbLf
      asDetail = asDetail +"  au "&CStr(li_maxDate)& vbLf
    End If        
	End Function
	
End Class

'-----------------------   BDC Strategie'
Class   CMSynchronizeBDCStrategie
	Private mName
	Private mSrcDir
	Private mDestDir
	Private mPathPattern
	
	Public Property Let Name  (asName)
	       mName = asName
	End Property 
	
	Public Property Get Name  ()
	     Name = mName
	End Property 
	
	Public Property Let SrcDir  (asSrcDir)
	       mSrcDir = asSrcDir
	End Property 
	
	Public Property Let DestDir  (asDestDir)
	       mDestDir = asDestDir
	End Property 	
	
	Public Property Let PathPattern(asPathPattern)
		mPathPattern=asPathPattern
	End Property
	
	Private Function genereBDCPath(asPath)
	Dim lsParentDir
 
		genereBDCPath=True	  'Cas Final 1 : defaut chemin exist déja ?
 
		If not fso.FolderExists(asPath)Then
	      'A creer'
	  		'1> Parent'
			  lsParentDir=fso.GetParentFolderName(asPath)
	 
			  If (lsParentDir <> "") Then
			  	'Ctrl Parent ? -> recursivité'
			    genereBDCPath=GenereBDCPath(lsParentDir) 
			  Else
			  	  genereBDCPath=True 'Cas Final 2 : racine'
				End If
				
				'2> Fils (courant)'
			  If  genereBDCPath Then
			  		'Le repertoire parent créé -> creation repertoire fils'
						fso.CreateFolder(asPath)
	        ''  WScript.Echo "genereBDCPath  :"& asPath
	          If Err.Number = 0 Then
						  genereBDCPath=true
					  End If
				End If
		End If
	End Function
	
	Public Sub classify(ByRef asDetail)
	Dim loBDCInfo
	Dim loBDCFolder
	Dim lsFile
	Dim lsBDCPath
	Dim laAnneeMois
	Dim liNbFile 
	Dim loRegExp 
	
		set loBDCInfo = new CMBDCFileInfo
		set loRegExp = New RegExp
		
		loRegExp.Pattern  = ".bdc"
		
		If  fso.FolderExists(mSrcDir) Then
			
			Set  loBDCFolder=fso.getfolder(mSrcDir)
			liNbFile=0
			
			
			
			On Error Resume Next   'mode gestion erreur perso ...'
			For Each  lsFile In  loBDCFolder.Files
		   

		  	If loRegExp.Test(lsFile) Then
		  	
		     loBDCInfo.setFile(lsFile)
		     

		    'generation du répertoire		      
         lsBDCPath=Replace(mPathPattern,"%soc%",loBDCInfo.Societe)   
				 lsBDCPath=Replace(lsBDCPath,"%mag%",loBDCInfo.Magasin)
				 laAnneeMois=split(loBDCInfo.Periode,"-")
				 lsBDCPath=Replace(lsBDCPath,"%yyyy%",laAnneeMois(0))
				 lsBDCPath=Replace(lsBDCPath,"%mm%",laAnneeMois(1))
				 lsBDCPath=Replace(lsBDCPath,"%mmm%",MthToStr(CInt(laAnneeMois(1))))
				 
	
				  'creation repertoire BDC
					genereBDCPath(mSrcDir&"\"&lsBDCPath)
					If Err.Number <> 0 Then
							asDetail=asDetail&_
									"     - Erreur generation """&mSrcDir&"\"&lsBDCPath&""" : "&_
									Err.Description&vbLf 
 							Err.Clear 					 		
 					End If
					
					'déplacement du fichier' 
					fso.MoveFile lsFile, mSrcDir&"\"&lsBDCPath
					If Err.Number <> 0 Then
						asDetail=asDetail&_
									"     - Erreur de déplacement """&lsBDCPath&""": "&_
									Err.Description&vbLf 
 							Err.Clear 
 					Else
								'BDC classée
								liNbFile=liNbFile + 1 
          End If	  
				End If ' loRegExp.Test(ls_File) 	  
			Next
		   
		End IF ' fso.FolderExists(SrcDir)'
	
	End Sub
	
	Public Function synchronize(ByRef asDetail)
	Dim loDirStrategie
	    
	    
			'Commence par ranger'
			classify(asDetail)    
			
			set loDirStrategie=new  CMSynchronizeDirStrategie
			loDirStrategie.SrcDir  = mSrcDir
			loDirStrategie.DestDir = mDestDir
			
			'synchro DIR'
			synchronize=loDirStrategie.synchronize(asDetail)
	End Function

End Class

'------------------- Fonctions syncro---------------------'

'Return le nom du jour du  numero du jour de la semaine 
Function DoWtoStr(ai_DayOfWeek)
 Dim ls_DoW
 
  ls_DoW = ""    
  Select Case ai_DayOfWeek
 
      Case 1 
         ls_DoW     = "Dimanche"
      Case 2 
         ls_DoW     = "Lundi"
      Case 3 
         ls_DoW     = "Mardi"
      Case 4 
         ls_DoW      = "Mercredi"
      Case 5 
         ls_DoW     = "Jeudi"
      Case 6 
         ls_DoW      = "Vendredi"
      Case 7 
         ls_DoW     = "Samedi"
      Case Else
         ls_DoW    = "Jour" + CStr(ai_DayOfWeek)
     End Select 
 
  DoWtoStr = ls_DoW
 
 End Function
 
  'Return le nom du mois du  numero de mois 
 
 Function MthToStr(ai_Month)
 
 Dim ls_Month
 ls_Month = ""    
 
  Select Case ai_Month
 
      Case 1
         ls_Month   = "Janv"
      Case 2 
         ls_Month   = "Fevr"
      Case 3 
         ls_Month   = "Mars"
      Case 4 
         ls_Month   = "Avr"
      Case 5 
         ls_Month   = "Mai"
      Case 6 
         ls_Month   = "Juin" 
      Case 7 
         ls_Month   = "Juil"
      Case 8 
         ls_Month   = "Aout"
      Case 9 
         ls_Month   = "Sept" 
      Case 10       
         ls_Month   = "Oct" 
      Case 11  
         ls_Month   = "Nov"  
      Case 12  
         ls_Month   = "Dec"
      Case Else 
         ls_Month   = "Mois"+CStr(ai_Month) 
     End Select 
 
    'Résultat
    MthToStr=ls_Month
 
 End Function                
 
 'Retourne la valeur d'une cle de registre si elle existe' 
Function readReg(as_keyPath)
 
Dim ls_value
 
      on error resume next
 
      ls_value=WshShell.RegRead(as_keyPath)
 
      on error goto 0
 
     readReg=ls_value
 
End Function
 
 
 
'Retour la valeur d'une cle de registre CashMag si elle existe'
 
Function readCMReg(as_key)
 
Dim ls_value
 
      ls_value=readReg(CM_REG_PRG_X64&"\"&as_key)
 
     If(ls_value = "" )Then
 
        ls_value=readReg(CM_REG_PRG_X86&"\"&as_key)
 
     End If
 
     readCMReg=ls_value
 
End Function
                                                 
' ------------------- Programme Principal ---------------------'

'1 > init variables Globales
Set fso = CreateObject( "Scripting.FileSystemObject" )
Set WshShell = WScript.CreateObject("WScript.Shell")

SaveDir     = ""
NoMail      = false
NoPrint     = false
NoBDC       = false
CodeClient  = "<inconnu>"
MailSupport = ""
BDCPath=CM_DEFAULT_BDC_PATH

Dim lbOK

set Rapport  =new   CMRapport
set Mail =new CMMail
lbOk=1
 
Rapport.Title = "Rapport d'Archives" & vbLf & "du " & Cstr(date())

Dim li_idx_arg
For li_idx_arg = 0 To WScript.Arguments.Count -1

  Select Case WScript.Arguments(li_idx_arg)
  
    Case "-saveDir"
      SaveDir = WScript.Arguments(li_idx_arg+1)
      li_idx_arg = li_idx_arg+1
    Case "-noPrint"
        NoPrint = true
    Case "-noMail"
        NoMail = true    
    Case "-support"
	   	MailSupport = WScript.Arguments(li_idx_arg+1)
		li_idx_arg = li_idx_arg+1	
	Case "-codeClient"	
		CodeClient = WScript.Arguments(li_idx_arg+1)
		li_idx_arg = li_idx_arg+1	
	Case "-noBDC"
		NoBDC = True        
	Case "-BDCPath"	
		BDCPath = WScript.Arguments(li_idx_arg+1)
		li_idx_arg = li_idx_arg+1	        
    Case "-noDataBaseNf"	
	    noDataBaseNf = True
  Case "-h"
    WScript.Echo "Usage : cm_copie_archive.vbs [option] destination"&vbLf
    WScript.Echo "   Option:"&vbLf
    WScript.Echo "    -saveDir  [Repertoire] : Repertoire de sauvegardes certifiées"&vbLf
    WScript.Echo "    -noMail  : Désactive l'envoi par mail"&vbLf 
    WScript.Echo "    -noPrint : Désactive l'impression du rapport"&vbLf 
    WScript.Echo "    -noBDC   : Pas de sauvegarde des Bandes de controle"&vbLf
    WScript.Echo "    -BDCPath [pathformat]: Format des répertoire d'archive BDC"&vbLf
		WScript.Echo "                          > %soc% Code société"&vbLf
		WScript.Echo "                          > %mag% Code magasin"&vbLf
		WScript.Echo "                          > %yyyy% Année"&vbLf
		WScript.Echo "                          > %mm% Mois en numérique"&vbLf
		WScript.Echo "                          > %mmm% Mois en abrégé"&vbLf&vbLf
		WScript.Echo "                         Ex :-BDCPath "&CM_DEFAULT_BDC_PATH&"   (défaut)" &vbLf 
    WScript.Echo "    -support  [email Support CashMag]  : Envoie mail support si erreur(s)."&vbLf 
  	WScript.Echo "    -codeClient  [Code client CashMag] : Ajoute code client dans objet du mail. Mettre en double quote si votre code client contient plusieurs codes ou mots " &vbLf
    WScript.Echo "    -noDataBaseNf  [Base de données] : Base de données NF ou non ? Si absent = NF " &vbLf          
    WScript.Quit(0)
  Case Else
    OutDir  =  WScript.Arguments(li_idx_arg)          
  
  End Select

Next

DataDir= readCMReg(OMC_DATA_DIR_KEY)


If fso.FolderExists(OutDir ) Then 
Dim loSynchronizer
Dim loDirStrategie
Dim loStrategieDB       

	set  loSynchronizer    = new   CMSynchronizer
	set loDirStrategie	   = new  CMSynchronizeDirStrategie
	set loStrategieDB      = new   CMSynchronizeDBFileStrategie
	
	'defaut
	loSynchronizer.setStrategie(loDirStrategie)
	loSynchronizer.setReport(Rapport)
    
'Est ce que GOMCPos est installé ?	
If readCMReg(OMC_GOMCPOS_INSTAL_KEY)     Then
 
    '2> Synchro Archives Fiscales'   
	  WScript.Echo  "2> Synchro Archives Fiscale"  
      If  fso.FolderExists(DataDir&CM_DB_GOMCPOS_DIR&CM_ARCH_DIR) Then
      
        ' OMCRapport  =OMCRapport&"  - Archives Fiscales :"&vbLf
        
         'configure strategie 
        loDirStrategie.SrcDir   = DataDir&CM_DB_GOMCPOS_DIR&CM_ARCH_DIR
        loDirStrategie.DestDir = OutDir& CM_ARCH_DIR
        loDirStrategie.Name = "Archives fiscales"
        'synchro ...  
        lbOk = lbOK and loSynchronizer.synchronize()
      End If
      
    '3> Synchro JET '
      WScript.Echo  "3> Synchro JET" 
      If  fso.FolderExists(DataDir&CM_DB_GOMCPOS_DIR&CM_JET_OUT_DIR) Then
              
        'configure strategie 
        loDirStrategie.SrcDir  = DataDir&CM_DB_GOMCPOS_DIR&CM_JET_OUT_DIR
        loDirStrategie.DestDir = OutDir&CM_JET_OUT_DIR
        loDirStrategie.Name = "Archives JET"
        'synchro ...  
        lbOk = lbOK and loSynchronizer.synchronize()
      End If
  
    '4> Synchro Journal ET 124_747'      
        If readCMReg(OMC_GOMCPOS_MODEL_KEY) = "ET124747"   Then
            WScript.Echo  "4> Synchro Journal ET 124_747" 
            If  fso.FolderExists(DataDir&CM_DB_GOMCPOS_DIR) Then
                Dim  loArchivesStrategie
                set loArchivesStrategie = new CMSynchronizeArchivesStrategie
                loSynchronizer.setStrategie(loArchivesStrategie)
  
                'configure strategie
                loArchivesStrategie.SrcDir   = DataDir&CM_DB_GOMCPOS_DIR&CM_ARCH_DIR
                loArchivesStrategie.DestDir  = OutDir&CM_ET_OUT_DIR
                loArchivesStrategie.Name     = "Archives ET 124-747"
  
                'synchro ...  
                lbOk = lbOK and loSynchronizer.synchronize()
            End If
        End If           
      
      '5> Synchro  Archive base Restau'
      WScript.Echo  "5> Synchro  Archive base Restau" 
      loSynchronizer.setStrategie(loStrategieDB)
    	
        'configure strategie
    	If SaveDir <> "" Then
   		  loStrategieDB.SrcDir = SaveDir
			Else
   			loStrategieDB.SrcDir = OutDir
   		End If
  		
    	loStrategieDB.DestDir 		 = OutDir&"\"&CM_DB_GOMCPOS_OUT_DIR
        
        'Si l'utilisateur veut effectuer une sauvegarde non NF
        if noDataBaseNf = True then        
        
        loStrategieDB.Pattern  	     = CM_DB_GOMCPOS_FILES_PATTERN_STANDARD        
        else
        
        loStrategieDB.Pattern  	     = CM_DB_GOMCPOS_FILES_PATTERN_NF
        end if  	         
                         
    	loStrategieDB.ConnectString  = CM_RESTAU_CS
    	loStrategieDB.Name     	     = "Bases GOMCPOS"
    	
    	'synchro ...  
      lbOk = lbOK and loSynchronizer.synchronize()
     
			 'control...      	
     	ls_detail=loStrategieDB.getCtrlArch()
        Rapport.appendMsg(ls_detail)
End If
                                        
'Est ce que GOMC est installé ?                                            
If readCMReg(OMC_GOMC_INSTAL_KEY)     Then
  
    	loSynchronizer.setStrategie(loStrategieDB)
    
  	  '6> Archives Bases GOMC
  	   WScript.Echo  "6> Synchro  Archives Bases GESCOM" 
			
	    'configure strategie 	
  		If SaveDir <> ""Then
   		  loStrategieDB.SrcDir = SaveDir
			Else
   			loStrategieDB.SrcDir = OutDir
   		End If
   		
    	loStrategieDB.DestDir 			= OutDir&"\"&CM_DB_GOMC_OUT_DIR   	
    	loStrategieDB.Pattern  			= CM_DB_GOMC_FILES_PATTERN
    	loStrategieDB.ConnectString	    = CM_GOMC_CS
    	loStrategieDB.Name     			= "Bases GESCOM"
    	
      'synchro ...  
      lbOk = lbOK and loSynchronizer.synchronize()
      
      'control... 
      ls_detail=loStrategieDB.getCtrlArch()
      Rapport.appendMsg(ls_detail)
      
      
      '7> BDC'
      WScript.Echo  "7> Synchro  BDC" 
      
      If not NoBDC Then
      	'configure strategie 
	      Dim loStrategieBDC 
				set loStrategieBDC =	 new CMSynchronizeBDCStrategie
				loSynchronizer.setStrategie(loStrategieBDC)
				 	
	      loStrategieBDC.SrcDir   = DataDir&CM_BDC_DIR
	      loStrategieBDC.DestDir = OutDir&"\BDCs"
	    	loStrategieBDC.Name     = "Archives BDCs"
	    	loStrategieBDC.PathPattern = BDCPath	
				
				'synchro ...  
	      lbOk = lbOK and loSynchronizer.synchronize()
      End If
End If               
  
      '8> Synchro Licences '
      loSynchronizer.setStrategie(loDirStrategie)
      loDirStrategie.SrcDir     = CM_LIC_DIRS
      loDirStrategie.DestDir    = OutDir & "\Licences"
      loDirStrategie.Name       = "Licences CashMag"
  
      'synchro ...  
      lbOk = lbOK and loSynchronizer.synchronize()

  
      '9 > Stat'
        Dim lo_drive
        Dim ls_drive
        ls_drive=fso.getDriveName(OutDir)
        set lo_drive=fso.getDrive(ls_drive)
        Rapport.appendMsg("Support Archives ("&ls_drive&")")
        Rapport.appendMsg("   Utilisation : "&CStr(100-((lo_drive.FreeSpace/1024)\(lo_drive.TotalSize/102400)) )&"%")
        Rapport.appendMsg(OutDir)
      Else
        Rapport.appendMsg("Fichier destination '"&OutDir&"' absent!")
        lbOk = 0 'Pas de destination -> Erreur'Rapport.appendMsg(OutDir)
      End If      
      
      dim ls_ini
      ls_ini=getRestauIni()

'----impression'
If not NoPrint and ls_ini <> "" Then
 
  dim Printer
  
  Set Printer=new CMPrinter
  Printer.SelectPrinter(getTicketPrinter(ls_ini))
  'Printer.SelectPrinter("EPSON TM-T88V ReceiptE4")
  Printer.printTxt(Rapport.toString()) 
End If

getDefautSMTP(Mail)
If not NoMail  then
  	Mail.setAccount CM_MAIL_ACCOUNT,CM_MAIL_PWD,"CashMag Solution<"&CM_MAIL_ACCOUNT&">" 

		Dim lsStatut
		lsStatut="OK"
		If  lbOk <> 1 Then
			lsStatut="ERREUR"
		End If
		
	 'envoi au magasin/dirigant/responsbale defint dans GOMC'
	 Err.Clear
	 If  readCMReg(OMC_GOMC_INSTAL_KEY)  Then 
	 	  'envoi au magasin/dirigant/responsbale defint dans GOMC'
		 	sendToGomcUsers Mail,"Rapport Archive : "&lsStatut,Rapport.toString()    
	Else
	 	
         'si pas de GOMC -> responsable/superviseur de GOMC-POS'
	     sendToRestauUsers Mail,"Rapport Archive : "&lsStatut,Rapport.toString()
	 End If
	 
	 	If Err.Number <> 0 Then
	 			Rapport.appendMsg("Envois Mail Client :")
				Rapport.appendMsg("    Erreur envois Mail :"&Err.Description) 
				lbOk=0
 				Err.Clear 					 		
 		End If                       		
 		
	 If lbOk <> 1 Then
	 	'mailsupport	 	
		
			sendToSupport  Mail,"Rapport Archive : Client ["&CodeClient&"] - ERREUR",Rapport.toString()
			If Err.Number <> 0 Then
				lbOk=0
				Err.Clear 					 		
 			End If 
	End If	
End If            

WScript.Echo        Rapport.toString()
WScript.Quit(1-lbOk)