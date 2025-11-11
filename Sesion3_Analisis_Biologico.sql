-- SESIÓN 3 – Tema 3: Aplicación de SQL en el análisis biológico
-- Script: consultas, función GC% y vista comparacion_gc
-- Ajusta nombres de esquemas/tabla si fuera necesario (aquí usamos public.secuencia y public.especie)

-- 0) Limpia versiones previas (opcional)
DROP VIEW IF EXISTS public.comparacion_gc;
DROP FUNCTION IF EXISTS public.gc_percent(text);

-- ============================
-- Actividad 1: Consultas de longitud por secuencia y resumen por especie
-- ============================

-- 1.a) Longitud de cada secuencia (lista)
-- Muestra id, acceso, especie y longitud
SELECT s.id_secuencia,
       s.acceso,
       s.id_especie,
       e.nombre_cientifico AS especie,
       s.longitud_bp
FROM public.secuencia s
LEFT JOIN public.especie e USING (id_especie)
ORDER BY e.nombre_cientifico, s.id_secuencia;

-- 1.b) Estadísticos por especie: cuenta, promedio, min y max
SELECT e.nombre_cientifico AS especie,
       COUNT(*) AS n_secuencias,
       ROUND(AVG(s.longitud_bp)::numeric, 2) AS promedio_long_bp,
       MIN(s.longitud_bp) AS min_long_bp,
       MAX(s.longitud_bp) AS max_long_bp
FROM public.secuencia s
JOIN public.especie e USING (id_especie)
GROUP BY e.nombre_cientifico
ORDER BY promedio_long_bp DESC;


-- ============================
-- Actividad 2: Crear función SQL para calcular porcentaje de bases GC
-- ============================

/*
Función: gc_percent(seq_text)
- Elimina caracteres que no sean A,C,G,T (mayúsculas/minúsculas).
- Calcula porcentaje: 100 * (#G + #C) / longitud_útil
- Devuelve NUMERIC con 4 decimales (ajustable).
*/
CREATE OR REPLACE FUNCTION public.gc_percent(seq_text TEXT)
RETURNS NUMERIC AS
$$
DECLARE
    s_clean TEXT;
    len_seq INT;
    count_gc INT;
    pct NUMERIC;
BEGIN
    IF seq_text IS NULL THEN
        RETURN NULL;
    END IF;

    -- Normalizar y quitar cualquier carácter que no sea A, C, G o T
    s_clean := regexp_replace(upper(seq_text), '[^ACGT]', '', 'g');
    len_seq := length(s_clean);

    IF len_seq = 0 THEN
        RETURN NULL;  -- no hay bases válidas para calcular
    END IF;

    -- contar G y C
    count_gc := regexp_count(s_clean, '[GC]');

    pct := round( (count_gc::numeric / len_seq::numeric) * 100.0, 4 );

    RETURN pct;
END;
$$ LANGUAGE plpgsql IMMUTABLE;


-- Prueba rápida (opcional): calcula GC% en una secuencia de ejemplo
-- SELECT public.gc_percent('ATGCGCatnnn--GCGT') AS ejemplo_gc;


-- ============================
-- Actividad 3: Crear vista comparacion_gc que muestre especie, ID y GC%
-- ============================

CREATE OR REPLACE VIEW public.comparacion_gc AS
SELECT
    e.id_especie,
    e.nombre_cientifico AS especie,
    s.id_secuencia,
    s.acceso,
    s.longitud_bp,
    public.gc_percent(s.cadena) AS gc_percent
FROM public.secuencia s
JOIN public.especie e USING (id_especie)
ORDER BY e.nombre_cientifico, s.id_secuencia;

-- Consulta para ver la vista
-- SELECT * FROM public.comparacion_gc LIMIT 100;


-- Consulta adicional: promedio de GC% por especie y ordenado
SELECT
    especie,
    COUNT(*) AS n_secuencias,
    ROUND(AVG(gc_percent)::numeric, 4) AS avg_gc_percent,
    MIN(gc_percent) AS min_gc,
    MAX(gc_percent) AS max_gc
FROM public.comparacion_gc
GROUP BY especie
ORDER BY avg_gc_percent DESC;
