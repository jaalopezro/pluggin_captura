SELECT 'Resumen Captura','1. Predios cancelados', count (lp.t_id)as cantidad, GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
FROM lc_predio lp
LEFT join lc_terreno lt on lt.t_id=lp.lc_terreno
WHERE lp.cancelar_predio is true
union all
SELECT 'Resumen Captura','2. Predios con excepcion a la regla', count (lp.t_id)as cantidad, GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
FROM lc_predio lp
LEFT join lc_terreno lt on lt.t_id=lp.lc_terreno
WHERE lp.excepcion is true
union all
select 'Resumen Captura','3. Unidades constructivas levantadas', count (lu.t_id)as cantidad, 'No aplica' AS Npn_concatenados
from lc_unidadconstruccion lu 
union all 
select 'Resumen Captura','4. Ruinas levantadas', count (lu.t_id)as cantidad, 'No aplica' AS Npn_concatenados
from lc_unidadconstruccion lu 
where tipo_construccion =691
union all 
select 'Resumen Captura','5. Predios nuevos creados', count (lT.t_id)as cantidad, GROUP_CONCAT(lt.numero_predial, ', ') AS Npn_concatenados
from lc_terreno lt 
where lt.numero_predial like '%NUEVO%' 
union all 
select 'Resumen Captura','6. Archivos capturados', count (a.t_id)as cantidad, 'No aplica' AS Npn_concatenados
from archivo a
union all 
select 'Resumen Captura','7. Terreno con plano general de asignacion', count (s.numero_predial)cantidad  , GROUP_CONCAT(s.numero_predial, ', ') AS Npn_concatenados
from 
(select lt.numero_predial,tipo_archivo 
from archivo a
left join lc_terreno lt on lt.t_id = a.lc_terreno 
where tipo_archivo = 17)s