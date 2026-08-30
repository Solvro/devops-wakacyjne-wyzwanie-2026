# Kurs DevOps Wakacyjnego Wyzwania KN Solvro 2026 - Lista 4

## Zadanie 0 - Przygotowanie środowiska

Utwórz nową maszynę wirtualną z Debianem 13.
Przydziel jej dysk o wielkości 20GB.
Przy instalacji wybierz schemat partycjonowania z LVM, z pojedynczą partycją /.
(w przypadku ręcznego partycjonowania: pamiętaj o partycjach ESP i /boot poza LVM)

> [!NOTE]
> W tym zadaniu dozwolone jest tworzenie maszyn na Windowsie, z wykorzystaniem innego wirtualizatora niż QEMU/KVM.

Po skonfigurowaniu systemu wyłącz maszynę wirtualną i ją sklonuj.
W jednej maszynie wirtualnej zainstaluj dockera, w drugiej podmana.

W maszynie wirtualnej z dockerem upwenij się, że daemon `docker.service` jest włączony i aktywny.

W maszynie wirtualnej z podmanem utwórz nowego użytkownika systemowego `containers`.
Przydziel mu dodatkowe identyfikatory użytkowników i grup, dodając linijkę `containers:2147483647:2147483648` do `/etc/subuid` i `/etc/subgid`.

Sprawdź, czy oba silniki kontenerów działają, uruchamiając testowy kontener.
Dla podmana sprawdź również, czy działa flaga `--userns auto`.

## Zadanie 1 - Podstawowy serwis

Utwórz nowy katalog, a w nim napisz podstawowy plik `index.html`.
Niech wyświetla twoje imie i nazwisko jako nagłówek pierwszego stopnia. (`<h1>`)

Korzystając z wybranego silnika kontenerów, uruchom w kontenerze serwer nginx tak, by serwował napisaną "stronę".
Ustaw przekierowanie portu 8080 na hoście do portu, na którym nasłuchuje nginx.

Wyświetl stronę za pomocą przeglądarki internetowej lub curl.

> [!NOTE]
> Uwaga dla osób korzystających z podmana: (może dotyczyć również dockera)
>
> Wersja linuxa z której korzystam wydaje się zachowywać niepoprawnie w przypadku przekierowania połączenia skierowanego do localhosta na inny, nielokalny adres.
> Ma to wpływ na zachowanie publikacji portów w podmanie, gdy próbujemy uzyskać dostęp do opublikowanego serwisu poprzez adres `localhost`.
> Jeżeli pomimo poprawnego ustawienia publikacji portów, curl nie może się połączyć z kontenerem, szczególnie jeżeli zamiast "Connection refused" otrymujemy timeout, spróbuj użyć jednego z pozostałych adresów maszyny wirtualnej zamiast `localhost`.

## Zadanie 2 - Reverse proxy

### Część 1 - Strona statyczna

Utwórz kolejny katalog z kolejną podstawową "stroną" (plikiem `index.html`), z treścią lekko inną od strony zadania 1.

Zainstaluj w maszynie wirtualnej nginx.
Skonfiguruj go tak, by serwował napisaną stronę na subdomenie `localhost`. (np. `statyczna.localhost`)
Przetestuj przeglądarką internetową lub curlem.

> [!NOTE]
> Jeżeli używasz przeglądarki internetowej na innej maszynie wirtualnej niż ta, na której jest nginx, to użyj innej domeny niż `localhost`.
>
> Dobrym wyborem może być np. `dockertest.local` (wtedy zamiast `statyczna.localhost` użyj `statyczna.dockertest.local`)
>
> W takim przypadku będzie trzeba dodać te domeny do pliku `/etc/hosts` maszyny z przeglądarką.
> (lub `C:/Windows/System32/drivers/etc/hosts` w przypadku windowsa)
>
> Jeżeli przeglądarkę uruchamiasz na Windowsie, a do wirtualizacji używasz VirtualBox'a, to wystarczy ustawić przekazywanie portów z maszyny wirtualnej na hosta.
> W takiej sytuacji możesz korzystać z domeny `localhost`, ale może być wymagane ręczne podanie portu.
>
> Innym sposobem na przekierowanie portów jest SSH z flagą `-L`.
> W takiej konfiguracji też możesz korzystać z domeny `localhost`.

### Część 2 - Przekazywanie do kolejnego serwera HTTP

