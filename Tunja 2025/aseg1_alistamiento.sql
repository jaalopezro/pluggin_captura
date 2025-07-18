select 'Alistamiento' as Tipo,'1. Numero de Predios asignados' as Explicacion, count(lp.t_id) as Cantidad, GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from lc_predio lp
left join lc_terreno lt on lt.t_id =lp.lc_terreno
union all
select 'Alistamiento', '2. Numero de Terrenos asignados ', count (t_id) as cantidad, GROUP_CONCAT(numero_predial, ', ') AS Npn_concatenados
from lc_terreno lt
union all
select 'Alistamiento','3. Omisiones pendientes por resolver', count (lp.t_id)as cantidad, GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from lc_predio lp
left join lc_terreno lt on lp.lc_terreno =lt.t_id
where lp.omision = 2 
union all
select 'Alistamiento','4. Comisiones por resolver', count (lp.t_id)as cantidad, GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from lc_predio lp
left join lc_terreno lt on lt.t_id =lp.lc_terreno
where lp.comision in  (2) 
union all
select 'Alistamiento','5. PH matrices', count (t_id)as cantidad,GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from lc_terreno lt
where substr (numero_predial,22,1)='9' and substr (numero_predial,23,8)='00000000'
union all
select 'Alistamiento','6. Unidades ph', count (t_id)as cantidad,GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from lc_terreno lt
where substr (numero_predial,22,1)='9' and substr (numero_predial,23,8)<>'00000000'
union all
select 'Alistamiento','7. Condominios matrices ', count (t_id)as cantidad,GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from lc_terreno lt
where substr (numero_predial,22,1)='8' and substr (numero_predial,23,8)='00000000'
union all
select 'Alistamiento','8. Condominios unidades', count (t_id)as cantidad,GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from lc_terreno lt
where substr (numero_predial,22,1)='8' and substr (numero_predial,23,8)<>'00000000'
union all
select 'Alistamiento','9. Mejoras o informales', count (t_id)as cantidad,GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from lc_terreno lt
where substr (numero_predial,22,1)in ('2','5')
union all
select 'Alistamiento','10. NPH, vias y bienes de uso publico', count (t_id)as cantidad,GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from lc_terreno lt
where substr (numero_predial,22,1)in ('0','3','4')
union all
select 'Alistamiento','11. Predios con incorporaciones pendientes', count (lp.t_id)as cantidad, GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from lc_predio lp
left join lc_terreno lt on lt.t_id =lp.lc_terreno
where lp.posible_incorporacion is not null 
union all
select 'Alistamiento','12. Predios con diferencia de area juridica vs area geometrica', count (lp.t_id)as cantidad, GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from lc_predio lp
left join lc_terreno lt on lt.t_id =lp.lc_terreno
where lp.diferencia_area is not null 
union all
select 'Alistamiento','13. Predios con inconsistencia en FMI (duplicado, nulo, etc.)', count (lp.t_id)as cantidad, GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from lc_predio lp
left join lc_terreno lt on lt.t_id =lp.lc_terreno
where lp.verificar_fmi =1 
