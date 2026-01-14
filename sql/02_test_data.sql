-- Dane testowe dla FitnessDB
-- Waluta: PLN | 1 PLN ≈ 1 pkt lojalnościowy
-- ============================================================

-- ============================================================
-- 1. SŁOWNIKI (Typy Karnetów, Nagrody, Typy Zajęć)
-- ============================================================

-- Typy karnetów (6 opcji)
INSERT INTO Typy_Karnetow (nazwa, cena, dlugosc_w_dniach, liczba_wejsc, opis, punkty_lojalnosciowe_za_zakup) VALUES 
('Standard Open Miesięczny', 159.00, 30, NULL, 'Nielimitowany dostęp 24/7, siłownia + fitness. Najpopularniejszy wybór.', 160),
('Student Open', 109.00, 30, NULL, 'Zniżka studencka (-30%). Wymagana legitymacja. Dostęp do 16:00.', 110),
('Karnet Poranny (Early Bird)', 89.00, 30, NULL, 'Wstęp w godzinach 06:00 - 14:00. Opcja budżetowa.', 90),
('Karnet 8 Wejść', 139.00, 60, 8, 'Ważny 2 miesiące. Idealny dla trenujących 1x w tygodniu.', 140),
('Roczny Prepaid (VIP)', 1199.00, 365, NULL, 'Płatność z góry za rok. Oszczędzasz 700 zł rocznie. W cenie ręcznik i woda.', 1500),
('Wejściówka Jednorazowa', 39.00, 1, 1, 'Jeden trening bez zobowiązań.', 10);

-- Nagrody (10 opcji: drobne, średnie, premium)
INSERT INTO Nagrody (nazwa, koszt_w_punktach, opis) VALUES 
-- Drobne nagrody (do zdobycia po 2-3 treningach)
('Baton Proteinowy (Matrix Pro)', 250, 'Szybka dawka białka po treningu. Różne smaki.'),
('Napój Izotoniczny (0.7L)', 150, 'Nawodnienie podczas treningu.'),
('Shake Waniliowy (30g WPC)', 300, 'Świeżo robiony shake białkowy w recepcji.'),
('Bomba Przedtreningowa (Shot)', 200, 'Kofeina i Beta-alanina dla pobudzenia przed rekordem.'),
-- Średnie nagrody (cel na 3-6 miesięcy)
('Ręcznik Treningowy z Logo', 1200, 'Szybkoschnący ręcznik z mikrofibry.'),
('Opaska na telefon (Armband)', 1500, 'Wygodne bieganie z telefonem.'),
('Serwatka Białkowa (1kg WPC)', 2500, 'Opakowanie białka do domu. Smak do wyboru.'),
-- Nagrody Premium (cel roczny / lojalnościowy)
('Torba Sportowa Premium', 4500, 'Pojemna torba z przegrodą na buty.'),
('Trening Personalny (60 min)', 5000, 'Indywidualna sesja z trenerem o wartości 150 zł.'),
('Zniżka -50% na kolejny miesiąc', 6000, 'Zapłać połowę za następny karnet.');

-- Typy zajęć (6 rodzajów)
INSERT INTO Typy_Zajec (nazwa, opis, punkty_za_obecnosc, maksymalny_limit_miejsc) VALUES 
('CrossFit WOD', 'Trening funkcjonalny o wysokiej intensywności. Budowanie siły i kondycji.', 25, 12),
('Joga Vinyasa', 'Dynamiczna joga łącząca ruch z oddechem. Redukcja stresu.', 20, 15),
('Zdrowy Kręgosłup', 'Zajęcia profilaktyczne, wzmacnianie mięśni głębokich. Dla siedzących.', 15, 20),
('Zumba Fitness', 'Połączenie tańca latynoamerykańskiego z fitnessem. Spalanie kalorii.', 20, 25),
('Trening Obwodowy', 'Stacje ćwiczeniowe na maszynach. Idealne dla początkujących.', 15, 15),
('Siłownia (Wejście Wolne)', 'Indywidualny trening bez instruktora.', 5, 100);

-- ============================================================
-- 2. PERSONEL (Trenerzy)
-- ============================================================