Dodaj do nginxa konfigurację, która przekaże wszystkie żądania skierowane do kolejnej subdomeny `localhost` (np. `proxied.localhost`) do kontenera utworzonego w zadaniu 1.
Przetestuj przeglądarką internetową lub curlem.

### Część 3 - Przekazywanie oryginalnych adresów IP

Uruchom nowy kontener z usługą [devops-ip-checker](https://github.com/Solvro/devops-ip-checker), konfigurując ją tak, by nasłuchiwała na jakimś porcie TCP, na wszystkich adresach.
Skonfiguruj odpowiednio nagłówek z oryginalnym adresem IP oraz adres zaufanego reverse proxy, czyli adres hosta na sieci dockerowej, do której podłączony jest kontener - domyślnie `docker0`.
Ustaw wybraną nazwę serwera.

> [!TIP]
> Szybki wstęp do tego konkretnego serwisu:
>
> - devops-ip-checker to prosty serwis napisany w rustcie, przeznaczony do testowania konfiguracji HTTP.
> - Repozytorium zawiera gotowy plik `Dockerfile`, z którego można zbudować obraz.
>   - Gotowe obrazy są publikowane na [`ghcr.io`](https://github.com/Solvro/devops-ip-checker/pkgs/container/devops-ip-checker).
>     Nie musisz ręcznie budować obrazu, chyba że korzystasz z architektury innej niż amd64/x86_64 - sprawdź za pomocą `uname -m`.
> - Serwis konfiguruje się poprzez kombinację pliku JSON oraz zmiennej środowiskowej.
>   - Przykład pliku konfiguracyjnego znajduje się w repozytorium, pod nazwą [`config.example.json`](https://github.com/Solvro/devops-ip-checker/blob/main/config.example.json) i [`config.test.json`](https://github.com/Solvro/devops-ip-checker/blob/main/config.test.json)
>     - Najważniejszymi dla tej listy opcjami są `trusted_proxies`, `forwarded_headers`, `server_name` i `listen`.
>     - Wszystkie opcje sa opcjonalne i mogą zostać pominięte.
>     - Opcja `trusted_proxies` powinna być listą zakresów sieciowych w formacie CIDR.
>       - Opcja ma tylko znaczenie w przypadku połączeń TCP - serwis domyślnie ufa każdemu połączeniu na gniazdach unixowych.
>     - Opcja `forwarded_headers` powinna być listą nazw nagłówków HTTP, na których serwis powinien spodziewać się oryginalnego adresu IP klienta.
>     - Opcja `server_name` definiuje sposób uzyskania nazwy serwera przez serwis.
>       - W przypadku tego zadania należy ustawić źródło na `static` i ręcznie podać nazwę.
>       - Alternatywnie można również ustawić kontenerowi ręcznie hostname (flaga `-h`) i ustawić źródło na `hostname`.
>     - Opcja `listen` definiuje, gdzie serwis powinien nasłuchiwać.
>       - Podopcja `tcp` powinna zaweirać adres i port, na którym serwis powinien nasłuchiwać.
>         `[::]` oznacza wszystkie adresy IPv6 (w tym IPv4), a `0.0.0.0` wszystkie adresy IPv4.
>         Jeżeli ta opcja zostanie pominięta, to serwis nie będzie nasłuchiwał na żadnym porcie TCP.
>       - Podopcja `unix` powinna zawierać ścieżkę z perspektywy kontenera, gdzie serwis powinien utworzyć gniazdo unixowe.
>         Jeżeli ta opcja zostanie pominięta, to serwis nie utworzy żadnego gniazda unixowego.
>   - Plik JSON możesz zamontować w kontenerze w dowolnym miejscu, o ile podasz jego lokalizację w zmiennej środowiskowej `IP_CHECKER_CONFIG_FILE`.

Utwórz nową konfigurację strony w nginx, która będzie przekierowywała cały ruch z wybranej subdomeny `localhost` do tego serwisu.
Skonfiguruj przekazywanie adresu IP klienta w nagłówku HTTP.

Przetestuj przeglądarką internetową lub curlem.
Upewnij się, że serwis poprawnie wyświetla adres IP klienta. (tj. nie powinien wyświetlać `unknown/nieznany` lub adresu z sieci dockerowej)

### Część 4 - Przekazywanie do gniazda unixowego

Utwórz nowy, pusty katalog, przeznaczony do zamontowania w kontenerze.

Uruchom kolejny kontener z usługą `devops-ip-checker`, tym razem montując do kontenera utworzony katalog i konfigurując ją tak, by w tym katalogu utworzyła gniazdo unixowe.
Nie konfiguruj nasłuchiwania na gnieździe TCP.
Skonfiguruj odpowiednio nagłówek, na którym zostanie przesłany adres IP.
Ustaw nazwę serwera, inną niż w części 4.

Utwórz nową konfigurację strony w nginx, która będzie przekierowywała cały ruch z wybranej subdomeny `localhost` do tego serwisu.
Skonfiguruj przekazywanie adresu IP klienta w nagłówku HTTP.

> [!TIP]
> W konfiguracji adres serwisu podaj jako `http://unix:<ścieżka do gniazda>`.
>
> Więcej informacji znajdziesz w [dokumentacji nginxa](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_pass).

Przetestuj przeglądarką internetową lub curlem.
Upewnij się, że serwis poprawnie wyświetla adres IP klienta. (tj. nie powinien wyświetlać `unknown/nieznany`)

## Zadanie 3 - Tworzenie własnych obrazów

### Część 1 - Elo żelo!

Stwórz własny obraz, który po uruchomieniu wypisze na ekranie wybrany tekst i zakończy działanie.
Możesz użyć dowolnego obrazu bazowego i dowolnego języka programowania i/lub skryptowego.

### Część 2 - Serwer HTTP z wbudowaną stroną

Stwórz własny obraz bazujący na `docker.io/library/nginx`, który po uruchomieniu wystawi serwer HTTP z własną "stroną". (tj. conajmniej własny plik `index.html`)

Zaprezentuj działanie tworząc kontener, testując curlem lub przeglądarką, dodając go do konfiguracji reverse proxy i ponownie testując.

### Część 3 - Wieloetapowe tworzenie obrazu

Napisz dwuetapowy Dockerfile dla serwisu [web-solvro-docs](https://github.com/Solvro/web-solvro-docs).

Zaprezentuj działanie tworząc kontener, testując curlem lub przeglądarką, dodając go do konfiguracji reverse proxy i ponownie testując.

> [!TIP]
> Szybki wstęp do budowania serwisu `web-solvro-docs`:
>
> - Do zbudowania serwisu wymagany jest nodejs, najlepiej najnowszy LTS.
> - Sklonuj repozytorium komendą `git clone https://github.com/Solvro/web-solvro-docs`
> - W pliku `package.json`, w obiekcie `allowScripts`, zmień dla `sharp` wartość z `false` na `true`
> - W katalogu repozytorium uruchom `npm ci`, by zainstalować wymagane biblioteki
> - Uruchom `npm run build`, by skompilować stronę do statycznych plików
>   - Podczas tego procesu mogą zostać wyświetlone różne ostrzeżenia - jest to spodziewane, o ile nie spowoduje przerwania procesu budowania.
> - Skompilowana strona powinna znajdować się w katalogu `dist` w repozytorium
>
> Katalogi do ukrycia przed dockerem:
>
> - `.git`
> - `node_modules`
> - `dist`

> [!NOTE]
> W przypadku, gdy port w kontenerze i poza nim nie zgadzają się, nginx może niepoprawnie niepoprawnie generować przekierowania.
>
> Może się to objawiać jako niedziałające linki w postawionej stronie.
>
> Workaround: dodaj plik o zawartości `absolute_redirect off;` do `/etc/nginx/conf.d/` z końcówką `.conf` (w przypadku obrazu :alpine)

> [!TIP]
> Dokumentacja dockerfile: [docs.docker.com/reference/dockerfile](https://docs.docker.com/reference/dockerfile)
>
> Konkretne podpowiedzi - jak napisać podstawowego Dockerfile:
> (uwaga spoilery - polecam samemu spróbować napisać Dockerfile, używając tych podpowiedzi tylko gdy nie macie już żadnych pomysłów)
>
> <details>
>  <summary>Pokaż podpowiedzi</summary>
>  <details>
>     <summary>Podpowiedź 1: rozpoczęcie</summary>
>     Sklonuj repozytorium.
>     Zmień w nim plik `package.json` według instrukcji powyżej.
>     Utwórz pliki `Dockerfile` i `.dockerignore`.
>   </details>
>   <details>
>     <summary>Podpowiedź 2: obrazy</summary>
>     Potrzebujesz dwóch obrazów: jeden do zbudowania strony, drugi do obrazu końcowego.
>     Do zbudowania strony wystarczy `docker.io/library/node:lts`, do obrazu końcowego `docker.io/library/nginx:alpine`.
>   </details>
>   <details>
>     <summary>Podpowiedź 3: importowanie kodu do obrazu w budowie</summary>
>     Kod możesz przekopiować do obrazu w budowie komendą `COPY`.
>     Przekopiuj cały katalog główny do nowego katalogu w obrazie, np. `COPY . /source`.
>     (`.` po lewej oznacza katalog kontekstu, czyli katalogu w którym znajduje się `Dockerfile`)
>     Ustaw nowy katalog jako domyślny komendą `WORKDIR /source`.
>   </details>
>   <details>
>     <summary>Podpowiedź 4: budowanie strony</summary>
>     Użyj komendy `RUN` by wykonać odpowiednie komendy (opisane wyżej) w budowanym obrazie.
>     Upewnij się, że wykonujesz je w odpowiednim katalogu obrazu!
>   </details>
>   <details>
>     <summary>Podpowiedź 5: kopiowanie plików między obrazami</summary>
>     Użyj komendy `COPY` z flagą `--from=<nazwa kroku>` by skopiować pliki z wybranego kroku zamiast katalogu kontekstowego.
>     Kroki muszą być nazwane za pomocą `AS <nazwa>` w komendzie `FROM`!
>   </details>
>   <details>
>     <summary>Podpowiedź 6: gdzie umieścić pliki?</summary>
>     nginx domyślnie czyta pliki z `/usr/share/nginx/html/`.
>     To tam możesz umieścić gotowe pliki strony.
>   </details>
> </details>

## Zadanie 4 - Bezpieczeństwo w kontenerach

### Część 1 - Grupa `docker`

W maszynie wirtualnej z dockerem utwórz nowego użytkownika.
Przypisz mu grupę `docker`.

Zaloguj się na konto utworzonego użytkownika i wykorzystaj `docker` do eskalacji uprawnień.
Twoim celem jest uzyskać uprawnienia `root` na systemie.

### Część 2 - Rootless podman

W maszynie wirtualnej z podmanem utwórz nowego zwykłego (czyli nie systemowego) użytkownika.

Zaloguj się na konto utworzonego użytkownika i spróbuj w podobny sposób przejąć system.

Utwórz nowy katalog z uprawnieniami `1777` i zamontuj go w nowym kontenerze z interaktywnym shellem.
Z poziomu kontenera, jako root utwórz nowy plik w katalogu.
Wyświetl informacje o właścicielu i uprawnieniach z poziomu kontenera i poza nim.

W kontenerze utwórz nowego użytkownika i zmień właściciela utworzonego pliku na nowego użytkownika.
Wyświetl informacje o właścicielu i uprawnieniach z poziomu kontenera i poza nim.

### Część 3 - Mapowanie identyfikatorów użytkowników w podmanie

W maszynie wirtualnej z podmanem, jako root uruchom nowy kontener z interaktywnym shellem, podając flagę `--userns=auto`.
Zamontuj w kontenerze katalog `/etc` hosta.
Spróbuj z kontenera odczytać plik `/etc/shadow` hosta jako root.
Usuń kontener.

Utwórz nowy katalog z uprawnieniami `1777`.
Utwórz dwa kontenery z interaktywnym shellem, flagą `--userns=auto` i zamontowanym nowym katalogiem.
Utwórz po jednym pliku w katalogu z każdego kontenera.
Porównaj informacje o właścicielu i uprawnieniach z poziomu obu kontenerów i poza nimi.

### Część 4 - Capabilities

W wybranej maszynie wirtualnej (docker lub podman) utwórz nowy kontener z interaktywnym shellem.

Utwórz nowy plik w katalogu `/root`. Ustaw jego uprawnienia na `000`. Spróbuj go odczytać jako `root`

Zainstaluj pakiety `iproute2` i `iptables`.
Spróbuj w kontenerze utworzyć nowy interfejs, zmienić adresację interfejsów, odczytać reguły firewalla i dodać nową regułę firewalla.

Usuń poprzedni kontener i utwórz nowy, dodając mu capability `NET_ADMIN` i jednocześnie usuwając capability `DAC_OVERRIDE`.

Zainstaluj pakiety `iproute2` i `iptables`.
Ponownie spróbuj utworzyć nowy interfejs, zmienić adresację interfejsów, odczytać reguły firewalla i dodać nową regułę firewalla.
