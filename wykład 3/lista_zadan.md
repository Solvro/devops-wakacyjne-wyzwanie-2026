# Kurs DevOps Wakacyjnego Wyzwania KN Solvro 2026 - Lista 3

> [!WARNING]
> Zadania z tej listy należy wykonać przy użyciu systemu wirtualizacji QEMU/KVM.
>
> Do poprawnego wykonania tych zadań będzie potrzebny komputer z zainstalowanym Linuxem.
> O ile została na tym komputerze wcześniej włączona wirtualizacja, wystarczy do niego dostęp zdalny poprzez SSH.
> Środowiska typu live CD nie będą wystarczające ze względu na ograniczenia w przechowywaniu danych.

## Zadanie 0 - Przygotowanie środowiska

Upewnij się, że na komputerze który posłuży jako wirtualizator jest włączona wirtualizacja.
W przypadku poprawnie włączonej wirtualizacji, Linux powinien załadować moduł `kvm` oraz `kvm_intel`/`kvm_amd`.

> [!TIP]
>
> - Załadowane moduły możesz wylistować komendą `lsmod`
> - Moduł możesz próbować załadować komendą `insmod` lub `modprobe`
> - Jeżeli dystrybucja została zainstalowana w trybie UEFI zamiast BIOS,
>   możesz użyć komendy `systemctl reboot --firmware` by uruchomić
>   komputer bezpośredio do konfiguracji UEFI bez konieczności wciskania
>   klaiwszy podczas uruchamiania
> - W konfiguracji płyty głównej szukaj opcji takich jak `Intel-VTx` lub `AMD-V`.

Po włączeniu wirtualizacji zainstaluj i włącz oprogramowanie wirtualizatora - libvirt i qemu.

Na komputerze, z którego będziesz zarządzać maszynami wirtualnymi (może to być ten sam komputer) zainstaluj i skonfiguruj virt-manager.

## Zadanie 1 - Instalacja debiana w maszynie wirtualnej

Pobierz najnowszy instalator debiana ze strony dystrybucji. (bonusowe punkty za pobranie torrentem :tf:)

Utwórz nową maszynę wirtualną, wybierając instalację systemu za pomocą pobranego instalatora.
Zmodyfikuj maszynę wirtualną przed pierwszym uruchomieniem tak, by używała UEFI zamiast BIOS.

> [!IMPORTANT]
> Korekta informacji z wykładu: jeżeli wirtualizator zainstalowany jest na debianie, w polu "Oprogramowanie sprzętowe" zamiast opcji "UEFI" koniecznie wybierz opcję "**UEFI x86_64: /usr/share/OVMF/OVMF_CODE_4M.fd**"!
>
> Opcja "UEFI" na debianie domyślnie spowoduje włączenie opcji Secure Boot w UEFI maszyny wirtualnej, co utrudni ci wykonanie zadania 3.
>
> Opcję tą można tylko zmienić przed pierwszym uruchomieniem maszyny wirtualnej.
> Nie musisz jednak resetować maszyny wirtualnej, by wyłączyć Secure Boot - procedurę opisano w korekcie do zadania 3.

Uruchom maszynę wirtualną i zainstaluj system.
Podczas instalacji zainstaluj jedynie podstawowe narzedzia i serwer SSH.
Manualnie rozpartycjonuj dysk:

- Utwórz partycję ESP (EFI system partition) o rozmiarze min. 512MB
- Utwórz partycję `/boot` o rozmiarze min. 512MB używając systemu plików ext4
  - zamontuj ten system plików w sposób uniemożliwiający korzystanie z zapisanych na nim urządzeń i plików SUID
- Resztę wolnego miejsca przeznacz na wolumen fizyczny LVM
  - nie musisz wymuszać przydzielenia całości wolnego miejsca - pozostawienie kilku MB wolnego miejsca przed/za partycjami nie jest błędem
- Utwórz grupę wolumenów LVM
- Utwórz wolumen logiczny na system plików `/`
  - min. rozmiar: 2GB
- Utwórz wolumen logiczny na przestrzeń wymiany (swap)
  - zalecany rozmiar: 0.5-2x przydzielonego RAMu (im mniej ramu, tym większa zalecana partycja wymiany)
- Utwórz wolumen logiczny na min. jeden dodatkowy system plików
  - np. `/var`, `/srv`, `/var/log`, `/var/tmp`, `/usr/local`, ...
  - ustaw odpowiednie flagi ograniczające pliki specjalne, jeżeli jest to zasadne dla danej gałęzi systemu plików