INSERT INTO Trenerzy (imie, nazwisko, specjalizacja, email, czy_aktywny) VALUES 
('Piotr', 'Kowalski', 'CrossFit & Dwubój', 'piotr.kow@fitness.pl', TRUE),
('Anna', 'Nowak', 'Joga & Pilates', 'anna.now@fitness.pl', TRUE),
('Marek', 'Stanowski', 'Kulturystyka & Dieta', 'marek.stan@fitness.pl', TRUE),
('Kasia', 'Bąk', 'Zumba & Taniec', 'kasia.bak@fitness.pl', TRUE),
-- Dodatkowi trenerzy
('Michał', 'Wiśniewski', 'Trening Funkcjonalny', 'michal.wis@fitness.pl', TRUE),
('Ewa', 'Zielińska', 'Rehabilitacja & Stretching', 'ewa.ziel@fitness.pl', FALSE); -- Nieaktywny (urlop macierzyński)

-- ============================================================
-- 3. KLIENCI (10 osób o różnej historii)
-- ============================================================

INSERT INTO Klienci (imie, nazwisko, email, telefon, data_rejestracji, czy_aktywny) VALUES 
-- Klienci długoterminowi (ponad rok)
('Jan', 'Nowak', 'jan.now@gmail.com', '500100100', CURRENT_DATE - INTERVAL '14 month', TRUE),
('Maria', 'Kowalczyk', 'maria.kow@onet.pl', '600200200', CURRENT_DATE - INTERVAL '10 month', TRUE),
-- Klienci średnioterminowi (kilka miesięcy)
('Tomasz', 'Kowalski', 'tomek.kow@wp.pl', '700300300', CURRENT_DATE - INTERVAL '3 month', TRUE),
('Julia', 'Lewandowska', 'julia.lew@gmail.com', '800400400', CURRENT_DATE - INTERVAL '2 month', TRUE),
('Adam', 'Mazur', 'adam.mazur@gmail.com', '501501501', CURRENT_DATE - INTERVAL '45 day', TRUE),
-- Nowi klienci (< miesiąc)
('Karolina', 'Wójcik', 'karolina.w@wp.pl', '602602602', CURRENT_DATE - INTERVAL '7 day', TRUE),
('Bartosz', 'Dąbrowski', 'bartosz.d@onet.pl', '703703703', CURRENT_DATE - INTERVAL '3 day', TRUE),
('Alicja', 'Szymańska', 'alicja.sz@gmail.com', '804804804', CURRENT_DATE, TRUE),
-- Klient nieaktywny (do testów soft-delete)
('Robert', 'Piotrowski', 'robert.piotr@wp.pl', '905905905', CURRENT_DATE - INTERVAL '8 month', FALSE),
-- Klient usunięty logicznie
('Monika', 'Jankowska', 'monika.j@onet.pl', '106106106', CURRENT_DATE - INTERVAL '1 year', FALSE);

-- Aktualizacja danych dla usuniętego klienta (ID=10)
UPDATE Klienci SET data_deaktywacji = CURRENT_DATE - INTERVAL '2 month', 
                   data_usuniecia = CURRENT_TIMESTAMP - INTERVAL '1 month'
WHERE email = 'monika.j@onet.pl';

-- ============================================================
-- 4. HARMONOGRAM ZAJĘĆ (przeszłe, dzisiejsze, przyszłe)
-- ============================================================

INSERT INTO Harmonogram_Zajec (id_typu_zajec, id_trenera, data_godzina_rozpoczecia, czas_trwania_min, limit_miejsc) VALUES 
-- Zajęcia z PRZESZŁOŚCI (do testów historycznych i punktów za obecność)
(1, 1, CURRENT_TIMESTAMP - INTERVAL '7 day' + TIME '09:00', 60, 12),   -- CrossFit - tydzień temu
(2, 2, CURRENT_TIMESTAMP - INTERVAL '7 day' + TIME '11:00', 75, 15),   -- Joga - tydzień temu
(4, 4, CURRENT_TIMESTAMP - INTERVAL '5 day' + TIME '18:00', 60, 20),   -- Zumba - 5 dni temu
(3, 5, CURRENT_TIMESTAMP - INTERVAL '3 day' + TIME '10:00', 45, 15),   -- Zdrowy Kręgosłup - 3 dni temu
(1, 1, CURRENT_TIMESTAMP - INTERVAL '2 day' + TIME '09:00', 60, 12),   -- CrossFit - przedwczoraj

