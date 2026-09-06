# Kurs DevOps Wakacyjnego Wyzwania KN Solvro 2026 - Lista 5

## Zadanie 0 - Przygotowanie środowiska

Przygotuj trzy maszyny wirtualne.
Każda maszyna wirtualna powinna mieć działający system docker lub podman, oraz zainstalowaną wtyczkę docker-compose.
Maszyny powinny być w tej samej sieci wirtualnej.
Przypisz statycznie adresy IP dla każdej z maszyn.

Dwie maszyny wirtualne powinny mieć działającego nginxa.

## Zadanie 1 - Compose

> [!NOTE]
> Jeżeli znasz inny serwis, który składa się z wielu kontenerów (np. głównej aplikacji i bazy danych),
> możesz to zadanie wykonać bazując na innym serwisie, niż opisano poniżej.
>
> Podczas wykonywania zadania możesz wzorować się na gotowych plikach compose,
> jednak twój plik musi zawierać jakieś modyfikacje względem dostępnych publicznie.
>
> Przydatna może okazać sie również [oficjalna dokumentacja Docker Compose](https://docs.docker.com/reference/compose-file/)

Utwórz stos kontenerów z plikiem Docker Compose składający się z następujących kontenerów:

- [`docker.io/library/wordpress` w wersji `*-apache`](https://hub.docker.com/_/wordpress), jako główny serwis
  - kontener powinien mieć podane poświadczenia dla bazy danych tak, by serwis nie pytał o nie przy pierwszym uruchomieniu
  - z kontenera należy "wystawić" port 80, i skonfigurować dla tego portu jakąś domenę w nginxie.
- [`docker.io/library/mariadb`](https://hub.docker.com/_/mariadb), jako zamiennik dla mysql (baza danych)
  - kontener powinien utworzyć bazę i użytkownika dla pozostałych kontenerów, a użytkownikowi `root` ustawić losowe hasło.
- [`docker.io/library/phpmyadmin` w wersji `*-apache`](https://hub.docker.com/_/phpmyadmin), jako panel administracyjny bazy danych
  - kontener powinien mieć podany adres serwera bazodanowego
  - z kontenera należy "wystawić" port 80, i skonfigurować dla tego portu jakąś domenę w nginxie.

Dla pełnej kompatybilności z alternatywnymi silnikami kontenerów, użyj pełnych nazw używanych obrazów.
(czyli `docker.io/library/wordpress` zamiast po prostu `wordpress`)

Kontenery powinny utworzone i zamontowane w odpowiednich miejscach wolumeny.

> [!TIP]
> Informacja o tym, w jakich miejscach należy zamontować wolumeny z reguły znajduje się w dokumentacji danego obrazu.
>
> By usunąć wolumeny razem z kontenerami należy użyć komendy `docker compose down --volumes`, lub odpowiednich komend `docker volume`.

Skonfiguruj dwie sieci wirtualne tak, by każdy z kontenerów miał dostęp do bazy danych, ale by `phpmyadmin` nie miał dostępu do `wordpress`a.

Uruchom kontenery, skonfiguruj nginxa i otwórz każdą ze stron w przeglądarce.
Dokończ proces instalacyjny wordpressa. (nie, nie musisz podawać faktycznego adresu email - możesz podać nieistniejący)
Zaloguj się do bazy poprzez phpmyadmin i potwierdź istnienie w niej danych.

Usuń kontenery **nieusuwając wolumenów** i utwórz je ponownie.
Sprawdź, czy dane nadal są w bazie i czy główny serwis nadal działa.

## Zadanie 2 - Rekuencyjny resolver DNS

Na drugiej maszynie zainstaluj [Unbound](https://nlnetlabs.nl/projects/unbound/about/) - rekurenycjny resolver DNS.

> [!NOTE]
> Unbound nie ma oficjalnych obrazów kontenerowych.
> W ramach tego zadania możesz Unbound zainstalować zarówno bezpośrednio na systemie maszyny wirtualnej, lub we własnym obrazie kontenera.
> Osobiście preferuję instalację bezpośrednio na systemie, z repozytoriów dystrybucji.
>
> Znalazłem równiez obraz [`docker.io/alpinelinux/unbound`]. Do tego obrazu należy ręcznie zamontować plik `unbound.conf` do `/etc/unbound/unbound.conf`.
> Domyślny plik konfiguracyjny możecie znaleźć [w repozytorium unbound](https://github.com/NLnetLabs/unbound/blob/master/doc/example.conf.in).

Upewnij się, że na maszynie nie ma uruchomionego innego serwera DNS, np. `systemd-resolved`.
Zmień konfigurację serwera tak, by nasłuchiwał on na wszystkich adresach - opcje `interface` i `access-control`:

```
server:
  interface: ::0
  interface: 0.0.0.0
  access-control: 0.0.0.0/0 allow
  access-control: ::0/0 allow
```

Za pomocą narzędzia `drill` z pakietu `ldnsutils`, przetestuj serwer DNS wysyłając mu kilka zapytań o domeny z obu maszyn wirtualnych.
Pamiętaj, by wskazać ręcznie serwer w komendzie.
Przykład: `drill @127.0.0.1 minibomba.pro`.

Na obu maszynach usuń istniejący plik `/etc/resolv.conf` i utwórz nowy, wskazujący maszynę wirtualną z unbound jako resolver DNS.
Przetestuj działanie konfiguracji, np. komendą `ping minibomba.pro`.

## Zadanie 3 - Serwer autorytatywny DNS

Na pierwszej maszynie zainstaluj [NSD](https://nlnetlabs.nl/projects/nsd/about/) - serwer autorytatywny DNS.

> [!NOTE]
> Tak jak unbound, NSD nie ma oficjalnych obrazów kontenerowych.
> Zalecam konfigurację bezpośrednio na systemie maszyny wirtualnej.

Napisz plik strefy dla subdomeny `wakacyjne-wyzwanie.`: (np. `minibomba.wakacyjne-wyzwanie.`)

- Ustaw TTL wszystkich rekordów na 5 minut
- Skonfiguruj subdomenę dla serwera nazw (np. `ns1.minibomba.wakacyjne-wyzwanie.`) z rekordem A (i AAAA, jeżeli sieć wirtualna ma skonfigurowane IPv6)
- Utwórz rekord SOA i NS dla strefy
  - W SOA i NS jako domenę serwera nazw wskaż tą skonfigurowaną wcześniej
  - Jako kontaktowy adres email wskaż `nsadmin@<główna domena strefy>`
  - Użyj formatu `YYYYMMDDxx` jako numeru seryjnego
    - gdzie `YYYY`, `MM`, `DD` to rok miesiąc i dzień, a `xx` to numer wersji danego dnia
    - pamiętaj, by zmieniać numer seryjny przy edycji pliku!
  - Ustaw interwał synchronizacji serwerów podrzędnych na 5 minut
  - Ustaw opóźnienie między ponownymi próbami na 1 minutę
  - Ustaw czas wygaśnięcia strefy na 30 minut
  - Ustaw minimalny TTL strefy na 30 sekund
  - Te ustawienia nie są odpowiednie dla "produkcyjnych" stref - używamy ich tylko w ramach testów
- Utwórz domeny dla wordpressa, phpmyadmin oraz resolvera DNS, z odpowiednimi rekordami A/AAAA
- Utwórz testowy rekord TXT na głównej domenie strefy

Plik strefy umieść w `/etc/nsd/<głowna domena strefy>.zone`, np `/etc/nsd/minibomba.wakacyjne-wyzwanie.zone`.

Skonfiguruj NSD, by się zachowywał jako główny serwer autorytatywny dla utworzonej strefy,
dodając do jego konfiguracji nową sekcję `zone` z parametrami `name` i `zonefile`, np:

```
zone:
  name: "minibomba.wakacyjne-wyzwanie"
  zonefile: "/etc/nsd/minibomba.wakacyjne-wyzwanie.zone"
```

> [!TIP]
> Informacje o dostępnych opcjach konfiguracyjnych znajdziesz w [manpageach nsd.conf(5)](https://www.mankier.com/5/nsd.conf).

Uruchom ponownie NSD i przetestuj jego działanie za pomocą drill - wyślij do serwera zapytanie o rekordy w jego strefie autorytatywnej oraz poza nią i zaobserwuj otrzymane odpowiedzi.

## Zadanie 4 - Konfiguracja serwera podrzędnego

Na trzecim serwerze zainstaluj kolejną instancję NSD.

Zmień konfigurację strefy na głównym serwerze autorytatywnym tak, by zezwalała nowemu serwerowi inicjować transfery strefy (`provide-xfr`) oraz by ten serwer był powiadamiany o zmianach w strefie (`notify`) bez autoryzacji. (opcja `NOKEY` w `provide-xfr` i `notify`)

Na nowym serwerze NSD skonfiguruj tą samą strefę, ale jako serwerz podrzędny - utwórz sekcję `zone` bez parametru `zonefile`, ale z opcją `request-xfr` (inicjuj transfery od wskazanego serwera) i `allow-notify` (akceptuj powiadomienia od wskazanego serwera)

Uruchom ponownie oba serwery NSD poprzez `systemctl`.
Odczytaj stan stref na obu serwerach komendami `nsd-control zonestatus`.
Wyślij zapytanie do nowego serwera komendą `drill`.

Zaktualizuj strefę na serwerze głównym, tworząc nową subdomenę dla nowego serwera oraz dodając go do listy serwerów autorytatywnych dla tej strefy.
Dodaj nowy rekord TXT na domenie głównej swojej strefy.
Nie zapomnij zaktualizować numeru seryjnego!
Wczytaj nową strefę na serwerze głównym komendą `nsd-control reload wakacyjne-wyzwanie`.

Sprawdź status strefy na serwerze podrzędnym komendą `nsd-control zonestatus`.
Wyślij zapytania do obu serwerów odpowiednimi komendami `drill`.
Czy strefa zaktualizowała się na serwerze podrzędnym?

## Zadanie 5 - Konfiguracja lokalnej strefy w unbound

Na serwerze z unbound napisz plik strefy `wakacyjne-wyzwanie.`:

- Ustaw TTL wszystkich rekordów na 5 minut
- Skonfiguruj subdomenę dla serwera nazw (np. `resolver.wakacyjne-wyzwanie.`) z rekordem A (i AAAA, jeżeli sieć wirtualna ma skonfigurowane IPv6)
- Utwórz rekord SOA i NS dla strefy
  - W SOA i NS jako domenę serwera nazw wskaż tą skonfigurowaną wcześniej
  - Jako kontaktowy adres email wskaż `nsadmin@<główna domena strefy>`
  - Użyj formatu `YYYYMMDDxx` jako numeru seryjnego
  - Ustaw interwał synchronizacji serwerów podrzędnych na 5 minut
  - Ustaw opóźnienie między ponownymi próbami na 1 minutę
  - Ustaw czas wygaśnięcia strefy na 30 minut
  - Ustaw minimalny TTL strefy na 30 sekund
- Oddeleguj domenę strefy skonfigurowanej w zadaniu 3 serwerom NSD
  - Pamiętaj o dodaniu rekordów "glue" - rekordów A/AAAA dla serwerów nazw

Zapisz plik do `/etc/unbound/wakacyjne-wyzwanie.zone`.
Skonfiguruj serwer unbound, by czytał rekordy dla tej strefy z pliku:

```
server:
  domain-insecure: "wakacyjne-wyzwanie."
auth-zone:
  name: "wakacyjne-wyzwanie."
  zonefile: /etc/unbound/wakacyjne-wyzwanie.zone
  for-downstream: no
```

Uruchom ponownie unbound i przetestuj działanie resolvera z własnymi domenami.

## Zadanie 6 - Lokalny urząd certyfikacji

### Część 1 - Konfiguracja urzędu

Na serwerze z serwerem podrzędnym NSD uruchom serwis HashiCorp Vault poniższą komendą:

```bash
podman run -d --cap-add=IPC_LOCK --name vault -v vault-data:/vault \
  -e 'VAULT_LOCAL_CONFIG={"storage": {"file": {"path": "/vault/file"}}, "listener": [{"tcp": { "address": "0.0.0.0:8200", "tls_disable": true}}]}' \
  -e 'VAULT_ADDR=http://localhost:8200' \
  -p 8200:8200 docker.io/hashicorp/vault server
```

Skonfiguruj nginxa na maszynie wirtualnej tak, by przekazywał żądania dla subdomeny `vault` strefy skonfigurowanej w zadaniu 3 na port 8200.

Zainicjuj Vault komendą `docker exec vault vault operator init -key-shares=1 -key-threshold=1`.
Vault wygeneruje klucz szyfrowania i podzieli go na jeden udział, gdzie min. 1 będzie wymagany do odszyfrowania.
Wygeneruje też token do zarządzania serwisem.
Zapisz obie wartości.

> [!NOTE]
> Czym są te udziały?
>
> Vault jest serwisem do przechowywania poświadczeń.
> Poświadczenia przechowywane przez Vault są szyfrowane przed zapisem na dysk.
> Przy instalacji, klucz szyfrowania jest dzielony na "udziały".
> By klucz szyfrowania odzyskać (w celu odszyfrowania zawartości) należy podać minimalną liczbę "udziałów" skonfigurowaną przy instalacji.
> Bez wymaganej liczby "udziałów" nie da się odzyskać żadnej cześci klucza.
>
> Więcej informacji znajdziesz pod hasłem: [Shamir's secret sharing](https://en.wikipedia.org/wiki/Shamir%27s_secret_sharing)

Odszyfruj Vault komendą `docker exec -it vault vault operator unseal`, podając wygenerowany udział klucza.
Zaloguj się komendą `docker exec -it vault login`, podając token root.

Włącz silink PKI i protokół ACME następującymi komendami:

```bash
docker exec vault vault secrets enable pki
docker exec vault vault write pki/root/generate/internal common_name="Wakacyjne Wyzwanie 2026 Local CA" permitted_dns_domains="wakacyjne-wyzwanie"
docker exec vault vault secrets tune -allowed-response-headers=Link -allowed-response-headers=Location -allowed-response-headers=Replay-Nonce pki/
docker exec vault vault write pki/config/cluster path=http://vault.<strefa z zadania 3>/v1/pki
docker exec vault vault write pki/config/acme enabled=true dns_resolver=<adres ip serwera unbound>:53
docker exec -u 0 vault sh -c 'echo "nameserver <adres ip serwera unbound>" > /etc/resolv.conf'
```

Na każdym z serwerów, zainstaluj certyfikat lokalnego urzędu nastepującymi komendami:

```bash
curl -o /usr/share/ca-certificates/wakacyjne-wyzwanie.crt http://vault.<strefa z zadania 3>/v1/pki/ca/pem
dpkg-reconfigure ca-certificates
# Zaznacz certyfikat wakacyjne-wyzwanie.crt!
```

### Część 2 - Generowanie certyfikatów z wyzwaniem HTTP-01

Na serwerze z zadania 1 utwórz nowy katalog `/var/www/acme`.
Skonfiguruj wszystkie domeny w nginxie tak, by w przypadku żądań dla lokalizacji `/.well-known/acme-challenge` plików szukał w `/var/www/acme`, zamiast przekazwyać żądań dalej.

<details>
  <summary>Jak to skonfigurować?</summary>

```nginx
location /.well-known/acme-challenge {
  root /var/www/acme;
}
```

</details>

Zainstaluj `acme.sh` i wygeneruj certyfikaty dla domen tego serwera następującą komendą:

```bash
acme.sh --issue --server http://vault.<strefa z zadania 3>/v1/pki/acme/directory -w /var/www/acme -d <domena 1> -d <domena 2> ...
acme.sh --install-cert -d <domena 1> --fullchain-file /etc/nginx/cert.pem --key-file /etc/nginx/key.pem --reloadcmd "systemctl reload nginx"
```

Zaktualizuj konfiguracje nginx, dodając nastepujące linijki do każdego bloku `server`:

```nginx
listen 0.0.0.0:443 ssl;
listen [::]:443 ssl;

ssl_certificate /etc/nginx/cert.pem;
ssl_certificate_key /etc/nginx/key.pem;
```

Uruchom ponownie serwer nginx i przetestuj działanie certyfikatów curlem i/lub przeglądarką.

> [!IMPORTANT]
> W przypadku testowania firefoxem: Firefox przechowuje własną listę zaufanych urzędów certyfikacji - dodaj certyfikat ręcznie w ustawieniach.

### Część 3 - Certyfikaty wildcard z wyzwaniem DNS-01

Oprócz certyfikatów na określone domeny, da się również uzywać certyfikaty na wszystkie subdomeny danej domeny.
Utworzenie takiego certyfikatu wymaga weryfikacji za pomocą DNS.

W produkcyjnych konfiguracjach zazwyczaj korzysta się z API dostawcy chmurowego, by na bieżąco zmieniać wymagane rekordy.
W naszym przypadku nie mamy takiej możliwości, wiec skorzystamy z [trybu ręcznego w acme.sh](https://github.com/acmesh-official/acme.sh/wiki/dns-manual-mode).

Generowanie takiego certyfikatu będzie się składało z kilku kroków:

1. złożenie zamówienia na certyfikat, w ramach którego otrzymamy ciąg znaków do umieszczenia w DNS pod odpowiednią domeną
2. ręczna aktualizacja strefy DNS według wymagań
3. potwierdzenie wprowadzenia zmian i zażądanie weryfikacji - jeżeli urząd zweryfikuje nasz wpis, otrzymamy certyfikat

Na innym serwerze niż w cześci 1 zainstaluj acme.sh i wygeneruj certyfikat wildcard dla swojej domeny:

```bash
acme.sh --issue --server http://vault.<strefa z zadania 3>/v1/pki/acme/directory --dns -d '*.<strefa z zadania 3>' --yes-I-know-dns-manual-mode-enough-go-ahead-please
```

Komenda wyświetli komunikat z domeną i rekordem do utworzenia.
Utwórz ten rekord w swojej strefie, pamiętając o aktualizacji numeru seryjnego, i odśwież strefę w NSD.

Zażądaj weryfikacji następującą komendą:

```bash
acme.sh --renew --server http://vault.<strefa z zadania 3>/v1/pki/acme/directory --dns -d '*.<strefa z zadania 3>' --yes-I-know-dns-manual-mode-enough-go-ahead-please
```

Zainstaluj certyfikat w nginx następującą komendą:

```bash
acme.sh --install-cert -d '*.<strefa z zadania 3>' --fullchain-file /etc/nginx/cert.pem --key-file /etc/nginx/key.pem --reloadcmd "systemctl reload nginx"
```

Skonfiguruj nginx, by korzystał z nowego certyfikatu, uruchom ponownie serwer nginx i przetestuj działanie.
