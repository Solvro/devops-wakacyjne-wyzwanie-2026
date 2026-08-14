# Kurs DevOps Wakacyjnego Wyzwania KN Solvro 2026 - Lista 1

## Zadanie 0

Korzystając ze skryptu `./tools/addrgen.py` wygeneruj adresy sieci do wykorzystania w zadaniu.

## Zadanie 1 - Podział na podsieci w IPv4

Podziel swoją sieć IPv4 na podsieci o następujących liczbach urządzeń:

- 892 urządzenia
- 512 urządzeń
- 150 urządzeń
- 64 urządzenia
- 14 urządzeń
- 2 urządzenia
- 2 urządzenia
- 2 urządzenia
- 2 urządzenia

Dla każdej podsieci zapisz proponowane adresy sieci, maski podsieci (w formacie IPv4 lub CIDR), pierwsze i ostatnie używalne adresy, oraz adresy rozgłoszeniowe

## Zadanie 2 - 2 komputery

- Z wygenerowanego przez siebie zakresu IPv4 wydziel podsieć odpowiednią dla min. 14 urządzeń.
- Korzystając ze skryptu `./tools/netns.sh` utwórz dwie przestrzenie sieciowe.
  - Będą symulowały urządzenia końcowe - sugerowana nazwa `pc1`, `pc2`
- Połącz przestrzenie wirtualnym kablem
- W każdej przestrzeni skonfiguruj adres na wirtualnym interfejsie i go włącz
- Przetestuj łączność poleceniem `ping`.

## Zadanie 3 - Wirtualny switch

- Utwórz przestrzeń wirtualnego switcha
  - sugerowana nazwa `s1`
- Utwórz w niej wirtualnego switcha
- Usuń wirtualny kabel między `pc1` i `pc2`
- Połącz `pc1` i `pc2` do `s1`
- Podłącz wirtualne kable w `s1` do wirtualnego switcha
- Nadaj odpowiednim intefejsom odpowiednie adresy
  - W tym nadaj adres switchowi
- Przetestuj łączność poleceniem `ping`.

## Zadanie 4 - Router

- Utwórz przestrzeń `pc3` i `r1`
- Z wygenerowanego zakresu IPv4 wydziel kolejną sieć na min. 6 urządzeń
- Połącz `pc3` z `r1`
- Połącz `r1` z `s1`
  - Podłącz kabel `r1` do switcha w `s1`
- Przypisz odpowiednie adresy
  - Połączenie `pc3`-`r1` traktuj jako osobną sieć
- Włącz routing w `r1`
  - jeżeli jesteś na debianie i `sysctl` wydaje się nie istnieć na systemie:
    - debian przydziela różne wartości zmiennej `PATH` rootowi i innym użytkownikom
      - `PATH` decyduje, gdzie system szuka pliku wykonywalnego dla danej komendy - są to ścieżki do katalogów rozdzielone dwukropkami
      - jeżeli w wyjściu z `echo $PATH` nie znajdziesz `/usr/sbin` lub `/sbin`, to ten problem dotyczy Ciebie
    - upewnij się, że odpowiednio "wchodzisz" na konto root: za pomocą `sudo -i` lub `su -l`
      - samo `su` nie wczytuje ponownie pliku `/etc/profile`
    - wpis do `PATH` można dodać doraźnie za pomocą `export PATH="$PATH:/usr/sbin"`
      - alternatywnie możesz wywoływać `sysctl` za pomocą pełnej ścieżki (`/sbin/sysctl` zamiast `sysctl`)
    - możesz również permanentnie dodać `/sbin` lub `/usr/sbin` dla pozostałych użytkowników edytując plik `/etc/profile`, a następnie się wylogować i ponownie zalogować do systemu
- Utwórz wpisy tras domyślnych w `pc*` i `s1`
- Przetestuj łączność poleceniem `ping`.

## Zadanie 5 - IPv6

- Z wygenerowanego zakresu IPv6 wydziel dwie sieci /64
- Przypisz adresy z tych sieci interfejsom `r1`
- Rozgłoś dostępność adresacji IPv6:
  - Zainstaluj na systemie program `radvd` (z repozytoriów)
  - Skopiuj i zmodyfikuj plik konfiguracyjny [`tools/radvd.conf`](../tools/radvd.conf)
    - utwórz blok `interface` dla obu interfejsów przestrzeni routera, zmieniając odpowiednio nazwę interfejsu w pliku konfiguracyjnym tak, by pasowała do faktycznych
  - W nowym oknie terminala, po wejściu do przestrzeni `r1` uruchom program komendą `radvd -n -p "/run/radvd.$(hostname).pid" -C <ścieżka do pliku>`
- Zaobserwuj adresy i tablicę routingu w pozostałych przestrzeniach
  - protip: `ip -6 route` by pokazać tablicę routingu ipv6
  - protip2: `ip -6 route show table local` by pokazać tablicę wpisów specjalnych ipv6
- Przetestuj poleceniem `ping`
- Zatrzymaj program `radvd` poprzez CTRL+C i zaobserwuj zmiany w tablicy routingu w pozostałych przestrzeniach

## Zadanie 6 - Router za routerem

- Odłącz `r1` od `pc3`
- Z zakresu IPv4 wydziel kolejną sieć na min. 2 urządzenia
- Utwórz przestrzeń `r2`
- Połącz `r1` z `r2`, `r2` z `pc3`
  - Adresację, która była na połączeniu `r1`-`pc3` przenieś na `r2`-`pc3`
- Adresy na połączeniu `r1`-`r2`
- Ustaw trasy na `r1` i `r2` tak, by można było przesyłać dane z `pc1` do `pc3` po IPv4
  - protip: `ip route {show,add,delete}`
- Utwórz dwa pliki konfiguracyjne `radvd.conf` dla przestrzeni `r1` i `r2`
  - Uruchom `radvd` w obu przestrzeniach (w osobnym terminalu)
- Ustaw trasy na `r1` i `r2` tak, by działało również połączenie po IPv6
  - protip: `ip -6 route {show,add,delete}`
  - protip2: gdy włączasz interfejs, linux automatycznie generuje adres link-local IPv6 - jest on ważny tylko w danej sieci lokalnej, ale nadal możesz go ustawić jako adres następnego routera, pod warunkiem że w regule podasz również nazwę interfejsu
    - `ip -6 route add <sieć> dev <interfejs> via <następny router>`
    - możesz również przydzielić kolejną sieć /64 na ten odcinek i przypisać przestrzenim adres ręcznie
      - w IPv6 jeden interfejs może mieć wiele adresów
      - w v4 na linuxie też, ale na windowsie już trudniej c:
- Przetestuj za pomocą `ping` i `traceroute`
