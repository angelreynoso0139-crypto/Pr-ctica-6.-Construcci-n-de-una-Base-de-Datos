-- ============================================================
-- Práctica 6: Construcción de una Base de Datos
-- Materia: Bases de Datos I - CUTONALÁ (UdeG)
-- Alumno: Angel Emiliano Reynoso Lopez
-- Script SQL completo (DDL + Triggers + DML)
-- ============================================================

CREATE DATABASE IF NOT EXISTS campeonato_juvenil;
USE campeonato_juvenil;

-- ------------------------------------------------------------
-- LIMPIEZA DE TABLAS
-- ------------------------------------------------------------
DROP TABLE IF EXISTS Juega_Partido;
DROP TABLE IF EXISTS Jugador_Posicion_Habilitado;
DROP TABLE IF EXISTS Partido;
DROP TABLE IF EXISTS Jugador;
DROP TABLE IF EXISTS Posicion;
DROP TABLE IF EXISTS Colegiado;
DROP TABLE IF EXISTS Equipo;

-- ------------------------------------------------------------
-- 1. TABLA: Equipo
-- ------------------------------------------------------------
CREATE TABLE Equipo (
    id_equipo INT AUTO_INCREMENT PRIMARY KEY,
    nombre_equipo VARCHAR(50) NOT NULL
);

-- ------------------------------------------------------------
-- 2. TABLA: Colegiado
-- ------------------------------------------------------------
CREATE TABLE Colegiado (
    id_colegiado INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL
);

-- ------------------------------------------------------------
-- 3. TABLA: Posicion
-- ------------------------------------------------------------
CREATE TABLE Posicion (
    numero_posicion INT PRIMARY KEY CHECK (numero_posicion > 0),
    funcion VARCHAR(50) NOT NULL
);

