-- ======================================================================================
-- DATA WAREHOUSE - MANORDOMO (ESQUEMA EN ESTRELLA)
-- ======================================================================================
-- Este script define el modelo dimensional OLAP optimizado para análisis de IA y BI.
-- Actualizado para coincidir con los nuevos modelos del backend (C# Entity Framework).
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
    sk_usuario_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_usuario VARCHAR(100) NULL,
    email_usuario VARCHAR(150) NULL,
    contrasenia VARCHAR(500) NULL,
    nombre_arduino VARCHAR(100) NULL,
    mac_address_usuario VARCHAR(17) NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- DIMENSIÓN 2: GESTOS (dim_gestos)
-- =====================================================
CREATE TABLE dim_gestos (
    sk_gesto_id INT AUTO_INCREMENT PRIMARY KEY,
    bk_gesto_id INT NOT NULL,
    nombre_gesto VARCHAR(100) NULL,
    icono VARCHAR(50) NULL,
    identificador_ia INT NOT NULL,
    nivel_confianza_minimo DECIMAL(5,2) NOT NULL,
    tipo_disparador_nombre VARCHAR(100) NULL,
    
    -- Relaciones adicionales
    sk_aparato_id INT NULL,
    sk_usuario_id INT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- DIMENSIÓN 3: APARATOS (dim_aparatos)
-- =====================================================
CREATE TABLE dim_aparatos (
    sk_aparato_id INT AUTO_INCREMENT PRIMARY KEY,
    nombre_aparato VARCHAR(100) NULL,
    icono VARCHAR(50) NULL,
    fecha_sincronizacion DATETIME NULL,
    
    -- Relaciones adicionales / FKs
    sk_aparato_tipo_id INT NULL,
    sk_aparato_accion_id INT NULL,
    sk_usuario_id INT NULL,
    sk_habitacion_id INT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- DIMENSIÓN 4: TIEMPO (dim_tiempo)
-- =====================================================
CREATE TABLE dim_tiempo (
    sk_tiempo_id INT PRIMARY KEY,
    fecha_completa DATE NOT NULL,
    anio INT NOT NULL,
    mes_numero INT NOT NULL,
    mes_nombre VARCHAR(255) NULL,
    dia_semana_nombre VARCHAR(255) NULL,
    hora_periodo INT NOT NULL
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
    tiempo_respuesta INT NOT NULL,
    ejecucion_exitosa BIT NOT NULL,
    
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
