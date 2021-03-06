#!/bin/bash

# Version:    1.0.10
# Author:     KeyofBlueS
# Repository: https://github.com/KeyofBlueS/debianupdate
# License:    GNU General Public License v3.0, https://opensource.org/licenses/GPL-3.0

# set to "true" to enable autoupdate of this script
UPDATE=true

if echo $UPDATE | grep -Eq '^(true|True|TRUE|si|NO|no)$'; then
echo -e "\e[1;34mControllo aggiornamenti per questo script...\e[0m"
if curl -s github.com > /dev/null; then
	SCRIPT_LINK="https://raw.githubusercontent.com/KeyofBlueS/debianupdate/master/debian_update.sh"
	UPSTREAM_VERSION="$(timeout -s SIGTERM 15 curl -L "$SCRIPT_LINK" 2> /dev/null | grep "# Version:" | head -n 1)"
	LOCAL_VERSION="$(cat "${0}" | grep "# Version:" | head -n 1)"
	REPOSITORY_LINK="$(cat "${0}" | grep "# Repository:" | head -n 1)"
	if echo "$LOCAL_VERSION" | grep -q "$UPSTREAM_VERSION"; then
		echo -e "\e[1;32m
## Questo script risulta aggiornato alla versione upstream
\e[0m
"
	else
		echo -e "\e[1;33m-----------------------------------------------------------------------------------	
## ATTENZIONE: questo script non risulta aggiornato alla versione upstream, visita:
\e[1;32m$REPOSITORY_LINK

\e[1;33m$LOCAL_VERSION (locale)
\e[1;32m$UPSTREAM_VERSION (upstream)
\e[1;33m-----------------------------------------------------------------------------------

\e[1;35mPremi invio per aggiornare questo script o attendi 10 secondi per andare avanti normalmente
\e[1;31m## ATTENZIONE: eventuali modifiche effettuate a questo script verranno perse!!!
\e[0m
"
		if read -t 10 _e; then
			echo -e "\e[1;34m	Aggiorno questo script...\e[0m"
			if [[ -L "${0}" ]]; then
				scriptpath="$(readlink -f "${0}")"
			else
				scriptpath="${0}"
			fi
			if [ -z "${scriptfolder}" ]; then
				scriptfolder="${scriptpath}"
				if ! [[ "${scriptpath}" =~ ^/.*$ ]]; then
					if ! [[ "${scriptpath}" =~ ^.*/.*$ ]]; then
					scriptfolder="./"
					fi
				fi
				scriptfolder="${scriptfolder%/*}/"
				scriptname="${scriptpath##*/}"
			fi
			if timeout -s SIGTERM 15 curl -s -o /tmp/"${scriptname}" "$SCRIPT_LINK"; then
				if [[ -w "${scriptfolder}${scriptname}" ]] && [[ -w "${scriptfolder}" ]]; then
					mv /tmp/"${scriptname}" "${scriptfolder}"
					chown root:root "${scriptfolder}${scriptname}" > /dev/null 2>&1
					chmod 755 "${scriptfolder}${scriptname}" > /dev/null 2>&1
					chmod +x "${scriptfolder}${scriptname}" > /dev/null 2>&1
				elif which sudo > /dev/null 2>&1; then
					echo -e "\e[1;33mPer proseguire con l'aggiornamento occorre concedere i permessi di amministratore\e[0m"
					sudo mv /tmp/"${scriptname}" "${scriptfolder}"
					sudo chown root:root "${scriptfolder}${scriptname}" > /dev/null 2>&1
					sudo chmod 755 "${scriptfolder}${scriptname}" > /dev/null 2>&1
					sudo chmod +x "${scriptfolder}${scriptname}" > /dev/null 2>&1
				else
					echo -e "\e[1;31m	Errore durante l'aggiornamento di questo script!
Permesso negato!
\e[0m"
				fi
			else
				echo -e "\e[1;31m	Errore durante il download!
\e[0m"
			fi
			LOCAL_VERSION="$(cat "${0}" | grep "# Version:" | head -n 1)"
			if echo "$LOCAL_VERSION" | grep -q "$UPSTREAM_VERSION"; then
				echo -e "\e[1;34m	Fatto!
\e[0m"
				exec "${scriptfolder}${scriptname}"
			else
				echo -e "\e[1;31m	Errore durante l'aggiornamento di questo script!
\e[0m"
			fi
		fi
	fi
fi
fi

mkdir -p $HOME/.status_files/
touch $HOME/.status_files/debianupdate-status

OPTIONS="-o Dpkg::Progress-Fancy=1 -o APT::Color=1 -o APT::Keep-Downloaded-Packages=0"
APT_LISTCHANGES_FRONTEND=none
STEP=pre_update_process

#echo -n "Checking dependencies... "
for name in apt-get aptitude fping
do
if which $name > /dev/null; then
	echo -n
else
	if [ -z "${missing}" ]; then
		missing="$name"
	else
		missing="$missing $name"
	fi
fi
done
if ! [ -z "${missing}" ]; then
	echo -e "\e[1;31mQuesto script dipende da \e[1;34m$missing\e[1;31m. Utilizza \e[1;34msudo apt-get install $missing
\e[1;31mInstalla le dipendenze necessarie e riavvia questo script.\e[0m"
	exit 1
fi

#echo -n "Checking recommended... "
for name in beep sox
do
if which $name > /dev/null; then
	echo -n
else
	if [ -z "${missing}" ]; then
		missing="$name"
	else
		missing="$missing $name"
	fi
fi
done
if ! [ -z "${missing}" ]; then
	echo -e "\e[1;31mQuesto script consiglia \e[1;34m$missing\e[1;31m per poter utilizzare le segnalazioni acustiche. Utilizza \e[1;34msudo apt-get install $missing
\e[1;31mSe preferisci, installa le dipendenze consigliate e riavvia questo script.\e[0m"
fi

menu(){
echo -e "\e[1;34m
## UPDATE DEBIAN\e[1;35m
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
if which beep | grep -q "beep"; then
	if lsmod | grep -q "pcspkr"; then
		AUDIO=BEEP
		BELL0=( "beep" )
		BELL1=( "beep -f 2000 -r 3 -D 50 -l 60 -n" )
		BELL2=( "beep -f 1000 -n -f 2000 -n -f 1500" )
	else
		AUDIO=NULL
		BELL0="echo -n"
		BELL1="echo -n"
		BELL2="echo -n"
	fi
else
	BELL0="echo -n"
	BELL1="echo -n"
	BELL2="echo -n"
fi
checkoldupdateprocess
}

audio_sox(){
if which sox | grep -q "sox"; then
	AUDIO=SOX
	GAIN=-50
	BELL0=( "play -qn -t alsa synth 0.2 square 1000 gain $GAIN fade h 0.01" )
	BELL1=( "play -qn -t alsa synth 0.13 square 2000 gain $GAIN : synth 0.13 square 2000 gain $GAIN fade h 0.01 : synth 0.13 square 2000 gain $GAIN fade h 0.01 : synth 0.3 square 1000 gain $GAIN fade h 0.01" )
	BELL2=( "play -qn -t alsa synth 0.2 square 1000 gain $GAIN : synth 0.2 square 2000 gain $GAIN fade h 0.01 : synth 0.2 square 1500 gain $GAIN fade h 0.01" )
else
	AUDIO=NULL
	BELL0="echo -n"
	BELL1="echo -n"
	BELL2="echo -n"
fi
checkoldupdateprocess
}

audio_null(){
AUDIO=NULL
BELL0="echo -n"
BELL1="echo -n"
BELL2="echo -n"
checkoldupdateprocess
}

checkoldupdateprocess(){
processpath="${0}"
processname="${processpath##*/}"
for pid in $(pgrep "$processname"); do
    if [ $pid != $$ ]; then
        updatekill
    fi 
done
ping_repo
}

updatekill(){
echo -e "\e[1;34m
## UPDATE DEBIAN\e[1;31m
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
if echo $AUDIO | grep -xq "BEEP"; then
	if lsmod | grep -q "pcspkr"; then
		BELL0=( "beep" )
		BELL1=( "beep -f 2000 -r 3 -D 50 -l 60 -n" )
		BELL2=( "beep -f 1000 -n -f 2000 -n -f 1500" )
	else
		BELL0="echo -n"
		BELL1="echo -n"
		BELL2="echo -n"
	fi
fi
REPO="$(cat /etc/apt/sources.list | grep "deb " | grep "http" | grep "main" | grep -m1 -oP '[^/]*\.[^\./]*(:|/)' | sed -e 's/\(:.*\/\|\/\)//g' | uniq)"
if fping -r0 -t 2000 $REPO | grep "alive"; then
	break
fi
	$BELL0 &
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
$BELL1 &
echo -e "\e[1;34m## INSTALLO EVENTUALI DIPENDENZE MANCANTI ##\e[0m"
sudo apt-get $OPTIONS -f install -y
if [ $? = 0 ]; then
	sudo dpkg --configure --pending
	sudo apt-get $OPTIONS -f install -y
fi
echo -e "\e[1;34m## CONFIGURO EVENTUALI PACCHETTI IN SOSPESO ##\e[0m"
sudo dpkg --configure --pending
STEP=update_process
ping_repo
}

update_process(){
echo -e "\e[1;31m
## UPDATE PROCESS STARTED (AUDIO: $AUDIO)
\e[0m"
$BELL1 &
echo "" > $HOME/.status_files/debianupdate-status
echo -e "\e[1;34m## UPDATE ##\e[0m" && sudo apt-get $OPTIONS update 2>&1 | tee $HOME/.status_files/debianupdate-status
if cat $HOME/.status_files/debianupdate-status | grep "Risoluzione di" | grep "$REPO" | grep "temporaneamente non riuscita"; then
	update_error
else
	STEP=upgrade1_process
	ping_repo
fi
}

upgrade1_process(){
$BELL1 &
echo "" > $HOME/.status_files/debianupdate-status
echo -e "\e[1;34m## UPGRADE ##\e[0m" && sudo apt-get $OPTIONS upgrade -y 2>&1 | tee $HOME/.status_files/debianupdate-status
if cat $HOME/.status_files/debianupdate-status | grep "Risoluzione di" | grep "$REPO" | grep "temporaneamente non riuscita"; then
	update_error
else
	STEP=upgrade2_process
	ping_repo
fi
}

upgrade2_process(){
$BELL1 &
echo "" > $HOME/.status_files/debianupdate-status
echo -e "\e[1;34m## UPGRADE (with-new-pkgs) ##\e[0m" && sudo apt-get $OPTIONS upgrade --with-new-pkgs -y 2>&1 | tee $HOME/.status_files/debianupdate-status
if cat $HOME/.status_files/debianupdate-status | grep "Risoluzione di" | grep "$REPO" | grep "temporaneamente non riuscita"; then
	update_error
else
	STEP=distupgrade_process
	ping_repo
fi
}

distupgrade_process(){
$BELL1 &
echo "" > $HOME/.status_files/debianupdate-status
echo -e "\e[1;34m## DIST-UPGRADE ##\e[0m" && sudo apt-get $OPTIONS dist-upgrade 2>&1 | tee $HOME/.status_files/debianupdate-status
if cat $HOME/.status_files/debianupdate-status | grep "Risoluzione di" | grep "$REPO" | grep "temporaneamente non riuscita"; then
	update_error
else
	echo "" > $HOME/.status_files/debianupdate-status
	clean_process
fi
}

clean_process(){
$BELL1 &
echo -e "\e[1;34m## AUTOREMOVE ##\e[0m" && sudo apt-get $OPTIONS autoremove -y
$BELL1 &
echo -e "\e[1;34m## PURGE ##\e[0m" && sudo aptitude purge ~c
#sudo dpkg --purge `dpkg -l | egrep "^rc" | cut -d' ' -f3`
$BELL1 &
echo -e "\e[1;34m## AUTOCLEAN ##\e[0m" && sudo apt-get $OPTIONS autoclean
$BELL1
echo -e "\e[1;34m## CLEAN ##\e[0m" && sudo apt-get $OPTIONS clean
$BELL1
$BELL2 &
echo -e "\e[1;34m## FINITO! ##\e[0m"
STEP=update_process
end
}

update_error(){
echo -e "\e[1;34m
REPOSYTORY @ $REPO è\e[0m" "\e[1;31mOFFLINE o rete non raggiungibile\e[1;31m
Premi INVIO per uscire, o attendi 1 secondo per riprovare\e[0m"
if read -t 1 _e; then
	exit 0
fi
ping_repo
}

end(){
echo -e "\e[1;35m
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

# Version:    1.0.10
# Author:     KeyofBlueS
# Repository: https://github.com/KeyofBlueS/debianupdate
# License:    GNU General Public License v3.0, https://opensource.org/licenses/GPL-3.0

### DESCRIZIONE
Lo script bash debianupdate esegue l'aggiornamento di un sistema Debian provando a ridurre al minimo le interazioni con l'utente, ad eseguire
soltanto operazioni sicure ed a richiedere l'intervento manuale unicamente per operazioni ritenute rischiose.

### CONFIGURAZIONE
È possibile aumentare o diminuire il volume del segnale acustico tramite la scheda audio (tramite sox), agendo sul valore della
variabile "GAIN" (linea 202; default -50)

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

if [ "$1" = "--menu" ]; then
	menu
elif [ "$1" = "--audio-beep" ]; then
	audio_beep
elif [ "$1" = "--audio-sox" ]; then
	audio_sox
elif [ "$1" = "--audio-null" ]; then
	audio_null
elif [ "$1" = "--help" ]; then
	givemehelp
else
#	menu
#	audio_beep
	audio_sox
#	audio_null
fi
