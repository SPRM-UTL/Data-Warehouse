import pandas as pd
import numpy as np
from datetime import datetime

datos_historico_raw = {
    'Id': [1, 2, 3, 4, 5],
    'UsuarioId': [101, 102, 101, 103, 102],
    'ArduinoId': [10, 20, 10, 30, 20],
    'AccionConfiguradaId': [501, 502, 501, 503, 502],

    'GestoDetectado': [
        'Mano Abierta ',
        'Puno Cerrado',
        None,
        ' Victoria',
        'Puno Cerrado'
    ],

    'DisparadorDetectado': [
        'Por Pulso',
        'Continuo',
        'Por Pulso',
        'Por Pulso',
        'Continuo'
    ],

    'AccionEjecutada': [
        'encender_foco',
        'apagar_tv',
        'encender_foco',
        'abrir_chapa',
        'apagar_tv'
    ],

    'AparatoAfectado': [
        'Foco Sala',
        'TV Recamara',
        'Foco Sala',
        'Chapa Principal',
        'TV Recamara'
    ],

    'ConfianzaIA': [94.50, 88.20, 45.00, 120.00, 88.20],

    'TiempoRespuestaMS': [120, 340, -50, 210, 340],

    'FechaEjecucion': [
        '2026-05-21 14:22:10',
        '2026-05-21 14:25:15',
        '2026-05-21 14:26:00',
        '2026-05-21 15:01:02',
        '2026-05-21 14:25:15'
    ]
}

df_raw = pd.DataFrame(datos_historico_raw)

print("=== DATOS ORIGINALES TRANSACCIONALES (BRUTOS) ===")
print(df_raw[['Id', 'GestoDetectado', 'ConfianzaIA', 'TiempoRespuestaMS']])

df_clean = df_raw.copy()

df_clean['GestoDetectado'] = (
    df_clean['GestoDetectado']
    .str.strip()
    .str.title()
)

# B. Tratamiento de valores nulos
df_clean['GestoDetectado'] = (
    df_clean['GestoDetectado']
    .fillna('No Identificado')
)

df_clean = df_clean.drop_duplicates(
    subset=['ArduinoId', 'FechaEjecucion'],
    keep='first'
)

df_clean.loc[
    df_clean['ConfianzaIA'] > 100,
    'ConfianzaIA'
] = 100.00

df_clean.loc[
    df_clean['TiempoRespuestaMS'] < 0,
    'TiempoRespuestaMS'
] = 0

df_clean['EjecucionExitosa'] = np.where(
    (df_clean['ConfianzaIA'] >= 70.0) &
    (df_clean['TiempoRespuestaMS'] <= 1000),
    1,
    0
)

df_clean['FechaEjecucion'] = pd.to_datetime(
    df_clean['FechaEjecucion']
)

df_clean['sk_tiempo_id'] = (
    df_clean['FechaEjecucion']
    .dt.strftime('%Y%m%d')
    .astype(int)
)

print("\n=== DATASET PREPROCESADO Y LIMPIO PARA DATA WAREHOUSE ===")
print(
    df_clean[
        [
            'Id',
            'GestoDetectado',
            'ConfianzaIA',
            'TiempoRespuestaMS',
            'EjecucionExitosa',
            'sk_tiempo_id'
        ]
    ]
)

df_clean.to_csv(
    'dataset_manordomo_clean.csv',
    index=False
)

print(
    "\n[INFO] Archivo "
    "'dataset_manordomo_clean.csv' "
    "generado exitosamente para el repositorio."
)
