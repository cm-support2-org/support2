CREATE FUNCTION "omc"."omc_f_calculCheckDigit"(barcodes t_code_barre)
RETURNS VARCHAR(13)
DETERMINISTIC

    //Cette fonction permet le calcul du checkdigit pour les EAN 8 ou 13.
    //Cela permet de remplacer l'étoile de GOMC par le digit.
    //Fonction basé sur le site https://github.com/segovoni/GS1-barcode-check-digit-calculator/blob/master/TSQL/sources/GS1CDC.class.sql

BEGIN
	DECLARE ls_barcodes t_code_barre;
    DECLARE ls_digit char(1);

    set ls_barcodes = barcodes;

    //C'est un EAN13 ?
    if len(barcodes) = 13 then

        //On supprime l'étoile
        set ls_barcodes = REPLACE(ls_barcodes,'*','');

	if isnumeric(ls_barcodes) = 1 then
    
	    	set ls_digit = string(
	                                (10 - (CAST(SUBSTRING(ls_barcodes, 1, 1) AS INTEGER)
	                                + 3* CAST(SUBSTRING(ls_barcodes, 2, 1) AS INTEGER)
	                                + CAST(SUBSTRING(ls_barcodes, 3, 1) AS INTEGER)
	                                + 3* CAST(SUBSTRING(ls_barcodes, 4, 1) AS INTEGER)
	                                + CAST(SUBSTRING(ls_barcodes, 5, 1) AS INTEGER)
	                                + 3* CAST(SUBSTRING(ls_barcodes, 6, 1) AS INTEGER)
	                                + CAST(SUBSTRING(ls_barcodes, 7, 1) AS INTEGER)
	                                + 3* CAST(SUBSTRING(ls_barcodes, 8, 1) AS INTEGER)
	                                + CAST(SUBSTRING(ls_barcodes, 9, 1) AS INTEGER)
	                                + 3* CAST(SUBSTRING(ls_barcodes, 10, 1) AS INTEGER)
	                                + CAST(SUBSTRING(ls_barcodes, 11, 1) AS INTEGER)
	                                + 3* CAST(SUBSTRING(ls_barcodes, 12, 1) AS INTEGER)
	                                    )%10
	                                )%10
	                             );
	        
	        //Contruction du codebarre avec le checkdigit
	        set ls_barcodes = string(ls_barcodes + ls_digit);
	end if;

    //C'est un EAN8 8
    elseif len(barcodes) = 8 then
        
        //On supprime l'étoile
        set ls_barcodes = REPLACE(ls_barcodes,'*','');

	if isnumeric(ls_barcodes) = 1 then
    
	        set ls_digit = string(
	                              (
	                                10 - (3* CAST(SUBSTRING(ls_barcodes, 1, 1) AS INTEGER)
	                                + CAST(SUBSTRING(ls_barcodes, 2, 1) AS INTEGER)
	                                + 3* CAST(SUBSTRING(ls_barcodes, 3, 1) AS INTEGER)
	                                + CAST(SUBSTRING(ls_barcodes, 4, 1) AS INTEGER)
	                                + 3* CAST(SUBSTRING(ls_barcodes, 5, 1) AS INTEGER)
	                                + CAST(SUBSTRING(ls_barcodes, 6, 1) AS INTEGER)
	                                + 3* CAST(SUBSTRING(ls_barcodes, 7, 1) AS INTEGER)
	                                    )%10
	                              )%10
	                             );
	
	        //Contruction du codebarre avec le checkdigit
	        set ls_barcodes = string(ls_barcodes + ls_digit);
	end if;
    end if;

	RETURN "ls_barcodes";
END;
