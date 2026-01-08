-- PROCEDURA 1: Zakup Karnetu (Rejestracja transakcji)
-- Co robi: Dodaje wpis o karnecie ustawia daty ważności i rejestruje płatność.
-- Obsługuje opcjonalną przyszłą datę aktywacji.

CREATE OR REPLACE PROCEDURE sp_zakup_karnetu(
    p_id_klienta INT,
    p_id_typu_karnetu INT,
    p_metoda_platnosci metoda_platnosci,
    p_data_aktywacji DATE DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_cena NUMERIC;
    v_dni INT;
    v_id_sprzedanego INT;
    v_data_aktywacji DATE;
BEGIN
    SELECT cena, dlugosc_w_dniach INTO v_cena, v_dni
    FROM Typy_Karnetow
    WHERE id_typu_karnetu = p_id_typu_karnetu;

    -- Użyj podanej daty lub ustaw na dzisiaj
    v_data_aktywacji := COALESCE(p_data_aktywacji, CURRENT_DATE);

    -- Walidacja - data aktywacji nie może być w przeszłości
    IF v_data_aktywacji < CURRENT_DATE THEN
        RAISE EXCEPTION 'Data aktywacji nie może być w przeszłości!';
    END IF;

    INSERT INTO Sprzedane_Karnety (
        id_klienta, id_typu_karnetu, cena_transakcyjna, 
        data_zakupu, data_aktywacji, data_wygasniecia, status
    ) VALUES (
        p_id_klienta, 
        p_id_typu_karnetu, 
        v_cena, 
        CURRENT_DATE, 
        v_data_aktywacji, 
        v_data_aktywacji + (v_dni || ' days')::INTERVAL,
        CASE WHEN v_data_aktywacji > CURRENT_DATE THEN 'Zamrozony' ELSE 'Aktywny' END
    ) RETURNING id_sprzedanego_karnetu INTO v_id_sprzedanego;

    INSERT INTO Platnosci (
        id_sprzedanego_karnetu, kwota, metoda_platnosci, status_platnosci
    ) VALUES (
        v_id_sprzedanego, v_cena, p_metoda_platnosci, 'Opłacona'
    );

    RAISE NOTICE 'Karnet zakupiony pomyślnie. ID: %, Aktywacja: %', v_id_sprzedanego, v_data_aktywacji;
END;
$$;


-- PROCEDURA 2: Zapis na Zajęcia (Z walidacją)
-- Co robi: Sprawdza, czy klient ma aktywny karnet, czy są miejsca i czy nie przekroczono limitu wejść.

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
    v_limit_wejsc INT;
    v_wykorzystane_wejscia INT;
    v_id_karnetu INT;
BEGIN
    -- Sprawdzenie czy klient ma aktywny karnet
    SELECT EXISTS (
        SELECT 1 FROM Sprzedane_Karnety 
        WHERE id_klienta = p_id_klienta 
          AND status = 'Aktywny' 
          AND data_wygasniecia >= CURRENT_DATE
    ) INTO v_czy_ma_karnet;

    IF NOT v_czy_ma_karnet THEN
        RAISE EXCEPTION 'Klient nie posiada aktywnego karnetu!';
    END IF;

    -- Sprawdzenie limitu wejść dla karnetów z ograniczeniem
    SELECT sk.id_sprzedanego_karnetu, tk.liczba_wejsc, sk.liczba_wykorzystanych_wejsc 
    INTO v_id_karnetu, v_limit_wejsc, v_wykorzystane_wejscia
    FROM Sprzedane_Karnety sk
    JOIN Typy_Karnetow tk ON sk.id_typu_karnetu = tk.id_typu_karnetu
    WHERE sk.id_klienta = p_id_klienta 
      AND sk.status = 'Aktywny' 
      AND sk.data_wygasniecia >= CURRENT_DATE
    ORDER BY sk.data_wygasniecia ASC
    LIMIT 1;

    -- Jeśli karnet ma limit wejść, sprawdź czy nie został przekroczony
    IF v_limit_wejsc IS NOT NULL AND v_wykorzystane_wejscia >= v_limit_wejsc THEN
        RAISE EXCEPTION 'Karnet wyczerpał dostępne wejścia! Wykorzystano: %, Limit: %', 
            v_wykorzystane_wejscia, v_limit_wejsc;
    END IF;

    -- Sprawdzenie limitu miejsc na zajęciach
    SELECT limit_miejsc INTO v_limit_miejsc 
    FROM Harmonogram_Zajec WHERE id_harmonogramu = p_id_harmonogramu;

    SELECT COUNT(*) INTO v_zapisanych 
    FROM Zapisy_Na_Zajecia 
    WHERE id_harmonogramu = p_id_harmonogramu AND status_obecnosci != 'Anulowany';

    IF v_zapisanych >= v_limit_miejsc THEN
        RAISE EXCEPTION 'Brak wolnych miejsc na te zajęcia!';
    END IF;

    INSERT INTO Zapisy_Na_Zajecia (id_klienta, id_harmonogramu)
    VALUES (p_id_klienta, p_id_harmonogramu);
    
    RAISE NOTICE 'Klient zapisany na zajęcia.';
END;
$$;

-- PROCEDURA 3: Wymiana Punktów na Nagrodę
-- Co robi: Sprawdza saldo punktowe klienta i "kupuje" nagrodę.
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
    SELECT koszt_w_punktach INTO v_koszt_punktowy 
    FROM Nagrody WHERE id_nagrody = p_id_nagrody;

    SELECT COALESCE(SUM(ilosc_punktow), 0) INTO v_aktualne_punkty
    FROM Punkty_Lojalnosciowe
    WHERE id_klienta = p_id_klienta;

    IF v_aktualne_punkty < v_koszt_punktowy THEN
        RAISE EXCEPTION 'Brak wystarczającej liczby punktów. Masz: %, Potrzeba: %', v_aktualne_punkty, v_koszt_punktowy;
    END IF;

    INSERT INTO Klienci_Nagrody (id_klienta, id_nagrody, koszt_punktowy_w_momencie_zakupu, czy_wykorzystana)
    VALUES (p_id_klienta, p_id_nagrody, v_koszt_punktowy, FALSE);

    RAISE NOTICE 'Nagroda odebrana!';
END;
$$;

-- PROCEDURA 4: Zamrażanie Karnetu
-- Co robi: Zmienia status na 'Zamrozony' i przesuwa datę wygaśnięcia (max 30 dni)

CREATE OR REPLACE PROCEDURE sp_zamroz_karnet(
    p_id_karnetu INT,
    p_liczba_dni INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_aktualny_status karnet_status;
    v_data_wygasniecia DATE;
BEGIN
    -- Sprawdzenie aktualnego statusu
    SELECT status, data_wygasniecia INTO v_aktualny_status, v_data_wygasniecia
    FROM Sprzedane_Karnety
    WHERE id_sprzedanego_karnetu = p_id_karnetu;

    IF v_aktualny_status IS NULL THEN
        RAISE EXCEPTION 'Karnet o ID % nie istnieje!', p_id_karnetu;
    END IF;

    IF v_aktualny_status != 'Aktywny' THEN
        RAISE EXCEPTION 'Można zamrozić tylko aktywny karnet! Obecny status: %', v_aktualny_status;
    END IF;

    IF p_liczba_dni <= 0 THEN
        RAISE EXCEPTION 'Liczba dni zamrożenia musi być większa od 0!';
    END IF;

    IF p_liczba_dni > 30 THEN
        RAISE EXCEPTION 'Maksymalny okres zamrożenia to 30 dni!';
    END IF;

    -- Zamrożenie karnetu i przesunięcie daty wygaśnięcia
    UPDATE Sprzedane_Karnety
    SET status = 'Zamrozony',
        data_wygasniecia = v_data_wygasniecia + (p_liczba_dni || ' days')::INTERVAL
    WHERE id_sprzedanego_karnetu = p_id_karnetu;

    RAISE NOTICE 'Karnet ID % zamrożony na % dni. Nowa data wygaśnięcia: %', 
        p_id_karnetu, p_liczba_dni, v_data_wygasniecia + (p_liczba_dni || ' days')::INTERVAL;
END;
$$;

-- PROCEDURA 5: Odmrażanie Karnetu
-- Co robi: Przywraca status 'Aktywny' dla zamrożonego karnetu

CREATE OR REPLACE PROCEDURE sp_odmroz_karnet(
    p_id_karnetu INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_aktualny_status karnet_status;
BEGIN
    SELECT status INTO v_aktualny_status
    FROM Sprzedane_Karnety
    WHERE id_sprzedanego_karnetu = p_id_karnetu;

    IF v_aktualny_status IS NULL THEN
        RAISE EXCEPTION 'Karnet o ID % nie istnieje!', p_id_karnetu;
    END IF;

    IF v_aktualny_status != 'Zamrozony' THEN
        RAISE EXCEPTION 'Można odmrozić tylko zamrożony karnet! Obecny status: %', v_aktualny_status;
    END IF;

    UPDATE Sprzedane_Karnety
    SET status = 'Aktywny'
    WHERE id_sprzedanego_karnetu = p_id_karnetu;

    RAISE NOTICE 'Karnet ID % został odmrożony i jest teraz aktywny.', p_id_karnetu;
END;
$$;

-- PROCEDURA 6: Automatyczna Aktywacja Karnetów
-- Co robi: Aktywuje karnety z przyszłą datą aktywacji, gdy nadejdzie ich termin

CREATE OR REPLACE PROCEDURE sp_aktywuj_karnety()
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE Sprzedane_Karnety
    SET status = 'Aktywny'
    WHERE status = 'Zamrozony' 
      AND data_aktywacji <= CURRENT_DATE
      AND data_wygasniecia >= CURRENT_DATE;
    
    RAISE NOTICE 'Aktywowano karnety z dzisiejszą datą aktywacji.';
END;
$$;