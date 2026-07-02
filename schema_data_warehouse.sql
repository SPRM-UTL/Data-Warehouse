-- ======================================================================================
-- DATA WAREHOUSE - MANORDOMO (ESQUEMA EN ESTRELLA)
-- ======================================================================================
-- Este script define el modelo dimensional OLAP optimizado para análisis de IA y BI.
-- ======================================================================================

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS fact_historico_actividad;
DROP TABLE IF EXISTS dim_usuarios;
DROP TABLE IF EXISTS dim_gestos;
DROP TABLE IF EXISTS dim_aparatos;
DROP TABLE IF EXISTS dim_tiempo;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================
-- DIMENSIÓN 1: USUARIOS (dim_usuarios)
-- =====================================================
CREATE TABLE dim_usuarios (
    sk_usuario_id INT AUTO_INCREMENT PRIMARY KEY, -- Clave subrogada (Surrogate Key)
    bk_usuario_id INT NOT NULL,                   -- Clave de negocio (Business Key original)
    nombre_usuario VARCHAR(100) NOT NULL,
    email_usuario VARCHAR(150) NOT NULL,
    nombre_arduino VARCHAR(100) NULL,
    mac_address_arduino VARCHAR(17) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- DIMENSIÓN 2: GESTOS (dim_gestos)
-- =====================================================
CREATE TABLE dim_gestos (
    sk_gesto_id INT AUTO_INCREMENT PRIMARY KEY,
    bk_gesto_id INT NOT NULL,
    nombre_gesto VARCHAR(100) NOT NULL,
    identificador_ia INT NOT NULL,
    nivel_confianza_minimo DECIMAL(5,2) DEFAULT 0.70,
    tipo_disparador_nombre VARCHAR(100) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- DIMENSIÓN 3: APARATOS (dim_aparatos)
-- =====================================================
CREATE TABLE dim_aparatos (
    sk_aparato_id INT AUTO_INCREMENT PRIMARY KEY,
    bk_aparato_id INT NOT NULL,
    nombre_aparato VARCHAR(100) NOT NULL,
    tipo_aparato VARCHAR(50) NULL,
    accion_nombre VARCHAR(100) NULL,
    comando_bluetooth VARCHAR(50) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- DIMENSIÓN 4: TIEMPO (dim_tiempo)
-- =====================================================
CREATE TABLE dim_tiempo (
    sk_tiempo_id INT PRIMARY KEY, -- Formato AAAAMMDD (Ej. 20260701)
    fecha_completa DATE NOT NULL,
    anio INT NOT NULL,
    mes_numero INT NOT NULL,
    mes_nombre VARCHAR(15) NOT NULL,
    dia_semana_nombre VARCHAR(15) NOT NULL,
    hora_periodo INT NOT NULL     -- Hora del día (0-23)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- TABLA DE HECHOS: ACTIVIDAD (fact_historico_actividad)
-- =====================================================
CREATE TABLE fact_historico_actividad (
    sk_actividad_id INT AUTO_INCREMENT PRIMARY KEY,
    
    -- Claves foráneas hacia las dimensiones
    sk_usuario_id INT NOT NULL,
    sk_gesto_id INT NOT NULL,
    sk_aparato_id INT NOT NULL,
    sk_tiempo_id INT NOT NULL,
    
    -- Métricas / Hechos (Facts)
    confianza_ia DECIMAL(5,2) NOT NULL,
    tiempo_respuesta_ms INT NOT NULL,
    
    CONSTRAINT FK_Fact_Usuario FOREIGN KEY (sk_usuario_id) REFERENCES dim_usuarios(sk_usuario_id) ON DELETE CASCADE,
    CONSTRAINT FK_Fact_Gesto FOREIGN KEY (sk_gesto_id) REFERENCES dim_gestos(sk_gesto_id) ON DELETE CASCADE,
    CONSTRAINT FK_Fact_Aparato FOREIGN KEY (sk_aparato_id) REFERENCES dim_aparatos(sk_aparato_id) ON DELETE CASCADE,
    CONSTRAINT FK_Fact_Tiempo FOREIGN KEY (sk_tiempo_id) REFERENCES dim_tiempo(sk_tiempo_id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- ÍNDICES PARA RENDIMIENTO ANALÍTICO
-- =====================================================
CREATE INDEX idx_fact_tiempo ON fact_historico_actividad(sk_tiempo_id);
CREATE INDEX idx_fact_usuario ON fact_historico_actividad(sk_usuario_id);
CREATE INDEX idx_fact_gesto ON fact_historico_actividad(sk_gesto_id);