- Odpowiednio zdefinuj użycie dla każdego z utworzonych wolumenów logicznych

Dokończ instalację i uruchom po raz pierwszy zainstalowany system operacyjny

## Zadanie 2 - Rozszerzanie dysku na żywo

Dodaj kolejny dysk wirtualny, sformatuj go jako wolumen fizyczny LVM i dodaj do grupy wolumenów.

Wylistuj wszystkie dostępne woluemny fizyczne, grupy wolumenów oraz wolumeny logiczne - komendy `pvs`, `vgs`, `lvs`.
Sprawdź zajętość systemów plików - komenda `df -h`.

Rozszerz jeden z wolumenów logicznych tak, by znalazł się częściowo na nowym wolumenie fizycznym. Pamiętaj o dodaniu flagi `--resizefs`, by automatycznie zaktualizować rozmiar systemu plików.
Pokaż zmiany w rozmiarze i zajętości systemu plików.

Uruchom system ponownie by sprawdzić, czy zmiany nie uszkodziły procesu uruchamiania.

## Zadanie 3 - Przenoszenie istniejącej gałęzi drzewa systemu plików na nowy wolumen

Pobierz środowisko live CD dystrybucji Arch Linux.
Zamontuj pobrany obraz iso w wirtualnym napędzie płyt optycznych.
Upewnij się, że napęd płyt jest przed dyskiem twardym w kolejności uruchamiania maszyny wirtualnej.
Uruchom ponownie maszynę wirtualną, uruchamiając system z pobranego obrazu.

> [!NOTE]
> W teorii to zadanie możesz wykonać również z instalatora debiana, uruchamiając go w trybie rescue.
>
> W mojej opinii tryb rescue debiana jest po prostu trudniejszy w obsłudze niż zwykły instalator Arch Linux,
> który w swoim środowisku ma wiele narzędzi gotowych do naprawy systemu operacyjnego.

> [!TIP]
> Korekta 24-08-2026: Instalator nie chce się uruchomić, a na ekranie wyświetla się monit o niepowodzonym rozruchu z błędem "Access denied"?
>
> Najprawdopodobniej w twojej maszynie wirtualnej włączony jest Secure Boot.
> By tą opcję wyłączyć, wejdź do konfiguracji UEFI maszyny wirtualnej, przejdź do menu "Device Manager", dalej "Secure Boot Configuration", a tam wyłącz opcję Secure Boot.
> Zapisz zmiany klawiszem F10.

Po uruchomieniu upewnij się, że wszystkie obiekty LVM utworzone na debianie są nadal widoczne.
Zamontuj wolumen logiczny katalogu `/` w `/mnt`.
Wejdź do środowiska zamontowanego systemu za pomocą komendy `arch-chroot /mnt`.
Zamontuj automatycznie pozostałe systemy plików komendą `mount -a`.
Wyjdź ze środowiska zamontowanego systemu, powracając do środowiska instalatora Arch Linuxa.

Wybierz katalog z zainstalowanego debiana do przeniesienia na nowy wolumen, najlepiej jeżeli nie jest pusty.
Utwórz nowy wolumen logiczny w istniejącej grupie wolumenów - `lvcreate`.
Sformatuj go w wybranym systemie plików - `mkfs.*`, np. `mkfs.ext4` dla systemu `ext4`.
Utwórz pusty katalog w środowisku instalatora i zamontuj w nim tymczasowo nowy system plików.

> [!TIP]
> Po utworzeniu wolumenu logicznego, powinien on się pojawić w katalogu `/dev`
> jako `/dev/<grupa wolumenów>/<nazwa wolumenu>`.
>
> Na przykład, wolumen `testlv` w grupie `testvg` powinien pojawić się jako `/dev/testvg/testlv`.

Przekopiuj zawartość katalogu z zainstalowanego systemu do nowego wolumenu komendą `rsync` z flagami `-aAXH`, + opcjonalnie `--progress`.
Upewnij się, że pliki zostały poprawnie przekopiowane.
Usuń przekopiowane pliki z systemu źródłowego.
Odmontuj wolumen.
Zmodyfikuj plik `/etc/fstab` zainstalowanego systemu tak, by automatycznie zamontować nowy wolumen w odpowiednim miejscu.
Przetestuj zmiany wykonując `mount -a` po przejściu do zainstalowanego systemu komendą `arch-chroot`.

