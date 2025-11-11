import sys
import psycopg2
import pandas as pd
import matplotlib.pyplot as plt

DB_PARAMS = {
    "dbname": "genetica_comparada",
    "user": "postgres",
    "password": 1234 ,
    "host": "localhost",
    "port": 5432
}

OUT_CSV = "comparacion_gc_export.csv"
OUT_PNG = "comparacion_gc_barras.png"

def fetch_gc_view(db_params):
    q = """
    SELECT especie, id_secuencia, acceso, longitud_bp, gc_percent
    FROM public.comparacion_gc
    ORDER BY especie, id_secuencia;
    """
    conn = psycopg2.connect(**db_params)
    df = pd.read_sql(q, conn)
    conn.close()
    return df

def save_csv(df, path):
    df.to_csv(path, index=False, encoding='utf-8')
    print(f"CSV guardado en: {path} ({len(df)} filas)")

def plot_bar_gc(df, path):
    agg = df.groupby('especie', as_index=False).agg(
        avg_gc=('gc_percent', 'mean'),
        n=('gc_percent', 'count')
    ).sort_values('avg_gc', ascending=False)

    fig, ax = plt.subplots(figsize=(8, 5))
    ax.bar(agg['especie'], agg['avg_gc'])
    ax.set_xlabel('Especie')
    ax.set_ylabel('GC% promedio')
    ax.set_title('Comparación de GC% promedio por especie')
    ax.set_ylim(0, 100)
    for i, row in agg.reset_index().iterrows():
        ax.text(i, row['avg_gc'] + 0.5, f"{row['avg_gc']:.3f}\n(n={int(row['n'])})", ha='center', va='bottom', fontsize=9)
    plt.tight_layout()
    plt.savefig(path, dpi=300)
    plt.close()
    print(f"Gráfico guardado en: {path}")

def main():
    print("Consultando la vista comparacion_gc...")
    df = fetch_gc_view(DB_PARAMS)
    if df.empty:
        print("La vista comparacion_gc no contiene datos.")
        sys.exit(1)
    save_csv(df, OUT_CSV)
    plot_bar_gc(df, OUT_PNG)
    print("Hecho.")

if __name__ == "__main__":
    main()
