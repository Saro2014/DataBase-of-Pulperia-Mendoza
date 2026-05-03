USE PulperiaMendoza;
GO

CREATE TABLE Usuarios (
    IDUsuario INT PRIMARY KEY IDENTITY(1,1),
    Usuario NVARCHAR(50) UNIQUE NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL,
    Rol NVARCHAR(20) NOT NULL,
    Activo BIT DEFAULT 1,
    CONSTRAINT CHK_Rol CHECK (Rol IN ('Administrador', 'Trabajador', 'Tecnico'))
);

CREATE TABLE Clientes (
    IDClientes INT PRIMARY KEY IDENTITY(1,1),
    NombreCliente VARCHAR(255) NOT NULL, 
    ApellidoCliente VARCHAR(255) NOT NULL
);

CREATE TABLE ClienteLogin (
    IDClienteLogin INT PRIMARY KEY IDENTITY(1,1),
    IDClientes INT UNIQUE,
    Usuario NVARCHAR(50) UNIQUE NOT NULL,
    PasswordHash NVARCHAR(255) NOT NULL,
    Activo BIT DEFAULT 1,
    FOREIGN KEY (IDClientes) REFERENCES Clientes(IDClientes)
);

CREATE TABLE Productos (
    IDProductos INT PRIMARY KEY IDENTITY(1,1),
    NombreProducto VARCHAR(255) NOT NULL,
    TipoProducto VARCHAR(255),
    PrecioCompra DECIMAL(10,2),
    PrecioVenta DECIMAL(10,2) NOT NULL,
    UnidadCompra VARCHAR(20),
    UnidadVenta VARCHAR(20),
    FactorConversion DECIMAL(10,2),
    Stock INT DEFAULT 0
);

CREATE TABLE Proveedores (
    IDProveedores INT PRIMARY KEY IDENTITY(1,1),
    NombreProveedores VARCHAR(255) NOT NULL,
    TipoProveedores VARCHAR(255)
);

CREATE TABLE Productos_Proveedores (
    IDProducto_Proveedor INT PRIMARY KEY IDENTITY(1,1),
    IDProductos INT,
    IDProveedores INT,
    FOREIGN KEY (IDProductos) REFERENCES Productos(IDProductos),
    FOREIGN KEY (IDProveedores) REFERENCES Proveedores(IDProveedores)
);

CREATE TABLE Factura (
    IDFactura INT PRIMARY KEY IDENTITY(1,1),
    IDClientes INT,
    IDUsuario INT,
    TipoPago VARCHAR(20) NOT NULL,
    Total DECIMAL(10,2),
    Fecha DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (IDClientes) REFERENCES Clientes(IDClientes),
    FOREIGN KEY (IDUsuario) REFERENCES Usuarios(IDUsuario),
    CONSTRAINT CHK_TipoPago CHECK (TipoPago IN ('Efectivo', 'Credito'))
);

CREATE TABLE DetalleFactura (
    IDDetalle INT PRIMARY KEY IDENTITY(1,1),
    IDFactura INT,
    IDProductos INT,
    Cantidad INT,
    Precio DECIMAL(10,2),
    FOREIGN KEY (IDFactura) REFERENCES Factura(IDFactura),
    FOREIGN KEY (IDProductos) REFERENCES Productos(IDProductos)
);

CREATE TABLE Servicios (
    IDServicio INT PRIMARY KEY IDENTITY(1,1),
    NombreServicio VARCHAR(255),
    Precio DECIMAL(10,2)
);

CREATE TABLE OrdenServicio (
    IDOrden INT PRIMARY KEY IDENTITY(1,1),
    IDClientes INT,
    IDUsuario INT,
    Problema VARCHAR(255),
    Solucion VARCHAR(255),
    Total DECIMAL(10,2),
    Fecha DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (IDClientes) REFERENCES Clientes(IDClientes),
    FOREIGN KEY (IDUsuario) REFERENCES Usuarios(IDUsuario)
);

CREATE TABLE DetalleServicio (
    IDDetalleServicio INT PRIMARY KEY IDENTITY(1,1),
    IDOrden INT,
    IDServicio INT,
    Cantidad INT,
    Precio DECIMAL(10,2),
    FOREIGN KEY (IDOrden) REFERENCES OrdenServicio(IDOrden),
    FOREIGN KEY (IDServicio) REFERENCES Servicios(IDServicio)
);

CREATE INDEX IDX_Usuarios_Usuario ON Usuarios(Usuario);
CREATE INDEX IDX_Clientes_Nombre ON Clientes(NombreCliente);
CREATE INDEX IDX_Productos_Nombre ON Productos(NombreProducto);

GO
CREATE TRIGGER TR_ValidarStock
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
GO

CREATE VIEW VistaVentas AS
SELECT 
    f.IDFactura,
    c.NombreCliente,
    u.Usuario,
    f.TipoPago,
    f.Total,
    f.Fecha
FROM Factura f
JOIN Clientes c ON f.IDClientes = c.IDClientes
JOIN Usuarios u ON f.IDUsuario = u.IDUsuario;
GO

INSERT INTO Productos (NombreProducto, TipoProducto, PrecioCompra, PrecioVenta, UnidadCompra, UnidadVenta, FactorConversion, Stock)
VALUES 
('Arroz Maria', 'Grano', 1650, 18, 'Quintal', 'Libra', 100, 200),
('Aceite (Balde 20L)', 'Liquido', 560, 70, 'Balde', 'Litro', 20, 40),
('Arroz Faizan', 'Grano', 2000, 26, 'Quintal', 'Libra', 100, 100),
('Frijoles Crudos', 'Grano', 2550, 35, 'Quintal', 'Libra', 100, 300),
('Cafe Presto Caja', 'Cafe', 150, 4, 'Caja', 'Unidad', 60, 300),
('Leche Eskimo 1/2L', 'Lacteo', 15.5, 24, 'Unidad', 'Unidad', 1, 40);

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
