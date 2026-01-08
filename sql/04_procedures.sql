-- 06_procedures.sql

-- ==========================================
-- PROCEDURA 1: Zakup Karnetu (Rejestracja transakcji)
-- Co robi: Dodaje wpis o karnecie, ustawia daty ważności i rejestruje płatność.
-- Punkty lojalnościowe zostaną dodane automatycznie przez TRIGGER (patrz niżej).
-- ==========================================
CREATE OR REPLACE PROCEDURE sp_zakup_karnetu(
    p_id_klienta INT,
    p_id_typu_karnetu INT,
    p_metoda_platnosci metoda_platnosci
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_cena NUMERIC;
    v_dni INT;
    v_id_sprzedanego INT;
BEGIN
    -- 1. Pobierz dane o karnecie (cena i długość)
    SELECT cena, dlugosc_w_dniach INTO v_cena, v_dni
    FROM Typy_Karnetow
    WHERE id_typu_karnetu = p_id_typu_karnetu;

    -- 2. Wstaw sprzedany karnet
    INSERT INTO Sprzedane_Karnety (
        id_klienta, id_typu_karnetu, cena_transakcyjna, 
        data_zakupu, data_aktywacji, data_wygasniecia, status
    ) VALUES (
        p_id_klienta, 
        p_id_typu_karnetu, 
        v_cena, 
        CURRENT_DATE, 
        CURRENT_DATE, -- Zakładamy aktywację od razu przy zakupie
        CURRENT_DATE + (v_dni || ' days')::INTERVAL, 
        'Aktywny'
    ) RETURNING id_sprzedanego_karnetu INTO v_id_sprzedanego;

    -- 3. Zarejestruj płatność
    INSERT INTO Platnosci (
        id_sprzedanego_karnetu, kwota, metoda_platnosci, status_platnosci
    ) VALUES (
        v_id_sprzedanego, v_cena, p_metoda_platnosci, 'Opłacona'
    );

    RAISE NOTICE 'Karnet zakupiony pomyślnie. ID: %', v_id_sprzedanego;
END;
$$;

-- ==========================================
-- PROCEDURA 2: Zapis na Zajęcia (Z walidacją)
-- Co robi: Sprawdza, czy klient ma aktywny karnet i czy są miejsca, potem zapisuje.
-- ==========================================
CREATE OR REPLACE PROCEDURE sp_zapis_na_zajecia(
    p_id_klienta INT,
    p_id_harmonogramu INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_czy_ma_karnet BOOLEAN;
    v_limit_miejsc INT;
    v_zapisanych INT;
BEGIN
    -- 1. Sprawdź czy klient ma AKTYWNY karnet
    SELECT EXISTS (
        SELECT 1 FROM Sprzedane_Karnety 
        WHERE id_klienta = p_id_klienta 
          AND status = 'Aktywny' 
          AND data_wygasniecia >= CURRENT_DATE
    ) INTO v_czy_ma_karnet;

    IF NOT v_czy_ma_karnet THEN
        RAISE EXCEPTION 'Klient nie posiada aktywnego karnetu!';
    END IF;

    -- 2. Sprawdź limity miejsc
    SELECT limit_miejsc INTO v_limit_miejsc 
    FROM Harmonogram_Zajec WHERE id_harmonogramu = p_id_harmonogramu;

    SELECT COUNT(*) INTO v_zapisanych 
    FROM Zapisy_Na_Zajecia 
    WHERE id_harmonogramu = p_id_harmonogramu AND status_obecnosci != 'Anulowany';

    IF v_zapisanych >= v_limit_miejsc THEN
        RAISE EXCEPTION 'Brak wolnych miejsc na te zajęcia!';
    END IF;

    -- 3. Dokonaj zapisu
    INSERT INTO Zapisy_Na_Zajecia (id_klienta, id_harmonogramu)
    VALUES (p_id_klienta, p_id_harmonogramu);
    
    RAISE NOTICE 'Klient zapisany na zajęcia.';
END;
$$;

-- ==========================================
-- PROCEDURA 3: Wymiana Punktów na Nagrodę
-- Co robi: Sprawdza saldo punktowe klienta i "kupuje" nagrodę.
-- ==========================================
CREATE OR REPLACE PROCEDURE sp_wymiana_punktow_na_nagrode(
    p_id_klienta INT,
    p_id_nagrody INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_koszt_punktowy INT;
    v_aktualne_punkty INT;
BEGIN
    -- 1. Pobierz koszt nagrody
    SELECT koszt_w_punktach INTO v_koszt_punktowy 
    FROM Nagrody WHERE id_nagrody = p_id_nagrody;

    -- 2. Oblicz saldo klienta
    SELECT COALESCE(SUM(ilosc_punktow), 0) INTO v_aktualne_punkty
    FROM Punkty_Lojalnosciowe
    WHERE id_klienta = p_id_klienta;

    -- 3. Walidacja
    IF v_aktualne_punkty < v_koszt_punktowy THEN
        RAISE EXCEPTION 'Brak wystarczającej liczby punktów. Masz: %, Potrzeba: %', v_aktualne_punkty, v_koszt_punktowy;
    END IF;

    -- 4. Zapisz w tabeli łączącej (Trigger zajmie się odjęciem punktów z salda!)
    INSERT INTO Klienci_Nagrody (id_klienta, id_nagrody, koszt_punktowy_w_momencie_zakupu, czy_wykorzystana)
    VALUES (p_id_klienta, p_id_nagrody, v_koszt_punktowy, FALSE);

    RAISE NOTICE 'Nagroda odebrana!';
END;
$$;