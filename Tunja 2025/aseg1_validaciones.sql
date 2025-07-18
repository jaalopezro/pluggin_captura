with predio as (select* from lc_predio lp 
					where lp.cancelar_predio is not true )							
	select 'Validacion', '1. Predio marcado como excepción sin observacion' validador, count (distinct lt.numero_predial) cantidad,GROUP_CONCAT(lt.numero_predial, ', ') AS identificador, 'Número predial de la tabla lc_terreno' tipo_identificador
	from 
	lc_terreno lt 
	left join lc_predio lp on lt.t_id = lp.lc_terreno
	left join archivo a on a.lc_terreno = lt.t_id
	where lp.excepcion is true and (lp.observacion_reconocedor is null or lp.observacion_reconocedor = '')
union all 
	select 'Validacion', '2. Predio marcado como cancelación sin observacion' validador, 
	count (distinct lt.numero_predial) cantidad,GROUP_CONCAT(lt.numero_predial, ', ') AS identificador, 'Número predial de la tabla lc_terreno' tipo_identificador
	from lc_terreno lt 
	left join lc_predio lp on lt.t_id = lp.lc_terreno
	where lp.cancelar_predio is true and (lp.observacion_reconocedor is null or lp.observacion_reconocedor = '')
union all 	
	select  'Consistencia de dominio' tipo,'3. Predio o terreno eliminado' explicacion, count (lpi.t_id) cantidad,GROUP_CONCAT(lpi.t_id, ', ') AS npn_concatenados, 'lc_predio, lc_terreno' tabla_error
	from  lc_predio_inicial lpi
	left join lc_predio lp on lpi.t_id = lp.t_id
	left join lc_terreno lt on lpi.lc_terreno =lt.t_id
	where  lp.t_id is null or lt.t_id is null
union all
	select 'Validacion' tipo,'4. Unidad constructiva sin adjunto de CROQUIS CONSTRUCCION' explicacion , count (s.t_id)cantidad, GROUP_CONCAT(s.t_id, ', ') AS Npn_concatenados, 'lc_unidadconstruccion'
	from 
	(select lu.t_id, GROUP_CONCAT(a.tipo_archivo, ', ')
	from lc_unidadconstruccion lu
	left join archivo a on a.lc_unidadconstruccion = lu.t_id
	left join lc_terreno lt on lt.t_id = lu.lc_terreno
	left join predio lp on lp.lc_terreno =lt.t_id
	where lu.tipo_construccion not in (691) or lu.tipo_construccion is null
	group by lu.t_id--,lt.numero_predial
	having GROUP_CONCAT(a.tipo_archivo, ', ') not like '%13%' or GROUP_CONCAT(a.tipo_archivo, ', ') is null )s 
union all 
	select 'Consistencia logica', '5. Unidad sin archivo ', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS Npn_concatenados, 'lc_unidadconstruccion'
	from lc_unidadconstruccion lu 
	left join  archivo a on lu.t_id = a.lc_unidadconstruccion
	where a.t_id is null
union all 
	select 'Validacion','6. Unidad constructiva sin adjunto de foto unidad espacial o ruina', count (s.t_id) , GROUP_CONCAT(s.t_id, ', ') AS Npn_concatenados, 'lc_unidadconstruccion'
	from (select lu.t_id, GROUP_CONCAT(a.tipo_archivo, ', ')
	from lc_unidadconstruccion lu
	left join archivo a on a.lc_unidadconstruccion = lu.t_id
	group by lu.t_id
	having (
	        GROUP_CONCAT(a.tipo_archivo, ', ') not LIKE '%10%'  or GROUP_CONCAT(a.tipo_archivo, ', ') is null
	    ))s  
union all 
	select 'Validacion','7. Terreno sin adjunto relacionado a los linderos', count (s.t_id),GROUP_CONCAT(s.numero_predial, ', ') AS Npn_concatenados, 'lc_terreno'
	from (select lt.t_id, lt.numero_predial, GROUP_CONCAT(a.tipo_archivo, ', ') 
	from lc_terreno lt
	left join archivo a on a.lc_terreno = lt.t_id
	inner join  lc_predio lp on lp.lc_terreno = lt.t_id
	where   lp.condicion_predio not in (457,458,462,459,461,462,465) 
	group by lt.t_id,lt.numero_predial
	having (GROUP_CONCAT(a.tipo_archivo, ', ') not like '%11%' and  GROUP_CONCAT(a.tipo_archivo, ', ') not like '%12%'  
	and GROUP_CONCAT(a.tipo_archivo, ', ') not like '%17%') or GROUP_CONCAT(a.tipo_archivo, ', ') is null)s
