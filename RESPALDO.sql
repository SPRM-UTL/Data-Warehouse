/*
=========================================================
MANORDOMO - MODELO RELACIONAL MEJORADO
=========================================================
Mejoras aplicadas:
✔ Separación correcta entre:
   - Gestos IA
   - Eventos/Disparadores
   - Acciones ejecutables
✔ Soporte real para:
   - ON_PRESS
   - ON_RELEASE
   - HOLD
   - LOOP
   - DOUBLE_GESTURE
✔ Evita duplicidad de comandos.
✔ Permite múltiples acciones por gesto.
✔ Historial más consistente.
✔ Preparado para IA en tiempo real.
✔ Mejor normalización.
=========================================================
*/

SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS historicoactividad;
DROP TABLE IF EXISTS accionesconfiguradas;
DROP TABLE IF EXISTS tiposdisparadores;
DROP TABLE IF EXISTS acciones;
DROP TABLE IF EXISTS gestoscatalogo;
DROP TABLE IF EXISTS aparatosvinculados;
DROP TABLE IF EXISTS dispositivosarduino;
DROP TABLE IF EXISTS token;
DROP TABLE IF EXISTS usuarios;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================
-- USUARIOS
-- =====================================================

CREATE TABLE usuarios (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    Nombre VARCHAR(100) NOT NULL,
    Email VARCHAR(150) NOT NULL UNIQUE,
    PasswordHash LONGTEXT NOT NULL,
    CreadoEn DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- TOKENS
-- =====================================================

CREATE TABLE token (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    Cadena LONGTEXT NOT NULL,
    FechaExpiracion DATETIME(6) NOT NULL,

    UsuarioId INT NOT NULL,

    CONSTRAINT FK_Token_Usuarios
        FOREIGN KEY (UsuarioId)
        REFERENCES usuarios(Id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- DISPOSITIVOS ARDUINO
-- =====================================================

CREATE TABLE dispositivosarduino (
    Id INT AUTO_INCREMENT PRIMARY KEY,

    UsuarioId INT NOT NULL,

    Nombre VARCHAR(100) NOT NULL,
    MacAddress VARCHAR(17) NOT NULL UNIQUE,

    EstadoConexion BIT(1) DEFAULT b'0',

    UltimaConexion DATETIME NULL,
    VinculadoEn DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT FK_DispositivosArduino_Usuarios
        FOREIGN KEY (UsuarioId)
        REFERENCES usuarios(Id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- APARATOS VINCULADOS
-- =====================================================

CREATE TABLE aparatosvinculados (
    Id INT AUTO_INCREMENT PRIMARY KEY,

    ArduinoId INT NOT NULL,

    Nombre VARCHAR(100) NOT NULL,

    TipoAparato VARCHAR(50) NULL,
    PinArduino INT NOT NULL,

    EstaActivo BIT(1) DEFAULT b'1',

    CreadoEn DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT FK_Aparatos_Dispositivo
        FOREIGN KEY (ArduinoId)
        REFERENCES dispositivosarduino(Id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- GESTOS IA (CATALOGO GLOBAL)
-- =====================================================

CREATE TABLE gestoscatalogo (
    Id INT AUTO_INCREMENT PRIMARY KEY,

    NombreGesto VARCHAR(100) NOT NULL,

    /*
      ID entregado por el modelo IA.
      Ej:
      0 = OPEN_HAND
      1 = FIST
      2 = THUMBS_UP
    */
    IdentificadorIA INT NOT NULL UNIQUE,

    Descripcion TEXT NULL,

    NivelConfianzaMinimo DECIMAL(5,2) DEFAULT 0.70,

    CreadoEn DATETIME DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- TIPOS DE DISPARADORES
-- =====================================================

CREATE TABLE tiposdisparadores (
    Id INT AUTO_INCREMENT PRIMARY KEY,

    Codigo VARCHAR(50) NOT NULL UNIQUE,

    Nombre VARCHAR(100) NOT NULL,

    Descripcion VARCHAR(255)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- ACCIONES REALES DEL SISTEMA
-- =====================================================

CREATE TABLE acciones (
    Id INT AUTO_INCREMENT PRIMARY KEY,

    Codigo VARCHAR(50) NOT NULL UNIQUE,

    Nombre VARCHAR(100) NOT NULL,

    Descripcion VARCHAR(255),

    /*
      Comando que Arduino entiende.
    */
    ComandoBluetooth VARCHAR(50) NOT NULL,

    /*
      Ej:
      TOGGLE
      DIGITAL_WRITE
      PWM
      MEDIA
    */
    TipoAccion VARCHAR(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- CONFIGURACION PRINCIPAL
-- =====================================================

CREATE TABLE accionesconfiguradas (
    Id INT AUTO_INCREMENT PRIMARY KEY,

    UsuarioId INT NOT NULL,

    GestoId INT NOT NULL,

    TipoDisparadorId INT NOT NULL,

    AparatoId INT NOT NULL,

    AccionId INT NOT NULL,

    /*
      Tiempo mínimo que debe mantenerse
      el gesto antes de ejecutar.
    */
    TiempoMinimoMs INT DEFAULT 0,

    /*
      Cooldown para evitar spam.
    */
    CooldownMs INT DEFAULT 1000,

    /*
      SOLO PARA LOOP.
    */
    IntervaloLoopMs INT DEFAULT NULL,

    /*
      Prioridad de ejecución.
    */
    Prioridad INT DEFAULT 1,

    EstaActivado BIT(1) DEFAULT b'1',

    ActualizadoEn DATETIME
        DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT FK_Config_Usuario
        FOREIGN KEY (UsuarioId)
        REFERENCES usuarios(Id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT FK_Config_Gesto
        FOREIGN KEY (GestoId)
        REFERENCES gestoscatalogo(Id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT FK_Config_Disparador
        FOREIGN KEY (TipoDisparadorId)
        REFERENCES tiposdisparadores(Id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT FK_Config_Aparato
        FOREIGN KEY (AparatoId)
        REFERENCES aparatosvinculados(Id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT FK_Config_Accion
        FOREIGN KEY (AccionId)
        REFERENCES acciones(Id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- HISTORICO
-- =====================================================

CREATE TABLE historicoactividad (
    Id INT AUTO_INCREMENT PRIMARY KEY,

    UsuarioId INT NOT NULL,

    ArduinoId INT NULL,

    AccionConfiguradaId INT NULL,

    GestoDetectado VARCHAR(100) NOT NULL,

    DisparadorDetectado VARCHAR(100) NOT NULL,

    AccionEjecutada VARCHAR(100) NOT NULL,

    AparatoAfectado VARCHAR(100) NOT NULL,

    ConfianzaIA DECIMAL(5,2) NULL,

    TiempoRespuestaMs INT NULL,

    FechaEjecucion DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT FK_Historico_Usuario
        FOREIGN KEY (UsuarioId)
        REFERENCES usuarios(Id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT FK_Historico_Arduino
        FOREIGN KEY (ArduinoId)
        REFERENCES dispositivosarduino(Id)
        ON DELETE SET NULL
        ON UPDATE CASCADE,

    CONSTRAINT FK_Historico_Config
        FOREIGN KEY (AccionConfiguradaId)
        REFERENCES accionesconfiguradas(Id)
        ON DELETE SET NULL
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- DATOS BASE
-- =====================================================

INSERT INTO tiposdisparadores
(Codigo, Nombre, Descripcion)
VALUES
(
    'ON_PRESS',
    'Pulso',
    'Se ejecuta una sola vez al detectar el gesto.'
),
(
    'HOLD',
    'Sostenido',
    'La accion permanece activa mientras exista el gesto.'
),
(
    'LOOP',
    'Continuo',
    'Ejecuta repetidamente cada cierto intervalo.'
),
(
    'ON_RELEASE',
    'Al Soltar',
    'Se ejecuta cuando el gesto desaparece.'
),
(
    'DOUBLE_GESTURE',
    'Doble Gesto',
    'Requiere detectar el gesto dos veces.'
);

-- =====================================================
-- GESTOS IA
-- =====================================================

INSERT INTO gestoscatalogo
(NombreGesto, IdentificadorIA, Descripcion)
VALUES
(
    'Mano Abierta',
    0,
    'Cinco dedos extendidos.'
),
(
    'Puño Cerrado',
    1,
    'Todos los dedos cerrados.'
),
(
    'Pulgar Arriba',
    2,
    'Pulgar levantado.'
),
(
    'Señalar Izquierda',
    3,
    'Indice apuntando a la izquierda.'
),
(
    'Señalar Derecha',
    4,
    'Indice apuntando a la derecha.'
);

-- =====================================================
-- ACCIONES DEL SISTEMA
-- =====================================================

INSERT INTO acciones
(Codigo, Nombre, Descripcion, ComandoBluetooth, TipoAccion)
VALUES
(
    'LIGHT_TOGGLE',
    'Alternar Luz',
    'Enciende o apaga un foco.',
    'TOGGLE_LIGHT',
    'DIGITAL_WRITE'
),
(
    'LIGHT_ON',
    'Encender Luz',
    'Enciende el foco.',
    'LIGHT_ON',
    'DIGITAL_WRITE'
),
(
    'LIGHT_OFF',
    'Apagar Luz',
    'Apaga el foco.',
    'LIGHT_OFF',
    'DIGITAL_WRITE'
),
(
    'VOLUME_UP',
    'Subir Volumen',
    'Incrementa volumen continuamente.',
    'VOL_UP',
    'MEDIA'
),
(
    'VOLUME_DOWN',
    'Bajar Volumen',
    'Reduce volumen continuamente.',
    'VOL_DOWN',
    'MEDIA'
);

-- =====================================================
-- USUARIO DEMO
-- =====================================================

INSERT INTO usuarios
(Nombre, Email, PasswordHash)
VALUES
(
    'Jose Angel',
    'jose@manordomo.com',
    'HASH_AQUI'
);

-- =====================================================
-- DISPOSITIVO DEMO
-- =====================================================

INSERT INTO dispositivosarduino
(
    UsuarioId,
    Nombre,
    MacAddress,
    EstadoConexion
)
VALUES
(
    1,
    'Arduino Sala',
    '00:1A:7D:DA:71:11',
    b'1'
);

-- =====================================================
-- APARATOS DEMO
-- =====================================================

INSERT INTO aparatosvinculados
(
    ArduinoId,
    Nombre,
    TipoAparato,
    PinArduino
)
VALUES
(
    1,
    'Foco Sala',
    'LUZ',
    13
),
(
    1,
    'Bocina',
    'AUDIO',
    11
);

-- =====================================================
-- CONFIGURACIONES DEL USUARIO
-- =====================================================

/*
MANO ABIERTA
→ Toggle foco
→ Pulso único
*/

INSERT INTO accionesconfiguradas
(
    UsuarioId,
    GestoId,
    TipoDisparadorId,
    AparatoId,
    AccionId,
    CooldownMs
)
VALUES
(
    1,
    1,
    1,
    1,
    1,
    1500
);

/*
PULGAR ARRIBA
→ Subir volumen
→ LOOP
*/

INSERT INTO accionesconfiguradas
(
    UsuarioId,
    GestoId,
    TipoDisparadorId,
    AparatoId,
    AccionId,
    IntervaloLoopMs,
    TiempoMinimoMs
)
VALUES
(
    1,
    3,
    3,
    2,
    4,
    250,
    500
);


/*
=========================================================
MEJORA RELACIONAL:
EL TIPO DE DISPARADOR AHORA DEPENDE DEL GESTO
=========================================================

ANTES:
AccionConfigurada
→ GestoId
→ TipoDisparadorId

PROBLEMA:
Un gesto podía usar cualquier disparador aunque
no tuviera sentido.

Ej:
"Pulgar Arriba" + ON_RELEASE
aunque el modelo IA no soporte ese comportamiento.

=========================================================
SOLUCION:
Crear una tabla intermedia:

gestosdisparadores

Esto define QUÉ disparadores soporta cada gesto.
=========================================================
*/

-- =====================================================
-- TABLA:
-- RELACION GESTO ↔ TIPO DISPARADOR
-- =====================================================

CREATE TABLE gestosdisparadores (
    Id INT AUTO_INCREMENT PRIMARY KEY,

    GestoId INT NOT NULL,

    TipoDisparadorId INT NOT NULL,

    /*
      Configuración IA:
      tiempo mínimo requerido
      para validar el gesto.
    */
    TiempoMinimoDeteccionMs INT DEFAULT 0,

    /*
      Si el gesto permite
      ejecución continua.
    */
    PermiteLoop BIT(1) DEFAULT b'0',

    /*
      Si requiere desaparición
      del gesto para ejecutar.
    */
    RequiereLiberacion BIT(1) DEFAULT b'0',

    CreadoEn DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT UK_Gesto_Disparador
        UNIQUE (GestoId, TipoDisparadorId),

    CONSTRAINT FK_GestoDisparador_Gesto
        FOREIGN KEY (GestoId)
        REFERENCES gestoscatalogo(Id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT FK_GestoDisparador_Disparador
        FOREIGN KEY (TipoDisparadorId)
        REFERENCES tiposdisparadores(Id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- AHORA:
-- accionesconfiguradas
-- YA NO USA:
-- GestoId + TipoDisparadorId separados
--
-- USA:
-- GestoDisparadorId
-- =====================================================

DROP TABLE IF EXISTS accionesconfiguradas;

CREATE TABLE accionesconfiguradas (
    Id INT AUTO_INCREMENT PRIMARY KEY,

    UsuarioId INT NOT NULL,

    /*
      RELACION YA VALIDADA:
      Gesto + TipoDisparador
    */
    GestoDisparadorId INT NOT NULL,

    AparatoId INT NOT NULL,

    AccionId INT NOT NULL,

    /*
      Tiempo mínimo requerido
      antes de ejecutar.
    */
    TiempoMinimoMs INT DEFAULT 0,

    /*
      Anti spam.
    */
    CooldownMs INT DEFAULT 1000,

    /*
      SOLO LOOP.
    */
    IntervaloLoopMs INT DEFAULT NULL,

    Prioridad INT DEFAULT 1,

    EstaActivado BIT(1) DEFAULT b'1',

    ActualizadoEn DATETIME
        DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT FK_Config_Usuario
        FOREIGN KEY (UsuarioId)
        REFERENCES usuarios(Id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT FK_Config_GestoDisparador
        FOREIGN KEY (GestoDisparadorId)
        REFERENCES gestosdisparadores(Id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT FK_Config_Aparato
        FOREIGN KEY (AparatoId)
        REFERENCES aparatosvinculados(Id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT FK_Config_Accion
        FOREIGN KEY (AccionId)
        REFERENCES acciones(Id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- =====================================================
-- EJEMPLOS REALES
-- =====================================================

/*
MANO ABIERTA
→ SOLO SOPORTA:
   - ON_PRESS
*/

INSERT INTO gestosdisparadores
(
    GestoId,
    TipoDisparadorId,
    TiempoMinimoDeteccionMs,
    PermiteLoop
)
VALUES
(
    1, -- Mano abierta
    1, -- ON_PRESS
    300,
    b'0'
);

/*
PULGAR ARRIBA
→ SOPORTA:
   - HOLD
   - LOOP
*/

INSERT INTO gestosdisparadores
(
    GestoId,
    TipoDisparadorId,
    TiempoMinimoDeteccionMs,
    PermiteLoop
)
VALUES
(
    3, -- Pulgar arriba
    2, -- HOLD
    500,
    b'0'
),
(
    3, -- Pulgar arriba
    3, -- LOOP
    500,
    b'1'
);

/*
PUÑO CERRADO
→ SOPORTA:
   - ON_RELEASE
*/

INSERT INTO gestosdisparadores
(
    GestoId,
    TipoDisparadorId,
    TiempoMinimoDeteccionMs,
    RequiereLiberacion
)
VALUES
(
    2, -- Puño
    4, -- ON_RELEASE
    700,
    b'1'
);

-- =====================================================
-- CONFIGURACIONES DEL USUARIO
-- =====================================================

/*
MANO ABIERTA
→ Toggle Luz
*/

INSERT INTO accionesconfiguradas
(
    UsuarioId,
    GestoDisparadorId,
    AparatoId,
    AccionId,
    CooldownMs
)
VALUES
(
    1,
    1, -- Mano abierta + ON_PRESS
    1,
    1,
    1500
);

/*
PULGAR ARRIBA
→ Subir volumen continuamente
*/

INSERT INTO accionesconfiguradas
(
    UsuarioId,
    GestoDisparadorId,
    AparatoId,
    AccionId,
    IntervaloLoopMs
)
VALUES
(
    1,
    3, -- Pulgar arriba + LOOP
    2,
    4,
    250
);