# Kurs DevOps Wakacyjnego Wyzwania KN Solvro 2026 - Lista 6

## Zadanie 0 - Przygotowanie środowiska

Przygotuj jedną maszynę wirtualną z dockerem lub podmanem, oraz nginxem.

## Zadanie 1 - Instalacja Prometheusa i Grafany

Zainstaluj prometheus na hostcie i grafanę w kontenerze.
Skonfiguruj nginxa jako reverse proxy dla grafany.

Skonfiguruj grafanę, łącząc ją z zainstalowanym prometheusem.
Zweryfikuj działanie połączenia.

## Zadanie 2 - Eksportery

Zainstaluj prometheus-node-exporter oraz prometheus-nginx-exporter.

Skonfiguruj nginxa tak, by wystawiał swoje statystyki do zbierania przez prometheus-nginx-exporter.
Skonfiguruj prometheus-nginx-exporter.

Dodaj eksportery do konfiguracji prometheusa i przeładuj ją.
Zweryfikuj działanie zbierania metryk za pośrednictwem grafany - sprawdź metrykę `up`.

## Zadanie 3 - Dashboardy

Zaimportuj dashboard "Node Exporter Full".
Zweryfikuj działanie.

Utwórz nowy dashboard dla eksportera nginx.
Utwórz co najmniej wykres obsłużonych żądań na sekundę.

> [!TIP]
> Użyj strony Explore na grafanie, by dowiedzieć więcej o dostępnych metrykach

## Zadanie 4 - Alerty

Skonfiguruj powiadamianie poprzez discorda na swój prywatny serwer.

Skonfiguruj jakąś regułę ostrzegania, w oparciu o zbierane metryki.
Zademonstruj działanie reguły.

> [!TIP]
> Pomysły na dobre reguły ostrzegania znajdują się pod koniec prezentacji z tego tygodnia.

> [!TIP]
> Reguły domyślnie mają pewne opóźnienie od zaistnienia sytuacji alarmowej, do wysłania pierwszych powiadomień.
> By wywołać alarm, może być wymagane utrzymanie sytuacji alarmowej przez okres od 30s do kilku minut.
>
> Możesz spróbować zmniejszyć opóźnienie zmieniając parametry reguły ostrzegania.
> Miej jednak na uwadze, że może to doprowadzić do nadmiernych fałszywych alarmów!
