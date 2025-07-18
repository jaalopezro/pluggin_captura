with cuenta as (
select lt.numero_predial , count(distinct lt.numero_predial) as count ,GROUP_CONCAT(lt.numero_predial, ', ') AS npn_concatenados
 from lc_terreno lt
left join lc_contacto lc 
on lt.t_id = lc.lc_terreno
group by lt.t_id
having count (lt.t_id)> 1)
select  'Consistencia de dominio' tipo,'2. Predio o terreno eliminado' explicacion, count (lpi.t_id) cantidad,GROUP_CONCAT(lpi.t_id, ', ') AS npn_concatenados
from  lc_predio_inicial lpi
left join lc_predio lp on lpi.t_id = lp.t_id
left join lc_terreno lt on lpi.lc_terreno =lt.t_id
where lt.t_id is null or lp.t_id is null
union all
select 'Validacion' tipo,'3. Unidad constructiva sin adjunto de CROQUIS CONSTRUCCION' explicacion , count (s.t_id)cantidad, GROUP_CONCAT(s.t_id, ', ') AS Npn_concatenados
from 
(select lu.t_id, GROUP_CONCAT(a.tipo_archivo, ', ')
from lc_unidadconstruccion lu
left join archivo a on a.lc_unidadconstruccion = lu.t_id
left join (select * from lc_terreno lt) lt on lt.t_id = lu.lc_terreno
left join lc_predio lp on lp.lc_terreno =lt.t_id
where lu.tipo_construccion not in (691) or lu.tipo_construccion is null
group by lu.t_id--,lt.numero_predial
having GROUP_CONCAT(a.tipo_archivo, ', ') not like '%13%' or GROUP_CONCAT(a.tipo_archivo, ', ') is null )s 
union all 
select 'Consistencia logica', '4. Unidad sin archivo ', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS Npn_concatenados
from lc_unidadconstruccion lu
left join  archivo a on lu.t_id = a.lc_unidadconstruccion
where a.t_id is null
union all 
select 'Validacion','6. Unidad constructiva sin adjunto de foto unidad espacial o ruina', count (s.t_id) , GROUP_CONCAT(s.t_id, ', ') AS Npn_concatenados
from (select lu.t_id, GROUP_CONCAT(a.tipo_archivo, ', ')
from (select* from lc_unidadconstruccion lu /*where upper(trim(lu.identificador)) not like '%X%' */) lu
left join archivo a on a.lc_unidadconstruccion = lu.t_id
group by lu.t_id
having (
        GROUP_CONCAT(a.tipo_archivo, ', ') not LIKE '%10%' 
    ))s
union all 
select 'Validacion','7. Terreno sin adjunto relacionado a los linderos', count (s.t_id),GROUP_CONCAT(s.numero_predial, ', ') AS Npn_concatenados
from (select lt.t_id, lt.numero_predial, GROUP_CONCAT(a.tipo_archivo, ', ') 
from lc_terreno lt
left join archivo a on a.lc_terreno = lt.t_id
inner join (select  *
			from lc_predio lp 
			where (upper (lp.observacion) not like '%CANC%' or lp.observacion is null) 
			and (lp.omision=3 and upper (trim(replace(lp.observacion, ' ', ''))) not like '%NORESUEL%' or lp.observacion is null )) lp on lp.lc_terreno = lt.t_id
where   lp.condicion_predio not in (457,458,462,459,461) and substr(lt.asignacion,1,2) in ('01', '02', '03', '04', '05','06')
group by lt.t_id,lt.numero_predial
having (GROUP_CONCAT(a.tipo_archivo, ', ') not like '%11%' and  GROUP_CONCAT(a.tipo_archivo, ', ') not like '%12%'  
and GROUP_CONCAT(a.tipo_archivo, ', ') not like '%17%') or GROUP_CONCAT(a.tipo_archivo, ', ') is null)s
union all 
select 'Validacion','9. Omision no resuelta por falta de adjuntos', count (s.t_id) , GROUP_CONCAT(s.numero_predial, ', ') AS Npn_concatenados
from (
select lp.t_id, lt.numero_predial,GROUP_CONCAT(a.tipo_archivo, ', ')
from (select* from lc_predio lp where (upper (trim(lp.observacion) )not like '%CANC%' or lp.observacion is null) and (upper (trim(replace(lp.observacion, ' ', ''))) 
		not like '%NORESUEL%' or lp.observacion is null)) lp 
left join lc_terreno lt on lp.lc_terreno=lt.t_id
left join archivo a on lt.t_id=a.lc_terreno
where lp.omision =3 
		 and ((a.tipo_archivo not in (10, 13, 14, 15, 16, 17 ,19, 21, 22) or a.tipo_archivo is null))
		 and (upper(trim(a.cual)) not like '%FA%' )
group by lp.t_id,lt.numero_predial
having (group_concat(a.tipo_archivo, ', ') not like'%11%' and 
		 (group_concat(a.tipo_archivo, ', ') not like'%12%' )
or (group_concat(a.tipo_archivo, ', ') is null))
)s
union all 
select 'Consistencia logica', '10. Predio con datos incompletos', count (lp.t_id),GROUP_CONCAT(lp.t_id, ', ') AS Npn_concatenados
from (select  *
	from lc_predio lp 
		where (upper (trim(lp.observacion)) not like '%CANC%' or lp.observacion is null)
		and (upper (trim(replace(lp.observacion, ' ', ''))) not like '%NORESUEL%' or lp.observacion is null)
		and lp.condicion_predio not in (457,459,461)) lp
