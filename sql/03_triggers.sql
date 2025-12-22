-- 07_triggers.sql

-- ==========================================
-- TRIGGER 1: Automatyczne punkty za zakup karnetu
-- Kiedy: Po dodaniu wpisu do Sprzedane_Karnety
-- ==========================================
CREATE OR REPLACE FUNCTION trg_funkcja_punkty_za_karnet()
RETURNS TRIGGER AS $$
DECLARE
    v_punkty INT;
    v_nazwa_karnetu VARCHAR;
BEGIN
    -- Pobierz ile punktów należy się za ten typ karnetu
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


-- ==========================================
-- TRIGGER 2: Automatyczne punkty za obecność na zajęciach
-- Kiedy: Gdy status w Zapisy_Na_Zajecia zmieni się na 'Obecny'
-- ==========================================
CREATE OR REPLACE FUNCTION trg_funkcja_punkty_za_obecnosc()
RETURNS TRIGGER AS $$
DECLARE
    v_punkty INT;
    v_nazwa_zajec VARCHAR;
BEGIN
    -- Działaj tylko jeśli zmieniono status na 'Obecny' (z jakiegokolwiek innego)
    IF NEW.status_obecnosci = 'Obecny' AND OLD.status_obecnosci != 'Obecny' THEN
        
        -- Pobierz punkty przypisane do typu zajęć (poprzez harmonogram)
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
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_dodaj_punkty_za_obecnosc
AFTER UPDATE ON Zapisy_Na_Zajecia
FOR EACH ROW
EXECUTE FUNCTION trg_funkcja_punkty_za_obecnosc();


-- ==========================================
-- TRIGGER 3: Automatyczne odejmowanie punktów za nagrody
-- Kiedy: Po dodaniu wpisu do Klienci_Nagrody
-- ==========================================
CREATE OR REPLACE FUNCTION trg_funkcja_odejmij_punkty()
RETURNS TRIGGER AS $$
DECLARE
    v_nazwa_nagrody VARCHAR;
BEGIN
    SELECT nazwa INTO v_nazwa_nagrody 
    FROM Nagrody WHERE id_nagrody = NEW.id_nagrody;

    -- Wstawiamy ujemną wartość punktów!
    INSERT INTO Punkty_Lojalnosciowe (
        id_klienta, ilosc_punktow, zrodlo, id_wymiany_nagrody, opis
    ) VALUES (
        NEW.id_klienta,
        -NEW.koszt_punktowy_w_momencie_zakupu, -- MINUS!
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

-- ==========================================
-- TRIGGER 4: Automatyczne wygaszanie karnetów (Maintenance)
-- To rozwiązanie jest proste. Alternatywą jest cron/pg_cron.
-- Tutaj sprawdzamy status przy każdej próbie wejścia klienta (np. przy zapisie)
-- Ale dla porządku zróbmy prostą procedurę czyszczącą, którą można wywołać ręcznie.
-- ==========================================
-- Dodatkowa procedura techniczna
CREATE OR REPLACE PROCEDURE sp_odswiez_statusy_karnetow()
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE Sprzedane_Karnety
    SET status = 'Wygasły'
    WHERE status = 'Aktywny' AND data_wygasniecia < CURRENT_DATE;
    
    RAISE NOTICE 'Zaktualizowano statusy przeterminowanych karnetów.';
END;
$$;