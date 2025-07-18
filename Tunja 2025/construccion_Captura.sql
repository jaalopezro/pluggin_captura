
----------------------------------------------------------------
----------------------------------------------------------------

delete from tunja_captura.lc_unidadconstruccion; --1
delete from tunja_captura.lc_interesado; --2
delete from tunja_captura.lc_predio;--3
delete from tunja_captura.lc_terreno ;--4




---------ETL para insertar datos relacionados al terreno.-----------------------------------------
--------------------------------------------------------------------------------------------------

insert into tunja_captura.lc_terreno (numero_predial,geometria,area_terreno_geometrica,reconocedor,ui,asignacion)
with
inicial as (
select lp.numero_predial, lt.geometria
, lp.nombre_gpkg,st_area (lt.geometria) area_terreno
from tunja_precampo.lc_predio lp 
left  join (select distinct etiqueta, geometria from tunja_precampo.lc_terreno
			where etiqueta ~ '^[0-9]+$') lt on lt.etiqueta::int=lp.t_id
where
lp.nombre_gpkg is not null
--lp.excepcion is null and lp.unidad_intervencion ='3'
),
--geometria_unidad
geometria_unidad as (
SELECT 
    lu2.etiqueta,
    lu2.numero_predial,
    lu2.geometria
FROM (
    SELECT 
        lu.etiqueta,
        lp.numero_predial,
        lu.geometria,
        ROW_NUMBER() OVER (PARTITION BY lu.etiqueta ORDER BY lu.etiqueta ASC) AS row_num
    FROM tunja_precampo.lc_unidadconstruccion lu
    left  join tunja_precampo.lc_predio lp on lu.etiqueta::bigint=lp.t_id
) lu2
WHERE lu2.row_num = 1 and substring(lu2.numero_predial,22,1)='9'),
--geometria_matriz
geometria_matriz as(
select a.numero_predial, a.geometria
from (select lp.numero_predial, lt.geometria,
	row_number ()over (partition by lp.numero_predial order by lp.numero_predial asc)cat
	from tunja_precampo.lc_predio lp 
	left  join (select distinct etiqueta, geometria from tunja_precampo.lc_terreno where etiqueta ~ '^[0-9]+$') lt on lt.etiqueta::int=lp.t_id
	where SUBSTRING(lp.numero_predial, 22, 9)='900000000' and lt.geometria is not null)a
where a.cat=1
	)
--consulta
select i.numero_predial,
case 
	when i.geometria is not null then i.geometria
	when i.geometria is null and m.geometria is not null then m.geometria
	when i.geometria is null and m.geometria is null  and u.geometria is not null then u.geometria
end geometria,
1 area_terreno,
substr(i.nombre_gpkg,4,2)::int reconocedor,
substr(i.nombre_gpkg,1,2) ui,
i.nombre_gpkg gpkg
from inicial i
left  join geometria_matriz m on substring(m.numero_predial,1,22)= substring(i.numero_predial,1,22)
left  join geometria_unidad u on u.numero_predial=i.numero_predial;


---lc_predio construccion tabla-----------------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------------------------------
alter table tunja_captura.lc_predio add column excepcion boolean