left join lc_terreno lt on lt.t_id =lp.lc_terreno
where (case 
		when lt.numero_predial not like '%NUEVO%' and lp.fmi_null in (1,2) and substr (lt.numero_predial,22,1)not in ('5', '2')
			then lp.condicion_predio is null or lp.destino is null
		when lt.numero_predial not like '%NUEVO%' and lp.fmi_null not in (1,2) and substr (lt.numero_predial,22,1)not in ('5', '2')
			then lp.condicion_predio is null or lp.destino is null  or lp.matricula_inmobiliaria is null
		when lt.numero_predial not like '%NUEVO%' and substr (lt.numero_predial,22,1)in ('5', '2') 
			then lp.condicion_predio is null or lp.destino is null 
		when lt.numero_predial like '%NUEVO%' and lp.condicion_predio <>464 
			then  lp.condicion_predio is null or lp.matricula_inmobiliaria is null or lp.destino is null
		when lt.numero_predial like '%NUEVO%' and lp.condicion_predio =464 
			then  lp.condicion_predio is null or  lp.destino is null
		end
)
union all 

select 'Validacion','13. Predio nuevo sin fuente espacial', count (s.t_id),GROUP_CONCAT(s.numero_predial, ', ') AS Npn_concatenados
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

select 'Consistencia logica', '16. FMI no cumple estructura', count (lp.t_id),GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from (select* from lc_predio lp where upper (lp.observacion )not like '%CANC%' or lp.observacion is null) lp
left join lc_terreno lt on lt.t_id =lp.lc_terreno
where trim(lp.matricula_inmobiliaria) like '%-%' or upper(trim(lp.matricula_inmobiliaria)) like '%A%'or upper(trim(lp.matricula_inmobiliaria)) like '%B%'or upper(trim(lp.matricula_inmobiliaria)) like '%C%'or upper(trim(lp.matricula_inmobiliaria)) like '%D%'or upper(trim(lp.matricula_inmobiliaria)) like '%E%'or upper(trim(lp.matricula_inmobiliaria)) like '%F%'or upper(trim(lp.matricula_inmobiliaria)) like '%G%'or upper(trim(lp.matricula_inmobiliaria)) like '%H%'or upper(trim(lp.matricula_inmobiliaria)) like '%I%'or upper(trim(lp.matricula_inmobiliaria)) like '%J%'or upper(trim(lp.matricula_inmobiliaria)) like '%K%'or upper(trim(lp.matricula_inmobiliaria)) like '%L%'or upper(trim(lp.matricula_inmobiliaria)) like '%M%'or upper(trim(lp.matricula_inmobiliaria)) like '%N%'or upper(trim(lp.matricula_inmobiliaria)) like '%Ñ%'or upper(trim(lp.matricula_inmobiliaria)) like '%O%'or upper(trim(lp.matricula_inmobiliaria)) like '%P%'or upper(trim(lp.matricula_inmobiliaria)) like '%Q%'or upper(trim(lp.matricula_inmobiliaria)) like '%R%'or upper(trim(lp.matricula_inmobiliaria)) like '%S%'or upper(trim(lp.matricula_inmobiliaria)) like '%T%'or upper(trim(lp.matricula_inmobiliaria)) like '%U%'or upper(trim(lp.matricula_inmobiliaria)) like '%V%'or upper(trim(lp.matricula_inmobiliaria)) like '%W%'or upper(trim(lp.matricula_inmobiliaria)) like '%X%'or upper(trim(lp.matricula_inmobiliaria)) like '%Y%'or upper(trim(lp.matricula_inmobiliaria)) like '%Z%'or trim(lp.matricula_inmobiliaria) like '%.%'or trim(lp.matricula_inmobiliaria) like '%,%'or trim(lp.matricula_inmobiliaria) like '%#%'or trim(lp.matricula_inmobiliaria) like '%&%'or trim(lp.matricula_inmobiliaria) like '%<%'or trim(lp.matricula_inmobiliaria) like '%>%'or trim(lp.matricula_inmobiliaria) like '%>%'
union all 
select 'Consistencia logica', '17. NPN no cumple estructura', count (lt.t_id),GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from lc_terreno lt
where trim(lt.numero_predial) not like '%NUEVO%'and lt.numero_predial not like '%CE%'and ( length(trim(lt.numero_predial)) <>30 and trim(lt.numero_predial) like '%-%' or upper(trim(lt.numero_predial)) like '%A%'or upper(trim(lt.numero_predial)) like '%B%'or upper(trim(lt.numero_predial)) like '%C%'or upper(trim(lt.numero_predial)) like '%D%'or upper(trim(lt.numero_predial)) like '%E%'or upper(trim(lt.numero_predial)) like '%F%'or upper(trim(lt.numero_predial)) like '%G%'or upper(trim(lt.numero_predial)) like '%H%'or upper(trim(lt.numero_predial)) like '%I%'or upper(trim(lt.numero_predial)) like '%J%'or upper(trim(lt.numero_predial)) like '%K%'or upper(trim(lt.numero_predial)) like '%L%'or upper(trim(lt.numero_predial)) like '%M%'or upper(trim(lt.numero_predial)) like '%N%'or upper(trim(lt.numero_predial)) like '%Ñ%'or upper(trim(lt.numero_predial)) like '%O%'or upper(trim(lt.numero_predial)) like '%P%'or upper(trim(lt.numero_predial)) like '%Q%'or upper(trim(lt.numero_predial)) like '%R%'or upper(trim(lt.numero_predial)) like '%S%'or upper(trim(lt.numero_predial)) like '%T%'or upper(trim(lt.numero_predial)) like '%U%'or upper(trim(lt.numero_predial)) like '%V%'or upper(trim(lt.numero_predial)) like '%W%'or upper(trim(lt.numero_predial)) like '%X%'or upper(trim(lt.numero_predial)) like '%Y%'or upper(trim(lt.numero_predial)) like '%Z%'or trim(lt.numero_predial) like '%.%'or trim(lt.numero_predial) like '%,%'or trim(lt.numero_predial) like '%#%'or trim(lt.numero_predial) like '%&%'or trim(lt.numero_predial) like '%<%'or trim(lt.numero_predial) like '%>%'or trim(lt.numero_predial) like '%>%' )
union all 
select 'Consistencia logica', '18. Predio informal con FMI',  count (lp.t_id),group_concat(lp.t_id, ', ') AS Npn_concatenados
from lc_terreno lt 
left join (select  *from lc_predio lp where upper (lp.observacion) not like '%CANC%' or lp.observacion is null ) lp on lp.lc_terreno =lt.t_id
where (lp.condicion_predio =464) and lp.matricula_inmobiliaria is not null --and lt.numero_predial not like '%NUEVO%'
union all
select 'Consistencia logica', '19. Predios con destinación económica: Comercial, educativo, habitacional, industrial, institucional, Religioso, Recreacional y Salubridad sin unidades de construcción', count (lt.t_id),GROUP_CONCAT(lt.t_id, ', ') AS Npn_concatenados
from (select* from lc_predio lp where (upper (lp.observacion) not like '%CANC%' or lp.observacion is null )
				and (lp.omision=3 and upper (trim(replace(lp.observacion, ' ', ''))) not like '%NORESUEL%' or lp.observacion is null  )) lp 
