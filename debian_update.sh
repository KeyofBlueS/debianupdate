#!/bin/bash

# Version:    1.0.1
# Author:     KeyofBlueS
# Repository: https://github.com/KeyofBlueS/debianupdate
# License:    GNU General Public License v3.0, https://opensource.org/licenses/GPL-3.0

mkdir -p $HOME/.status_files/
touch $HOME/.status_files/debianupdate-status

APT_LISTCHANGES_FRONTEND=none
STEP=pre_update_process
REPO="$(cat /etc/apt/sources.list | grep "deb " | grep "http" | grep "main" | grep -m1 -oP '[^/]*\.[^\./]*(:|/)' | sed -e 's/\(:.*\/\|\/\)//g' | uniq)"

#echo -n "Checking dependencies... "
for name in fping apt aptitude
do
  [[ $(which $name 2>/dev/null) ]] || { echo -en "\n$name è richiesto da questo script. Utilizza 'sudo apt-get install $name'";deps=1; }
done
[[ $deps -ne 1 ]] && echo "" || { echo -en "\nInstalla le dipendenze necessarie e riavvia questo script\n";exit 1; }

for name in sox beep
do
  [[ $(which $name 2>/dev/null) ]] || { echo -en "\n$name è consigliato da questo script. Utilizza 'sudo apt-get install $name'";deps=1; }
done
[[ $deps -ne 1 ]] && echo "" || { echo -en "\nInstalla le dipendenze consigliate e riavvia questo script\n"; }

menu(){
echo -e "\e[1;34m
## UPDATE DEBIAN\e[0m"
echo -e "\e[1;31m
Che tipo di segnale acustico vuoi utilizzare?
(B)eep
(S)ox
(N)ull
(E)sci
\e[0m"
read -p "Scelta (B/S/N/E): " testo

case $testo in
    B|b)
	{
	echo -e "\e[1;34m
## HAI SCELTO BEEP\e[0m"
	audio_beep
	}
    ;;
    S|s)
	{
	echo -e "\e[1;34m
## HAI SCELTO SOX\e[0m"
	audio_sox
	}
    ;;
    N|n)
	{
	echo -e "\e[1;34m
## HAI SCELTO NULL\e[0m"
	audio_null
	}
    ;;
    E|e)
	{
	echo -e "\e[1;34mEsco dal programma\e[0m"
	exit 0
	}
    ;;
    *)
	echo -e "\e[1;31mHai sbagliato tasto.......cerca di stare un po' attento\e[0m"
	menu
    ;;
esac
}

audio_beep(){
AUDIO=BEEP
BEEP0=( "beep" )
BEEP1=( "beep -f 2000 -r 3 -D 50 -l 60 -n" )
BEEP2=( "beep -f 1000 -n -f 2000 -n -f 1500" )
checkoldupdateprocess
}

audio_sox(){
AUDIO=SOX
GAIN=-50
BEEP0=( "play -q -n synth 0.2 square 1000 gain $GAIN fade h 0.01" )
BEEP1=( "play -q -n synth 0.13 square 2000 gain $GAIN : synth 0.13 square 2000 gain $GAIN fade h 0.01 : synth 0.13 square 2000 gain $GAIN fade h 0.01 : synth 0.3 square 1000 gain $GAIN fade h 0.01" )
BEEP2=( "play -q -n synth 0.2 square 1000 gain $GAIN : synth 0.2 square 2000 gain $GAIN fade h 0.01 : synth 0.2 square 1500 gain $GAIN fade h 0.01" )
checkoldupdateprocess
}

audio_null(){
AUDIO=NULL
BEEP0="echo BEEP"
BEEP1="echo BEEP"
BEEP2="echo BEEP"
checkoldupdateprocess
}

checkoldupdateprocess(){
for pid in $(pgrep "debianupdate"); do
    if [ $pid != $$ ]; then
        updatekill
    fi 
done
ping_repo
}

