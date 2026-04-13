-- Crear base de datos
CREATE DATABASE IF NOT EXISTS mazza CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE mazza;

-- =========================
-- TABLAS BASE
-- =========================

CREATE TABLE roles (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion VARCHAR(200),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE estados (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =========================
-- USUARIOS
-- =========================

CREATE TABLE usuarios (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    rol_id TINYINT UNSIGNED NOT NULL,
    estado_id TINYINT UNSIGNED NOT NULL DEFAULT 1,
    created_by INT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (rol_id) REFERENCES roles(id),
    FOREIGN KEY (estado_id) REFERENCES estados(id),
    FOREIGN KEY (created_by) REFERENCES usuarios(id) ON DELETE SET NULL
);

-- =========================
-- CATEGORÍAS Y PRODUCTOS
-- =========================

CREATE TABLE categorias (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL,
    descripcion TEXT,
    estado_id TINYINT UNSIGNED NOT NULL DEFAULT 1,
    created_by INT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (estado_id) REFERENCES estados(id),
    FOREIGN KEY (created_by) REFERENCES usuarios(id) ON DELETE SET NULL
);

CREATE TABLE productos (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    codigo_barras VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(150) NOT NULL,
    descripcion TEXT,
    categoria_id INT UNSIGNED NOT NULL,
    precio_compra DECIMAL(10,2) UNSIGNED NOT NULL,
    precio_venta DECIMAL(10,2) UNSIGNED NOT NULL,
    stock INT UNSIGNED DEFAULT 0,
    stock_minimo INT UNSIGNED DEFAULT 5,
    imagen_url VARCHAR(255),
    estado_id TINYINT UNSIGNED NOT NULL DEFAULT 1,
    created_by INT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (categoria_id) REFERENCES categorias(id),
    FOREIGN KEY (estado_id) REFERENCES estados(id),
    FOREIGN KEY (created_by) REFERENCES usuarios(id) ON DELETE SET NULL,
    CONSTRAINT chk_precios_validos CHECK (precio_compra >= 0 AND precio_venta >= precio_compra)
);

-- =========================
-- VENTAS
-- =========================

CREATE TABLE metodos_pago (
    id TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(50) UNIQUE NOT NULL,
    descripcion VARCHAR(200),
    estado_id TINYINT UNSIGNED NOT NULL DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (estado_id) REFERENCES estados(id)
);

CREATE TABLE ventas (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    numero_boleta VARCHAR(20) UNIQUE NOT NULL,
    cajero_id INT UNSIGNED NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    subtotal DECIMAL(12,2) UNSIGNED NOT NULL,
    descuento DECIMAL(10,2) UNSIGNED DEFAULT 0,
    impuestos DECIMAL(10,2) UNSIGNED DEFAULT 0,
    total DECIMAL(12,2) UNSIGNED NOT NULL,
    metodo_pago_id TINYINT UNSIGNED NOT NULL,
    observaciones TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (cajero_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
    FOREIGN KEY (metodo_pago_id) REFERENCES metodos_pago(id),
    CONSTRAINT chk_total_positivo CHECK (total > 0)
);

CREATE TABLE detalle_venta (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    venta_id INT UNSIGNED NOT NULL,
    producto_id INT UNSIGNED NOT NULL,
    cantidad INT UNSIGNED NOT NULL,
    precio_unitario DECIMAL(10,2) UNSIGNED NOT NULL,
    descuento_unitario DECIMAL(10,2) UNSIGNED DEFAULT 0,
    subtotal DECIMAL(10,2) GENERATED ALWAYS AS (cantidad * (precio_unitario - descuento_unitario)) STORED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (venta_id) REFERENCES ventas(id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE RESTRICT,
    CONSTRAINT chk_cantidad_positiva CHECK (cantidad > 0)
);

-- =========================
-- COMPRAS Y PROVEEDORES
-- =========================

CREATE TABLE proveedores (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    ruc VARCHAR(20) UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    telefono VARCHAR(20),
    direccion VARCHAR(150),
    email VARCHAR(100),
    contacto VARCHAR(100),
    estado_id TINYINT UNSIGNED NOT NULL DEFAULT 1,
    created_by INT UNSIGNED NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP NULL,
    FOREIGN KEY (estado_id) REFERENCES estados(id),
    FOREIGN KEY (created_by) REFERENCES usuarios(id) ON DELETE SET NULL
);

CREATE TABLE compras (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    numero_factura VARCHAR(50),
    proveedor_id INT UNSIGNED NOT NULL,
    usuario_id INT UNSIGNED NOT NULL,
    fecha TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    subtotal DECIMAL(12,2) UNSIGNED NOT NULL,
    impuestos DECIMAL(10,2) UNSIGNED DEFAULT 0,
    total DECIMAL(12,2) UNSIGNED NOT NULL,
    observaciones TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (proveedor_id) REFERENCES proveedores(id) ON DELETE RESTRICT,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE RESTRICT,
    CONSTRAINT chk_total_compra CHECK (total > 0)
);

CREATE TABLE detalle_compra (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    compra_id INT UNSIGNED NOT NULL,
    producto_id INT UNSIGNED NOT NULL,
    cantidad INT UNSIGNED NOT NULL,
    precio_unitario DECIMAL(10,2) UNSIGNED NOT NULL,
    subtotal DECIMAL(10,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (compra_id) REFERENCES compras(id) ON DELETE CASCADE,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE RESTRICT,
    CONSTRAINT chk_cantidad_compra CHECK (cantidad > 0)
);

-- =========================
-- MOVIMIENTOS DE INVENTARIO
-- =========================

CREATE TABLE movimientos_inventario (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    producto_id INT UNSIGNED NOT NULL,
    tipo ENUM('entrada','salida','ajuste','inicial') NOT NULL,
    cantidad INT NOT NULL,
    stock_anterior INT NOT NULL,
    stock_nuevo INT NOT NULL,
    referencia_id INT UNSIGNED,
    referencia_tipo ENUM('venta','compra','ajuste','sistema'),
    motivo VARCHAR(200),
    usuario_id INT UNSIGNED NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (producto_id) REFERENCES productos(id) ON DELETE RESTRICT,
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE RESTRICT
);

-- =========================
-- ÍNDICES
-- =========================

CREATE INDEX idx_usuarios_email ON usuarios(email);
CREATE INDEX idx_productos_categoria ON productos(categoria_id);
CREATE INDEX idx_productos_estado ON productos(estado_id);
CREATE INDEX idx_ventas_fecha ON ventas(fecha);
CREATE INDEX idx_compras_fecha ON compras(fecha);
CREATE INDEX idx_movimientos_fecha ON movimientos_inventario(created_at);

-- =========================
-- DATOS BASE
-- =========================

INSERT INTO estados (nombre) VALUES 
('activo'), ('inactivo'), ('pendiente'), ('completado'), ('cancelado');

INSERT INTO roles (nombre, descripcion) VALUES 
('administrador', 'Acceso total al sistema'),
('cajero', 'Realiza ventas y maneja caja'),
('trabajador', 'Gestión de inventario y proveedores');

INSERT INTO metodos_pago (nombre, descripcion) VALUES 
('efectivo', 'Pago en efectivo'),
('tarjeta', 'Pago con tarjeta débito/crédito'),
('yape', 'Pago digital Yape'),
('transferencia', 'Transferencia bancaria');

INSERT INTO usuarios (nombre, email, password_hash, rol_id, estado_id) VALUES 
('Administrador', 'admin@revenge.com', '123456', 1, 1);

-- Agregar un cajero
INSERT INTO usuarios (nombre, email, password_hash, rol_id, estado_id, created_by)
VALUES ('Cajero Principal', 'cajero@revenge.com', '123456', 2, 1, 1);

-- Agregar un trabajador
INSERT INTO usuarios (nombre, email, password_hash, rol_id, estado_id, created_by)
VALUES ('Trabajador Almacén', 'trabajador@revenge.com', '123456', 3, 1, 1);
SHOW WARNINGS;

SELECT * FROM productos;
INSERT INTO productos (codigo_barras, nombre, descripcion, categoria_id, precio_compra, precio_venta, stock, stock_minimo, imagen_url, estado_id, created_by)
VALUES
('7750142000101', 'Coca-Cola 500ml', 'Gaseosa Coca-Cola botella PET 500ml', 1, 2.00, 3.50, 120, 10, NULL, 1, 1),
('7750142000200', 'Inca Kola 500ml', 'Gaseosa peruana Inca Kola botella PET 500ml', 1, 2.00, 3.50, 100, 10, NULL, 1, 1),
('7750142000309', 'Pepsi 500ml', 'Gaseosa Pepsi botella PET 500ml', 1, 2.00, 3.50, 90, 10, NULL, 1, 1),
('7750142000408', 'Sprite 500ml', 'Gaseosa Sprite botella PET 500ml', 1, 2.00, 3.50, 80, 10, NULL, 1, 1),
('7750142000507', 'Fanta Naranja 500ml', 'Gaseosa Fanta sabor naranja botella PET 500ml', 1, 2.00, 3.50, 70, 10, NULL, 1, 1),
('7750142000606', 'Agua San Luis 625ml', 'Agua mineral sin gas San Luis 625ml', 1, 1.20, 2.00, 150, 15, NULL, 1, 1),
('7750142000705', 'Agua Cielo 625ml', 'Agua mineral sin gas Cielo 625ml', 1, 1.20, 2.00, 140, 15, NULL, 1, 1),
('7750142000804', 'Gatorade Naranja 500ml', 'Bebida isotónica sabor naranja', 1, 3.50, 5.50, 60, 10, NULL, 1, 1),
('7750142000903', 'Volt Energy Drink 473ml', 'Bebida energética Volt lata 473ml', 1, 4.00, 6.50, 50, 10, NULL, 1, 1),
('7750142001009', 'Red Bull 250ml', 'Bebida energética Red Bull lata 250ml', 1, 5.50, 8.00, 45, 10, NULL, 1, 1),
('7750142001108', 'Frugos Néctar Durazno 1L', 'Jugo Frugos sabor durazno caja 1L', 1, 4.50, 7.00, 80, 10, NULL, 1, 1),
('7750142001207', 'Frugos Néctar Naranja 1L', 'Jugo Frugos sabor naranja caja 1L', 1, 4.50, 7.00, 70, 10, NULL, 1, 1),
('7750142001306', 'Cifrut Tropical 500ml', 'Bebida sabor tropical', 1, 1.80, 3.00, 90, 10, NULL, 1, 1),
('7750142001405', 'Cifrut Fresa 500ml', 'Bebida sabor fresa', 1, 1.80, 3.00, 90, 10, NULL, 1, 1),
('7750142001504', 'Kola Real 500ml', 'Gaseosa Kola Real botella PET 500ml', 1, 1.80, 3.00, 100, 10, NULL, 1, 1);

-- =========================
-- DATOS DE PRUEBA ADICIONALES
-- =========================

-- Insertar datos en CATEGORIAS (Necesario para PRODUCTOS)
INSERT INTO categorias (nombre, descripcion, estado_id, created_by) VALUES
('Bebidas', 'Todo tipo de bebidas, gaseosas, aguas, jugos.', 1, 1),
('Snacks', 'Papas fritas, galletas, golosinas, etc.', 1, 1),
('Limpieza', 'Productos para la limpieza del hogar.', 1, 1);

-- Insertar datos en PROVEEDORES
INSERT INTO proveedores (ruc, nombre, telefono, direccion, email, contacto, estado_id, created_by) VALUES
('20512345678', 'Distribuidora Principal S.A.', '987654321', 'Av. Los Libertadores 100', 'contacto@principal.com', 'Juan Pérez', 1, 1),
('20587654321', 'Bebidas del Perú E.I.R.L.', '999888777', 'Jr. Unión 500', 'ventas@bebidaperu.com', 'Ana Torres', 1, 1);

-- Nota: Los productos ya fueron insertados en tu script original, asumiendo que la categoría con ID 1 es 'Bebidas'.

-- =========================
-- INSERCIONES EN COMPRAS
-- =========================

-- Compra 1: A Distribuidora Principal S.A.
INSERT INTO compras (numero_factura, proveedor_id, usuario_id, subtotal, impuestos, total, observaciones) VALUES
('F001-000100', 1, 3, 220.00, 39.60, 259.60, 'Compra regular de gaseosas y agua.'), -- Subtotal 220.00 + IGV (18%) 39.60 = 259.60

-- Compra 2: A Bebidas del Perú E.I.R.L.
('B002-000050', 2, 3, 150.00, 27.00, 177.00, 'Reabastecimiento de bebidas energéticas.'), -- Subtotal 150.00 + IGV (18%) 27.00 = 177.00

-- Compra 3: Otra compra a Distribuidora Principal
('F001-000101', 1, 1, 300.00, 54.00, 354.00, 'Compra grande por promoción.'), -- Subtotal 300.00 + IGV (18%) 54.00 = 354.00

-- Compra 4: Compra sin número de factura (e.g., comprobante interno o boleta simple)
(NULL, 2, 3, 50.00, 9.00, 59.00, 'Pequeño pedido de urgencia.'), -- Subtotal 50.00 + IGV (18%) 9.00 = 59.00

-- Compra 5: Compra con descuento o precio neto
('F003-000001', 1, 3, 100.00, 0.00, 100.00, 'Compra exenta de impuestos, total neto.'), -- Subtotal 100.00 + Impuestos 0.00 = 100.00
('F001-000102', 2, 3, 180.00, 32.40, 212.40, 'Reabastecimiento de jugos y bebidas isotónicas.'); -- Subtotal 180.00 + IGV (18%) 32.40 = 212.40


-- =========================
-- DETALLE DE COMPRAS
-- =========================

-- Detalle Compra 1
INSERT INTO detalle_compra (compra_id, producto_id, cantidad, precio_unitario) VALUES
(1, 1, 50, 2.00), -- 50 * 2.00 = 100.00 (Coca-Cola 500ml)
(1, 6, 100, 1.20); -- 100 * 1.20 = 120.00 (Agua San Luis 625ml). Total Subcompra: 220.00

-- Detalle Compra 2
INSERT INTO detalle_compra (compra_id, producto_id, cantidad, precio_unitario) VALUES
(2, 8, 30, 3.50), -- 30 * 3.50 = 105.00 (Gatorade Naranja 500ml)
(2, 10, 10, 4.50); -- 10 * 4.50 = 45.00 (Red Bull 250ml - Asumiendo nuevo precio de compra). Total Subcompra: 150.00

-- Detalle Compra 3
INSERT INTO detalle_compra (compra_id, producto_id, cantidad, precio_unitario) VALUES
(3, 2, 100, 2.00), -- 100 * 2.00 = 200.00 (Inca Kola 500ml)
(3, 3, 50, 2.00); -- 50 * 2.00 = 100.00 (Pepsi 500ml). Total Subcompra: 300.00

-- Detalle Compra 4
INSERT INTO detalle_compra (compra_id, producto_id, cantidad, precio_unitario) VALUES
(4, 15, 20, 1.80), -- 20 * 1.80 = 36.00 (Kola Real 500ml)
(4, 7, 10, 1.40); -- 10 * 1.40 = 14.00 (Agua Cielo 625ml - Asumiendo un pequeño cambio). Total Subcompra: 50.00

-- Detalle Compra 5
INSERT INTO detalle_compra (compra_id, producto_id, cantidad, precio_unitario) VALUES
(5, 4, 50, 2.00); -- 50 * 2.00 = 100.00 (Sprite 500ml). Total Subcompra: 100.00

-- Detalle Compra 6
INSERT INTO detalle_compra (compra_id, producto_id, cantidad, precio_unitario) VALUES
(6, 11, 20, 4.50), -- 20 * 4.50 = 90.00 (Frugos Néctar Durazno 1L)
(6, 13, 30, 3.00); -- 30 * 3.00 = 90.00 (Cifrut Tropical 500ml - Asumiendo nuevo precio de compra). Total Subcompra: 180.00

-- Opcional: Para verificar
SELECT * FROM productos;
SELECT * FROM detalle_compra;