left join lc_terreno lt on lp.lc_terreno = lt.t_id
left join lc_unidadconstruccion lu on lu.lc_terreno=lt.t_id
where lp.destino in (574,576,578,579,585,592,591,593) and lu.t_id is null and lp.condicion_predio not in (457,458,459,460,461,462)
union all 
select 'Consistencia conceptual','20. Archivo creado pero sin relación con terreno o unidad', count (a.t_id),GROUP_CONCAT(a.t_id, ', ') AS Npn_concatenados
from archivo a 
left  join lc_terreno lt on lt.t_id=a.lc_terreno	
left join lc_unidadconstruccion lu on a.lc_unidadconstruccion = lu.t_id
left join lc_predio lp on lp.lc_terreno =lt.t_id
where (lt.t_id is null and lu.t_id is null) 
union all
select 'Validacion','21. Archivo creado, pero no se relaciona el tipo o no tiene ningun adjunto', count (ad.t_id),GROUP_CONCAT(ad.t_id, ', ') AS Npn_concatenados
from archivo ad
left  join lc_terreno lt on lt.t_id=ad.lc_terreno
where (ad.tipo_archivo is null or ad.archivo is null) 
union all 
select 'Consistencia logica', '22. Contacto sin resultado visita', count (lc.t_id),GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados 
from lc_contacto lc
left join lc_terreno lt on lt.t_id =lc.lc_terreno
where lc.resultado_visita is null or lc.resultado_visita not in (76,77,78,79,80,81,82,83)
union all
select 'Validacion','23. Contacto de visita con datos incompletos' , count (lc.t_id) ,GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from lc_contacto lc
left join lc_terreno lt on lt.t_id =lc.lc_terreno
where lc.resultado_visita=76 and (lc.numero_documento_quien_atendio is null or lc.primer_nombre_quien_atendio is null or lc.primer_apellido_quien_atendio is null)
union all
select 'Consistencia conceptual','24. Contacto visita sin relación con terreno', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS Npn_concatenados
from lc_contacto lu
left join lc_terreno lt on lt.t_id =lu.lc_terreno
where lt.t_id is null  
union all 
select 'Validacion','25. Correo electronico de contacto, sin estructura', count (lc.t_id),GROUP_CONCAT (lt.numero_predial, ', ') AS Npn_concatenados
from lc_contacto lc
left join lc_terreno lt on lt.t_id =lc.lc_terreno
where lc.correo_electronico not like ('%@%') or lc.correo_electronico not like ('%.%') 
union all 
select 'Consistencia logica', '26. Persona natural con NIT', count (lin.t_id),GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from lc_interesado lin
left join lc_predio p on lin.lc_predio = p.t_id 
left join lc_terreno lt on lt.t_id =p.lc_terreno
where lin.tipo = 45 and lin.tipo_documento= 559 and lt.numero_predial like '%NUEVO%'
union all
select 'Consistencia logica', '27. Persona jurídica con tipo de documento diferente a NIT', count (lin.t_id),GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from lc_interesado lin
left join lc_predio p on lin.lc_predio = p.t_id 
left join lc_terreno lt on lt.t_id =p.lc_terreno
where lin.tipo = 46 and lin.tipo_documento <> 559
union all
select 'Validacion', '28. Persona natural con nombres incompletos', count (lin.t_id),GROUP_CONCAT(lin.t_id, ', ') AS Npn_concatenados
from lc_interesado lin
left join lc_predio p on lin.lc_predio = p.t_id 
left join lc_terreno lt on lt.t_id =p.lc_terreno
where lin.tipo = 45  and lt.numero_predial like '%NUEVO%'and (lin.primer_nombre is null or lin.primer_apellido is null)
union all
---------------Juan Daniel 
select 'Validacion', '29. Persona jurídica sin razón social', count (lin.t_id),GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from lc_interesado lin
left join lc_predio p on lin.lc_predio = p.t_id 
left join lc_terreno lt on lt.t_id =p.lc_terreno
where lin.tipo = 46 and lin.razon_social is null and lt.numero_predial like '%NUEVO%'
union all 
select 'Consistencia logica', '30. Documento de identidad de contacto no cumple con estructura', count (lc.t_id),GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from lc_contacto lc
left join lc_terreno lt on lt.t_id =lc.lc_terreno
where trim(lc.numero_documento_quien_atendio) GLOB  '*[^0-9] *'
union all 
select 'Consistencia logica', '31. Documento de identidad de interesado no cumple con estructura', count (lin.t_id),GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from lc_interesado lin
left join lc_predio p on lin.lc_predio = p.t_id 
left join lc_terreno lt on lt.t_id =p.lc_terreno
where upper(lt.numero_predial) like '%NUEV%' and (trim(lin.documento_identidad) like '%-%' or upper(trim(lin.documento_identidad)) like '%A%'or upper(trim(lin.documento_identidad)) like '%B%'or upper(trim(lin.documento_identidad)) like '%C%'or upper(trim(lin.documento_identidad)) like '%D%'or upper(trim(lin.documento_identidad)) like '%E%'or upper(trim(lin.documento_identidad)) like '%F%'or upper(trim(lin.documento_identidad)) like '%G%'or upper(trim(lin.documento_identidad)) like '%H%'or upper(trim(lin.documento_identidad)) like '%I%'or upper(trim(lin.documento_identidad)) like '%J%'or upper(trim(lin.documento_identidad)) like '%K%'or upper(trim(lin.documento_identidad)) like '%L%'or upper(trim(lin.documento_identidad)) like '%M%'or upper(trim(lin.documento_identidad)) like '%N%'or upper(trim(lin.documento_identidad)) like '%Ñ%'or upper(trim(lin.documento_identidad)) like '%O%'or upper(trim(lin.documento_identidad)) like '%P%'or upper(trim(lin.documento_identidad)) like '%Q%'or upper(trim(lin.documento_identidad)) like '%R%'or upper(trim(lin.documento_identidad)) like '%S%'or upper(trim(lin.documento_identidad)) like '%T%'or upper(trim(lin.documento_identidad)) like '%U%'or upper(trim(lin.documento_identidad)) like '%V%'or upper(trim(lin.documento_identidad)) like '%W%'or upper(trim(lin.documento_identidad)) like '%X%'or upper(trim(lin.documento_identidad)) like '%Y%'or upper(trim(lin.documento_identidad)) like '%Z%'or trim(lin.documento_identidad) like '%.%'or trim(lin.documento_identidad) like '%,%'or trim(lin.documento_identidad) like '%#%'or trim(lin.documento_identidad) like '%&%'or trim(lin.documento_identidad) like '%<%'or trim(lin.documento_identidad) like '%>%'or trim(lin.documento_identidad) like '%>%')
union all 
select 'Consistencia logica', '32. Dirección estructurada mal diligenciada', count (ld.t_id),GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from lc_direccion ld
left join lc_terreno lt on ld.lc_terreno = lt.t_id
where (ld.tipo_direccion=213 and ( ld.clase_via_principal is null or ld.valor_via_principal is null or ld.valor_via_generadora is  null or ld.numero_predio is  null ))
union all 
select 'Consistencia logica', '33. Dirección no estructurada mal diligenciada', count (ld.t_id),GROUP_CONCAT(ld.t_id, ', ') AS Npn_concatenados
from lc_direccion ld
left join lc_terreno lt on ld.lc_terreno = lt.t_id
where ld.tipo_direccion=214 
		and (ld.nombre_predio is null )
