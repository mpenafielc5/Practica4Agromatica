DROP TRIGGER IF EXISTS trg_check_min_length ON public.secuencia;
DROP FUNCTION IF EXISTS public.fn_check_min_length();

CREATE OR REPLACE FUNCTION public.fn_check_min_length()
RETURNS trigger AS
$$
DECLARE
    effective_len INT;
BEGIN
    -- Si longitud_bp es NULL o no coincide con la longitud real, calculamos desde cadena
    IF NEW.longitud_bp IS NULL OR NEW.longitud_bp = 0 THEN
        effective_len := COALESCE(length(NEW.cadena), 0);
    ELSE
        -- Preferimos la longitud reportada, pero verificamos consistencia con cadena
        effective_len := NEW.longitud_bp;
        IF NEW.cadena IS NOT NULL AND length(trim(both from NEW.cadena)) <> NEW.longitud_bp THEN
            -- Si no coinciden, recalculamos desde cadena para prevenir inserciones inválidas
            effective_len := length(NEW.cadena);
        END IF;
    END IF;

    IF effective_len < 100 THEN
        RAISE EXCEPTION 'Inserción/actualización cancelada: longitud de secuencia = % < 100 pb', effective_len;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql VOLATILE;

CREATE TRIGGER trg_check_min_length
BEFORE INSERT OR UPDATE ON public.secuencia
FOR EACH ROW
EXECUTE FUNCTION public.fn_check_min_length();