union all
	select  'Validacion' tipo,'8. Premarca de folio incosistente sin resolver', count (S.t_id) cantidad,GROUP_CONCAT(S.numero_predial, ', ') AS npn_concatenados,'lc_predio'
	from (SELECT lp.t_id, lt.numero_predial, group_concat(a.tipo_archivo, ',')
	FROM lc_terreno lt
	left join predio lp on lp.lc_terreno=lt.t_id
	left join  lc_predio_inicial lpi on lpi.t_id = lp.t_id
	LEFT JOIN archivo a ON a.lc_terreno = lt.t_id
	where lp.verificar_fmi =2 and   lp.matricula_inmobiliaria=lpi.matricula_inmobiliaria  
	GROUP BY lp.t_id, lt.numero_predial
	HAVING SUM(
    CASE WHEN a.tipo_archivo IN ('18') THEN 1 ELSE 0 END) = 0)S
 union all
	select  'Validacion' tipo,'9. Premarca de area inconsistente sin resolver', count (S.t_id) cantidad,GROUP_CONCAT(S.numero_predial, ', ') AS npn_concatenados,'lc_predio'
	from (SELECT lp.t_id, lt.numero_predial, group_concat(a.tipo_archivo, ',')
	FROM lc_terreno lt
	left join predio lp on lp.lc_terreno=lt.t_id
	left join  lc_predio_inicial lpi on lpi.t_id = lp.t_id
	LEFT JOIN archivo a ON a.lc_terreno = lt.t_id
	where lp.diferencia_area =2 
	GROUP BY lp.t_id, lt.numero_predial
	HAVING SUM(
    CASE WHEN a.tipo_archivo IN ('11','12') THEN 1 ELSE 0 END) = 0)S
union all 
	select 'Validacion','10. Premarca de omision sin resolver', count (s.t_id) , GROUP_CONCAT(s.numero_predial, ', ') AS Npn_concatenados,'lc_predio'
	from (
	select lp.t_id, lt.numero_predial,GROUP_CONCAT(a.tipo_archivo, ', ')
	from  predio lp 
	left join lc_terreno lt on lp.lc_terreno=lt.t_id
	left join archivo a on lt.t_id=a.lc_terreno
	where lp.omision =2 
			 and ((a.tipo_archivo not in (17,12,11) or a.tipo_archivo is null))
	group by lp.t_id,lt.numero_predial
	having (group_concat(a.tipo_archivo, ', ') not like'%11%' and 
		 (group_concat(a.tipo_archivo, ', ') not like'%12%' )
	or (group_concat(a.tipo_archivo, ', ') is null))
		)s
union all 
	select 'Validacion','11. Comision no resuelta', count (s.t_id),group_concat(s.numero_predial, ', ') AS Npn_concatenados,'lc_predio'
	from (select lp.t_id,lt.numero_predial, group_concat(a.tipo_archivo, ', ')
	from predio lp
	left join lc_terreno lt on lt.t_id =lp.lc_terreno
	left join archivo a on a.lc_terreno = lt.t_id
	left join lc_predio_inicial lpi on lpi.t_id=lp.t_id
	where lp.comision = 2 
	and lp.matricula_inmobiliaria=lpi.matricula_inmobiliaria
	and a.tipo_archivo not in (18)
	group by lp.t_id,lt.numero_predial) as s
union all 
	select 'Validacion','12. Predio nuevo sin fuente espacial', count (s.t_id),GROUP_CONCAT(s.numero_predial, ', ') AS Npn_concatenados,'lc_predio'
	from (select lt.t_id,lt.numero_predial, GROUP_CONCAT(a.tipo_archivo, ', ')
	from lc_terreno lt
	left join archivo a on a.lc_terreno = lt.t_id
	left join lc_predio lp on lp.lc_terreno = lt.t_id
	where lt.numero_predial like '%NUEVO%'  and lp.condicion_predio not in (457,458)
	group by lt.t_id,lt.numero_predial
	having (GROUP_CONCAT(a.tipo_archivo, ', ') not like '%11%' 
	and  GROUP_CONCAT(a.tipo_archivo, ', ') not like '%12%'  
	and GROUP_CONCAT(a.tipo_archivo, ', ') not like '%17%'
	)or  GROUP_CONCAT(a.tipo_archivo, ', ')  is null )s
union all
	select 'Consistencia logica', '13. FMI no cumple estructura', count (lp.t_id),GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados,'lc_predio'
	from lc_predio lp
	left join lc_terreno lt on lt.t_id =lp.lc_terreno
	where lp.cancelar_predio is not true and trim(lp.matricula_inmobiliaria) like '%-%' or upper(trim(lp.matricula_inmobiliaria)) like '%A%'or upper(trim(lp.matricula_inmobiliaria)) like '%B%'or upper(trim(lp.matricula_inmobiliaria)) like '%C%'or upper(trim(lp.matricula_inmobiliaria)) like '%D%'or upper(trim(lp.matricula_inmobiliaria)) like '%E%'or upper(trim(lp.matricula_inmobiliaria)) like '%F%'or upper(trim(lp.matricula_inmobiliaria)) like '%G%'or upper(trim(lp.matricula_inmobiliaria)) like '%H%'or upper(trim(lp.matricula_inmobiliaria)) like '%I%'or upper(trim(lp.matricula_inmobiliaria)) like '%J%'or upper(trim(lp.matricula_inmobiliaria)) like '%K%'or upper(trim(lp.matricula_inmobiliaria)) like '%L%'or upper(trim(lp.matricula_inmobiliaria)) like '%M%'or upper(trim(lp.matricula_inmobiliaria)) like '%N%'or upper(trim(lp.matricula_inmobiliaria)) like '%Ñ%'or upper(trim(lp.matricula_inmobiliaria)) like '%O%'or upper(trim(lp.matricula_inmobiliaria)) like '%P%'or upper(trim(lp.matricula_inmobiliaria)) like '%Q%'or upper(trim(lp.matricula_inmobiliaria)) like '%R%'or upper(trim(lp.matricula_inmobiliaria)) like '%S%'or upper(trim(lp.matricula_inmobiliaria)) like '%T%'or upper(trim(lp.matricula_inmobiliaria)) like '%U%'or upper(trim(lp.matricula_inmobiliaria)) like '%V%'or upper(trim(lp.matricula_inmobiliaria)) like '%W%'or upper(trim(lp.matricula_inmobiliaria)) like '%X%'or upper(trim(lp.matricula_inmobiliaria)) like '%Y%'or upper(trim(lp.matricula_inmobiliaria)) like '%Z%'or trim(lp.matricula_inmobiliaria) like '%.%'or trim(lp.matricula_inmobiliaria) like '%,%'or trim(lp.matricula_inmobiliaria) like '%#%'or trim(lp.matricula_inmobiliaria) like '%&%'or trim(lp.matricula_inmobiliaria) like '%<%'or trim(lp.matricula_inmobiliaria) like '%>%'or trim(lp.matricula_inmobiliaria) like '%>%'