union all 
select 'Validacion' tipo, '34. Archivo con dominio inexistente en el atributo tipo_archivo' explicacion , count (a.t_id) conteo ,GROUP_CONCAT(a.t_id, ', ') AS npn_concatenados 
from archivo a
left join lc_terreno lt on a.lc_terreno=lt.t_id
left join lc_predio lp on lp.lc_terreno =lt.t_id
where a.tipo_archivo is null or a.tipo_archivo not in (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21) 
union all
select 'Validacion' tipo , '35. Archivo con nombre incorrecto', count (lp.t_id),group_concat(lt.numero_predial, ', ') AS Npn_concatenados
from archivo a
left join lc_terreno lt on a.lc_terreno=lt.t_id
left join lc_predio lp on lp.lc_terreno =lt.t_id
where (a.archivo not like '%TR%' and a.archivo not like '%UC%') 
union all 
select  'Consistencia logica', '37. Dirección con dominio inexistente en el atributo tipo_direccion', count (ld.t_id),group_concat(lt.numero_predial, ', ') AS Npn_concatenados
from lc_direccion ld
left join lc_terreno lt on ld.lc_terreno = lt.t_id
left join lc_predio lp on lp.lc_terreno =lt.t_id
where (ld.tipo_direccion is null or ld.tipo_direccion not in (213,214)) and substring(lt.numero_predial,22,9)<>'900000000' 
union all 
select 'Consistencia conceptual', '38. Dirección sin terreno', count (ld.t_id),group_concat(lt.numero_predial, ', ') AS Npn_concatenados
from lc_direccion ld
left join lc_terreno lt on ld.lc_terreno = lt.t_id
where lt.t_id is null
union all
select 'Consistencia de dominio','40. Interesado con dominio inexsitente en el atributo sexo', count (lu.t_id),group_concat(lt.numero_predial, ', ') AS Npn_concatenados
from lc_interesado lu
left join lc_predio lp on lu.lc_predio = lp.t_id 
left join lc_terreno lt on lt.t_id =lp.lc_terreno
where lu.tipo <> 46 and (lu.sexo is null or lu.sexo not in (438,439,440))
union all
select 'Consistencia conceptual','41. Interesado sin relación con predio', count (lin.t_id),group_concat(lin.t_id, ', ') AS Npn_concatenados
from lc_interesado lin
left join lc_predio lp on lin.lc_predio = lp.t_id 
where lp.t_id is null 
union all 
select 'Consistencia logica', '42. Predio sin terreno ', count (lp.t_id),group_concat(lp.t_id, ', ') AS Npn_concatenados
from lc_predio lp
left join  lc_terreno lt  on lt.t_id = lp.lc_terreno
where lt.t_id is null 
union all
select 'Consistencia de dominio','43.Predio con dominio inexistente en la condición de predio', count (lp.t_id),group_concat(lt.numero_predial, ', ') AS Npn_concatenados
from lc_predio lp
left join lc_terreno lt on lp.lc_terreno = lt.t_id
where lp.condicion_predio is null or lp.condicion_predio not in (456,457,458,459,460,461,462,463,464,465)
union all 
select 'Consistencia logica', '44. terreno sin predio', count (lt.t_id),group_concat(lt.numero_predial, ', ') AS Npn_concatenados
from lc_terreno lt 
left join lc_predio lp on lt.t_id = lp.lc_terreno
where lp.t_id is null 
union all
select 'Consistencia logica', '45. Terreno sin archivo ', count (lt.t_id),group_concat(lt.numero_predial, ', ') AS Npn_concatenados
from lc_terreno lt
left join  archivo a on lt.t_id= a.lc_terreno
inner join (select *
				from lc_predio lp where (upper (lp.observacion )not like '%CANC%' or lp.observacion is null ) 
				and (upper (trim(replace(lp.observacion, ' ', ''))) not like '%NORESUEL%' or lp.observacion is null)
				and lp.condicion_predio not in (457,459,461))
					 lp on lp.lc_terreno =lt.t_id
