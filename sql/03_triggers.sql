-- TRIGGER 1: Automatyczne punkty za zakup karnetu
-- Kiedy: Po dodaniu wpisu do Sprzedane_Karnety
CREATE OR REPLACE FUNCTION trg_funkcja_punkty_za_karnet()
RETURNS TRIGGER AS $$
DECLARE
    v_punkty INT;
    v_nazwa_karnetu VARCHAR;
BEGIN
    -- Ile pkt a ten karnet
    SELECT punkty_lojalnosciowe_za_zakup, nazwa INTO v_punkty, v_nazwa_karnetu
    FROM Typy_Karnetow
    WHERE id_typu_karnetu = NEW.id_typu_karnetu;

    IF v_punkty > 0 THEN
        INSERT INTO Punkty_Lojalnosciowe (
            id_klienta, ilosc_punktow, zrodlo, id_sprzedanego_karnetu, opis
        ) VALUES (
            NEW.id_klienta,
            v_punkty,
            'zakup',
            NEW.id_sprzedanego_karnetu,
            'Punkty za zakup karnetu: ' || v_nazwa_karnetu
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_dodaj_punkty_za_karnet
AFTER INSERT ON Sprzedane_Karnety
FOR EACH ROW
EXECUTE FUNCTION trg_funkcja_punkty_za_karnet();

-- TRIGGER 2: Automatyczne punkty za obecność na zajęciach
-- Kiedy: Gdy status w Zapisy_Na_Zajecia zmieni się na 'Obecny' lub zostanie anulowany

CREATE OR REPLACE FUNCTION trg_funkcja_punkty_za_obecnosc()
RETURNS TRIGGER AS $$
DECLARE
    v_punkty INT;
    v_nazwa_zajec VARCHAR;
BEGIN
    -- Przyznawanie punktów za oznaczenie obecności
    IF NEW.status_obecnosci = 'Obecny' AND OLD.status_obecnosci != 'Obecny' THEN
        
        -- Pobieranie punktow za te zajecia 
        SELECT tz.punkty_za_obecnosc, tz.nazwa INTO v_punkty, v_nazwa_zajec
        FROM Harmonogram_Zajec h
        JOIN Typy_Zajec tz ON h.id_typu_zajec = tz.id_typu_zajec
        WHERE h.id_harmonogramu = NEW.id_harmonogramu;

        IF v_punkty > 0 THEN
            INSERT INTO Punkty_Lojalnosciowe (
                id_klienta, ilosc_punktow, zrodlo, id_zapisu, opis
            ) VALUES (
                NEW.id_klienta,
                v_punkty,
                'obecnosc',
                NEW.id_zapisu,
                'Bonus za udział w zajęciach: ' || v_nazwa_zajec
            );
        END IF;
    
    -- Cofanie punktów przy anulowaniu wcześniej potwierdzonej obecności
    ELSIF OLD.status_obecnosci = 'Obecny' AND NEW.status_obecnosci != 'Obecny' THEN
        
        SELECT tz.punkty_za_obecnosc, tz.nazwa INTO v_punkty, v_nazwa_zajec
        FROM Harmonogram_Zajec h
        JOIN Typy_Zajec tz ON h.id_typu_zajec = tz.id_typu_zajec
        WHERE h.id_harmonogramu = NEW.id_harmonogramu;

        IF v_punkty > 0 THEN
            INSERT INTO Punkty_Lojalnosciowe (
                id_klienta, ilosc_punktow, zrodlo, id_zapisu, opis
            ) VALUES (
                NEW.id_klienta,
                -v_punkty,  -- Ujemna wartość = cofnięcie punktów
                'refund',
                NEW.id_zapisu,
                'Anulowanie punktów za zajęcia: ' || v_nazwa_zajec
            );
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_dodaj_punkty_za_obecnosc
AFTER UPDATE ON Zapisy_Na_Zajecia
FOR EACH ROW
EXECUTE FUNCTION trg_funkcja_punkty_za_obecnosc();

-- TRIGGER 3: Automatyczne odejmowanie punktów za nagrody
-- Kiedy: Po dodaniu wpisu do Klienci_Nagrody
CREATE OR REPLACE FUNCTION trg_funkcja_odejmij_punkty()
RETURNS TRIGGER AS $$
DECLARE
    v_nazwa_nagrody VARCHAR;
BEGIN
    SELECT nazwa INTO v_nazwa_nagrody 
    FROM Nagrody WHERE id_nagrody = NEW.id_nagrody;

    -- Wstawiamy ujemną wartość punktów
    INSERT INTO Punkty_Lojalnosciowe (
        id_klienta, ilosc_punktow, zrodlo, id_wymiany_nagrody, opis
    ) VALUES (
        NEW.id_klienta,
        -NEW.koszt_punktowy_w_momencie_zakupu,
        'wymiana_na_nagrode',
        NEW.id,
        'Wymiana punktów na nagrodę: ' || v_nazwa_nagrody
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_odejmij_punkty_za_nagrode
AFTER INSERT ON Klienci_Nagrody
FOR EACH ROW
EXECUTE FUNCTION trg_funkcja_odejmij_punkty();

-- UWAGA: Funkcjonalność automatycznego wygaszania karnetów została przeniesiona
-- do procedury sp_dzienna_konserwacja_karnetow() w pliku 04_procedures.sql

-- TRIGGER 5: Automatyczna inkrementacja/dekrementacja wykorzystanych wejść
-- Kiedy: Gdy status w Zapisy_Na_Zajecia zmieni się na 'Obecny' lub zostanie cofnięty

CREATE OR REPLACE FUNCTION trg_funkcja_inkrementuj_wejscia()
RETURNS TRIGGER AS $$
DECLARE
    v_id_karnetu INT;
    v_limit_wejsc INT;
BEGIN
    -- Inkrementacja przy oznaczeniu obecności
    IF NEW.status_obecnosci = 'Obecny' AND OLD.status_obecnosci != 'Obecny' THEN
        -- Znajdź aktywny karnet klienta z limitem wejść
        SELECT sk.id_sprzedanego_karnetu, tk.liczba_wejsc 
        INTO v_id_karnetu, v_limit_wejsc
        FROM Sprzedane_Karnety sk
        JOIN Typy_Karnetow tk ON sk.id_typu_karnetu = tk.id_typu_karnetu
        WHERE sk.id_klienta = NEW.id_klienta 
          AND sk.status = 'Aktywny' 
          AND sk.data_wygasniecia >= CURRENT_DATE
          AND tk.liczba_wejsc IS NOT NULL
        ORDER BY sk.data_wygasniecia ASC
        LIMIT 1;

        -- Inkrementuj licznik wejść
        IF v_id_karnetu IS NOT NULL THEN
            UPDATE Sprzedane_Karnety 
            SET liczba_wykorzystanych_wejsc = liczba_wykorzystanych_wejsc + 1
            WHERE id_sprzedanego_karnetu = v_id_karnetu;
        END IF;

    -- Dekrementacja przy cofnięciu obecności
    ELSIF OLD.status_obecnosci = 'Obecny' AND NEW.status_obecnosci != 'Obecny' THEN
        SELECT sk.id_sprzedanego_karnetu, tk.liczba_wejsc 
        INTO v_id_karnetu, v_limit_wejsc
        FROM Sprzedane_Karnety sk
        JOIN Typy_Karnetow tk ON sk.id_typu_karnetu = tk.id_typu_karnetu
        WHERE sk.id_klienta = NEW.id_klienta 
          AND tk.liczba_wejsc IS NOT NULL
        ORDER BY sk.data_wygasniecia ASC
        LIMIT 1;

        IF v_id_karnetu IS NOT NULL THEN
            UPDATE Sprzedane_Karnety 
            SET liczba_wykorzystanych_wejsc = GREATEST(0, liczba_wykorzystanych_wejsc - 1)
            WHERE id_sprzedanego_karnetu = v_id_karnetu;
        END IF;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_inkrementuj_wejscia_po_obecnosci
AFTER UPDATE ON Zapisy_Na_Zajecia
FOR EACH ROW
EXECUTE FUNCTION trg_funkcja_inkrementuj_wejscia();

-- TRIGGER 6: Walidacja limitu miejsc w harmonogramie
-- Kiedy: Przed INSERT lub UPDATE na Harmonogram_Zajec

CREATE OR REPLACE FUNCTION trg_funkcja_waliduj_limit_miejsc()
RETURNS TRIGGER AS $$
DECLARE
    v_max_limit INT;
    v_nazwa_zajec VARCHAR;
BEGIN
    -- Pobierz maksymalny limit dla tego typu zajęć
    SELECT maksymalny_limit_miejsc, nazwa INTO v_max_limit, v_nazwa_zajec
    FROM Typy_Zajec
    WHERE id_typu_zajec = NEW.id_typu_zajec;

    -- Jeśli typ zajęć ma zdefiniowany maksymalny limit, sprawdź czy nie jest przekroczony
    IF v_max_limit IS NOT NULL AND NEW.limit_miejsc > v_max_limit THEN
        RAISE EXCEPTION 'Limit miejsc (%) przekracza maksymalny limit dla zajęć "%" (%)!', 
            NEW.limit_miejsc, v_nazwa_zajec, v_max_limit;
    END IF;

    -- Sprawdź czy limit nie jest mniejszy niż 1
    IF NEW.limit_miejsc IS NOT NULL AND NEW.limit_miejsc < 1 THEN
        RAISE EXCEPTION 'Limit miejsc musi być większy od 0!';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_waliduj_limit_miejsc_harmonogram
BEFORE INSERT OR UPDATE ON Harmonogram_Zajec
FOR EACH ROW
EXECUTE FUNCTION trg_funkcja_waliduj_limit_miejsc();