union all 
	select 'Consistencia logica', '14. NPN no cumple estructura', count (lt.t_id),GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados,'lc_terreno'
	from lc_terreno lt
	where trim(lt.numero_predial) not like '%NUEVO%'and lt.numero_predial not like '%CE%'and ( length(trim(lt.numero_predial)) <>30 and trim(lt.numero_predial) like '%-%' or upper(trim(lt.numero_predial)) like '%A%'or upper(trim(lt.numero_predial)) like '%B%'or upper(trim(lt.numero_predial)) like '%C%'or upper(trim(lt.numero_predial)) like '%D%'or upper(trim(lt.numero_predial)) like '%E%'or upper(trim(lt.numero_predial)) like '%F%'or upper(trim(lt.numero_predial)) like '%G%'or upper(trim(lt.numero_predial)) like '%H%'or upper(trim(lt.numero_predial)) like '%I%'or upper(trim(lt.numero_predial)) like '%J%'or upper(trim(lt.numero_predial)) like '%K%'or upper(trim(lt.numero_predial)) like '%L%'or upper(trim(lt.numero_predial)) like '%M%'or upper(trim(lt.numero_predial)) like '%N%'or upper(trim(lt.numero_predial)) like '%Ñ%'or upper(trim(lt.numero_predial)) like '%O%'or upper(trim(lt.numero_predial)) like '%P%'or upper(trim(lt.numero_predial)) like '%Q%'or upper(trim(lt.numero_predial)) like '%R%'or upper(trim(lt.numero_predial)) like '%S%'or upper(trim(lt.numero_predial)) like '%T%'or upper(trim(lt.numero_predial)) like '%U%'or upper(trim(lt.numero_predial)) like '%V%'or upper(trim(lt.numero_predial)) like '%W%'or upper(trim(lt.numero_predial)) like '%X%'or upper(trim(lt.numero_predial)) like '%Y%'or upper(trim(lt.numero_predial)) like '%Z%'or trim(lt.numero_predial) like '%.%'or trim(lt.numero_predial) like '%,%'or trim(lt.numero_predial) like '%#%'or trim(lt.numero_predial) like '%&%'or trim(lt.numero_predial) like '%<%'or trim(lt.numero_predial) like '%>%'or trim(lt.numero_predial) like '%>%' )
union all 
	select 'Consistencia logica', '15. Predio informal con FMI',  count (lp.t_id),group_concat(lp.t_id, ', ') AS Npn_concatenados,'lc_predio'
	from lc_terreno lt 
	left join lc_predio lp on lp.lc_terreno =lt.t_id
	where (lp.condicion_predio =464) and lp.matricula_inmobiliaria is not null and lp.cancelar_predio is not true --and lt.numero_predial not like '%NUEVO%'
union all
	select 'Consistencia logica', '16. Predios con destinación económica: Comercial, educativo, habitacional, industrial, institucional, Religioso, Recreacional y Salubridad sin unidades de construcción', count (lt.t_id),GROUP_CONCAT(lt.t_id, ', ') AS Npn_concatenados,'lc_predio, lc_unidadconstruccion'
	from predio lp 
	left join lc_terreno lt on lp.lc_terreno = lt.t_id
	left join lc_unidadconstruccion lu on lu.lc_terreno=lt.t_id
	where lp.destino in (574,576,578,579,585,592,591,593) and lu.t_id is null and lp.condicion_predio not in (457,458,459,460,461,462)
union all 
	select 'Consistencia conceptual','17. Archivo creado  sin relación con terreno o unidad', count (a.t_id),GROUP_CONCAT(a.t_id, ', ') AS Npn_concatenados, 'archivo'
	from archivo a 
	left  join lc_terreno lt on lt.t_id=a.lc_terreno	
	left join lc_unidadconstruccion lu on a.lc_unidadconstruccion = lu.t_id
	left join lc_predio lp on lp.lc_terreno =lt.t_id
	where (lt.t_id is null and lu.t_id is null) 