where a.t_id is null --and upper (lp.observacion ) not like '%CANC%'
---------------Santiago 
union all
select 'Consistencia conceptual', ' 46. Unidad de construcción con datos incompletos', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS t_id_unidadconstruccion_concatenados
from lc_unidadconstruccion lu 
left JOIN lc_terreno lt on lt.t_id = lu.lc_terreno
left join lc_predio lp on lp.lc_terreno =lt.t_id 
where (case 
			when (lu.uso not in  (181, 182) or lu.uso is null)  then (lu.tipo_construccion is null or lu.tipo_unidadconstruccion is null or lu.tipo_planta is null or lu.uso is null or lu.anio_construccion is null or lu.acabados is null or lu.estructura is null or lu.sistema_constructivo is null or lu.estado is null or lu.identificador is null or lu.can_unidadconstruccion is null or lu.altura is null or lu.tipificacion is null or lu.tipologia is null)
			when lu.uso  in (181, 182) then (lu.tipo_construccion is null or lu.tipo_unidadconstruccion is null or lu.tipo_planta is null or lu.uso is null or lu.anio_construccion is null or lu.acabados is null or lu.sistema_constructivo is null or lu.estado is null or lu.identificador is null or lu.can_unidadconstruccion is null or lu.altura is null or lu.tipificacion is null or lu.tipologia is null)
end
) and (lu.tipo_construccion <> 691 or lu.tipo_construccion is null) --and  (upper (lp.observacion) not like '%CANC%' or lp.observacion is null)
union all 
select 'Consistencia conceptual', '47. Unidad de construcción con dominio inexistente en el planta tipo', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS t_id_unidadconstruccion_concatenados
from lc_unidadconstruccion lu
where lu.tipo_planta not in (71,
72,
73,
74,
75) and  lu.tipo_construccion not in (691)
union all 
select 'Consistencia conceptual', ' 48. Unidad de construcción con dominio inexistente en tipo de construcción', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS t_id_unidadconstruccion_concatenados
from lc_unidadconstruccion lu
where lu.tipo_construccion not in (689,
690,
691) and  lu.tipo_construccion not in (691)
union all 
select 'Consistencia conceptual', ' 49. Unidad de construcción con dominio inexistente en el tipo unidad de construcción', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS t_id_unidadconstruccion_concatenados
from lc_unidadconstruccion lu
where lu.tipo_unidadconstruccion not in (59,
60,
61,
62,
63) and  lu.tipo_construccion not in (691)
union all 
select 'Consistencia conceptual', ' 50. Unidad de construcción con dominio inexistente en el uso', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS t_id_unidadconstruccion_concatenados
from lc_unidadconstruccion lu
where lu.uso not in (117,118,	119,	120,	121,	122,	123,	124,	125,	126,	127,	128,	129,	130,	131,	132,	133,	134,	135,	136,	137,	138,	139,	140,	141,	142,	143,	144,	145,	147,	148,	149,	150,	151,	152,	153,	154,	155,	156,	157,	158,	159,	160,	161,	162,	163,	164,	165,	166,	178,	167,	168,	169,	171,	172,	173,	174,	175,	176,	177,	179,	180,	181,	182,	183,	184,	185,	186,	187,	188,	189,	190,	191,	111,	112,	113,	114,	115,	116,	1235647,	146,	170,	192,	193,	194,	195,	196,	197,	198,	199,	200,	201,	202,	203,	206,	204,	205,	207,	208,	209,	210,	211,	
212) and lu.tipo_construccion not in (691)
union all select 'Consistencia logica', '51. Unidad sin terreno ', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS Npn_concatenados
from lc_unidadconstruccion lu
left join  lc_terreno lt on lu.lc_terreno= lt.t_id
where lt.t_id is null 
union all
select 'Validacion','58. PH sin escritura', count (s.cond) , GROUP_CONCAT(s.cond, ', ') AS Npn_concatenados
from (
select GROUP_CONCAT(a.tipo_archivo, ', '),substr (lt.numero_predial,1,22) cond
from lc_terreno lt 
left join archivo a on a.lc_terreno=lt.t_id
left join (select  *from lc_predio lp where (upper (lp.observacion) not like '%CANC%' or lp.observacion is null)) lp on lp.lc_terreno = lt.t_id  
where (( substr(lt.numero_predial,22,1)in ('9')) or lp.condicion_predio = 458) and (a.tipo_archivo not in (10, 11, 12, 13, 14, 15, 16, 17, 18 ,19, 21) or a.tipo_archivo is null)
group by  substr (lt.numero_predial,1,22)
having (GROUP_CONCAT(a.tipo_archivo, ', ')not like'%1%')or GROUP_CONCAT(a.tipo_archivo, ', ')is null
)s
union all 
select 'Validacion','60. Predio sin resultado_visita', count (lt.t_id),GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from lc_terreno lt 
left join lc_contacto lc on lc.lc_terreno=lt.t_id
where lc.t_id is null  or lc.resultado_visita is null 
union all
select 'Consistencia logica','61. Tipo archivo otro sin complemento', count (a.t_id),GROUP_CONCAT(a.t_id, ', ') AS Npn_concatenados
from archivo a
where a.tipo_archivo = 21 and a.cual is null
union all
select 'Validacion','63.Predios con fmi nulo por resolver', count (s.t_id)as cantidad, group_concat(s.numero_predial, ', ') AS Npn_concatenados
from (
select lp.t_id,lt.numero_predial, group_concat(a.tipo_archivo, ', ')
from (select  *from lc_predio lp where upper (trim(replace(lp.observacion, ' ', ''))) not like '%NORESUEL%' or lp.observacion is null) lp
left join lc_terreno lt on lt.t_id =lp.lc_terreno
left join  archivo a on a.lc_terreno = lt.t_id
where lp.fmi_null =2 
group by lp.t_id,lt.numero_predial 
having (GROUP_CONCAT(a.tipo_archivo, ', ') not like'%18%'
and GROUP_CONCAT (a.tipo_archivo, ', ') not like'%1%'
and GROUP_CONCAT (a.tipo_archivo, ', ') not like'%2%'
and GROUP_CONCAT (a.tipo_archivo, ', ') not like'%3%')
or group_concat(a.tipo_archivo, ', ')is null 
)s
union all
select 'validacion','64. Terreno con màs de un contacto visita', count(numero_predial), GROUP_CONCAT(numero_predial, ', ') AS Npn_concatenados from cuenta
union all 
select 'Consistencia logica','65. Año de construccion atipico', count (lu.t_id), group_concat(lu.t_id,', ') as Npn_concatenados 
from lc_unidadconstruccion lu 
where (lu.anio_construccion<1800 or lu.anio_construccion>2025) and lu.tipo_construccion <>691
union all
select 'Consistencia logica','66. Diseño original - tipologias que no aplican', count (lu.t_id), group_concat(lu.t_id,', ') as Npn_concatenados 
from lc_unidadconstruccion lu 
where lu.tipificacion in (25,46,47,49) 
union all 
select 'Consistencia logica','67. Usos que no aplican', count (lu.t_id), group_concat(lu.t_id,', ') as Npn_concatenados 
from lc_unidadconstruccion lu 
where lu.uso in (72,73,85,101,97,88,69,9) 
union all
select 'Validacion','68. Diseño original - tipologias de PH en NPH', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS Npn_concatenados
from lc_predio lp
left join lc_terreno lt on lt.t_id = lp.lc_terreno
left join lc_unidadconstruccion lu on lu.lc_terreno =lt.t_id
where  lp.condicion_predio not in (458,460) and lu.tipificacion in (4,5,23) 
union all
select 'Validacion','69. Usos PH en NPH', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS Npn_concatenados
from lc_predio lp
left join lc_terreno lt on lt.t_id = lp.lc_terreno
left join lc_unidadconstruccion lu on lu.lc_terreno =lt.t_id
where lp.condicion_predio not in (458,460)  and lu.uso  in (127,129,133,136,139,142,147,149,151,153,166,111,118,123,125)
union all 
select 'Validacion','70. Usos NPH en PH', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS Npn_concatenados
from lc_predio lp
left join lc_terreno lt on lt.t_id = lp.lc_terreno
left join lc_unidadconstruccion lu on lu.lc_terreno =lt.t_id
where   lp.condicion_predio  in (458) and lu.uso not in (127,129,133,136,139,142,147,149,151,153,166,111,118,123,125)
union all
select 'Validacion','71. Anexos con diseño original - tipologias casa', count (lu.t_id), group_concat(lu.t_id,', ') as Npn_concatenados 
from lc_unidadconstruccion lu 
where lu.tipo_construccion=690 and lu.tipificacion in (3)
union all
select 'Validacion','72. Uso Residencial.Depositos_Lockers en NPH', count (lu.t_id),GROUP_CONCAT(lu.t_id, ', ') AS Npn_concatenados
from lc_predio lp
left join lc_terreno lt on lt.t_id = lp.lc_terreno
left join lc_unidadconstruccion lu on lu.lc_terreno =lt.t_id
where  lp.condicion_predio not in (458) and lu.uso in (116)
union all
select 'Validacion','73. Uso Anexo.Marquesinas_Patios_Cubiertos con diseño original - tipologias incorrecta', count (lu.t_id), group_concat(lu.t_id,', ') as Npn_concatenados 
from lc_unidadconstruccion lu 
where lu.uso in (197)  and lu.tipificacion not in (29,30)
union all
select 'Validacion','74.  Uso Anexo.Ramadas_Cobertizos_Caneyes con diseño original - tipologias incorrecta', count (lu.t_id), group_concat(lu.t_id,', ') as Npn_concatenados 
from lc_unidadconstruccion lu 
where lu.uso in (204)  and lu.tipificacion not in (30)
union all
select 'Validacion','75.  Uso Anexo.Cimientos_Estructura_Muros_y_Placa con diseño original - tipologias incorrecta', count (lu.t_id), group_concat(lu.t_id,', ') as Npn_concatenados 
from lc_unidadconstruccion lu 
where lu.uso in (185) and lu.tipificacion not in (43)
union all