Uruchom ponownie maszynę wirtualną, uruchamiając się z dysku twardego.
Zweryfikuj dokonane zmiany.

## Zadanie 4: Konsola szeregowa

Uaktywnij konsolę szeregową, uruchamiając na niej ekran logowania.
Upewnij się, że konsola szeregowa uaktywni się automatycznie również po ponowym uruchomieniu systemu.

## Zadanie 5: Konfiguracja sieci

Zainstaluj `systemd-resolved` i odinstaluj `ifupdown`.
Skonfiguruj `systemd-networkd` tak, by domyślnie na każdej fizycznej karcie sieciowej uruchamiał automatyczną konfigurację sieci.
Włącz `systemd-networkd` i `systemd-resolved`.
Zweryfikuj konfigurację.
Uruchom ponownie maszynę wirtualną i upewnij się, że sieć jest nadal poprawnie skonfigurowana.

> [!NOTE]
> Przy przełączaniu między oprogramowaniem do konfiguracji sieci możesz zaobserwować zmianę przydzielonego adresu IP.

Utwórz nową sieć wirtualną bez dostępu do internetu.
Dodaj nową kartę sieciową do maszyny wirtualnej, podłączoną do nowej sieci.
Zaobserwuj jak systemd-resolved skonfiguruje nowy interfejs.

Utwórz nowy plik konfiguracyjny sieci, gdzie przypiszesz ręcznie adres IP do nowego interfejsu sieciowego.
Przeładuj konfigurację systemd-networkd (`networkctl reload`) i ponownie skonfiguruj interfejs. (`networkctl reconfigure <interfejs>`)

## Zadanie 6: Konfiguracja SSH

Sprawdź, czy na hoście masz wygenerowane klucze SSH - powinny znajdować się w `~/.ssh`, zaczynać od `id_` i posiadać wariant bez rozszerzenia i `.pub`.
W razie potrzeby wygeneruj nową parę komendą `ssh-keygen`.

Zaloguj się do systemu poprzez SSH.
Przekopiuj swój klucz publiczny do `~/.ssh/authorized_keys`.
Wyloguj się i sprawdź, czy ponowna próba logowania użyje pary kluczy zamiast hasła.

> [!NOTE]
> Następna część zadania będzie obejmować konfigurację serwera SSH.
> Dokumentację na ten temat znajdziesz w [sshd_config(5)](https://www.mankier.com/5/sshd_config).

W maszynie wirtualnej utwórz nową grupę, której członkowie powinni móc logować się za pomocą SSH.
Dodaj do tej grupy odpowiednich użytkowników.
Dokonaj zmian w pliku `/etc/ssh/sshd_config` (lub w nowym pliku w katalogu `/etc/ssh/sshd_config.d/`) dodając nową regułę ograniczającą logowanie do użytkowników w utworzonej grupie - `AllowGroups`.
Przeładuj konfigurację sshd (`systemctl reload sshd`) i zweryfikuj zmiany.

Pobierz narzędzie [ssh-audit](https://github.com/jtesta/ssh-audit) i uruchom audyt serwera SSH maszyny wirtualnej.
Usuń algorytmy, które narzędzie wskaże jako potencjalnie niebezpieczne.
Przeładuj konfigurację serwera i sprawdź, czy nadal jesteś w stanie zalogować się do systemu.

Przjerzyj domyślną konfigurację serwera SSH i dokonaj innych zmian, które uznasz za zasadne.

## Zadanie 7: Konfiguracja sudo

Zainstaluj sudo w maszynie wirtualnej i dodaj swojego użytkownika do grupy `sudo`.

Utwórz nowego użytkownika i zezwól mu na wykonanie jednej konkretnej komendy jako wybrany inny użytkownik.
Zademonstruj działanie reguły.

Dodaj nową regułę zezwalającą użytkownikowi na uruchomienie innej komendy (lub tej samej, ale z innymi parametrami) bez konieczności hasła.
Zademonstruj działanie reguły.

> [!NOTE]
> sudo domyślnie nie pyta ponownie o hasło, jeżeli w tym samym terminalu w ostatnim czasie nastąpiło już poprane uwierzytelnienie.
>
> Użyj komendy `sudo -k` by wymusić ponowne zapytanie o hasło.