union all
	select 'Validacion','18. Archivo creado, pero no se relaciona el tipo o no tiene ningun adjunto', count (ad.t_id),GROUP_CONCAT(ad.t_id, ', ') AS Npn_concatenados,'archivo'
	from archivo ad
	left  join lc_terreno lt on lt.t_id=ad.lc_terreno
	where (ad.tipo_archivo is null or ad.archivo is null)
union all 
	select 'Consistencia logica', '19. Contacto sin resultado visita', count (lc.t_id),GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados ,'lc_contacto'
	from lc_contacto lc
	left join lc_terreno lt on lt.t_id =lc.lc_terreno
	where lc.resultado_visita is null or lc.resultado_visita not in (76,77,78,79,80,81,82,83)
union all
	select 'Validacion','20. Contacto de visita con datos incompletos' , count (lc.t_id) ,GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados,'lc_contacto'
	from lc_contacto lc
	left join lc_terreno lt on lt.t_id =lc.lc_terreno
	where lc.resultado_visita=76 and (lc.numero_documento_quien_atendio is null or lc.primer_nombre_quien_atendio is null or lc.primer_apellido_quien_atendio is null)
union all
	select 'Consistencia conceptual','21. Contacto visita sin relación con terreno', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS Npn_concatenados,'lc_contacto'
	from lc_contacto lu
	left join lc_terreno lt on lt.t_id =lu.lc_terreno
	where lt.t_id is null  
union all 
	select 'Validacion','22. Correo electronico de contacto, sin estructura', count (lc.t_id),GROUP_CONCAT (lt.numero_predial, ', ') AS Npn_concatenados,'lc_contacto'
	from lc_contacto lc
	left join lc_terreno lt on lt.t_id =lc.lc_terreno
	where lc.correo_electronico not like ('%@%') or lc.correo_electronico not like ('%.%') 
union all
	select 'Consistencia logica', '23. Persona natural con NIT', count (lin.t_id),GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados,'lc_interesado'
	from lc_interesado lin
	left join lc_predio p on lin.lc_predio = p.t_id 
	left join lc_terreno lt on lt.t_id =p.lc_terreno
	where lin.tipo = 45 and lin.tipo_documento= 559 and lt.numero_predial like '%NUEVO%'
union all
	select 'Consistencia logica', '24. Persona jurídica con tipo de documento diferente a NIT', count (lin.t_id),GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados,'lc_interesado'
	from lc_interesado lin
	left join lc_predio p on lin.lc_predio = p.t_id 
	left join lc_terreno lt on lt.t_id =p.lc_terreno
	where lin.tipo = 46 and lin.tipo_documento <> 559
union all
	select 'Validacion', '25. Persona natural con nombres incompletos', count (lin.t_id),GROUP_CONCAT(lin.t_id, ', ') AS Npn_concatenados,'lc_interesado'
	from lc_interesado lin
	left join lc_predio p on lin.lc_predio = p.t_id 
	left join lc_terreno lt on lt.t_id =p.lc_terreno
	where lin.tipo = 45  and lt.numero_predial like '%NUEVO%'and (lin.primer_nombre is null or lin.primer_apellido is null)
union all
	---------------Juan Daniel 
	select 'Validacion', '26. Persona jurídica sin razón social', count (lin.t_id),GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados,'lc_interesado'
	from lc_interesado lin
	left join lc_predio p on lin.lc_predio = p.t_id 
	left join lc_terreno lt on lt.t_id =p.lc_terreno
	where lin.tipo = 46 and lin.razon_social is null and lt.numero_predial like '%NUEVO%'
union all 
	select 'Consistencia logica', '27. Documento de identidad de contacto no cumple con estructura', count (lc.t_id),GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados,'lc_contacto'
	from lc_contacto lc
	left join lc_terreno lt on lt.t_id =lc.lc_terreno
	where trim(lc.numero_documento_quien_atendio) GLOB  '*[^0-9] *'
union all 
	select 'Consistencia logica', '28. Documento de identidad de interesado no cumple con estructura', count (lin.t_id),GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados,'lc_interesado'
	from lc_interesado lin
	left join lc_predio p on lin.lc_predio = p.t_id 
	left join lc_terreno lt on lt.t_id =p.lc_terreno
	where upper(lt.numero_predial) like '%NUEV%' and (trim(lin.documento_identidad) like '%-%' or upper(trim(lin.documento_identidad)) like '%A%'or upper(trim(lin.documento_identidad)) like '%B%'or upper(trim(lin.documento_identidad)) like '%C%'or upper(trim(lin.documento_identidad)) like '%D%'or upper(trim(lin.documento_identidad)) like '%E%'or upper(trim(lin.documento_identidad)) like '%F%'or upper(trim(lin.documento_identidad)) like '%G%'or upper(trim(lin.documento_identidad)) like '%H%'or upper(trim(lin.documento_identidad)) like '%I%'or upper(trim(lin.documento_identidad)) like '%J%'or upper(trim(lin.documento_identidad)) like '%K%'or upper(trim(lin.documento_identidad)) like '%L%'or upper(trim(lin.documento_identidad)) like '%M%'or upper(trim(lin.documento_identidad)) like '%N%'or upper(trim(lin.documento_identidad)) like '%Ñ%'or upper(trim(lin.documento_identidad)) like '%O%'or upper(trim(lin.documento_identidad)) like '%P%'or upper(trim(lin.documento_identidad)) like '%Q%'or upper(trim(lin.documento_identidad)) like '%R%'or upper(trim(lin.documento_identidad)) like '%S%'or upper(trim(lin.documento_identidad)) like '%T%'or upper(trim(lin.documento_identidad)) like '%U%'or upper(trim(lin.documento_identidad)) like '%V%'or upper(trim(lin.documento_identidad)) like '%W%'or upper(trim(lin.documento_identidad)) like '%X%'or upper(trim(lin.documento_identidad)) like '%Y%'or upper(trim(lin.documento_identidad)) like '%Z%'or trim(lin.documento_identidad) like '%.%'or trim(lin.documento_identidad) like '%,%'or trim(lin.documento_identidad) like '%#%'or trim(lin.documento_identidad) like '%&%'or trim(lin.documento_identidad) like '%<%'or trim(lin.documento_identidad) like '%>%'or trim(lin.documento_identidad) like '%>%')
