-- sql/schema.sql
-- Estructura de la base de datos del almacen de productos
-- Se carga con: sudo mysql < sql/schema.sql

CREATE DATABASE IF NOT EXISTS almacen_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_spanish_ci;

USE almacen_db;

CREATE TABLE IF NOT EXISTS categorias (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(60)  NOT NULL UNIQUE,
    descripcion VARCHAR(200) DEFAULT NULL
) ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS productos (
    id          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre      VARCHAR(100)  NOT NULL,
    descripcion VARCHAR(250)  DEFAULT NULL,
    precio      DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    cantidad    INT UNSIGNED  NOT NULL DEFAULT 0,
    categoria_id INT UNSIGNED DEFAULT NULL,
    creado_en    TIMESTAMP    DEFAULT CURRENT_TIMESTAMP,
    modificado_en TIMESTAMP   DEFAULT CURRENT_TIMESTAMP
                    ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_producto_categoria
        FOREIGN KEY (categoria_id) REFERENCES categorias (id)
        ON DELETE SET NULL
) ENGINE = InnoDB;