insert into tunja_captura.lc_predio 
(t_id,condicion_predio ,nombre ,
lc_terreno ,
matricula_inmobiliaria ,destino,
omision ,verificar_fmi ,comision ,
tipo_ph ,diferencia_area, 
observacion_reconocedor, observacion_oficina,
posible_incorporacion,area_juridica,area_terreno_catastral)
with insumo_inicial as (
select lt.t_id id_terreno,lp.*,DD.t_id id_destino,dc.t_id id_condicion
from tunja_captura.lc_terreno lt 
left join tunja_precampo.lc_predio lp on lt.numero_predial =lp.numero_predial
left join tunja_precampo.lc_destinacioneconomicatipo ld on ld.t_id =lp.destinacion_economica
left join tunja_precampo.lc_condicionprediotipo gc on gc.t_id=lp.condicion_predio
left join tunja_captura.d_destinacioneconomica dd on dd.itfcode =ld.itfcode
left join tunja_captura.d_condicionpredio dc on dc.itfcode =gc.itfcode
where lt.t_id is not null
),
-----premarcas
premarcas as (
select pp.t_id_predio ,
case 
when  pp.fmi_cerrado_snr =2 or pp.fmi_corto =2 or pp.fmi_dup =2or 
pp.fmi_largo =2 or pp.fmi_null =2 or pp.fmi_solo_catastro =2 then 2
else null 
end verificar_fmi,
CASE 
WHEN pp.obs_posible_incorporacion_catastro IS NULL and
     pp.obs_omision IS NULL and pp.obs_fmi_solo_catastro IS NULL and pp.obs_fmi_null IS NULL and pp.obs_fmi_largo IS NULL and
     pp.obs_fmi_corto IS NULL and pp.obs_fmi_cerrado_snr IS NULL and pp.obs_dos_mas_terrenos IS NULl
THEN NULL
ELSE 
    concat (pp.obs_posible_incorporacion_catastro ,pp.obs_omision ,pp.obs_fmi_solo_catastro ,pp.obs_fmi_null ,pp.obs_fmi_largo ,
    pp.obs_fmi_corto ,pp.obs_fmi_cerrado_snr ,pp.obs_dos_mas_terrenos)
    END AS concatenado
from gestionpredial_preoperativa.premarcas_preoperativa pp 
where omision=2 
),
incorporaciones as (
select *
from gestionpredial_preoperativa.incorporar_fmi_apartir_padre_catastro ifapc ),
areas as (
select * from espacial_preoperativa.v_marca_terreno_difareas_b1
)
/*,
-----juridica
juridica as (
select lt.numero_predial , lt.area_juridica::float, 
case 
	when lt.prioridad in ('AGOTO AREA') then '2'::int
	when lt.prioridad in ('SIN AREA EN VUR') then '3'::int
	when lt.prioridad in ('FMI CERRADO') then '4'::int 
end variacion
			from tunja_precampo.areas_juridicas_temporales lt
where lt.prioridad not in ('SIN AREA EN VUR')
)*/
----consulta general
select 
	i.t_id,
	i.id_condicion , 
	i.nombre , 
	i.id_terreno lc_terreno,
	i.matricula_inmobiliaria, 
	i.id_destino ,
	lp.omision , 
	lp.verificar_fmi ,
	lp.comision::int ,
	i.tipo_ph, null dif_area, null observacion,
	lp.concatenado, 
	null posible_incorporacion,
	null area_juridica,
	null area_catastral
from insumo_inicial i
left  join premarcas lp on lp.t_id_predio= i.t_id
--left  join juridica aj on aj.numero_predial =i.numero_predial
;


---delete from tunja_captura.lc_predio;
delete from tunja_captura.lc_terreno; 
delete from tunja_captura.lc_interesado 
-------lc_interesado construccion tabla-----------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------
insert into tunja_captura.lc_interesado (
t_id,
tipo,tipo_documento,
primer_nombre,
segundo_nombre,primer_apellido
,razon_social,sexo,lc_predio,documento_identidad,segundo_apellido)
SELECT DISTINCT
	10000+ROW_NUMBER() OVER ()AS consecutivo,
    di.t_id tipo_interesado,
    dd.t_id tipo_documento,
    li.primer_nombre,
    li.segundo_nombre,
    li.primer_apellido,
    li.razon_social,
    ds.t_id  sexo,
    lp.t_id AS predio_t_id,
    li.documento_identidad,
    li.segundo_apellido
FROM tunja_captura.lc_terreno lp2
left join tunja_captura.lc_predio lp on lp.lc_terreno =lp2.t_id 
LEFT JOIN tunja_precampo.lc_interesado li ON li.local_id::int = lp.t_id
LEFT JOIN tunja_captura.lc_interesado li2 ON li2.lc_predio = lp.t_id
left join tunja_precampo.lc_interesadotipo li3  on li3.t_id =li.tipo
left join tunja_captura.d_interesadotipo di on di.itfcode =li3.itfcode
left join tunja_precampo.lc_interesadodocumentotipo li4 on li4.t_id=li.tipo_documento
left join tunja_captura.d_documentotipo dd on dd.itfcode =li4.itfcode
left join tunja_precampo.lc_sexotipo ls on ls.t_id=li.sexo
left join tunja_captura.d_sexotipo ds on ds.itfcode =ls.itfcode
where li.t_id is not null ;



