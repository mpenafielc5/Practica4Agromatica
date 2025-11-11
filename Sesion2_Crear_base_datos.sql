CREATE TABLE especie (
  id_especie SERIAL PRIMARY KEY,
  nombre_cientifico VARCHAR(200) NOT NULL,
  nombre_comun VARCHAR(200),
  id_taxonomico INTEGER,
  reino VARCHAR(50),
  familia VARCHAR(100),
  observaciones TEXT
);

CREATE TABLE secuencia (
  id_secuencia SERIAL PRIMARY KEY,
  id_especie INTEGER NOT NULL REFERENCES especie(id_especie),
  acceso VARCHAR(100) UNIQUE NOT NULL,
  titulo TEXT,
  tipo_molecula VARCHAR(50),
  topologia VARCHAR(20),
  longitud_bp INTEGER,
  cadena TEXT,
  formato VARCHAR(20),
  fuente VARCHAR(50),
  fecha_descarga DATE
);

CREATE INDEX IF NOT EXISTS idx_secuencia_especie ON secuencia(id_especie);
CREATE INDEX IF NOT EXISTS idx_secuencia_acceso ON secuencia(acceso);