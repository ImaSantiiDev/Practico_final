-- sql/datos_demo.sql
-- Datos de prueba para probar la aplicacion
-- Se cargan con: sudo mysql almacen_db < sql/datos_demo.sql
-- (importante: cargar despues del schema.sql)

USE almacen_db;

INSERT INTO categorias (nombre, descripcion) VALUES
    ('Perifericos', 'Mouse, teclados, pads y auriculares'),
    ('Monitores',   'Monitores y pantallas de todo tamano'),
    ('Cables',      'Cables HDMI, USB y de red'),
    ('Almacenamiento', 'Discos, pendrives y tarjetas');

INSERT INTO productos (nombre, descripcion, precio, cantidad, categoria_id) VALUES
    ('Mouse logitech M185',  'Mouse inalambrico USB',             1500.00,  25, 1),
    ('Teclado USB generico', 'Teclado espanol con cable',         2200.00,  12, 1),
    ('Auriculares con micro','Auriculares para PC con microfono', 3100.00,   8, 1),
    ('Monitor 24 pulgadas',  'Monitor full HD con HDMI',         18500.00,   4, 2),
    ('Monitor 27 pulgadas',  'Monitor 2K IPS',                   32900.00,   2, 2),
    ('Cable HDMI 2 metros',  'Cable HDMI estandar',                450.00,  60, 3),
    ('Cable de red CAT6',     'Cable UTP de 3 metros',              380.00,  80, 3),
    ('Disco SSD 480 GB',     'Disco solido SATA',                6800.00,  15, 4),
    ('Pendrive 32 GB',       'Memoria USB 3.0',                  1200.00,  40, 4),
    ('Tarjeta microSD 64 GB','Tarjeta para camara y celular',      1600.00,  30, 4);