union all 
	select 'Validacion' tipo, '29. Archivo con dominio inexistente en el atributo tipo_archivo' explicacion , count (a.t_id) conteo ,GROUP_CONCAT(a.t_id, ', ') AS npn_concatenados,'archivo' 
	from archivo a
	left join lc_terreno lt on a.lc_terreno=lt.t_id
	left join lc_predio lp on lp.lc_terreno =lt.t_id
	where a.tipo_archivo is null or a.tipo_archivo not in (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21) 
union all
	select 'Validacion' tipo , '30. Archivo con nombre incorrecto', count (lp.t_id),group_concat(lt.numero_predial, ', ') AS Npn_concatenados,'archivo'
	from archivo a
	left join lc_terreno lt on a.lc_terreno=lt.t_id
	left join lc_predio lp on lp.lc_terreno =lt.t_id
	where (a.archivo not like '%TR%' and a.archivo not like '%UC%') 
union all
	select 'Consistencia de dominio','31. Interesado con dominio inexsitente en el atributo sexo', count (lu.t_id),group_concat(lt.numero_predial, ', ') AS Npn_concatenados,'lc_interesado'
	from lc_interesado lu
	left join lc_predio lp on lu.lc_predio = lp.t_id 
	left join lc_terreno lt on lt.t_id =lp.lc_terreno
	where lu.tipo <> 46 and (lu.sexo is null or lu.sexo not in (438,439,440))
union all
	select 'Consistencia conceptual','32. Interesado sin relación con predio', count (lin.t_id),group_concat(lin.t_id, ', ') AS Npn_concatenados,'lc_interesado'
	from lc_interesado lin
	left join lc_predio lp on lin.lc_predio = lp.t_id 
	where lp.t_id is null 
union all 
	select 'Consistencia logica', '33. Predio sin terreno ', count (lp.t_id),group_concat(lp.t_id, ', ') AS Npn_concatenados,'lc_predio'
	from lc_predio lp
	left join  lc_terreno lt  on lt.t_id = lp.lc_terreno
	where lt.t_id is null
union all
	select 'Consistencia de dominio','34. Predio con dominio inexistente en la condición de predio', count (lp.t_id),group_concat(lt.numero_predial, ', ') AS Npn_concatenados,'lc_predio'
	from lc_predio lp
	left join lc_terreno lt on lp.lc_terreno = lt.t_id
	where lp.condicion_predio is null 
union all 
	select 'Consistencia logica', '35. terreno sin predio', count (lt.t_id),group_concat(lt.numero_predial, ', ') AS Npn_concatenados,'lc_terreno'
	from lc_terreno lt 
	left join lc_predio lp on lt.t_id = lp.lc_terreno
	where lp.t_id is null 
union all
	select 'Consistencia logica', '36. Terreno sin archivo ', count (lt.t_id),group_concat(lt.numero_predial, ', ') AS Npn_concatenados,'lc_terreno'
	from lc_terreno lt
	left join  archivo a on lt.t_id= a.lc_terreno
	inner join predio lp on lp.lc_terreno =lt.t_id
	where a.t_id is null --and upper (lp.observacion ) not like '%CANC%'
	---------------Santiago
union all
	select 'Consistencia conceptual', '37. Unidad de construcción con datos incompletos', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS t_id_unidadconstruccion_concatenados,'lc_unidadconstruccion'
	from lc_unidadconstruccion lu 
	left JOIN lc_terreno lt on lt.t_id = lu.lc_terreno
	left join lc_predio lp on lp.lc_terreno =lt.t_id 
	where  (lu.uso is null or
		lu.tipo_construccion is null 
		or lu.tipo_unidadconstruccion is null 
		or lu.tipo_planta is null or lu.uso is null 
		or lu.anio_construccion is null 
		or lu.acabados is null or lu.estructura is null 
		or lu.sistema_constructivo is null or lu.estado is null 
		or lu.identificador is null or lu.can_unidadconstruccion is null 
		or lu.altura is null or lu.tipificacion is null 
		or lu.tipologia is null)
		and (lu.tipo_construccion <> 691 or lu.tipo_construccion is null  or lu.uso  in (181, 182)) 	
