-- =====================================================
-- SCRIPT PENGEMBANGAN 
-- Tabel baru: Tarif_Listrik, Pencatatan_Meter, Pembayaran
-- =====================================================

USE monitoring_listrik;

-- 1. Tabel Tarif_Listrik
CREATE TABLE Tarif_Listrik (
    ID_Tarif VARCHAR(10) PRIMARY KEY,
    Nama_Tarif VARCHAR(50) NOT NULL,
    Tarif_Per_KWh DECIMAL(10,2) NOT NULL,
    Tgl_Berlaku DATE NOT NULL,
    Tgl_Berakhir DATE NULL,

    CONSTRAINT chk_tarif_positif
        CHECK (Tarif_Per_KWh > 0),
    CONSTRAINT chk_tarif_tanggal
        CHECK (Tgl_Berakhir IS NULL OR Tgl_Berakhir >= Tgl_Berlaku)
);

-- 2. Tabel Pencatatan_Meter
CREATE TABLE Pencatatan_Meter (
    ID_Pencatatan INT PRIMARY KEY,
    No_Kamar VARCHAR(10) NOT NULL,
    Periode VARCHAR(20) NOT NULL,
    Angka_Awal DECIMAL(10,2) NOT NULL,
    Angka_Akhir DECIMAL(10,2) NOT NULL,
    Pemakaian_KWh DECIMAL(10,2)
        GENERATED ALWAYS AS (Angka_Akhir - Angka_Awal) STORED,
    Tgl_Catat DATE NOT NULL,

    CONSTRAINT fk_meter_kamar
        FOREIGN KEY (No_Kamar) REFERENCES Kamar(No_Kamar),
    CONSTRAINT uq_meter_kamar_periode
        UNIQUE (No_Kamar, Periode),
    CONSTRAINT chk_meter_angka
        CHECK (Angka_Awal >= 0 AND Angka_Akhir >= Angka_Awal)
);

-- 3. Ubah Transaksi_Tagihan (tambah kolom + constraint)
ALTER TABLE Transaksi_Tagihan
    ADD COLUMN ID_Tarif VARCHAR(10) NULL AFTER Pemakaian_KWh,
    ADD COLUMN ID_Pencatatan INT NULL AFTER ID_Tarif;

ALTER TABLE Transaksi_Tagihan
    ADD CONSTRAINT fk_tagihan_tarif
        FOREIGN KEY (ID_Tarif) REFERENCES Tarif_Listrik(ID_Tarif),
    ADD CONSTRAINT fk_tagihan_pencatatan
        FOREIGN KEY (ID_Pencatatan) REFERENCES Pencatatan_Meter(ID_Pencatatan),
    ADD CONSTRAINT uq_tagihan_pencatatan
        UNIQUE (ID_Pencatatan),
    ADD CONSTRAINT uq_tagihan_kamar_periode
        UNIQUE (No_Kamar, Periode),
    ADD CONSTRAINT chk_tagihan_status
        CHECK (StatusBayar IN ('Lunas', 'Belum Lunas')),
    ADD CONSTRAINT chk_tagihan_nilai
        CHECK (Pemakaian_KWh >= 0 AND TotalTagihan >= 0);

-- 4. Tabel Pembayaran
CREATE TABLE Pembayaran (
    ID_Pembayaran INT PRIMARY KEY,
    ID_Tagihan INT NOT NULL,
    Tgl_Bayar DATE NOT NULL,
    Jumlah_Bayar DECIMAL(12,2) NOT NULL,
    Metode_Bayar VARCHAR(20) NOT NULL,

    CONSTRAINT fk_bayar_tagihan
        FOREIGN KEY (ID_Tagihan) REFERENCES Transaksi_Tagihan(ID_Tagihan),
    CONSTRAINT chk_bayar_jumlah
        CHECK (Jumlah_Bayar > 0),
    CONSTRAINT chk_bayar_metode
        CHECK (Metode_Bayar IN ('Tunai', 'Transfer', 'E-Wallet'))
);

-- =====================================================
-- ISI DATA BARU
-- =====================================================

