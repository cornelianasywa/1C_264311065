SOAL 1 : DDL & RELASI

-- 1. Tabel Kamar (Tabel Induk)
CREATE TABLE Kamar (
    No_Kamar VARCHAR(10) PRIMARY KEY,
    Nama_Kamar VARCHAR(50) NOT NULL
);

-- 2. Tabel Penghuni (Tabel Induk)
CREATE TABLE Penghuni (
    ID_Penghuni VARCHAR(10) PRIMARY KEY,
    No_Kamar VARCHAR(10) NOT NULL UNIQUE,
    Nama_Penghuni VARCHAR(100) NOT NULL,
    NoWhatsApp VARCHAR(15),

    FOREIGN KEY (No_Kamar)
        REFERENCES Kamar(No_Kamar)
);

-- 3. Tabel Transaksi_Tagihan (Tabel Transaksi)
CREATE TABLE Transaksi_Tagihan (
    ID_Tagihan INT PRIMARY KEY,
    No_Kamar VARCHAR(10) NOT NULL,
    ID_Penghuni VARCHAR(10) NOT NULL,
    Periode VARCHAR(20) NOT NULL,
    Pemakaian_KWh DECIMAL(10,2) NOT NULL,
    TotalTagihan DECIMAL(12,2) NOT NULL,
    StatusBayar VARCHAR(20) NOT NULL,
    Tgl_Bayar DATE,

    FOREIGN KEY (No_Kamar)
        REFERENCES Kamar(No_Kamar),

    FOREIGN KEY (ID_Penghuni)
        REFERENCES Penghuni(ID_Penghuni)
);

  
SOAL 2 : OPERASI CROD DASAR


-- A1. INSERT Tabel Kamar
INSERT INTO Kamar (No_Kamar, Nama_Kamar)
VALUES
    ('K01', 'Kamar 01'),
    ('K02', 'Kamar 02'),
    ('K03', 'Kamar 03');

-- A2. INSERT Tabel Penghuni
INSERT INTO Penghuni
    (ID_Penghuni, No_Kamar, Nama_Penghuni, NoWhatsApp)
VALUES
    ('P001', 'K01', 'Neisya Grazia', '081234567801'),
    ('P002', 'K02', 'Nashwa', '081234567802'),
    ('P003', 'K03', 'Tia', '081234567803');

-- A3. INSERT Tabel Transaksi_Tagihan
INSERT INTO Transaksi_Tagihan
    (ID_Tagihan, No_Kamar, ID_Penghuni, Periode,
     Pemakaian_KWh, TotalTagihan, StatusBayar, Tgl_Bayar)
VALUES
    (101, 'K01', 'P001', '2026-01',
     45.50, 75000.00, 'Lunas', '2026-01-10'),

    (102, 'K02', 'P002', '2026-01',
     60.25, 95000.00, 'Belum Lunas', NULL),

    (103, 'K03', 'P003', '2026-01',
     35.75, 60000.00, 'Lunas', '2026-01-15');

B. READ

SELECT * FROM Kamar;

C. UPDATE

UPDATE Transaksi_Tagihan
SET StatusBayar = 'Lunas',
    Tgl_Bayar = '2026-01-20'
WHERE ID_Tagihan = 102;


D. DELETE


DELETE FROM Transaksi_Tagihan
WHERE ID_Tagihan = 103;

SOAL 3 : QUERY KOMPLEKS & AGREGASI LAPORAN

SELECT
    p.Nama_Penghuni,
    SUM(t.TotalTagihan) AS Total_Tagihan,
    SUM(t.Pemakaian_KWh) AS Total_Pemakaian_KWh
FROM Penghuni p
JOIN Kamar k
    ON p.No_Kamar = k.No_Kamar
JOIN Transaksi_Tagihan t
    ON p.ID_Penghuni = t.ID_Penghuni
    AND k.No_Kamar = t.No_Kamar
WHERE t.StatusBayar = 'Lunas'
GROUP BY p.ID_Penghuni, p.Nama_Penghuni;