union all 
	select 'Consistencia conceptual', '38. Unidad de construcción con dominio inexistente en el planta tipo', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS t_id_unidadconstruccion_concatenados,'lc_unidadconstruccion'
	from lc_unidadconstruccion lu
	where lu.tipo_planta not in (71,72,	73,	74,	75) and  lu.tipo_construccion not in (691)
union all 
	select 'Consistencia conceptual', '39. Unidad de construcción con dominio inexistente en tipo de construcción', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS t_id_unidadconstruccion_concatenados,'lc_unidadconstruccion'
	from lc_unidadconstruccion lu
	where lu.tipo_construccion not in (689,	690,	691) and  lu.tipo_construccion not in (691)
union all 
	select 'Consistencia conceptual', '40. Unidad de construcción con dominio inexistente en el tipo unidad de construcción', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS t_id_unidadconstruccion_concatenados,'lc_unidadcionstruccion'
	from lc_unidadconstruccion lu
	where lu.tipo_unidadconstruccion not in (59,	60,	61,	62,	63) and  lu.tipo_construccion not in (691)
union all 
	select 'Consistencia conceptual', '41. Unidad de construcción con dominio inexistente en el uso', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS t_id_unidadconstruccion_concatenados,'lc_unidadconstruccion'
	from lc_unidadconstruccion lu
	where lu.uso not in (117,118,	119,	120,	121,	122,	123,	124,	125,	126,	127,	128,	129,	130,	131,	132,	133,	134,	135,	136,	137,	138,	139,	140,	141,	142,	143,	144,	145,	147,	148,	149,	150,	151,	152,	153,	154,	155,	156,	157,	158,	159,	160,	161,	162,	163,	164,	165,	166,	178,	167,	168,	169,	171,	172,	173,	174,	175,	176,	177,	179,	180,	181,	182,	183,	184,	185,	186,	187,	188,	189,	190,	191,	111,	112,	113,	114,	115,	116,	1235647,	146,	170,	192,	193,	194,	195,	196,	197,	198,	199,	200,	201,	202,	203,	206,	204,	205,	207,	208,	209,	210,	211,	
	212) and lu.tipo_construccion not in (691)
union all 
	select 'Consistencia logica', '42. Unidad sin terreno ', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS Npn_concatenados,'lc_unidadconstruccion'
	from lc_unidadconstruccion lu
	left join  lc_terreno lt on lu.lc_terreno= lt.t_id
	where lt.t_id is null 	
union all
	select 'Validacion','43. PH sin escritura', count (s.cond) , GROUP_CONCAT(s.cond, ', ') AS Npn_concatenados,'lc_terreno'
	from (
	select GROUP_CONCAT(a.tipo_archivo, ', '),substr (lt.numero_predial,1,22) cond
	from lc_terreno lt 
	left join archivo a on a.lc_terreno=lt.t_id
	left join predio lp on lp.lc_terreno = lt.t_id  
	where (( substr(lt.numero_predial,22,1)in ('9')) or lp.condicion_predio = 458) and (a.tipo_archivo not in (10, 11, 12, 13, 14, 15, 16, 17, 18 ,19, 21) or a.tipo_archivo is null)
	group by  substr (lt.numero_predial,1,22)
	having (GROUP_CONCAT(a.tipo_archivo, ', ')not like'%1%')or GROUP_CONCAT(a.tipo_archivo, ', ')is null
	)s
union all 
	select 'Validacion','44. Predio sin resultado_visita', count (lt.t_id),GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados,'lc_terreno'
	from lc_terreno lt 
	left join lc_contacto lc on lc.lc_terreno=lt.t_id
	where lc.t_id is null  or lc.resultado_visita is null 
union all
	select 'Consistencia logica','45. Tipo archivo otro sin complemento', count (a.t_id),GROUP_CONCAT(a.t_id, ', ') AS Npn_concatenados,'archivo'
	from archivo a
	where a.tipo_archivo = 21 and a.cual is null
union all
	select 'Validacion','46.Predios con fmi nulo por resolver', count (s.t_id)as cantidad, group_concat(s.numero_predial, ', ') AS Npn_concatenados,'lc_predio'
	from (
	select lp.t_id,lt.numero_predial, group_concat(a.tipo_archivo, ', ')
	from (select  *from lc_predio lp where upper (trim(replace(lp.observacion_reconocedor , ' ', ''))) not like '%NORESUEL%' or lp.observacion_reconocedor is null) lp
	left join lc_terreno lt on lt.t_id =lp.lc_terreno
	left join  archivo a on a.lc_terreno = lt.t_id
	where lp.verificar_fmi =2 
	group by lp.t_id,lt.numero_predial 
	having (GROUP_CONCAT(a.tipo_archivo, ', ') not like'%18%'
	and GROUP_CONCAT (a.tipo_archivo, ', ') not like'%1%'
	and GROUP_CONCAT (a.tipo_archivo, ', ') not like'%2%'
	and GROUP_CONCAT (a.tipo_archivo, ', ') not like'%3%')
	or group_concat(a.tipo_archivo, ', ')is null 
	)s
union all 
	select 'Consistencia logica','47. Año de construccion atipico', count (lu.t_id), group_concat(lu.t_id,', ') as Npn_concatenados ,'lc_unidadconstruccion'
	from lc_unidadconstruccion lu 
	where (lu.anio_construccion<1800 or lu.anio_construccion>2025) and lu.tipo_construccion <>691
