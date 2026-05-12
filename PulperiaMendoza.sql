USE PulperiaMendoza;
GO

CREATE TABLE Clientes (
    IDClientes INT IDENTITY(1,1) PRIMARY KEY,
    Nombre VARCHAR(100),
    Telefono VARCHAR(20),
);
GO

CREATE TABLE Productos (
    IDProductos INT PRIMARY KEY IDENTITY(1,1),
    NombreProducto VARCHAR(255) NOT NULL,
    TipoProducto VARCHAR(255),
    PrecioCompra DECIMAL(10,2),
    PrecioVenta DECIMAL(10,2) NOT NULL,
    UnidadCompra VARCHAR(20),
    UnidadVenta VARCHAR(20),
    FactorConversion DECIMAL(10,2),
	Imagen VARCHAR(255),
    Descripcion VARCHAR(500),
	destacados BIT DEFAULT 0,
    Stock INT DEFAULT 0,
	Activo BIT DEFAULT 1
);

CREATE TABLE Proveedores (
    IDProveedores INT PRIMARY KEY IDENTITY(1,1),
    NombreProveedores VARCHAR(255) NOT NULL,
    TipoProveedores VARCHAR(255)
);
GO

CREATE TABLE Productos_Proveedores (
    IDProducto_Proveedor INT PRIMARY KEY IDENTITY(1,1),
    IDProductos INT,
    IDProveedores INT,
    FOREIGN KEY (IDProductos) REFERENCES Productos(IDProductos),
    FOREIGN KEY (IDProveedores) REFERENCES Proveedores(IDProveedores)
);
GO

CREATE TABLE Factura (
    IDFactura INT PRIMARY KEY IDENTITY(1,1),
    IDClientes INT NOT NULL,
    TipoPago VARCHAR(20) NOT NULL,
    Total DECIMAL(10,2) DEFAULT 0,
    Fecha DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (IDClientes) REFERENCES Clientes(IDClientes),

    CONSTRAINT CHK_TipoPago CHECK (TipoPago IN ('Efectivo', 'Credito'))
);
GO

CREATE TABLE DetalleFactura (
    IDDetalle INT PRIMARY KEY IDENTITY(1,1),
    IDFactura INT NOT NULL,
    IDProductos INT NOT NULL,
    Cantidad INT NOT NULL,
    Precio DECIMAL(10,2) NOT NULL,

    FOREIGN KEY (IDFactura) REFERENCES Factura(IDFactura),
    FOREIGN KEY (IDProductos) REFERENCES Productos(IDProductos)
);
GO

/*CREATE TABLE Servicios (
    IDServicio INT PRIMARY KEY IDENTITY(1,1),
    NombreServicio VARCHAR(255),
    Precio DECIMAL(10,2)
);
GO

CREATE TABLE OrdenServicio (
    IDOrden INT PRIMARY KEY IDENTITY(1,1),
    IDClientes INT,
    Problema VARCHAR(255),
    Solucion VARCHAR(255),
    Total DECIMAL(10,2),
    Fecha DATETIME DEFAULT GETDATE(),

    FOREIGN KEY (IDClientes) REFERENCES Clientes(IDClientes),
);
GO

CREATE TABLE DetalleServicio (
    IDDetalleServicio INT PRIMARY KEY IDENTITY(1,1),
    IDOrden INT,
    Cantidad INT,
    Precio DECIMAL(10,2),

    FOREIGN KEY (IDOrden) REFERENCES OrdenServicio(IDOrden),
);
GO*/

CREATE INDEX IDX_Clientes_Nombre ON Clientes(Nombre);
CREATE INDEX IDX_Productos_Nombre ON Productos(NombreProducto);
GO

/*CREATE TRIGGER TR_ValidarStock
ON DetalleFactura
INSTEAD OF INSERT
AS
BEGIN
    IF EXISTS (
        SELECT 1
        FROM inserted i
        JOIN Productos p ON i.IDProductos = p.IDProductos
        WHERE p.Stock < i.Cantidad
    )
    BEGIN
        RAISERROR('Stock insuficiente', 16, 1);
        RETURN;
    END

    INSERT INTO DetalleFactura (IDFactura, IDProductos, Cantidad, Precio)
    SELECT IDFactura, IDProductos, Cantidad, Precio
    FROM inserted;
END;
GO

CREATE TRIGGER TR_DescontarStock
ON DetalleFactura
AFTER INSERT
AS
BEGIN
    UPDATE p
    SET Stock = Stock - i.Cantidad
    FROM Productos p
    JOIN inserted i ON p.IDProductos = i.IDProductos
END;
GO

CREATE TRIGGER TR_CalcularTotalFactura
ON DetalleFactura
AFTER INSERT
AS
BEGIN
    UPDATE f
    SET Total = (
        SELECT SUM(Cantidad * Precio)
        FROM DetalleFactura
        WHERE IDFactura = f.IDFactura
    )
    FROM Factura f
    JOIN inserted i ON f.IDFactura = i.IDFactura
END;
GO*/