-------lc_direccion construccion tabla-----------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------------------
/*
insert into tunja_captura.lc_unidadconstruccion  (cancelar_unidad,identificador,planta_ubicacion,tipo_construccion,tipo_unidadconstruccion,tipo_planta,uso,tipificacion,sistema_constructivo,
estructura,cubierta,cerchas,acabados,estado,altura,tipologia,anio_construccion,lc_terreno,geometria)
select null, null, lud.planta_ubicacion ,
case
	when du.dispname like 'AN%' then '793'::int
	else '792'::int
end tipo_construccion,
case
	when du.dispname like 'AN%' then '62'::int
	when du.dispname like 'INST%' then '61'::int
	when du.dispname like 'R%' then '58'::int
	when du.dispname like 'CO%' then '59'::int
	when du.dispname like 'IND%' then '60'::int
end tipo_uconstruccion, lud.tipo_planta ,lud.uso , ltd.diseno_original , 
ltd.sistema_constructivo ,ltd.estructura ,ltd.cubiertas ,
ltd.cerchas::int cerchas ,ltd.acabados  ,ltd.estado_conservacion ,null, ltd.tipo_segun_diseno ,null,lt.t_id,
lud.geometria 
from tunja_captura.lc_terreno lt 
left  join tunja_precampo.lc_predio lp on lt.numero_predial =lp.numero_predial 
left join tunja_precampo.lc_unidadconstruccion_dig lud  on lud.etiqueta =lp.t_id 
left  join tunja_precampo.lc_tipologia_dig ltd on lud.tipologia =ltd.t_id 
left  join tunja_captura.d_usos du on du.t_id =lud.uso
where lud.geometria is not null and lt.nombre_gpkg in ();*/



--------------------------------------------------------------------------------------
---------------------------actualizar geometria nulas---------------------------------------
				

do $$
declare
    v_count integer;
begin

    update tunja_captura.lc_terreno lt
    set geometria = sub.geometria
    from (
        select lt.t_id, gc.geometria
        from tunja_captura.lc_terreno lt
        left join tunja_captura.lc_predio lp on lp.lc_terreno = lt.t_id
        left join tunja_precampo.lc_predio lp2 on lp2.t_id = lp.t_id 
        left join tunja_b0.lc_predio lp3 on lp3.t_id = lp2.t_id_b0 
        left join (
            select gc.etiqueta, gc.geometria, row_number() over (partition by etiqueta order by t_id) orden
            from tunja_b0.lc_construccion gc
        ) gc on gc.etiqueta::bigint = lp3.t_id
        where lt.geometria is null and gc.orden = 1
    ) sub 
    where sub.t_id = lt.t_id;

    select count(*) into v_count
    from tunja_captura.lc_terreno
    where geometria is null;
    if v_count > 0 then
        raise notice 'aún quedan % terrenos sin geometría, ejecutando acción adicional', v_count;

        update tunja_captura.lc_terreno lt
        set geometria =sub.geometria
		from (
		with centros_base as (
		    select lt.t_id,substring(lt1.numero_predial,1,17) as numero_predial,lt1.geom,st_centroid(lt1.geom) as centroide
		    from (
		        select * 
		        from tunja_captura.lc_terreno lt
		        where lt.geometria is null
		    ) lt
		    left join (
		        select st_union(lt.geometria) as geom,substring(lt.numero_predial,1,17) as numero_predial
		        from tunja_captura.lc_terreno lt
		        where lt.geometria is not null
		        group by substring(lt.numero_predial,1,17)
		    ) lt1
		    on substring(lt1.numero_predial,1,17) = substring(lt.numero_predial,1,17)
		),
		numerados as (
		    select *,row_number() over (partition by centroide order by t_id) as n,count(*) over (partition by centroide) as total_repetidos
		    from centros_base
		)
		select t_id,numero_predial,geom,st_multi( st_force3d( st_buffer(
        case 
            when total_repetidos = 1 then centroide
            else
                st_translate(
                    centroide,
                    5 * cos((n - 1) * 2 * pi() / total_repetidos),
                    5 * sin((n - 1) * 2 * pi() / total_repetidos)
                )
        end,4  ),0)) as geometria
		from numerados)sub
		where sub.t_id=lt.t_id
        ;
    else
        raise notice 'no quedan terrenos sin geometría';
    end if;
end $$;



/////////////////////////////////////////////////
/////////////////////////////////////////////////



select lt.numero_predial,lp.matricula_inmobiliaria fmi , di.dispname tipo_persona, dd.dispname tipo_documento,
concat_ws(' ',li.primer_nombre, li.segundo_nombre, li.primer_apellido, li.segundo_apellido, li.razon_social) nombre,
case when lp.omision is not null then 'omision' end omision ,
case when lp.comision is not null then 'comision' end comision ,
case when lp.verificar_fmi  is not null then 'verificar FMI' end inconsistencia_fmi ,
lp.posible_incorporacion incorporaciones ,
case when lp.diferencia_area is not null then 'verificacion de linderos' end marca_area 
from tunja_captura.lc_predio lp 
left join tunja_captura.lc_terreno lt on lt.t_id =lp.lc_terreno
left join tunja_captura.lc_interesado li on li.lc_predio =lp.t_id
left join tunja_captura.d_interesadotipo di on di.t_id =li.tipo  
left join tunja_captura.d_documentotipo dd  on dd.t_id =li.tipo_documento
where lt.asignacion in ()
order by  lt.numero_predial, lp.matricula_inmobiliaria