union all
	select 'Consistencia logica','48. Diseño original - tipologias que no aplican', count (lu.t_id), group_concat(lu.t_id,', ') as Npn_concatenados ,'lc_unidadconstruccion'
	from lc_unidadconstruccion lu 
	where lu.tipificacion in (25,46,47,49) 
union all 
	select 'Consistencia logica','49. Usos que no aplican', count (lu.t_id), group_concat(lu.t_id,', ') as Npn_concatenados ,'lc_unidadconstruccion'
	from lc_unidadconstruccion lu 
	where lu.uso in (72,73,85,101,97,88,69,9) 
union all
	select 'Validacion','50. Diseño original - tipologias de PH en NPH', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS Npn_concatenados,'lc_unidadconstruccion'
	from lc_predio lp
	left join lc_terreno lt on lt.t_id = lp.lc_terreno
	left join lc_unidadconstruccion lu on lu.lc_terreno =lt.t_id
	where  lp.condicion_predio not in (458,460) and lu.tipificacion in (4,5,23) 
union all
	select 'Validacion','51. Usos PH en NPH', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS Npn_concatenados,'lc_unidadconstruccion'
	from lc_predio lp
	left join lc_terreno lt on lt.t_id = lp.lc_terreno
	left join lc_unidadconstruccion lu on lu.lc_terreno =lt.t_id
	where lp.condicion_predio not in (458,460)  and lu.uso  in (127,129,133,136,139,142,147,149,151,153,166,111,118,123,125)
union all 
	select 'Validacion','52. Usos NPH en PH', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS Npn_concatenados,'lc_unidadconstruccion'
	from lc_predio lp
	left join lc_terreno lt on lt.t_id = lp.lc_terreno
	left join lc_unidadconstruccion lu on lu.lc_terreno =lt.t_id
	where   lp.condicion_predio  in (458) and lu.uso not in (127,129,133,136,139,142,147,149,151,153,166,111,118,123,125)
union all
	select 'Validacion','53. Anexos con diseño original - tipologias casa', count (lu.t_id), group_concat(lu.t_id,', ') as Npn_concatenados ,'lc_unidadconstruccion'
	from lc_unidadconstruccion lu 
	where lu.tipo_construccion=690 and lu.tipificacion in (3)
union all
	select 'Validacion','55. Uso Anexo.Marquesinas_Patios_Cubiertos con diseño original - tipologias incorrecta', count (lu.t_id), group_concat(lu.t_id,', ') as Npn_concatenados ,'lc_unidadconstruccion'
	from lc_unidadconstruccion lu 
	where lu.uso in (197)  and lu.tipificacion not in (29,30)
union all
	select 'Validacion','56. Uso Anexo.Ramadas_Cobertizos_Caneyes con diseño original - tipologias incorrecta', count (lu.t_id), group_concat(lu.t_id,', ') as Npn_concatenados ,'lc_unidadconstruccion'
	from lc_unidadconstruccion lu 
	where lu.uso in (204)  and lu.tipificacion not in (30)
union all
	select 'Validacion','57. Uso Anexo.Cimientos_Estructura_Muros_y_Placa con diseño original - tipologias incorrecta', count (lu.t_id), group_concat(lu.t_id,', ') as Npn_concatenados ,'lc_unidadconstruccion'
	from lc_unidadconstruccion lu 
	where lu.uso in (185) and lu.tipificacion not in (43)
union all
	select  'Validacion', '58. Manzana sin plano general de asignacion', count (s.manzana), group_concat(s.manzana, ',') as Npn_concatenados,'archivo'
	from (
	select substring(lt.numero_predial,1,17)manzana, group_concat( a.tipo_archivo, ', ')
	from predio lp 
	left join lc_terreno lt on lp.lc_terreno =lt.t_id 
	left join archivo a on a.lc_terreno =lt.t_id 
	where lt.numero_predial not like '%NUEVO%' 
	group by substring(lt.numero_predial,1,17)
	having (group_concat(a.tipo_archivo, ', ') not like '%17%') or group_concat(a.tipo_archivo, ', ') is null) as s 	
union all 
	--revisar
	select 'Consistencia logica', '59. Predio con datos incompletos', count (lp.t_id),GROUP_CONCAT(lp.t_id, ', ') AS Npn_concatenados,'lc_predio'
	from lc_predio lp 
	left join lc_terreno lt on lt.t_id =lp.lc_terreno
	where (case 
			when lt.numero_predial not like '%NUEVO%' and lp.verificar_fmi in (2) and substr (lt.numero_predial,22,1)not in ('5', '2')
				then lp.condicion_predio is null or lp.destino is null
			when lt.numero_predial not like '%NUEVO%' and lp.verificar_fmi in (2) and substr (lt.numero_predial,22,1)not in ('5', '2')
				then lp.condicion_predio is null or lp.destino is null  or lp.matricula_inmobiliaria is null
			when lt.numero_predial not like '%NUEVO%' and substr (lt.numero_predial,22,1)in ('5', '2') 
				then lp.condicion_predio is null or lp.destino is null 
			when lt.numero_predial like '%NUEVO%' and lp.condicion_predio <>464 
				then  lp.condicion_predio is null or lp.matricula_inmobiliaria is null or lp.destino is null
			when lt.numero_predial like '%NUEVO%' and lp.condicion_predio =464 
				then  lp.condicion_predio is null or  lp.destino is null
			end
	) and lp.condicion_predio not in (457,459,461) and lp.cancelar_predio is not true
