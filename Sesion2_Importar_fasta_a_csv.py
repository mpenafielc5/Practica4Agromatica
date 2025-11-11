import os
from Bio import SeqIO
import csv
from datetime import date

fasta_files = {
    "especie1.fasta": "Zea mays",
    "especie2.fasta": "Bos taurus"
}

species_to_id = {
    "Zea mays": 1,
    "Bos taurus": 2
}

OUT_SUFFIX = "_pg.csv"

DEFAULT_TIPO_MOLECULA = "DNA"
DEFAULT_TOPOLOGIA = ""
DEFAULT_FORMATO = "fasta"
DEFAULT_FUENTE = "NCBI"

def clean_sequence(seq_str: str) -> str:
    """Quita saltos de línea y retornos de carro; devuelve cadena limpia."""
    return seq_str.replace("\n", "").replace("\r", "")

def fasta_to_csv_for_pg(fasta_path: str, nombre_cientifico: str, start_id: int = 1):
    """
    Convierte un FASTA a CSV con columnas en el orden exacto para la tabla secuencia.
    start_id: id_secuencia inicial para este archivo; devuelve el último id usado + 1
    """
    csv_path = os.path.splitext(fasta_path)[0] + OUT_SUFFIX
    seq_counter = start_id

    if nombre_cientifico not in species_to_id:
        raise ValueError(f"No hay id_especie configurado para '{nombre_cientifico}'. Añádelo en species_to_id.")

    id_especie = species_to_id[nombre_cientifico]
    fecha_descarga = date.today().isoformat()

    records = list(SeqIO.parse(fasta_path, "fasta"))
    if not records:
        print(f"[WARN] No se encontraron registros en {fasta_path}. No se generará CSV.")
        return seq_counter

    with open(csv_path, "w", newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile, quotechar='"', quoting=csv.QUOTE_ALL, escapechar='\\')
        writer.writerow([
            "id_secuencia","id_especie","acceso","titulo","tipo_molecula","topologia",
            "longitud_bp","cadena","formato","fuente","fecha_descarga"
        ])

        for rec in records:
            acceso = rec.id
            titulo = rec.description if rec.description else rec.id
            cadena = clean_sequence(str(rec.seq))
            longitud_bp = len(cadena)

            row = [
                seq_counter,
                id_especie,
                acceso,
                titulo,
                DEFAULT_TIPO_MOLECULA,
                DEFAULT_TOPOLOGIA,
                longitud_bp,
                cadena,
                DEFAULT_FORMATO,
                DEFAULT_FUENTE,
                fecha_descarga
            ]
            writer.writerow(row)
            seq_counter += 1

    print(f"Escritas {len(records)} filas a {csv_path} (id_secuencia desde {start_id} hasta {seq_counter-1})")
    return seq_counter

def main():
    missing = [f for f in fasta_files.keys() if not os.path.exists(f)]
    if missing:
        print("[ERROR] No se encontraron los siguientes archivos FASTA:")
        for m in missing:
            print("  -", m)
        return

    next_id = 1
    for fasta, especie in fasta_files.items():
        try:
            next_id = fasta_to_csv_for_pg(fasta, especie, start_id=next_id)
        except Exception as e:
            print(f"[ERROR] Al procesar {fasta}: {e}")
            return

    print("Todos los CSV generados. Puedes importarlos en pgAdmin (Import/Export) seleccionando 'CSV' y marcando 'Header'.")

if __name__ == "__main__":
    main()