-- Zajęcia DZISIAJ (do testów dashboardu)
(2, 2, CURRENT_DATE + TIME '08:00', 75, 15),   -- Joga poranną
(5, 3, CURRENT_DATE + TIME '12:00', 50, 15),   -- Trening Obwodowy
(4, 4, CURRENT_DATE + TIME '18:00', 60, 25),   -- Zumba wieczorna

-- Zajęcia w PRZYSZŁOŚCI (do testów zapisów)
(1, 1, CURRENT_DATE + INTERVAL '1 day' + TIME '09:00', 60, 12),   -- CrossFit jutro
(3, 5, CURRENT_DATE + INTERVAL '2 day' + TIME '10:00', 45, 20),   -- Zdrowy Kręgosłup pojutrze
(2, 2, CURRENT_DATE + INTERVAL '3 day' + TIME '17:00', 75, 15),   -- Joga za 3 dni
(4, 4, CURRENT_DATE + INTERVAL '7 day' + TIME '19:00', 60, 25);   -- Zumba za tydzień

-- ============================================================
-- 5. SPRZEDANE KARNETY (różnorodne scenariusze)
-- ============================================================

-- UWAGA: Triggery automatycznie dodają punkty przy INSERT, więc nie dodajemy ich ręcznie

-- Klient 1 (Jan) - Weteran, aktywny karnet Open
INSERT INTO Sprzedane_Karnety (id_klienta, id_typu_karnetu, cena_transakcyjna, data_zakupu, data_aktywacji, data_wygasniecia, status) 
VALUES (1, 1, 159.00, CURRENT_DATE - INTERVAL '10 day', CURRENT_DATE - INTERVAL '10 day', CURRENT_DATE + INTERVAL '20 day', 'Aktywny');

-- Klient 2 (Maria) - Karnet studencki aktywny
INSERT INTO Sprzedane_Karnety (id_klienta, id_typu_karnetu, cena_transakcyjna, data_zakupu, data_aktywacji, data_wygasniecia, status) 
VALUES (2, 2, 109.00, CURRENT_DATE - INTERVAL '15 day', CURRENT_DATE - INTERVAL '15 day', CURRENT_DATE + INTERVAL '15 day', 'Aktywny');

-- Klient 3 (Tomasz) - Karnet 8 wejść, częściowo wykorzystany
INSERT INTO Sprzedane_Karnety (id_klienta, id_typu_karnetu, cena_transakcyjna, data_zakupu, data_aktywacji, data_wygasniecia, status, liczba_wykorzystanych_wejsc) 
VALUES (3, 4, 139.00, CURRENT_DATE - INTERVAL '20 day', CURRENT_DATE - INTERVAL '20 day', CURRENT_DATE + INTERVAL '40 day', 'Aktywny', 3);

-- Klient 4 (Julia) - Karnet ZAMROŻONY (testowanie zamrażania)
INSERT INTO Sprzedane_Karnety (id_klienta, id_typu_karnetu, cena_transakcyjna, data_zakupu, data_aktywacji, data_wygasniecia, status, zamrozony_do) 
VALUES (4, 1, 159.00, CURRENT_DATE - INTERVAL '25 day', CURRENT_DATE - INTERVAL '25 day', CURRENT_DATE + INTERVAL '15 day', 'Zamrozony', CURRENT_DATE + INTERVAL '5 day');

-- Klient 5 (Adam) - Karnet poranny aktywny
INSERT INTO Sprzedane_Karnety (id_klienta, id_typu_karnetu, cena_transakcyjna, data_zakupu, data_aktywacji, data_wygasniecia, status) 
VALUES (5, 3, 89.00, CURRENT_DATE - INTERVAL '5 day', CURRENT_DATE - INTERVAL '5 day', CURRENT_DATE + INTERVAL '25 day', 'Aktywny');

-- Klient 6 (Karolina) - Karnet z PRZYSZŁĄ datą aktywacji (testowanie przyszłej aktywacji)
INSERT INTO Sprzedane_Karnety (id_klienta, id_typu_karnetu, cena_transakcyjna, data_zakupu, data_aktywacji, data_wygasniecia, status) 
VALUES (6, 1, 159.00, CURRENT_DATE, CURRENT_DATE + INTERVAL '7 day', CURRENT_DATE + INTERVAL '37 day', 'Zamrozony');

