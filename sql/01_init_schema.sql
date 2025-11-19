-- 1. Sprzątanie (na wypadek gdybyś musiał zresetować bazę)
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

-- 2. Tworzenie Typów Wyliczeniowych (ENUM)
CREATE TYPE obecnosc_status AS ENUM ('Nieobecny', 'Obecny', 'Anulowany');
CREATE TYPE karnet_status AS ENUM ('Aktywny', 'Wygasły', 'Zamrozony', 'Anulowany');
CREATE TYPE metoda_platnosci AS ENUM ('Karta', 'Gotowka', 'Przelew', 'Blik');
CREATE TYPE zrodlo_punktow AS ENUM ('zakup', 'obecnosc', 'bonus', 'refund', 'wymiana_na_nagrode');

-- 3. Tworzenie Tabel (w kolejności zależności - najpierw te bez FK!)

CREATE TABLE Klienci (
    id_klienta SERIAL PRIMARY KEY,
    imie VARCHAR(100) NOT NULL,
    nazwisko VARCHAR(100) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    telefon VARCHAR(20),
    data_rejestracji DATE NOT NULL DEFAULT CURRENT_DATE,
    data_modyfikacji TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    czy_aktywny BOOLEAN DEFAULT TRUE,
    data_deaktywacji DATE,
    data_usuniecia TIMESTAMP
);

CREATE TABLE Trenerzy (
    id_trenera SERIAL PRIMARY KEY,
    imie VARCHAR(100) NOT NULL,
    nazwisko VARCHAR(100) NOT NULL,
    specjalizacja VARCHAR(100),
    email VARCHAR(255) UNIQUE NOT NULL,
    czy_aktywny BOOLEAN DEFAULT TRUE,
    data_deaktywacji DATE,
    data_usuniecia TIMESTAMP
);

CREATE TABLE Typy_Zajec (
    id_typu_zajec SERIAL PRIMARY KEY,
    nazwa VARCHAR(100) NOT NULL,
    opis TEXT,
    punkty_za_obecnosc INT DEFAULT 0,
    maksymalny_limit_miejsc INT
);

CREATE TABLE Typy_Karnetow (
    id_typu_karnetu SERIAL PRIMARY KEY,
    nazwa VARCHAR(100) NOT NULL,
    cena NUMERIC(10, 2) CHECK (cena > 0),
    dlugosc_w_dniach INT CHECK (dlugosc_w_dniach > 0),
    liczba_wejsc INT, -- NULL oznacza brak limitu (open)
    opis TEXT,
    punkty_lojalnosciowe_za_zakup INT DEFAULT 0
);

CREATE TABLE Nagrody (
    id_nagrody SERIAL PRIMARY KEY,
    nazwa VARCHAR(100) NOT NULL,
    koszt_w_punktach INT NOT NULL CHECK (koszt_w_punktach > 0),
    opis TEXT,
    czy_aktywna BOOLEAN DEFAULT TRUE
);

-- 4. Tworzenie Tabel z Kluczami Obcymi (FK)

CREATE TABLE Harmonogram_Zajec (
    id_harmonogramu SERIAL PRIMARY KEY,
    id_typu_zajec INT NOT NULL REFERENCES Typy_Zajec(id_typu_zajec),
    id_trenera INT NOT NULL REFERENCES Trenerzy(id_trenera),
    data_godzina_rozpoczecia TIMESTAMP NOT NULL,
    czas_trwania_min INT NOT NULL DEFAULT 60,
    limit_miejsc INT CHECK (limit_miejsc > 0)
);

CREATE TABLE Zapisy_Na_Zajecia (
    id_zapisu SERIAL PRIMARY KEY,
    id_klienta INT NOT NULL REFERENCES Klienci(id_klienta),
    id_harmonogramu INT NOT NULL REFERENCES Harmonogram_Zajec(id_harmonogramu),
    data_zapisu TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status_obecnosci obecnosc_status DEFAULT 'Nieobecny',
    -- Jeden klient nie może zapisać się dwa razy na te same zajęcia
    UNIQUE(id_klienta, id_harmonogramu) 
);

CREATE TABLE Sprzedane_Karnety (
    id_sprzedanego_karnetu SERIAL PRIMARY KEY,
    id_klienta INT NOT NULL REFERENCES Klienci(id_klienta),
    id_typu_karnetu INT NOT NULL REFERENCES Typy_Karnetow(id_typu_karnetu),
    cena_transakcyjna NUMERIC(10, 2) NOT NULL CHECK (cena_transakcyjna > 0), -- NOWE: Cena w dniu zakupu
    data_zakupu DATE NOT NULL DEFAULT CURRENT_DATE,
    data_aktywacji DATE,
    data_wygasniecia DATE NOT NULL,
    status karnet_status DEFAULT 'Aktywny',
    liczba_wykorzystanych_wejsc INT DEFAULT 0,
    CHECK (data_wygasniecia >= data_zakupu)
);

CREATE TABLE Platnosci (
    id_platnosci SERIAL PRIMARY KEY,
    id_sprzedanego_karnetu INT NOT NULL REFERENCES Sprzedane_Karnety(id_sprzedanego_karnetu),
    kwota NUMERIC(10, 2) CHECK (kwota > 0),
    data_platnosci TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    metoda_platnosci metoda_platnosci NOT NULL,
    status_platnosci VARCHAR(50) DEFAULT 'Opłacona'
);

CREATE TABLE Klienci_Nagrody (
    id SERIAL PRIMARY KEY,
    id_klienta INT NOT NULL REFERENCES Klienci(id_klienta),
    id_nagrody INT NOT NULL REFERENCES Nagrody(id_nagrody),
    koszt_punktowy_w_momencie_zakupu INT NOT NULL, 
    data_kupna DATE NOT NULL DEFAULT CURRENT_DATE,
    czy_wykorzystana BOOLEAN DEFAULT FALSE
);

-- 5. Tabela "wszystko widząca" - Punkty
-- Uwaga: Tu referencje są NULLABLE, bo punkty mogą być za różne rzeczy
CREATE TABLE Punkty_Lojalnosciowe (
    id_transakcji SERIAL PRIMARY KEY,
    id_klienta INT NOT NULL REFERENCES Klienci(id_klienta),
    ilosc_punktow NUMERIC NOT NULL, -- Może być ujemne przy wydawaniu!
    data_transakcji TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    zrodlo zrodlo_punktow NOT NULL,
    id_zapisu INT REFERENCES Zapisy_Na_Zajecia(id_zapisu),
    id_sprzedanego_karnetu INT REFERENCES Sprzedane_Karnety(id_sprzedanego_karnetu),
    id_wymiany_nagrody INT REFERENCES Klienci_Nagrody(id), -- Opcjonalnie, dla ścisłości
    opis VARCHAR(255)
);

-- Indeksy dla wydajności (Kuba będzie zadowolony)
CREATE INDEX idx_zapisy_klient ON Zapisy_Na_Zajecia(id_klienta);
CREATE INDEX idx_zapisy_harmonogram ON Zapisy_Na_Zajecia(id_harmonogramu);
CREATE INDEX idx_harmonogram_data ON Harmonogram_Zajec(data_godzina_rozpoczecia);
CREATE INDEX idx_karnety_klient ON Sprzedane_Karnety(id_klienta);
CREATE INDEX idx_karnety_status ON Sprzedane_Karnety(status);