select  'Validacion', '77. Manzana sin plano general de asignacion', count (s.manzana), group_concat(s.manzana, ',') as Npn_concatenados
from (
select substring(lt.numero_predial,1,17)manzana, group_concat( a.tipo_archivo, ', ')
from lc_predio lp 
left join lc_terreno lt on lp.lc_terreno =lt.t_id 
left join archivo a on a.lc_terreno =lt.t_id 
where lt.numero_predial not like '%NUEVO%' 
	and lt.numero_predial not like '%CE%'
	and substr(lt.asignacion,1,2) in ('07', '08', '09', '10', '11','12', '13', '14', '15', '16', '17', '18')
group by substring(lt.numero_predial,1,17)
having (group_concat(a.tipo_archivo, ', ') not like '%17%') or group_concat(a.tipo_archivo, ', ') is null) as s 
union all
select 'Validacion','5. Requiere actualizacion de interesados y no adjunta fuente', count (s.numero_predial),group_concat(s.numero_predial, ', ') AS Npn_concatenados
from (select lt.numero_predial, group_concat(a.tipo_archivo, ', ')
		from lc_terreno lt
		left join archivo a on a.lc_terreno = lt.t_id
		left join lc_predio lp on lp.lc_terreno = lt.t_id
		where lp.requiere_interesados is true and lt.numero_predial in (select lt.numero_predial 
																		from lc_terreno lt 
																		left join (select  lt.numero_predial , group_concat(tb1.tipo_archivo, ', ') 
																						from lc_terreno lt 
																						join (select a.t_id t_id_archivo , a.tipo_archivo, a.lc_terreno, a.cual from archivo a where a.tipo_archivo in (1,2,3,4,18) and a.lc_terreno is not null
																								union all 
																								select a.t_id t_id_archivo, a.tipo_archivo, a.lc_terreno, a.cual  from archivo a where upper(trim(a.cual)) like '%FA%' and a.lc_terreno is not null
																								) as tb1 on tb1.lc_terreno = lt.t_id 
																						group by lt.numero_predial ) 
																					as tb2 on tb2.numero_predial = lt.numero_predial
																		where tb2.numero_predial is null)
		group by lt.numero_predial) as s