CREATE VIEW VistaVentas AS
SELECT 
    f.IDFactura,
    c.Nombre,
    c.Telefono,
    f.TipoPago,
    f.Total,
    f.Fecha
FROM Factura f
JOIN Clientes c ON f.IDClientes = c.IDClientes;
GO

USE PulperiaMendoza;
GO

INSERT INTO Productos (NombreProducto, TipoProducto, PrecioCompra, PrecioVenta, UnidadCompra, UnidadVenta, FactorConversion, Stock, Imagen, Descripcion, destacados)
VALUES ('Arroz Maria', 'Grano', 1650, 18, 'Quintal', 'Libra', 100, 200, '/Imagenes/pulperiaimagenes/arrozmaria.jpg', 'Arroz de consumo básico, vendido por libra. Ideal para comidas diarias.', 1),
	   ( 'Aceite (Balde 20L)', 'Liquido', 560, 70, 'Balde', 'Litro', 20, 40, '/Imagenes/pulperiaimagenes/aceite.jpg', 'Aceite vegetal vendido por litro, ideal para cocina diaria.', 1),
	   ( 'Arroz Faizan', 'Grano', 2000, 26, 'Quintal', 'Libra', 100, 100, '/Imagenes/pulperiaimagenes/arrozfaisan.webp', 'Arroz premium de excelente calidad, ideal para familias.', 0),
	   ( 'Frijoles Crudos', 'Grano', 2550, 35, 'Quintal', 'Libra', 100, 300, '/Imagenes/pulperiaimagenes/frijoles.png', 'Frijoles rojos seleccionados, esenciales en la cocina nicaragüense.', 1),
	   ( 'Cafe Presto Caja', 'Cafe', 150, 4, 'Caja', 'Unidad', 60, 300, '/Imagenes/pulperiaimagenes/cafepresto.jpg', 'Café instantáneo práctico y económico para el día a día.', 0),
	   ( 'Leche Eskimo 1/2L', 'Lacteo', 15.5, 24, 'Unidad', 'Unidad', 1, 40, '/Imagenes/pulperiaimagenes/lecheeskimo.jpg', 'Leche líquida de medio litro, ideal para consumo familiar.', 1);
GO

INSERT INTO Proveedores (NombreProveedores, TipoProveedores)
VALUES
('Aceitera Real', 'Alimentos'),
('Mercado', 'General'),
('Eskimo', 'Lacteos');

INSERT INTO Productos_Proveedores (IDProductos, IDProveedores)
SELECT p.IDProductos, pr.IDProveedores
FROM Productos p, Proveedores pr
WHERE p.NombreProducto IN ('Arroz Maria', 'Arroz Faizan')
AND pr.NombreProveedores = 'Aceitera Real';

INSERT INTO Productos_Proveedores (IDProductos, IDProveedores)
SELECT p.IDProductos, pr.IDProveedores
FROM Productos p, Proveedores pr
WHERE p.NombreProducto IN ('Cafe Presto Caja', 'Frijoles Crudos')
AND pr.NombreProveedores = 'Mercado';

INSERT INTO Productos_Proveedores (IDProductos, IDProveedores)
SELECT p.IDProductos, pr.IDProveedores
FROM Productos p, Proveedores pr
WHERE p.NombreProducto = 'Leche Eskimo 1/2L'
AND pr.NombreProveedores = 'Eskimo';

INSERT INTO Productos_Proveedores (IDProductos, IDProveedores)
SELECT p.IDProductos, pr.IDProveedores
FROM Productos p, Proveedores pr
WHERE p.NombreProducto = 'Aceite (Balde 20L)'
AND pr.NombreProveedores = 'Mercado';

SELECT 
    p.NombreProducto,
    pr.NombreProveedores
FROM Productos p
JOIN Productos_Proveedores pp ON p.IDProductos = pp.IDProductos
JOIN Proveedores pr ON pp.IDProveedores = pr.IDProveedores;

SELECT 
    p.NombreProducto,
    p.PrecioCompra,
    CAST(ROUND(p.PrecioCompra / p.FactorConversion, 2) AS DECIMAL(10,2)) AS PrecioUnitario,
    pr.NombreProveedores
FROM Productos p
JOIN Productos_Proveedores pp ON p.IDProductos = pp.IDProductos
JOIN Proveedores pr ON pp.IDProveedores = pr.IDProveedores;


INSERT INTO Clientes (Nombre, Telefono)
VALUES 
('Cliente Prueba', '8888-8888');
SELECT * FROM Clientes;

select * from Productos