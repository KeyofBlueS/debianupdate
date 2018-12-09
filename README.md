# debianupdate

# Version:    1.0.0
# Author:     KeyofBlueS
# Repository: https://github.com/KeyofBlueS/debianupdate
# License:    GNU General Public License v3.0, https://opensource.org/licenses/GPL-3.0

### DESCRIZIONE
Lo script bash debianupdate esegue l'aggiornamento di un sistema Debian provando a ridurre al minimo le interazioni con l'utente, ad eseguire
soltanto operazioni sicure ed a richiedere l'intervento manuale unicamente per operazioni ritenute rischiose.

### INSTALLAZIONE
```sh
curl -o /tmp/debian_update.sh 'https://raw.githubusercontent.com/KeyofBlueS/debianupdate/master/debian_update.sh'
sudo mkdir -p /opt/debian-update/
sudo mv /tmp/debian_update.sh /opt/debian-update/
sudo chown root:root /opt/debian-update/debian_update.sh
sudo chmod 755 /opt/debian-update/debian_update.sh
sudo chmod +x /opt/debian-update/debian_update.sh
sudo ln -s /opt/debian-update/debian_update.sh /usr/local/bin/debianupdate
```

### CONFIGURAZIONE
È possibile aumentare o diminuire il volume del segnale acustico tramite la scheda audio (tramite sox), agendo sul valore della
variabile "GAIN" (linea 85; default "-50")

### UTILIZZO
Per utilizzare lo script basta digitare su un terminale:
```sh
$ debianupdate
```

È possibile utilizzare le seguenti opzioni:
```sh
--menu	      Avvia il menu principale

--audio-beep  Imposta il segnale acustico tramite lo speaker interno (richiede beep)

--audio-sox   Imposta il segnale acustico tramite la scheda audio (default; richiede sox)

--audio-null  Disattiva il segnale acustico

--help        Visualizza una descrizione ed opzioni di debianupdate
```