union all 
select 'Validacion','8. Comision no resuelta', count (s.t_id),group_concat(s.numero_predial, ', ') AS Npn_concatenados
from (select lp.t_id,lt.numero_predial, group_concat(a.tipo_archivo, ', ')
from lc_predio lp
left join lc_terreno lt on lt.t_id =lp.lc_terreno
left join archivo a on a.lc_terreno = lt.t_id
where lp.comision = 2 
		and (upper (trim(replace(lp.observacion, ' ', ''))) not like '%NORESUEL%' or lp.observacion is null)
		and lp.condicion_predio not in (457,459,461)
		and lt.numero_predial in (select lt.numero_predial 
																		from lc_terreno lt 
																		left join (select  lt.numero_predial , group_concat(tb1.tipo_archivo, ', ') 
																						from lc_terreno lt 
																						join (select a.t_id t_id_archivo , a.tipo_archivo, a.lc_terreno, a.cual from archivo a where a.tipo_archivo in (1,2,3,4,18) and a.lc_terreno is not null
																								union all 
																								select a.t_id t_id_archivo, a.tipo_archivo, a.lc_terreno, a.cual  from archivo a where upper(trim(a.cual)) like '%FA%' and a.lc_terreno is not null
																								) as tb1 on tb1.lc_terreno = lt.t_id 
																						group by lt.numero_predial ) 
																					as tb2 on tb2.numero_predial = lt.numero_predial
																		where tb2.numero_predial is null)
	group by lp.t_id,lt.numero_predial) as s
	union all 