-- Klient 7 (Bartosz) - Nowy klient, wejściówka jednorazowa (wykorzystana)
INSERT INTO Sprzedane_Karnety (id_klienta, id_typu_karnetu, cena_transakcyjna, data_zakupu, data_aktywacji, data_wygasniecia, status, liczba_wykorzystanych_wejsc) 
VALUES (7, 6, 39.00, CURRENT_DATE - INTERVAL '2 day', CURRENT_DATE - INTERVAL '2 day', CURRENT_DATE - INTERVAL '1 day', 'Wygasły', 1);

-- Klient 8 (Alicja) - Bardzo świeży, karnet Open aktywny
INSERT INTO Sprzedane_Karnety (id_klienta, id_typu_karnetu, cena_transakcyjna, data_zakupu, data_aktywacji, data_wygasniecia, status) 
VALUES (8, 1, 159.00, CURRENT_DATE, CURRENT_DATE, CURRENT_DATE + INTERVAL '30 day', 'Aktywny');

-- Karnet WYGASŁY dla klienta 1 (historia)
INSERT INTO Sprzedane_Karnety (id_klienta, id_typu_karnetu, cena_transakcyjna, data_zakupu, data_aktywacji, data_wygasniecia, status) 
VALUES (1, 1, 159.00, CURRENT_DATE - INTERVAL '60 day', CURRENT_DATE - INTERVAL '60 day', CURRENT_DATE - INTERVAL '30 day', 'Wygasły');

-- ============================================================
-- 6. PŁATNOŚCI (dla każdego karnetu)
-- ============================================================

INSERT INTO Platnosci (id_sprzedanego_karnetu, kwota, data_platnosci, metoda_platnosci, status_platnosci) VALUES 
(1, 159.00, CURRENT_TIMESTAMP - INTERVAL '10 day', 'Karta', 'Opłacona'),
(2, 109.00, CURRENT_TIMESTAMP - INTERVAL '15 day', 'Blik', 'Opłacona'),
(3, 139.00, CURRENT_TIMESTAMP - INTERVAL '20 day', 'Przelew', 'Opłacona'),
(4, 159.00, CURRENT_TIMESTAMP - INTERVAL '25 day', 'Gotowka', 'Opłacona'),
(5, 89.00, CURRENT_TIMESTAMP - INTERVAL '5 day', 'Karta', 'Opłacona'),
(6, 159.00, CURRENT_TIMESTAMP, 'Blik', 'Opłacona'),
(7, 39.00, CURRENT_TIMESTAMP - INTERVAL '2 day', 'Gotowka', 'Opłacona'),
(8, 159.00, CURRENT_TIMESTAMP, 'Karta', 'Opłacona'),
(9, 159.00, CURRENT_TIMESTAMP - INTERVAL '60 day', 'Przelew', 'Opłacona');

-- ============================================================
-- 7. ZAPISY NA ZAJĘCIA i OBECNOŚCI
-- ============================================================

-- Zapisy na zajęcia z PRZESZŁOŚCI (z oznaczoną obecnością - triggery przyznają punkty)
INSERT INTO Zapisy_Na_Zajecia (id_klienta, id_harmonogramu, data_zapisu, status_obecnosci) VALUES 
-- CrossFit tydzień temu (ID harmonogramu = 1)
(1, 1, CURRENT_TIMESTAMP - INTERVAL '8 day', 'Obecny'),
(3, 1, CURRENT_TIMESTAMP - INTERVAL '8 day', 'Obecny'),
(5, 1, CURRENT_TIMESTAMP - INTERVAL '8 day', 'Nieobecny'),

-- Joga tydzień temu (ID harmonogramu = 2)
(2, 2, CURRENT_TIMESTAMP - INTERVAL '8 day', 'Obecny'),
(1, 2, CURRENT_TIMESTAMP - INTERVAL '8 day', 'Obecny'),

-- Zumba 5 dni temu (ID harmonogramu = 3)
(2, 3, CURRENT_TIMESTAMP - INTERVAL '6 day', 'Obecny'),
(5, 3, CURRENT_TIMESTAMP - INTERVAL '6 day', 'Obecny'),

