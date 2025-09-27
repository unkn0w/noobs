# NOOBS - zestaw skryptów dla początkujących
## Skrypty dla FROGów (Alpine)

Skrypty przeznaczone są dla uzytkowników usługi [MIKR.US](https://mikr.us), pracujących w systemie Alpine, jednak większosć z nich powinna działać także poza środowiskiem Mikrusa.

## Instalacja

Skrypty możesz zainstalować na dwa sposoby.

➤  Metoda 'ręczna'

```bash
git clone https://github.com/unkn0w/noobs /opt/noobs
```

➤ Metoda w pełni automatyczna (dla początkujących)


```bash
curl -s https://noobs.mikr.us | bash
```

## Jak tego używać?

1) Wejdź do katalogu /opt/noobs/scripts
2) Uruchom skrypt odpowiedzialny za postawienie wybranej usługi

## Dołącz do projektu

Chcesz dodać swój skrypt do projektu lub poprawić istniejący? **Wyślij pull requesta**.

Kilka zasad:

1) Jeśli wrzucasz wiele skryptów jednocześnie, to rozbij je na oddzielne pull requesty
2) Staraj się, aby Twój skrypt instalował tak mało paczek, jak to tylko możliwe
3) Skrypt powinien po sobie sprzątać (używasz plików tymczasowych? Usuń je)
4) Pliki tymczasowe skrypt powinien wrzucać do /tmp/
5) Podpisz się w komentarzu na początku skryptu, aby każdy wiedział komu ma być wdzięczny :)
6) Nie zaszywaj w skryptach na stałe nazw maszyn, adresów IP serwera itp.
7) Pamiętaj, aby dodawany skrypt był wykonywalny (chmod +x)
8) Stawianie nowych usług wrzucaj do katalogu **scripts/**, a wykonywanie akcji systemowych do **actions/**

## Licencja
[MIT](https://choosealicense.com/licenses/mit/)