union all 
	select 'Validacion','60. Predio nuevo sin fuente administrativa', count (s.t_id),group_concat(s.numero_predial, ', ') AS Npn_concatenados,'lc_predio'
	from (SELECT lt.t_id, lt.numero_predial, group_concat(a.tipo_archivo, ',')
	FROM lc_terreno lt
	LEFT JOIN archivo a ON a.lc_terreno = lt.t_id
	WHERE lt.numero_predial  LIKE '%NUEVO%'
	GROUP BY lt.t_id, lt.numero_predial
	HAVING SUM(
    CASE WHEN a.tipo_archivo IN ('1','2','3','4','19','21','22') THEN 1 ELSE 0 END) = 0)s
union all
	select 'Validacion','61. Predio informal sin fuente administrativa', count (s.t_id),group_concat(s.numero_predial, ', ') AS Npn_concatenados,'lc_predio'
	from (SELECT lp.t_id, lt.numero_predial, group_concat(a.tipo_archivo, ',')
	FROM lc_terreno lt
	left join predio lp on lp.lc_terreno=lt.t_id
	LEFT JOIN archivo a ON a.lc_terreno = lt.t_id
	WHERE lt.numero_predial  not LIKE '%NUEVO%'
	and lp.condicion_predio=464
	GROUP BY lp.t_id, lt.numero_predial
	HAVING SUM(
    CASE WHEN a.tipo_archivo IN ('1','2','3','4','19','21','22','23','18') THEN 1 ELSE 0 END) = 0)s
union all     
	select 'validacion','62. Terreno con más de un contacto visita' validador, count(lt.numero_predial) cantidad, 
	GROUP_CONCAT(lt.numero_predial, ', ') AS identificador, 'Número predial de la tabla lc_terreno' tipo_identificador
	from lc_terreno lt
	join lc_contacto c on lt.t_id = c.lc_terreno 
    group by c.t_id 
	having count(c.t_id) > 1
union all 
	select 'Consistencia logica','63. Año de construccion atipico' validador, count (lu.t_id) cantidad,GROUP_CONCAT(lu.t_id, ', ') AS identificador, 't_id de la tabla lc_unidadconstruccion' tipo_identificador 
	from lc_unidadconstruccion lu 
	where (lu.anio_construccion<1800 or lu.anio_construccion>2026) and lu.tipo_construccion <>691
union all 	
	select 'Consistencia logica','64. Diseño original que no aplican' validador, count (lu.t_id) cantidad,GROUP_CONCAT(lu.t_id, ', ') AS identificador, 't_id de la tabla lc_unidadconstruccion' tipo_identificador 
	from lc_unidadconstruccion lu 
	where lu.tipificacion in (25,46,47,49)
union all 
	select 'Consistencia logica','65. Usos que no aplican' validador, count (lu.t_id) cantidad,GROUP_CONCAT(lu.t_id, ', ') AS identificador, 't_id de la tabla lc_unidadconstruccion' tipo_identificador 
	from lc_unidadconstruccion lu 
	where lu.uso in (120, 180, 183, 184, 196, 199, 208, 212)
union all 
	select 'Validacion','66. Diseño original de PH en predios con condición diferente a ph o condominio' validador, count (lu.t_id) cantidad,GROUP_CONCAT(lu.t_id, ', ') AS identificador, 't_id de la tabla lc_unidadconstruccion' tipo_identificador
	from lc_predio lp
	left join lc_terreno lt on lt.t_id = lp.lc_terreno
	left join lc_unidadconstruccion lu on lu.lc_terreno =lt.t_id
	where  lp.condicion_predio not in (457,458,459,460) and lu.tipificacion in (4,5,23)
UNION ALL
	select 'Validacion','67. Uso Residencial.Depositos_Lockers en predios con condición distian a PH o Condominio' validador, count (lu.t_id) cantidad,GROUP_CONCAT(lu.t_id, ', ') AS identificador, 't_id de la tabla lc_unidadconstruccion' tipo_identificador
	from lc_predio lp
	left join lc_terreno lt on lt.t_id = lp.lc_terreno
	left join lc_unidadconstruccion lu on lu.lc_terreno =lt.t_id
	where  lp.condicion_predio not in (457,458,459,460) and lu.uso in (116)
UNION ALL 
	select 'Validacion','68. predio que requiere planos que no adjunta planos', count (s.t_id),group_concat(s.numero_predial, ', ') AS Npn_concatenados,'lc_predio'
	from (SELECT lt.t_id, lt.numero_predial, group_concat(a.tipo_archivo, ',')
	FROM lc_terreno lt
	LEFT JOIN archivo a ON a.lc_terreno = lt.t_id
	left join predio lp on lp.lc_terreno=lt.t_id
	WHERE lp.requiere_planos is true
	GROUP BY lt.t_id, lt.numero_predial
	HAVING SUM(
    CASE WHEN a.tipo_archivo IN ('11','12') THEN 1 ELSE 0 END) = 0)s