select 'Validacion','12. Predio nuevo sin fuente administrativa', count (s.t_id),group_concat(s.numero_predial, ', ') AS Npn_concatenados
from (select lt.t_id,lt.numero_predial, group_concat(a.tipo_archivo, ', ')
from lc_terreno lt
left join archivo a on a.lc_terreno = lt.t_id
left join lc_predio lp on lp.lc_terreno = lt.t_id
where lt.numero_predial like '%NUEVO%' 
		and lt.numero_predial in (select lt.numero_predial 
																		from lc_terreno lt 
																		left join (select  lt.numero_predial , group_concat(tb1.tipo_archivo, ', ') 
																						from lc_terreno lt 
																						join (select a.t_id t_id_archivo , a.tipo_archivo, a.lc_terreno, a.cual from archivo a where a.tipo_archivo in (1,2,3,4,18,19) and a.lc_terreno is not null
																								union all 
																								select a.t_id t_id_archivo, a.tipo_archivo, a.lc_terreno, a.cual  from archivo a where upper(trim(a.cual)) like '%FA%' and a.lc_terreno is not null
																								) as tb1 on tb1.lc_terreno = lt.t_id 
																						group by lt.numero_predial ) 
																					as tb2 on tb2.numero_predial = lt.numero_predial
																		where tb2.numero_predial is null)
		group by lt.t_id,lt.numero_predial)s
union all
select 'Validacion','15. Predio informal sin fuente administrativa', count (s.t_id),group_concat(s.numero_predial, ', ') AS Npn_concatenados
from (select lt.t_id,lt.numero_predial, group_concat(a.tipo_archivo, ', ')
from lc_terreno lt
left join archivo a on a.lc_terreno = lt.t_id
left join (select  *
			from lc_predio lp 
			where upper (lp.observacion) not like '%CANC%' or lp.observacion is null) lp on lp.lc_terreno = lt.t_id
where lp.condicion_predio =464 
		and lt.numero_predial not like '%NUEVO&'
		and lt.numero_predial in (select lt.numero_predial 
																		from lc_terreno lt  
																		left join (select  lt.numero_predial , group_concat(tb1.tipo_archivo, ', ') 
																						from lc_terreno lt 
																						join (select a.t_id t_id_archivo , a.tipo_archivo, a.lc_terreno, a.cual from archivo a where a.tipo_archivo in (1,2,3,4,18) and a.lc_terreno is not null
																								union all 
																								select a.t_id t_id_archivo, a.tipo_archivo, a.lc_terreno, a.cual  from archivo a where upper(trim(a.cual)) like '%FA%' and a.lc_terreno is not null
																								) as tb1 on tb1.lc_terreno = lt.t_id 
																						group by lt.numero_predial ) 
																					as tb2 on tb2.numero_predial = lt.numero_predial
																		where tb2.numero_predial is null)
group by lt.t_id,lt.numero_predial)s
UNION ALL
 select 'Validacion','62.Predios con fmi duplicado por resolver', count (s.numero_predial),group_concat(s.numero_predial, ', ') AS Npn_concatenados
from (
select  lt.numero_predial  , group_concat( a.tipo_archivo,' ,') 
from lc_terreno lt 
left join lc_predio lp on lt.t_id = lp.lc_terreno
left join archivo a on a.lc_terreno = lt.t_id
where lp.fmi_duplicado =2 and (upper (trim(replace(lp.observacion, ' ', ''))) not like '%NORESUEL%'  )
		and lt.numero_predial in (select lt.numero_predial 
																		from lc_terreno lt 
																		left join (select  lt.numero_predial , group_concat(tb1.tipo_archivo, ', ') 
																						from lc_terreno lt 
																						join (select a.t_id t_id_archivo , a.tipo_archivo, a.lc_terreno, a.cual from archivo a where a.tipo_archivo in (1,2,3,4,18) and a.lc_terreno is not null
																								union all 
																								select a.t_id t_id_archivo, a.tipo_archivo, a.lc_terreno, a.cual  from archivo a where upper(trim(a.cual)) like '%FA%' and a.lc_terreno is not null
																								) as tb1 on tb1.lc_terreno = lt.t_id 
																						group by lt.numero_predial ) 
																					as tb2 on tb2.numero_predial = lt.numero_predial
																		where tb2.numero_predial is null)
group by  lt.numero_predial 
) as s
union all

select  'Validacion', '76. Predio caso especial no cancelado sin fuente administrativa', count (s.numero_predial), group_concat(s.numero_predial, ',') as Npn_concatenados
from (select lt.numero_predial , group_concat(a.tipo_archivo,' ,'), group_concat(a.cual, ' ,') 
from lc_predio lp 
left join lc_terreno lt on lp.lc_terreno =lt.t_id 
left join archivo a on a.lc_terreno =lt.t_id 
where lt.numero_predial like '%CE%' 
	and (upper (trim(lp.observacion)) not like '%CANCEL%'  or lp.observacion is null or lt.	documentos is false)
	and lp.lc_terreno in (select lp.lc_terreno
from lc_predio lp
left join (
			select  lt.t_id, lt.numero_predial , group_concat(tb1.tipo_archivo, ', ') 
																									from lc_terreno lt 
																									join (select a.t_id t_id_archivo , a.tipo_archivo, a.lc_terreno, a.cual from archivo a where a.tipo_archivo in (1,2,3,4,18) and a.lc_terreno is not null
																											union all 
																											select a.t_id t_id_archivo, a.tipo_archivo, a.lc_terreno, a.cual  from archivo a where upper(trim(a.cual)) like '%FA%' and a.lc_terreno is not null
																											) as tb1 on tb1.lc_terreno = lt.t_id 
																									group by lt.t_id, lt.numero_predial ) as tb2 
on tb2.t_id= lp.lc_terreno
where tb2.t_id is null)
group by lt.numero_predial) s