INSERT INTO Tarif_Listrik
    (ID_Tarif, Nama_Tarif, Tarif_Per_KWh, Tgl_Berlaku, Tgl_Berakhir)
VALUES
    ('T001', 'Tarif Kos Reguler 2026', 1500.00, '2026-01-01', NULL);

INSERT INTO Pencatatan_Meter
    (ID_Pencatatan, No_Kamar, Periode, Angka_Awal, Angka_Akhir, Tgl_Catat)
VALUES
    (1, 'K01', '2026-01', 1000.00, 1045.50, '2026-01-31'),
    (2, 'K02', '2026-01', 2000.00, 2060.25, '2026-01-31'),
    (3, 'K03', '2026-01',  500.00,  535.75, '2026-01-31');

-- Hubungkan data tagihan LAMA ke tarif & pencatatan baru
UPDATE Transaksi_Tagihan
SET ID_Tarif = 'T001', ID_Pencatatan = 1
WHERE ID_Tagihan = 101;

UPDATE Transaksi_Tagihan
SET ID_Tarif = 'T001', ID_Pencatatan = 2
WHERE ID_Tagihan = 102;

UPDATE Transaksi_Tagihan
SET ID_Tarif = 'T001', ID_Pencatatan = 3
WHERE ID_Tagihan = 103;

INSERT INTO Pembayaran
    (ID_Pembayaran, ID_Tagihan, Tgl_Bayar, Jumlah_Bayar, Metode_Bayar)
VALUES
    (1, 101, '2026-01-10', 75000.00, 'Transfer'),
    (2, 103, '2026-01-15', 60000.00, 'Tunai');

-- =====================================================
-- VIEW + QUERY PEMBUKTIAN
-- =====================================================

CREATE VIEW v_rekap_tagihan AS
SELECT
    t.ID_Tagihan,
    k.Nama_Kamar,
    p.Nama_Penghuni,
    t.Periode,
    m.Pemakaian_KWh,
    t.TotalTagihan,
    t.StatusBayar
FROM Transaksi_Tagihan t
JOIN Kamar k            ON t.No_Kamar      = k.No_Kamar
JOIN Penghuni p         ON t.ID_Penghuni   = p.ID_Penghuni
JOIN Pencatatan_Meter m ON t.ID_Pencatatan = m.ID_Pencatatan;

-- Q1. Detail tagihan lengkap
SELECT
    t.ID_Tagihan, k.Nama_Kamar, p.Nama_Penghuni, t.Periode,
    m.Angka_Awal, m.Angka_Akhir, m.Pemakaian_KWh,
    tr.Tarif_Per_KWh, t.TotalTagihan, t.StatusBayar
FROM Transaksi_Tagihan t
JOIN Kamar k            ON t.No_Kamar      = k.No_Kamar
JOIN Penghuni p         ON t.ID_Penghuni   = p.ID_Penghuni
JOIN Pencatatan_Meter m ON t.ID_Pencatatan = m.ID_Pencatatan
JOIN Tarif_Listrik tr   ON t.ID_Tarif      = tr.ID_Tarif;

-- Q2. Tunggakan
SELECT
    t.ID_Tagihan, p.Nama_Penghuni, p.NoWhatsApp, t.Periode,
    t.TotalTagihan - IFNULL(SUM(b.Jumlah_Bayar), 0) AS Sisa_Tagihan
FROM Transaksi_Tagihan t
JOIN Penghuni p ON t.ID_Penghuni = p.ID_Penghuni
LEFT JOIN Pembayaran b ON t.ID_Tagihan = b.ID_Tagihan
WHERE t.StatusBayar = 'Belum Lunas'
GROUP BY t.ID_Tagihan, p.Nama_Penghuni, p.NoWhatsApp,
         t.Periode, t.TotalTagihan;

-- Q3. Rekap per periode
SELECT
    Periode,
    COUNT(*)           AS Jumlah_Tagihan,
    SUM(Pemakaian_KWh) AS Total_KWh,
    SUM(TotalTagihan)  AS Total_Tagihan
FROM Transaksi_Tagihan
GROUP BY Periode;