updatekill(){
echo -e "\e[1;34m
## UPDATE DEBIAN\e[0m"
echo -e "\e[1;31m
Un altro processo di aggiornamento è già in esecuzione!
Non è consigliabile terminare un processo di aggiornamento
in corso! Terminarlo soltanto se si è sicuri che il vecchio
processo si trovi in una situazione di stallo

Vuoi terminare il precedente processo di aggiornamento
e procedere con questo?
(S)i
(N)o\e[0m"
read -p "Scelta (S/N): " testo

case $testo in
    S|s)
	{
	echo -e "\e[1;34m
## Termino il precedente processo di aggiornamento...\e[0m"
	kill -9 $pid
	sudo killall -9 apt-get
	sudo killall -9 aptitide
	ping_repo
	}
    ;;
    N|n)
	{
	echo -e "\e[1;34m
## Esco dal programma\e[0m"
	exit 0
	}
    ;;
    *)
	echo -e "\e[1;31mHai sbagliato tasto.......cerca di stare un po' attento\e[0m"
	updatekill
    ;;
esac
}

ping_repo(){
while true
do
fping -r0 -t 2000 $REPO | grep "alive"
if [ $? = 0 ]; then
	break
fi
	$BEEP0
	echo -e "\e[1;34m
REPOSYTORY @ $REPO è\e[0m" "\e[1;31mOFFLINE o rete non raggiungibile\e[0m"
	echo -e "\e[1;31mPremi INVIO per uscire, o attendi 1 secondo per riprovare\e[0m"
	if read -t 1 _e; then
		exit 0
	fi
done
echo "" > $HOME/.status_files/debianupdate-status
$STEP
}

pre_update_process(){
echo -e "\e[1;31m
## PRE UPDATE PROCESS STARTED (AUDIO: $AUDIO)
\e[0m"
$BEEP1
echo -e "\e[1;34m## INSTALLO EVENTUALI DIPENDENZE MANCANTI ##\e[0m" && sudo apt-get -f install -y
echo -e "\e[1;34m## CONFIGURO EVENTUALI PACCHETTI IN SOSPESO ##\e[0m" && sudo dpkg --configure --pending
STEP=update_process
ping_repo
}

update_process(){
echo -e "\e[1;31m
## UPDATE PROCESS STARTED (AUDIO: $AUDIO)
\e[0m"
$BEEP1
echo "" > $HOME/.status_files/debianupdate-status
echo -e "\e[1;34m## UPDATE ##\e[0m" && sudo apt-get update 2>&1 | tee $HOME/.status_files/debianupdate-status
	cat $HOME/.status_files/debianupdate-status | grep -q 'Risoluzione di "$REPO" temporaneamente non riuscita'
	if [ $? = 0 ]; then
		update_error
	else
	STEP=upgrade1_process
	ping_repo
	fi
}

upgrade1_process(){
$BEEP1
echo "" > $HOME/.status_files/debianupdate-status
echo -e "\e[1;34m## UPGRADE ##\e[0m" && sudo apt-get upgrade -y 2>&1 | tee $HOME/.status_files/debianupdate-status
	cat $HOME/.status_files/debianupdate-status | grep -q 'Risoluzione di "$REPO" temporaneamente non riuscita'
	if [ $? = 0 ]; then
		update_error
	else
	STEP=upgrade2_process
	ping_repo
	fi
}

upgrade2_process(){
$BEEP1
echo "" > $HOME/.status_files/debianupdate-status
echo -e "\e[1;34m## UPGRADE (with-new-pkgs) ##\e[0m" && sudo apt-get upgrade --with-new-pkgs -y 2>&1 | tee $HOME/.status_files/debianupdate-status
	cat $HOME/.status_files/debianupdate-status | grep -q 'Risoluzione di "$REPO" temporaneamente non riuscita'
	if [ $? = 0 ]; then
		update_error
	else
	STEP=distupgrade_process
	ping_repo
	fi
}

distupgrade_process(){
$BEEP1
echo "" > $HOME/.status_files/debianupdate-status
echo -e "\e[1;34m## DIST-UPGRADE ##\e[0m" && sudo apt-get dist-upgrade 2>&1 | tee $HOME/.status_files/debianupdate-status
	cat $HOME/.status_files/debianupdate-status | grep -q 'Risoluzione di "$REPO" temporaneamente non riuscita'
	if [ $? = 0 ]; then
		update_error
	else
	echo "" > $HOME/.status_files/debianupdate-status
	clean_process
	fi
}

clean_process(){
$BEEP1
echo -e "\e[1;34m## AUTOREMOVE ##\e[0m" && sudo apt-get autoremove -y
$BEEP1
echo -e "\e[1;34m## PURGE ##\e[0m" && sudo aptitude purge ~c
#sudo dpkg --purge `dpkg -l | egrep "^rc" | cut -d' ' -f3`
$BEEP1
echo -e "\e[1;34m## AUTOCLEAN ##\e[0m" && sudo apt-get autoclean
$BEEP1
echo -e "\e[1;34m## CLEAN ##\e[0m" && sudo apt-get clean
$BEEP1
$BEEP2
echo -e "\e[1;34m## FINITO! ##\e[0m"
STEP=update_process
end
}

update_error(){
echo -e "\e[1;34m
REPOSYTORY @ $REPO è\e[0m" "\e[1;31mOFFLINE o rete non raggiungibile\e[0m"
echo -e "\e[1;31mPremi INVIO per uscire, o attendi 1 secondo per riprovare\e[0m"
if read -t 1 _e; then
	exit 0
fi
ping_repo
}

end(){
echo -e "\e[1;31m
Come vuoi proseguire?
(U)pdate
(E)sci dal programma
\e[0m"
read -p "Scelta (U/E): " testo

case $testo in
    U|u)
	{
  echo -e "\e[1;34m
## HAI SCELTO UPDATE\e[0m"
	STEP=pre_update_process
	ping_repo
	}
    ;;
    E|e|"")
	{
	echo -e "\e[1;34mEsco dal programma\e[0m"
	exit 0
	}
    ;;
    *)
	echo -e "\e[1;31m## HAI SBAGLIATO TASTO.......cerca di stare un po' attento\e[0m"
	end
    ;;
esac
}

givemehelp(){
echo "
# debianupdate

# Version:    1.0.1
# Author:     KeyofBlueS
# Repository: https://github.com/KeyofBlueS/debianupdate
# License:    GNU General Public License v3.0, https://opensource.org/licenses/GPL-3.0

### DESCRIZIONE
Lo script bash debianupdate esegue l'aggiornamento di un sistema Debian provando a ridurre al minimo le interazioni con l'utente, ad eseguire
soltanto operazioni sicure ed a richiedere l'intervento manuale unicamente per operazioni ritenute rischiose.

### CONFIGURAZIONE
È possibile aumentare o diminuire il volume del segnale acustico tramite la scheda audio (tramite sox), agendo sul valore della
variabile "GAIN" (linea 86; default -50)

### UTILIZZO
Per utilizzare lo script basta digitare su un terminale:
$ debianupdate

È possibile utilizzare le seguenti opzioni:
--menu	      Avvia il menu principale

--audio-beep  Imposta il segnale acustico tramite lo speaker interno (richiede beep)

--audio-sox   Imposta il segnale acustico tramite la scheda audio (default; richiede sox)

--audio-null  Disattiva il segnale acustico

--help        Visualizza una descrizione ed opzioni di debianupdate
"
exit 0
}

if [ "$1" = "--menu" ]
then
   menu
elif [ "$1" = "--audio-beep" ]
then
   audio_beep
elif [ "$1" = "--audio-sox" ]
then
   audio_sox
elif [ "$1" = "--audio-null" ]
then
   audio_null
elif [ "$1" = "--help" ]
then
   givemehelp
else
#   menu
#   audio_beep
   audio_sox
#   audio_null
fi
