-- WIDOK 1: Pełny Grafik Zajęć 
-- Co robi: Łączy Harmonogram z Trenerem i Typem Zajęć + liczy wolne miejsca

CREATE OR REPLACE VIEW vw_grafik_zajec_full AS
SELECT 
    h.id_harmonogramu,
    tz.nazwa AS nazwa_zajec,
    t.imie || ' ' || t.nazwisko AS trener,
    h.data_godzina_rozpoczecia,
    to_char(h.data_godzina_rozpoczecia, 'Day') AS dzien_tygodnia, 
    h.czas_trwania_min,
    h.limit_miejsc,
    (SELECT COUNT(*) FROM Zapisy_Na_Zajecia z WHERE z.id_harmonogramu = h.id_harmonogramu AND z.status_obecnosci != 'Anulowany') AS zapisanych_osob,
    h.limit_miejsc - (SELECT COUNT(*) FROM Zapisy_Na_Zajecia z WHERE z.id_harmonogramu = h.id_harmonogramu AND z.status_obecnosci != 'Anulowany') AS wolne_miejsca
FROM Harmonogram_Zajec h
JOIN Typy_Zajec tz ON h.id_typu_zajec = tz.id_typu_zajec
JOIN Trenerzy t ON h.id_trenera = t.id_trenera
ORDER BY h.data_godzina_rozpoczecia;

-- WIDOK 2: Aktywni Klienci 
-- Co robi: Pokazuje tylko tych, którzy mają ważny, opłacony karnet

CREATE OR REPLACE VIEW vw_aktywni_klienci_karnety AS
SELECT 
    k.id_klienta,
    k.imie,
    k.nazwisko,
    k.email,
    tk.nazwa AS typ_karnetu,
    sk.data_zakupu,
    sk.data_wygasniecia,
    sk.status,
    (sk.data_wygasniecia - CURRENT_DATE) AS dni_do_konca
FROM Klienci k
JOIN Sprzedane_Karnety sk ON k.id_klienta = sk.id_klienta
JOIN Typy_Karnetow tk ON sk.id_typu_karnetu = tk.id_typu_karnetu
WHERE sk.status = 'Aktywny' 
  AND sk.data_wygasniecia >= CURRENT_DATE;

-- WIDOK 3: Portfel Punktowy Klienta (Dla aplikacji mobilnej)
-- Co robi: Historia transakcji punktowych 

CREATE OR REPLACE VIEW vw_historia_punktow_klienta AS
SELECT 
    pl.id_transakcji,
    pl.id_klienta,
    pl.data_transakcji,
    pl.ilosc_punktow,
    pl.zrodlo, 
    pl.opis,
    SUM(pl.ilosc_punktow) OVER (PARTITION BY pl.id_klienta ORDER BY pl.data_transakcji) AS saldo_po_transakcji
FROM Punkty_Lojalnosciowe pl
ORDER BY pl.data_transakcji DESC;

-- WIDOK 4: Raport Finansowy Miesięczny 
-- Co robi: Grupuje przychody po miesiącach i metodach płatności

CREATE OR REPLACE VIEW vw_raport_finansowy AS
SELECT 
    to_char(p.data_platnosci, 'YYYY-MM') AS miesiac,
    p.metoda_platnosci,
    COUNT(*) AS liczba_transakcji,
    SUM(p.kwota) AS przychod_calkowity
FROM Platnosci p
WHERE p.status_platnosci = 'Opłacona'
GROUP BY 1, 2
ORDER BY 1 DESC, 3 DESC;
-- WIDOK 5: DASHBOARD GŁÓWNY 
-- Co robi: Zwraca jeden wiersz z najważniejszymi liczbami dla managera

CREATE OR REPLACE VIEW vw_dashboard_kpi AS
SELECT
    -- 1. Finanse
    (SELECT COALESCE(SUM(kwota), 0) 
     FROM Platnosci 
     WHERE data_platnosci >= DATE_TRUNC('month', CURRENT_TIMESTAMP)) AS przychod_ten_miesiac,

    -- 2. Sprzedaż
    (SELECT COUNT(*) 
     FROM Sprzedane_Karnety 
     WHERE status = 'Aktywny' AND data_wygasniecia >= CURRENT_DATE) AS liczba_aktywnych_karnetow,

    -- 3. Operacje
    (SELECT COUNT(*) 
     FROM Harmonogram_Zajec 
     WHERE DATE(data_godzina_rozpoczecia) = CURRENT_DATE) AS liczba_zajec_dzisiaj,

    -- 4. Frekwencja
    (SELECT COUNT(*) 
     FROM Zapisy_Na_Zajecia z
     JOIN Harmonogram_Zajec h ON z.id_harmonogramu = h.id_harmonogramu
     WHERE DATE(h.data_godzina_rozpoczecia) = CURRENT_DATE 
       AND z.status_obecnosci != 'Anulowany') AS zapisani_na_dzis,

    -- 5. Nowi klienci
    (SELECT COUNT(*) 
     FROM Klienci 
     WHERE data_rejestracji >= DATE_TRUNC('month', CURRENT_DATE)) AS nowi_klienci_w_tym_miesiacu,

    -- 6. Lojalność
    (SELECT COALESCE(SUM(ilosc_punktow), 0) 
     FROM Punkty_Lojalnosciowe) AS punkty_w_obiegu_suma;

-- WIDOK 6: Raport Efektywności Trenerów 
-- Co robi: Liczy ile zajęć poprowadził trener i ilu łącznie ludzi na nie przyszło

CREATE OR REPLACE VIEW vw_oblozenie_trenerow AS
SELECT 
    t.id_trenera,
    t.imie,
    t.nazwisko,
    t.specjalizacja,
    COUNT(DISTINCT h.id_harmonogramu) AS liczba_zajec,
    COUNT(z.id_zapisu) FILTER (WHERE z.status_obecnosci != 'Anulowany') AS suma_uczestnikow,
    ROUND(
        CASE WHEN COUNT(DISTINCT h.id_harmonogramu) > 0 
             THEN COUNT(z.id_zapisu)::NUMERIC / COUNT(DISTINCT h.id_harmonogramu) 
             ELSE 0 
        END, 1
    ) AS srednia_na_zajecia
FROM Trenerzy t
LEFT JOIN Harmonogram_Zajec h ON t.id_trenera = h.id_trenera
LEFT JOIN Zapisy_Na_Zajecia z ON h.id_harmonogramu = z.id_harmonogramu
GROUP BY t.id_trenera, t.imie, t.nazwisko, t.specjalizacja
ORDER BY suma_uczestnikow DESC;