-- ------------------------------------------------------------
-- 4. TABLA: Jugador
-- ------------------------------------------------------------
CREATE TABLE Jugador (
    codigo_jugador INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    fecha_nacimiento DATE NOT NULL CHECK (fecha_nacimiento > '1971-12-31'),
    nss VARCHAR(15) NOT NULL UNIQUE,
    peso DECIMAL(5,2) NOT NULL CHECK (peso > 0),
    altura INT NOT NULL CHECK (altura > 0),
    id_equipo INT NOT NULL,
    FOREIGN KEY (id_equipo) REFERENCES Equipo(id_equipo) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- ------------------------------------------------------------
-- 5. TABLA: Partido
-- ------------------------------------------------------------
CREATE TABLE Partido (
    id_partido INT AUTO_INCREMENT PRIMARY KEY,
    fecha DATE NOT NULL CHECK (fecha BETWEEN '1996-01-01' AND '1996-12-31'),
    hora TIME NOT NULL CHECK (hora BETWEEN '10:00:00' AND '21:30:00'),
    id_equipo_local INT NOT NULL,
    id_equipo_visita INT NOT NULL,
    id_arbitro_principal INT NOT NULL,
    id_arbitro_derecha INT NOT NULL,
    id_arbitro_izquierda INT NOT NULL,
    CONSTRAINT chk_equipos_distintos CHECK (id_equipo_local <> id_equipo_visita),
    CONSTRAINT chk_arbitros_distintos CHECK (
        id_arbitro_principal <> id_arbitro_derecha AND 
        id_arbitro_principal <> id_arbitro_izquierda AND 
        id_arbitro_derecha <> id_arbitro_izquierda
    ),
    FOREIGN KEY (id_equipo_local) REFERENCES Equipo(id_equipo),
    FOREIGN KEY (id_equipo_visita) REFERENCES Equipo(id_equipo),
    FOREIGN KEY (id_arbitro_principal) REFERENCES Colegiado(id_colegiado),
    FOREIGN KEY (id_arbitro_derecha) REFERENCES Colegiado(id_colegiado),
    FOREIGN KEY (id_arbitro_izquierda) REFERENCES Colegiado(id_colegiado)
);

-- ------------------------------------------------------------
-- 6. TABLA INTERMEDIA: Jugador_Posicion_Habilitado
-- ------------------------------------------------------------
CREATE TABLE Jugador_Posicion_Habilitado (
    codigo_jugador INT NOT NULL,
    numero_posicion INT NOT NULL,
    PRIMARY KEY (codigo_jugador, numero_posicion),
    FOREIGN KEY (codigo_jugador) REFERENCES Jugador(codigo_jugador) ON DELETE CASCADE,
    FOREIGN KEY (numero_posicion) REFERENCES Posicion(numero_posicion) ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- 7. TABLA INTERMEDIA: Juega_Partido
-- ------------------------------------------------------------
CREATE TABLE Juega_Partido (
    id_partido INT NOT NULL,
    codigo_jugador INT NOT NULL,
    numero_posicion INT NOT NULL,
    PRIMARY KEY (id_partido, codigo_jugador),
    FOREIGN KEY (id_partido) REFERENCES Partido(id_partido) ON DELETE CASCADE,
    FOREIGN KEY (codigo_jugador) REFERENCES Jugador(codigo_jugador) ON DELETE CASCADE,
    FOREIGN KEY (numero_posicion) REFERENCES Posicion(numero_posicion) ON DELETE CASCADE
);

-- ------------------------------------------------------------
-- TRIGGER: Validaciones de Negocio en Juega_Partido
-- ------------------------------------------------------------
DELIMITER //
CREATE TRIGGER trg_validar_juega_partido
BEFORE INSERT ON Juega_Partido
FOR EACH ROW
BEGIN
    DECLARE v_equipo_jugador INT;
    DECLARE v_local INT;
    DECLARE v_visita INT;
    DECLARE v_habilitado INT;

    SELECT COUNT(*) INTO v_habilitado 
    FROM Jugador_Posicion_Habilitado 
    WHERE codigo_jugador = NEW.codigo_jugador AND numero_posicion = NEW.numero_posicion;

    IF v_habilitado = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El jugador no está habilitado para ocupar esa posición.';
    END IF;

    SELECT id_equipo INTO v_equipo_jugador FROM Jugador WHERE codigo_jugador = NEW.codigo_jugador;
    SELECT id_equipo_local, id_equipo_visita INTO v_local, v_visita FROM Partido WHERE id_partido = NEW.id_partido;

    IF v_equipo_jugador <> v_local AND v_equipo_jugador <> v_visita THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error: El equipo del jugador no participa en este partido.';
    END IF;
END;
//
DELIMITER ;

-- ============================================================
-- INSERCIÓN DE DATOS (DML) - 5 REGISTROS POR TABLA
-- ============================================================

INSERT INTO Equipo (nombre_equipo) VALUES 
('Leones Negros Juvenil'),
('Chivas Sub-25'),
('Atlas FC Académicos'),
('Tecos F.C.'),
('Deportivo Tonalá');

INSERT INTO Colegiado (nombre) VALUES 
('Marco Antonio Rodríguez'),
('Armando Archundia'),
('Roberto García Orozco'),
('Lucila Venegas'),
('César Arturo Ramos');

INSERT INTO Posicion (numero_posicion, funcion) VALUES 
(1, 'Portero'),
(2, 'Defensa Central'),
(3, 'Mediocampista'),
(4, 'Delantero'),
(5, 'Lateral Derecho');

INSERT INTO Jugador (nombre, fecha_nacimiento, nss, peso, altura, id_equipo) VALUES 
('Carlos Eduardo Silva', '1998-05-12', '12345678901', 72.50, 178, 1),
('Luis Fernando Gómez', '1999-11-20', '12345678902', 68.86, 172, 1),
('Jorge Alberto Hernández', '2000-03-15', '12345678903', 75.10, 182, 2),
('Mateo Rodríguez Pérez', '1997-08-04', '12345678904', 80.90, 185, 2),
('Diego Alejandro López', '2001-01-30', '12345678905', 70.36, 175, 3);

INSERT INTO Jugador_Posicion_Habilitado (codigo_jugador, numero_posicion) VALUES 
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(2, 5);

INSERT INTO Partido (fecha, hora, id_equipo_local, id_equipo_visita, id_arbitro_principal, id_arbitro_derecha, id_arbitro_izquierda) VALUES 
('1996-03-10', '10:30:00', 1, 2, 1, 2, 3),
('1996-04-15', '12:00:00', 3, 4, 2, 3, 4),
('1996-05-20', '15:00:00', 1, 3, 3, 4, 5),
('1996-06-12', '18:00:00', 2, 5, 4, 5, 1),
('1996-07-08', '20:00:00', 4, 5, 5, 1, 2);

INSERT INTO Juega_Partido (id_partido, codigo_jugador, numero_posicion) VALUES 
(1, 1, 1),
(1, 2, 2),
(1, 3, 3),
(1, 4, 4),
(3, 1, 1);