-- Zdrowy Kręgosłup 3 dni temu (ID harmonogramu = 4)
(1, 4, CURRENT_TIMESTAMP - INTERVAL '4 day', 'Obecny'),
(3, 4, CURRENT_TIMESTAMP - INTERVAL '4 day', 'Anulowany'),

-- CrossFit przedwczoraj (ID harmonogramu = 5)
(1, 5, CURRENT_TIMESTAMP - INTERVAL '3 day', 'Obecny'),
(3, 5, CURRENT_TIMESTAMP - INTERVAL '3 day', 'Obecny'),
(5, 5, CURRENT_TIMESTAMP - INTERVAL '3 day', 'Obecny');

-- Zapisy na zajęcia DZISIEJSZE (statystyki dashboardu)
INSERT INTO Zapisy_Na_Zajecia (id_klienta, id_harmonogramu, data_zapisu, status_obecnosci) VALUES 
-- Joga poranna dziś (ID harmonogramu = 6)
(2, 6, CURRENT_TIMESTAMP - INTERVAL '1 day', 'Nieobecny'),
(1, 6, CURRENT_TIMESTAMP - INTERVAL '1 day', 'Nieobecny'),
(8, 6, CURRENT_TIMESTAMP - INTERVAL '2 hour', 'Nieobecny'),

-- Trening Obwodowy dziś (ID harmonogramu = 7)
(3, 7, CURRENT_TIMESTAMP - INTERVAL '1 day', 'Nieobecny'),
(5, 7, CURRENT_TIMESTAMP - INTERVAL '12 hour', 'Nieobecny'),

-- Zumba wieczorna dziś (ID harmonogramu = 8)
(2, 8, CURRENT_TIMESTAMP - INTERVAL '2 day', 'Nieobecny'),
(5, 8, CURRENT_TIMESTAMP - INTERVAL '1 day', 'Nieobecny');

-- Zapisy na zajęcia PRZYSZŁE
INSERT INTO Zapisy_Na_Zajecia (id_klienta, id_harmonogramu, data_zapisu, status_obecnosci) VALUES 
-- CrossFit jutro (ID harmonogramu = 9)
(1, 9, CURRENT_TIMESTAMP - INTERVAL '1 day', 'Nieobecny'),
(3, 9, CURRENT_TIMESTAMP - INTERVAL '6 hour', 'Nieobecny'),
(5, 9, CURRENT_TIMESTAMP, 'Nieobecny'),
(8, 9, CURRENT_TIMESTAMP, 'Nieobecny');

-- ============================================================
-- 8. WYMIANA PUNKTÓW NA NAGRODY (dla klientów z dużą ilością punktów)
-- ============================================================

-- Jan (ID=1) ma dużo punktów (karnet + obecności), wymienia na średnią nagrodę
-- Triggery automatycznie odjęły punkty przy INSERT
INSERT INTO Klienci_Nagrody (id_klienta, id_nagrody, koszt_punktowy_w_momencie_zakupu, data_kupna, czy_wykorzystana) VALUES 
(1, 1, 250, CURRENT_DATE - INTERVAL '5 day', TRUE),  -- Baton proteinowy (wykorzystany)
(1, 2, 150, CURRENT_DATE - INTERVAL '3 day', FALSE); -- Napój izotoniczny (do odbioru)

-- Maria (ID=2) wymienia drobną nagrodę
INSERT INTO Klienci_Nagrody (id_klienta, id_nagrody, koszt_punktowy_w_momencie_zakupu, data_kupna, czy_wykorzystana) VALUES 
(2, 3, 300, CURRENT_DATE - INTERVAL '1 day', FALSE); -- Shake (do odbioru)

-- ============================================================
-- 9. DODATKOWE PUNKTY BONUSOWE (promocje, eventy)
-- ============================================================

-- Punkty powitalne dla nowego klienta (promocyjna akcja)
INSERT INTO Punkty_Lojalnosciowe (id_klienta, ilosc_punktow, zrodlo, opis) VALUES 
(8, 100, 'bonus', 'Punkty powitalne za rejestrację w styczniu 2026');

-- Punkty za polecenie znajomego
INSERT INTO Punkty_Lojalnosciowe (id_klienta, ilosc_punktow, zrodlo, opis) VALUES 
(1, 200, 'bonus', 'Bonus za polecenie nowego klienta (Alicja)');

-- ============================================================
-- KONIEC DANYCH TESTOWYCH
-- ============================================================
