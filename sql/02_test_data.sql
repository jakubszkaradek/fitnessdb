-- Dane testowe 
-- Walita PLN
-- 1 PLN = 1 pkt 
-- Typy karnetow 
INSERT INTO Typy_Karnetow (nazwa, cena, dlugosc_w_dniach, liczba_wejsc, opis, punkty_lojalnosciowe_za_zakup) VALUES 
('Standard Open Miesięczny', 159.00, 30, NULL, 'Nielimitowany dostęp 24/7, siłownia + fitness. Najpopularniejszy wybór.', 160),
('Student Open', 109.00, 30, NULL, 'Zniżka studencka (-30%). Wymagana legitymacja. Dostęp do 16:00.', 110),
('Karnet Poranny (Early Bird)', 89.00, 30, NULL, 'Wstęp w godzinach 06:00 - 14:00. Opcja budżetowa.', 90),
('Karnet 8 Wejść', 139.00, 60, 8, 'Ważny 2 miesiące. Idealny dla trenujących 1x w tygodniu.', 140),
('Roczny Prepaid (VIP)', 1199.00, 365, NULL, 'Płatność z góry za rok. Oszczędzasz 700 zł rocznie. W cenie ręcznik i woda.', 1500),
('Wejściówka Jednorazowa', 39.00, 1, 1, 'Jeden trening bez zobowiązań.', 10);

-- Nagrody
INSERT INTO Nagrody (nazwa, koszt_w_punktach, opis) VALUES 
-- Drobne nagrody 
('Baton Proteinowy (Matrix Pro)', 250, 'Szybka dawka białka po treningu. Różne smaki.'),
('Napój Izotoniczny (0.7L)', 150, 'Nawodnienie podczas treningu.'),
('Shake Waniliowy (30g WPC)', 300, 'Świeżo robiony shake białkowy w recepcji.'),
('Bomba Przedtreningowa (Shot)', 200, 'Kofeina i Beta-alanina dla pobudzenia przed rekordem.'),

-- Średnie nagrody (Cel na 3-6 miesięcy)
('Ręcznik Treningowy z Logo', 1200, 'Szybkoschnący ręcznik z mikrofibry.'),
('Opaska na telefon (Armband)', 1500, 'Wygodne bieganie z telefonem.'),
('Serwatka Białkowa (1kg WPC)', 2500, 'Opakowanie białka do domu. Smak do wyboru.'),

-- Nagrody Premium (Cel roczny / Lojalnościowy)
('Torba Sportowa Premium', 4500, 'Pojemna torba z przegrodą na buty.'),
('Trening Personalny (60 min)', 5000, 'Indywidualna sesja z trenerem o wartości 150 zł.'),
('Zniżka -50% na kolejny miesiąc', 6000, 'Zapłać połowę za następny karnet.');

-- Typy zajec

INSERT INTO Typy_Zajec (nazwa, opis, punkty_za_obecnosc, maksymalny_limit_miejsc) VALUES 
('CrossFit WOD', 'Trening funkcjonalny o wysokiej intensywności. Budowanie siły i kondycji.', 25, 12),
('Joga Vinyasa', 'Dynamiczna joga łącząca ruch z oddechem. Redukcja stresu.', 20, 15),
('Zdrowy Kręgosłup', 'Zajęcia profilaktyczne, wzmacnianie mięśni głębokich. Dla siedzących.', 15, 20),
('Zumba Fitness', 'Połączenie tańca latynoamerykańskiego z fitnessem. Spalanie kalorii.', 20, 25),
('Trening Obwodowy', 'Stacje ćwiczeniowe na maszynach. Idealne dla początkujących.', 15, 15),
('Siłownia (Wejście Wolne)', 'Indywidualny trening bez instruktora.', 5, 100);

-- Trenerzy testowi
INSERT INTO Trenerzy (imie, nazwisko, specjalizacja, email) VALUES 
('Piotr', 'Kowalski', 'CrossFit & Dwubój', 'piotr.kow@fitness.pl'),
('Anna', 'Nowak', 'Joga & Pilates', 'anna.now@fitness.pl'),
('Marek', 'Stanowski', 'Kulturystyka & Dieta', 'marek.stan@fitness.pl'),
('Kasia', 'Bąk', 'Zumba & Taniec', 'kasia.bak@fitness.pl');

-- klienci testowi
INSERT INTO Klienci (imie, nazwisko, email, telefon, data_rejestracji) VALUES 
('Jan', 'Nowak', 'jan.now@gmail.com', '500100100', CURRENT_DATE - INTERVAL '3 month'),
('Maria', 'Kowalczyk', 'maria.kow@onet.pl', '600200200', CURRENT_DATE - INTERVAL '1 month'),
('Tomasz', 'Kowalski', 'tomek.kow@wp.pl', '700300300', CURRENT_DATE - INTERVAL '10 day'),
('Julia', 'Lewandowska', 'julia.lew@gmail.com', '800400400', CURRENT_DATE);

-- symulacja historii
INSERT INTO Sprzedane_Karnety (id_klienta, id_typu_karnetu, cena_transakcyjna, data_zakupu, data_aktywacji, data_wygasniecia, status) 
VALUES 
(1, 1, 159.00, CURRENT_DATE - INTERVAL '10 day', CURRENT_DATE - INTERVAL '10 day', CURRENT_DATE + INTERVAL '20 day', 'Aktywny');

-- Dodajemy wstępne punkty za zakup tego karnetu 
INSERT INTO Punkty_Lojalnosciowe (id_klienta, ilosc_punktow, zrodlo, id_sprzedanego_karnetu, opis)
VALUES
(1, 160, 'zakup', 1, 'Punkty startowe za karnet');
