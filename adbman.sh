#!/bin/bash

# MIT License

# Copyright (c) 2022 Marko Ćošić

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

set +H
#»STARTUP CHECK
function _adbman_check(){
	local CADB=""
	local -i EADB=0
	CADB="$(adb version 2>/dev/null)"
	EADB=$?
	[ $EADB -ne 0 ] &&\
		echo "'adb' not found! Ensure 'adb' is in PATH!" &&\
	exit $EADB
	CADB="$(adb shell whoami 2>/dev/null)"
	EADB=$?
	[ $EADB -ne 0 ] &&\
		echo "adb not connected! Check: 'adb devices'!" &&\
	exit $EADB
	#»DEBUG/PARALOG
	CHECKER=0
	DEBUG=0
	PARALOG=0
	[ "$1" == "debug" ] && DEBUG=1
	[ "$1" == "paralog" ] && PARALOG=1
	TIFU='';
}
_adbman_check $@
# echo "$(date +'[%T:%N]')>_adbman_check"

#»ICONS & CHARS
function _adbman_icons(){
# Chars: MENU field Separator(chs), Column(chc), Newline(nln), Tab(tab)
chs='§' 
chc='¶'
nln='
'; tab='	'
# Icons:
#■□▢▣▤▥▦▧▨▩
#∎⧈⧇⧆⊟⧄⧅⟎⟏⌧⍰⍯⌷⎕⌸⌹⌺⌻⌼☑☒☐⍇⍗⍄⍃⍈⍐⍍⍔☐⚿⌷⌸⍌⍓⍞⍠⍯⍰
#⬤⊙⦾⊛⊝⊘⦸⦶⦷⊗⦹⦺⦻⦼⦿⧀⧁᮰⍟⨀⨁⨂⌽⌾
#⟁⚠ⵠ⨹⨻⧌⨺⧊⧋⍙⧍✔✖★•⬅⬆⬇⬈⬉⬊⬋⬌⬍←↑→↓↔↕↖↗↘↙
#⬛⬜⚪⚫⚡❓❔❕❤⏩⏪⏫⏬⏰⏳〈〉
APPCHD=❎ #⊘⧄:disabled
APPCHE=✅ #⦾☑:enabled
APPCHF=⛔ #⊝⊟:suspended
APPCHH=⭕ #᮰☐:hidden
APPCHU=❌ #⊗☒:uninstalled
APPCHS=❗ #⦶⚿:sys
APPCHT=⭐ #⊛⧆:usr
APPCH0=☐
APPCH1=☑
PRMCHD=⌸  #:declared
PRMCHI=⍗  #:installed
PRMCHN=⍐  #:runtime
PRMCHR=⍍  #:restricted
SORT09='⁰↓₉'
SORT90='⁹↓₀'
SORTAZ='ᴬ↓ᴢ'
SORTZA='ᶻ↓ᴀ'
}
_adbman_icons
# echo "$(date +'[%T:%N]')>_adbman_icons"

#»TIME FUNCTION
#»Calculate function execution time
function _tifu(){
	local tifu="$(date +'[%T]')"
	tis=$( date +%s%N );
	$@;
	tie=$( date +%s%N );
	tifu+="$@|$(bc <<<"scale=3;($tie-$tis)/1000000000" |\
		sed 's/^\./0./;s/$/sec/')";
	TIFU+="$tifu
";
}

#»FILE LIST
#»List (only) files recursively: _adbman_flist "/path/to/dir"
function _adbman_flist(){
	[ -d "$1" ] && for y in "$1"/*; do
		if [ -d "$y" ]; then _adbman_flist "$y";
		else [ -f "$y" ] && echo "$y"; fi;
	done || return 1;
}

#»DIALOG VARS
#»Set Dialog Variables
function _adbman_diavars(){
#»dialog "${DIAOPT[@]}" "$DIABOX" "$LABEL" "$HGHT" "$WDTH"
DIABOX='';      # --menu|--checklist|--radiolist|--inputmenu|--textbox|--yesno|--msgbox
DTITLE='';      # --title "$DTITLE"
BTITLE='';      # --backtitle "$BTITLE"
BTLYS='';       # --yes-label "$BTLYS"
BTLNO='';       # --no-label "$BTLNO"
BTLOK='';       # --ok-label "$BTLOK"
BTLCL='';       # --cancel-label "$BTLCL"
BTLXT='';       # --extra-button --extra-label "$BTLXT"
BTLHL='';       # --help-button --help-label "$BTLHL"
BTDEF='';       # --default-button "$BTDEF" (ok|cancel|extra|help)
DITAG='';       # --default-item "$DITAG"
LABEL='';       # Dialog Label (text)
MENU='';        # Menu/Checklist/InputMenu list: tag1:item1:..
((HGHT=-2));    # Height of dialog box
((WDTH=-2));    # Width of dialog box
((SIZE=-2));    # Size of MENU (list-height|menu-height)
((WIDTHMIN=50));# Minimum dialog width
SORT=();        # Sort options array
DIALIST=();     # Array of MENU elements
DIAOPT=();      # Dialog other common options
DIALOG=();      # Dialog command with options array
DIAOUT=();      # Dialog output array
((DIACODE=-2)); # Dialog return code
DINPUT='';      # Dialog InputMenu output: RENAMED $DITAG $DINPUT
((DINPUTOK=0)); # DINPUTOK=0:empty|1:ok|2:bad, run:eval "$CHECKDINPUT"
DIASTATE='';    # Saved Dialog options list, use:eval "$SAVEDIASTATE" | "$LOADDIASTATE"
DIALID='';      # Dialog Menu LEVEL ID (Main|Applist|Appinfo|Install|Confirm|Message|...)
DIALVL='';      # Dialog Menu LEVEL (:Main:Applist:Appinfo:Install:Confirm:Message:)
#»»»»»»»»»»»
DIAOPT=("--no-shadow" "--colors" "--column-separator" "${chc}");
}
_tifu _adbman_diavars

#»DIALOG PARAMETER FUNCTIONS: eval "$PARAMETER"
function _adbman_diavarf(){
#»Check DINPUT for invalid characters, DINPUTOK=0:empty|1:ok|2:bad
CHECKDINPUT=\
'if [ -n "$DINPUT" ]; then \
l=$(echo "$DINPUT" | sed "s/[-_\.]//g;s/[[:alnum:]]//g");
if [ -n "$l" ]; then dialog \
--title "Directory and File naming restriction" \
--msgbox "Only alphanumeric, hyphen (-), underscore (_), and dot (.) characters alowed!" 6 50;
DINPUTOK=2;
else DINPUTOK=1; fi;
else DINPUTOK=0; fi;'
#»Switch 'on|off' checklist MENU per DITAG
SETCHECKLIST=\
'[ -z "$MENU" ] &&\
echo "SETCHECKLIST error: empty MENU list!" && exit 1;
SIZE=$(sed -n "\$=;d" <<<"$MENU");
for ((i=1;i<=$SIZE;i++)); do \
j=$(echo "$MENU" |\
sed -n "${i}s/^\([0-9A-Z]\+\)${chs}.*/\1/p");
[ -z "$j" ] && j="$i";
j=$(sed -n "/ $j /p" <<<"$DITAG");
[ -n "$j" ] &&\
MENU=$(sed "${i}s/${chs}off$/${chs}on/" <<<"$MENU") ||\
MENU=$(sed "${i}s/${chs}on$/${chs}off/" <<<"$MENU");	done;'
#»Switch 'on|off' checklist MENU, remove unchanged
RETCHECKLIST=\
'[ -z "$MENU" ] &&\
echo "RETCHECKLIST error: empty MENU list!" && exit 1;
SIZE=$(sed -n "\$=;d" <<<"$MENU"); l="";
for ((i=1;i<=$SIZE;i++)); do \
j=$(echo "$MENU" |\
sed -n "${i}s/^\([0-9A-Z]\+\)${chs}.*/\1/p");
[ -z "$j" ] && j="$i";
j=$(sed -n "/ $j /p" <<<"$DITAG");
[ -n "$j" ] &&\
l+="$(sed -n "${i}s/${chs}off$/${chs}on/p" <<<"$MENU")$nln" ||\
l+="$(sed -n "${i}s/${chs}on$/${chs}off/p" <<<"$MENU")$nln"; done;
[ -n "$l" ] && MENU=$(sed "/^\$/d" <<<"$l") || MENU="";'
#»Set LABEL='Package:[sys|user]<package>'
SETLABELAPP=\
'[ "${APP_sys}" == "SYSTEM" ] &&\
LABEL="Package:${APPCHS}$APPNAME" ||\
LABEL="Package:${APPCHT}$APPNAME";'
#»SAVE/LOAD/CLEAR DIALOG (only DTITLE, BTDEF, DITAG) to DIASTATE
#»Save (DTITLE, BTDEF, DITAG) to DIASTATE (Trim:' [*' from DTITLE)
SAVEDIASTATE=\
'DIASTATE=$(sed "/${DTITLE%% [*}/d" <<<"$DIASTATE");
DIASTATE+="${nln}DTITLE=${DTITLE%% [*}${chs}BTDEF=$BTDEF=BTDEF${chs}DITAG=$DITAG=DITAG${chs}";
DIASTATE=$(sed "/^\$/d" <<<"$DIASTATE")'
#»Load DIALOG state (DTITLE, BTDEF, DITAG) from DIASTATE
LOADDIASTATE=\
'BTDEF=$(echo "$DIASTATE" |\
sed -n "/${DTITLE%% [*}/s/.*${chs}BTDEF=\(.*\)=BTDEF${chs}.*/\1/p");
DITAG=$(echo "$DIASTATE" |\
sed -n "/${DTITLE%% [*}/s/.*${chs}DITAG=\(.*\)=DITAG${chs}.*/\1/p");'
#»Clear current DIALOG state (DTITLE, BTDEF, DITAG) from DIASTATE
CLEARDIASTATE=\
'DIASTATE=$(echo "$DIASTATE" | sed -n "/${DTITLE%% [*}/d");'
CLEARDIAVARS='DIALOG=(); DIALIST=(); DTITLE=""; DIALID=""; BTITLE="";
DIABOX=""; DIAOUT=""; DIACODE=-2; DITAG=""; DINPUT=''; DINPUTOK=0;
BTDEF=""; BTLYS=""; BTLNO=""; BTLOK=""; BTLCL=""; BTLXT=""; BTLHL="";
LABEL=""; MENU=""; WDTH=-2; HGHT=-2; SIZE=-2;'
CLEARDIABTTN='BTDEF=""; BTLYS=""; BTLNO=""; BTLOK=""; BTLCL=""; BTLXT=""; BTLHL="";'
#»Set Custom Parameters per MenuID DIALID to ParaLog argument PARARG
PARARGSET='PARARG=("$DTITLE");
[ "$DIALID" == "AppInfo" ] && PARARG+=("APPSTATS" "APPACTTS");
[ "$DIALID" == "Options" ] && PARARG+=("$ADBMANC");
[ "$DIALID" == "Settings" ] && PARARG+=("${!BTLIST[$LSTATE]}");
[ "$DIALID" == "User" ] && PARARG+=("PKGDUMP");'
}
_tifu _adbman_diavarf
# echo "$(date +'[%T:%N]')>_adbman_dialogvars"

#»TEXT BOUDARY
#»Outputs "WDTH" "HGHT" of a multiline parameter
#»WDTH=longest line; HGHT=number of lines
function _adbman_tb(){
	# $1=text, $2=border width, $3=border height
	local i j k l;
	# set -xv
	if [ -n "$1" ]; then
		((i=$WIDTHMIN)); #Width
		j=$(echo "$1" | sed '$=;d'); #Height
		# Remove formatting; replace tab with spaces
		l=$(echo "$1" |\
			sed -e 's/\\Z.//g' -e 's/	/        /g');
		# Remove 'DITAG:'; k='' if not MENU
		k=$(echo "$l" | sed -n "s/^[0-9]\+${chs}\|^[A-Z]${chs}//p");
		# Reduce WIDTHMIN - (#DITAG) - (#'  ') if MENU
		[ -n "$k" ] && l="$k" && ((i=$i-${#j}-2));
		# Reduce WIDTHMIN - border width
		[ -n "$2" ] && [ $2 -gt 0 ] && ((i-=$2));
		# Print only lines longer than $i
		l=$(echo "$l" | sed -n "/.\{$i,\}/p")
		# Get longest line if $l not empty
		if [ -n "$l" ]; then
			# Mask lines with '1'; sort; last line is longest
			l=$(echo "$l" |	sed 's/./1/g' | sort -n | sed -n '$p');
			# The longest line length
			[ -n "$l" ] && ((i=${#l}))
			# Add back removed #DITAG+#(' ') width if MENU
			[ -n "$k" ] && ((i=${#l}+${#j}+2));
			# Add border width
			[ -n "$2" ] && [ $2 -gt 0 ] && ((i+=$2));
		else ((i=$WIDTHMIN));
		fi;
	else i=0; j=0;
	fi;
	[ -n "$3" ] && [ $3 -gt 0 ] && ((j+=$3))
	echo "$i" "$j";
	# set +xv
}

#»PARAMETER LOG
#»Display variables Dialog
#»_adbman_paralog 'Title' [ ["/dir/file"] | ["VAR1"] ["VAR2"] .. ]
function _adbman_paralog(){
local MNU='' LBL='' TTL="$1" BXT='times'
local LBLV='' LBLT='' g='' l='';
local -i DXC=0 PDW=0 PDH=0;
#Create vars Label
LBLV="|DIALID=$DIALID|DIALVL=$DIALVL|\n";
[ -n "$DIABOX" ] && LBLV+="|DIABOX=$DIABOX|";
[ -n "$DTITLE" ] && LBLV+="DTITLE=$DTITLE|";
[ -n "$BTITLE" ] && LBLV+="\n|BTITLE=$BTITLE|";
[ -n "$BTLYS$BTLNO$BTLOK$BTLCL$BTLXT$BTLHL" ] && LBL+="\n";
[ -n "$BTLYS" ] && LBLV+="|BTLYS=$BTLYS|";
[ -n "$BTLNO" ] && LBLV+="|BTLNO=$BTLNO|";
[ -n "$BTLOK" ] && LBLV+="|BTLOK=$BTLOK|";
[ -n "$BTLCL" ] && LBLV+="|BTLCL=$BTLCL|";
[ -n "$BTLXT" ] && LBLV+="|BTLXT=$BTLXT|";
[ -n "$BTLHL" ] && LBLV+="|BTLHL=$BTLHL|";
[ "$WDTH" -ge -1 ] && LBLV+="\n|WDTH=$WDTH|";
[ "$HGHT" -ge -1 ] && LBLV+="|HGHT=$HGHT|";
[ "$SIZE" -ge -1 ] && LBLV+="|SIZE=$SIZE|";
[ "$DIACODE" -ge -1 ] && LBLV+="\n|DIACODE=$DIACODE|";
[ -n "$BTDEF" ] && LBLV+="|BTDEF=$BTDEF|";
[ -n "$DIAOUT" ] && LBLV+="\n|DIAOUT=$DIAOUT|";
[ -n "$DITAG" ] && LBLV+="|DITAG=$DITAG|";
[ -n "$DINPUT" ] && LBLV+="|DINPUT=$DINPUT|";
[ -n "$DEVUSER" ] && LBLV+="\n|DEVUSER=$DEVUSER|";
[ -n "$APPNAME" ] && LBLV+="|APPNAME=$APPNAME||APPIX=$APPIX||APPLX=$APPLX|";
[ -n "$DIASTATE" ] &&\
	LBLV+="\n\Zu|DIASTATE|\Zn\n${DIASTATE//$'\n'/'\n'}\n——————————";
[ -n "$ADBOPT" ] &&\
	LBLV+="\n\Zu|ADBOPT|\Zn\n$ADBOPT\n————————";
[ -n "$ADBCOM" ] &&\
	LBLV+="\n\Zu|ADBCOM|\Zn\n$ADBCOM\n————————";
[ -n "$ADBOUT" ] &&\
	LBLV+="\n\Zu|ADBOUT|\Zn\n$ADBOUT\n————————";
[ -n "$LOG" ] && LBLV+="\n\Zu|LOG|\Zn\n$LOG\n—————";
[ -n "$OUT" ] && LBLV+="\n\Zu|OUT|\Zn\n$OUT\n—————";
[ -n "$LABEL" ] && LBLV+="\n\Zu|LABEL|\Zn\n$LABEL\n———————";
[ -n "$MENU" ] && MNU=$(sed -n '1,100p' <<<"$MENU") &&\
	LBLV+="\n\Zu|MENU|\Zn\n${MNU//$'\n'/'\n'}\n——————\n(head 100)";
if [ -n "$APP_apk" ]; then
	LBLV+="\n\Zu|APPSTATUS|\Zn" &&\
		LBLV+="\n|APP_apk=${APP_apk}|";
	[ -n "$APP_cpa" ] && LBLV+="\n|APP_cpa=${APP_cpa}|";
	[ -n "$APP_rpa" ] && LBLV+="\n|APP_rpa=${APP_rpa}|";
	[ -n "$APP_dpa" ] && LBLV+="\n|APP_dpa=${APP_dpa}|";
	[ -n "$APP_fla" ] && LBLV+="\n|APP_fla=${APP_fla}|";
	[ -n "$APP_enb" ] && LBLV+="\n|APP_enb=${APP_enb}|";
	[ -n "$APP_hid" ] && LBLV+="\n|APP_hid=${APP_hid}|";
	[ -n "$APP_ins" ] && LBLV+="\n|APP_ins=${APP_ins}|";
	[ -n "$APP_sus" ] && LBLV+="\n|APP_sus=${APP_sus}|";
	[ -n "$APP_uid" ] && LBLV+="\n|APP_uid=${APP_uid}|";
	[ -n "$APP_gid" ] && LBLV+="\n|APP_gid=${APP_gid}|";
	[ -n "$APP_ver" ] && LBLV+="\n|APP_ver=${APP_ver}|";
	[ -n "$APP_sys" ] && LBLV+="\n|APP_sys=${APP_sys}|";
	[ -n "$APP_sta" ] && LBLV+="\n|APP_sta=${APP_sta}|";
	[ -n "$APP_std" ] && LBLV+="\n|APP_std=${APP_std}|";
	[ -n "$APP_stc" ] && LBLV+="\n|APP_stc=${APP_stc}|";
	[ -n "$APP_stt" ] && LBLV+="\n|APP_stt=${APP_stt}|";
	[ -n "$APP_prn" ] && LBLV+="\n|APP_prn=${APP_prn}|";
	[ -n "$APP_prm" ] && LBLV+="\n\Zu|APP_prm|\Zn\n" &&\
	LBLV+=$(sed -n '1,100p' <<<"${APP_prm//$'\n'/'\n'}") &&\
	LBLV+="\n—————\n(head 100)";
fi
[ -n "$2" ] && if [ -f "$2" ]; then
	# Add file to msgbox
	LBLV+="\n\Zu|""$2""|\Zn\n";
	LBLV+=$(sed -n '1,100p' "$2");
	LBLV+="\n—————\n(head 100)";
else
	# Add variable(s) to msgbox
	[ ${#@} -ge 2 ] && for ((i=2;i<=${#@};i++)); do
		g=${!i}
		l=$(sed -n '$=;d' <<<"${!g}")
		if [ "$l" -eq 1 ]; then
			LBLV+="\n|${!i}=${!g}|";
		else
			l=$(sed -n '1,100p' <<<"${!g}");
			LBLV+="\n\Zu|${!i}|\Zn\n";
			LBLV+="${l//$'\n'/'\n'}";
			LBLV+="\n—————\n(head 100)";
		fi
	done
fi;
# Create times Label
LBLT="Function Execution Times:$nln$TIFU"

while true; do
	case "$BXT" in
	'times') LBL="$LBLV";;
	'vars')  LBL="$LBLT";;
	esac;
	PDW=-1; PDH=-1;
	# l="$(_adbman_tb "${LBL//'\n'/$'\n'}" 5 6)";
	# [ "${l%% *}" -gt 30 ] && PDW=${l%% *} || PDW=30;
	# PDH=${l#* };
	dialog --no-shadow --colors \
		--title "$TTL" \
		--extra-button --extra-label "$BXT" \
		--msgbox "$LBL" $PDH $PDW \
		--max-input 8192 \
		--output-fd 1;
	DXC=$?;
	case $DXC in
	0|255)#OK|<ESC>
		break;;
	3)#EXTRA
		case "$BXT" in
		'vars')		BXT='times';;
		'times')	BXT='vars';;
		esac;;
	esac
done
unset MNU LBL LBLV LBLT TTL BXT PDW PDH DXC l;
}

#»ADBman DIALOG
#»Create Dialog from parameters
#»_adbman_dialog ['noWH'] skips WDTH and HGHT calculation
function _adbman_dialog(){
	# Calculate DIALOG LABEL/+MENU WDTH, HGHT, SIZE
	TB=();
	[ -n "$MENU" ] &&\
		SIZE=$(sed "\$=;d" <<<"$MENU") || SIZE=0;
	if [ ! "$1" == "noWH" ]; then
		[ "$DIABOX" == "--textbox" ] && TB=(-1 -1) ||\
		TB=($(_adbman_tb "${LABEL//'\n'/$'\n'}" 5 5));
		WDTH=${TB[0]}; HGHT=${TB[1]};
		[ "$DIABOX" == "--menu" ] &&\
			TB=($(_adbman_tb "$MENU" 6 2)) && ((HGHT+=${TB[1]}));
		[ "$DIABOX" == "--checklist" ] &&\
			TB=($(_adbman_tb "$MENU" 15 2)) && ((HGHT+=${TB[1]}));
		[ "$DIABOX" == "--radiolist" ] &&\
			TB=($(_adbman_tb "$MENU" 15 2)) && ((HGHT+=${TB[1]}));
		[ "$DIABOX" == "--inputmenu" ] &&\
			TB=($(_adbman_tb "$MENU" 15)) && ((HGHT+=${TB[1]}*3+2));
		[ "${TB[0]}" -gt "$WDTH" ] && WDTH=${TB[0]};
		unset TB;
	fi;
	# Create DIALOG command array
	if [ -n "$DIABOX" ]; then
		DIALOG=(dialog);
		DIALOG+=("${DIAOPT[@]}");
		# Only nonempty option params included
		[ -n "$BTLYS" ] &&\
			DIALOG+=('--yes-label' "$BTLYS");
		[ -n "$BTLNO" ] &&\
			DIALOG+=('--no-label' "$BTLNO");
		[ -n "$BTLOK" ] &&\
			DIALOG+=('--ok-label' "$BTLOK");
		[ -n "$BTLCL" ] &&\
			DIALOG+=('--cancel-label' "$BTLCL");
		[ -n "$BTLXT" ] &&\
			DIALOG+=('--extra-button' '--extra-label' "$BTLXT");
		[ -n "$BTLHL" ] &&\
			DIALOG+=('--help-button' '--help-label' "$BTLHL");
		[ -n "$BTDEF" ] &&\
			DIALOG+=('--default-button' "$BTDEF");
		[ -n "$DITAG" ] &&\
			DIALOG+=('--default-item' "$DITAG");
		[ -n "$BTITLE" ] &&\
			DIALOG+=('--backtitle' "$BTITLE");
		[ -n "$DTITLE" ] &&\
			DIALOG+=('--title' "$DTITLE");
		# --menu|--checklist|--inputmenu
		if [ "$DIABOX" == "--menu" ] ||\
			[ "$DIABOX" == "--checklist" ] ||\
			[ "$DIABOX" == "--radiolist" ] ||\
			[ "$DIABOX" == "--inputmenu" ]; then
			DIALOG+=("$DIABOX" "$LABEL" $HGHT $WDTH $SIZE);
			readarray -t DIALIST <<<"${MENU//$chs/$'\n'}";
			DIALOG+=("${DIALIST[@]}");
		else
			# --msgbox|--yesno|--textbox|--dselect
			DIALOG+=("$DIABOX" "$LABEL" $HGHT $WDTH);
		fi;
		# Set DIALVL Menu path
		local lvl=$([ -n "$DIALID" ] && echo "$DIALVL" |\
			sed -n "/$DIALID/s/>$DIALID.*/>$DIALID/p");
		[ -n "$lvl" ] && DIALVL="$lvl" || DIALVL+=">$DIALID";
		unset lvl;
		# Execute dialog
		while true; do
			DIAOUT="$("${DIALOG[@]}" --output-fd 1)";
			DIACODE=$?;
			# Call Paralog with <ESC>
			[ $PARALOG -eq 0 ] && break ||\
				if [ $DIACODE -eq 255 ]; then
					eval "$PARARGSET"; # Set PARARG
					_adbman_paralog "${PARARG[@]}";
				else break;
				fi
		done
		# Set BTDEF pressed, DITAG choice, DINPUT user input
		case $DIACODE in
		0)	BTDEF='ok';;
		1)	BTDEF='cancel';;
		2)	BTDEF='help';;
		3)	BTDEF='extra';;
		esac;
		case "$DIABOX" in
		'--inputmenu')
			[ "${DIAOUT%% *}" == "HELP" ] &&\
				DITAG="${DIAOUT#* }" ||	DITAG="$DIAOUT";
			if [ "${DIAOUT%% *}" == "RENAMED" ]; then
				DITAG="${DIAOUT#* }"; # Remove first param
				DINPUT="${DITAG#* }"; # Remove second param
				DITAG="${DITAG%% *}"; # Remove after second param
			fi;
			;;
		'--menu')
			[ "${DIAOUT%% *}" == "HELP" ] &&\
				DITAG="${DIAOUT#* }" ||	DITAG="$DIAOUT";
			;;
		'--checklist')
			# DITAG for checklist returns list
			[ "${DIAOUT%% *}" == "HELP" ] &&\
				DITAG="${DIAOUT#* }" ||	DITAG=" $DIAOUT ";
			# If list is empty set DITAG to ''
			[ -z "$(echo "$DITAG" | sed 's/\s*//g')" ] && DITAG='';
			# Use: eval "$RETCHECKLIST" to extract list to MENU
			;;
		'--radiolist')
			[ "${DIAOUT%% *}" == "HELP" ] &&\
				DITAG="${DIAOUT#* }" ||	DITAG="$DIAOUT";
			;;
		esac;
	fi;
}

#»USER DATA
function _adbman_userdata(){
	ADBMANA="$ADBMANB" # Backup path:$ADBMANB/ || $ADBMANB/<package>/
	ADBMANF="<package>-<time>" # Backup file name, templates: <package>, <time> 
	ADBMANP="$HOME/.adbman"
	ADBMANB="$ADBMANP/backup"
	ADBMANC="$ADBMANP/adbman.cfg"
	ADBMAND="$ADBMANP/adbman.dmp"
	ADBMANL="$ADBMANP/adbman.log"
	[ ! -d "$ADBMANP" ] && mkdir "$ADBMANP"
	# [ ! -d "$ADBMANB" ] && mkdir "$ADBMANB"
	[ ! -f "$ADBMANC" ] && touch "$ADBMANC"
	[ ! -f "$ADBMANL" ] && touch "$ADBMANL"
	# [ ! -f "$ADBMAND" ] && adb shell pm dump 0 |\
	# sed -n '/^Packages/,/^Queries/p' >"$ADBMAND"
}
_tifu _adbman_userdata
# echo "$(date +'[%T:%N]')>_adbman_userdata"

#»MENU LISTS
function _adbman_menuvars(){
#»Options Menu List Dialog
MANOPT=\
"1${chs}Config Directory
2${chs}Paralog"
#»Users Menu List Dialog
MANUSR="$(adb shell pm list users |\
	sed -n 's/.*{\(.*\)}.*/\1/p' |\
	sed "s/:/ [/2;s/$/]${chs}off/;s/:/${chs}/g")"
#»Parafunc: set DEVUSER to 'on' in MENU
MANUSRMENU='MENU=$(echo "$MANUSR" | sed "/^$DEVUSER/s/${chs}off/${chs}on/")'
#»Main Menu List Dialog
MANMLD=\
"A${chs}Applications [APPLTN]
B${chs}Backup and Restore
H${chs}History Log
L${chs}Log
O${chs}Options
P${chs}Permissions
S${chs}Settings [Demo]
T${chs}Tasks
U${chs}User [DEVUSER]"
#»Parafunc: set App Count and active user in MANMLD
MANMLDMENU='MENU=$(echo "$MANMLD" | sed "s/APPLTN/$APPLTN/;s/DEVUSER/$DEVUSER/")'
#_App List Filtered Dialog; Total/Filtered Number
APPLFD=''; APPLTN=0; APPLFN=0;
#»App Menu List Dialog
APPMLD=\
"A${chs}Activities
B${chs}Backup & Restore
C${chs}Clear Data
D${chs}Dump App
E${chs}EnableDisable
F${chs}SuspendUnsuspend
H${chs}HideUnhide [root]
I${chs}InstallUninstall
P${chs}Permissions [<prn>]
S${chs}Force Stop
U${chs}User [DEVUSER]"
#»Parafunc: Modify App Menu List Dialog per App status
APPMLDMENU=\
'MENU="$APPMLD";
MENU=$(sed "s/DEVUSER/$DEVUSER/" <<<"$MENU");
if [ ${APP_ins} -eq 1 ]; then\
	MENU=$(sed "s+Install++" <<<"$MENU"); 
	[ ${APP_enb} -le 1 ] &&\
		MENU=$(sed "s+Enable++" <<<"$MENU") ||\
		MENU=$(sed "s+Disable++" <<<"$MENU");
	[ ${APP_sus} -eq 1 ] &&\
		MENU=$(sed "s+Suspend++" <<<"$MENU") ||\
		MENU=$(sed "s+Unsuspend++" <<<"$MENU");
	[ ${APP_hid} -eq 1 ] &&\
		MENU=$(sed "s+Hide++" <<<"$MENU") ||\
		MENU=$(sed "s+Unhide++" <<<"$MENU");
	[ ${APP_prn} -gt 0 ] &&\
		MENU=$(sed "s+<prn>+${APP_prn}+" <<<"$MENU") ||\
		MENU=$(sed "/^P/d" <<<"$MENU");
else\
	MENU=$(sed "/^I\|^D\|^U/!d;s+Uninstall++" <<<"$MENU"); fi'
#»Parafunc: Set LABEL for App Menu from APPINFO
APPMLDLABEL=\
'LABEL="Package: $APPNAME";
LABEL="$LABEL\nVersion: ${APP_ver}";
LABEL="$LABEL, UserID: ${APP_uid}";
[ -n "${APP_gid}" ] &&\
	LABEL="$LABEL, GroupIDs: ${APP_gid}";
LABEL="$LABEL\nStatus: ";
[ "${APP_sys}" == "SYSTEM" ] &&\
	LABEL="$LABEL ${APPCHS}System" ||\
	LABEL="$LABEL ${APPCHT}ThirdParty";
if [ ${APP_ins} -eq 1 ];
then [ ${APP_enb} -le 1 ] &&\
	LABEL="$LABEL, ${APPCHE}Enabled[${APP_enb}]" ||\
	LABEL="$LABEL, ${APPCHD}Disabled[${APP_enb}]";
else LABEL="$LABEL, ${APPCHU}Uninstalled"; fi;
[ ${APP_sus} -eq 1 ] && LABEL="$LABEL, ${APPCHF}Suspended";
[ ${APP_hid} -eq 1 ] && LABEL="$LABEL, ${APPCHH}Hidden";
[ -n "${APP_fla}" ] &&\
	LABEL="$LABEL\nFlags:   ${APP_fla}";
LABEL="$LABEL\nStorage:";
LABEL="$LABEL App($(_adbman_sizeformat ${APP_sta})),";
LABEL="$LABEL Data($(_adbman_sizeformat ${APP_std})),";
LABEL="$LABEL Cache($(_adbman_sizeformat ${APP_stc})),";
LABEL="$LABEL ∑($(_adbman_sizeformat ${APP_stt}))";'
#»Parafunc: Set ADBOPT per App Menu List Dialog selected Option in DITAG
APPMLDOPT=\
'[ "$DITAG" == "C" ] && ADBOPT="clear --user $DEVUSER";
if [ "$DITAG" == "E" ]; then [ ${APP_enb} -le 1 ] &&\
	ADBOPT=\
"1${chs}Disable (disable --user $DEVUSER) [root]
2${chs}Disable (disable-user --user $DEVUSER)
3${chs}Disable (disable-until-used --user $DEVUSER)" ||\
	ADBOPT=\
"1${chs}Enable (default-state --user $DEVUSER)
2${chs}Enable (enable --user $DEVUSER)"; fi;
if [ "$DITAG" == "F" ]; then [ ${APP_sus} -eq 1 ] &&\
	ADBOPT="unsuspend --user $DEVUSER" ||\
	ADBOPT="suspend --user $DEVUSER"; fi;
if [ "$DITAG" == "H" ]; then [ ${APP_hid} -eq 1 ] &&\
	ADBOPT="unhide --user $DEVUSER" ||\
	ADBOPT="hide --user $DEVUSER"; fi;
if [ "$DITAG" == "I" ]; then [ ${APP_ins} -eq 1 ] &&\
	ADBOPT=\
"1${chs}Uninstall and keep data (uninstall -k --user $DEVUSER)
2${chs}Uninstall and remove data (uninstall --user $DEVUSER)
3${chs}Uninstall and keep data (uninstall -k)
4${chs}Uninstall and remove data (uninstall)" ||\
	ADBOPT="install-existing --user $DEVUSER"; fi'
#»App Backup Options Dialog
APPBOD=\
"1${chs}Backup
2${chs}Restore"
#»APP Filter Status Dialog Checklist
APPFSD=\
"D${chs}Disabled${chs}on
E${chs}Enabled${chs}on
F${chs}Suspended${chs}on
H${chs}Hidden${chs}on
U${chs}Uninstalled${chs}on
S${chs}System${chs}on
T${chs}ThirdParty${chs}on
0${chs}Custom${chs}on"
# APP Filter Status Count
APPFSN=$(sed '$=;d' <<<"$APPFSD");
#»APP Filter Custom Dialog List
APPFCD=\
"1${chs}android${chs}on
2${chs}google${chs}on"
# APP Filter Custom Count
APPFCN=$(sed '$=;d' <<<"$APPFCD");
APPFCDMENU='MENU="";
for i in {1..9}; do \
l=$(sed -n "/^${i}${chs}/s/${chs}on\$\|${chs}off\$//p" <<<"$APPFCD");
[ -n "$l" ] && MENU+="$l$nln" || MENU+="$i${chs}$nln"; done;
MENU=$(sed "/^\$/d" <<<"$MENU")'
#»APP Filter Backup Dialog Checklist
APPFBD=\
"A${chs}apk${chs}Backup .apk files${chs}on
B${chs}obb${chs}Backup .obb files${chs}on
C${chs}storage${chs}Backup shared storage${chs}on
D${chs}subdir${chs}Backup to <package> subdirectory${chs}on
E${chs}split${chs}Backup each option separately${chs}off
S${chs}system${chs}Include system apps${chs}off"
APPOBL="" #_Options Backup Label
SETAPPOBL='APPOBL=$(echo "$APPFBD" |\
sed "s/^.${chs}//;s/${chs}.*${chs}/${chs}/;s/${chs}on$/:$APPCH1/;s/${chs}off$/:$APPCH0/")'
APPOCL="" #_Options Custom Label
SETAPPOCL='APPOCL=$(echo "$APPFCD" |\
sed "s/^.${chs}//;s/${chs}on$/:$APPCH1/;s/${chs}off$/:$APPCH0/")'
APPOSL="" #_Options Status Label
SETAPPOSL='APPOSL=$(echo "$APPFSD" | sed "\$d" |\
sed "s/^D${chs}/$APPCHD/" |\
sed "s/^E${chs}/   $APPCHE/" |\
sed "s/^F${chs}/$APPCHF/" |\
sed "s/^H${chs}/$APPCHH/" |\
sed "s/^U${chs}/\\\n$APPCHU/" |\
sed "s/^S${chs}/$APPCHS/" |\
sed "s/^T${chs}/ $APPCHT/" |\
sed "s/${chs}on$/:$APPCH1  /;s/${chs}off$/:$APPCH0  /")'
APPOPL="" #_Options Permission Label
APPOPL="\Z4${PRMCHD}\Zn:Declared
\Z2${PRMCHI}\Zn:Installed
\Z5${PRMCHN}\Zn:Runtime
\Z1${PRMCHR}\Zn:Restricted"
#»Set ADBMANA='$ADBMANB || $ADBMANB/<package>' from APPFBD
SETADBMANA=\
'[ -n "$(sed -n "/^D${chs}.*${chs}on$/p" <<<"$APPFBD")" ] &&\
ADBMANA="$ADBMANB/<package>" ||\
ADBMANA="$ADBMANB"';
}
_tifu _adbman_menuvars
# echo "$(date +'[%T:%N]')>_adbman_menuvars"

#»DATA VARS
function _adbman_datavars(){
#»User
DEVUSER=0; DEVUSER=$(echo "$MANUSR" | sed -n "/^0\\|Owner/s/${chs}.*${chs}.*$//p")
#»Device Settings: Global; Secure; System
DEVSGLO=''; DEVSSEC=''; DEVSSYS=''
#»Packages dump; custom Package List
PKGDUMP=''; PKGLIST='';
#»App Name; Dump Package status; Dump Package Activities
APPNAME=''; APPSTATS=''; APPACTTS='';
#»App List Filtered (dialog list); App List Filtered Number; App List Total Number
APPLFD=''; APPLFN=0; APPLTN=0;
#»App Permissions (dialog list)
APPPERMS='';
#»App Info data associative array
APP_apk=''; # Package Name
APP_cpa=''; # Package Path
APP_rpa=''; # Resources Path
APP_dpa=''; # Data Path
APP_fla=''; # Flags
APP_enb=-1; # Enabled Status [0|1|2|3]
APP_hid=-1; # Hidden Status [0|1]
APP_ins=-1; # Installed Status [0|1]
APP_sus=-1; # Suspended Status [0|1]
APP_uid=''; # Package userID
APP_gid=''; # Package groupIDs
APP_ver=''; # Package Version
APP_sys=''; # Package SYSTEM flag
APP_prm=''; # Package Permissions list
APP_prn=0;  # Package Permissions count
APP_sta=0;  # Package apk Size
APP_stc=0;  # Package cache Size
APP_std=0;  # Package data Size
APP_stt=0;  # Package total Size
}
_tifu _adbman_datavars
# echo "$(date +'[%T:%N]')>_adbman_datavars"

#»DUMP PACKAGES
#»Create list of packages from: adb shell pm dump
function _adbman_dumppackages(){
	PKGDUMP=$(adb shell pm dump 0 |\
	sed -n '/^Packages/,/^Queries/p' |\
	sed '1d;$d;/^$/d;s/^\s\+/;/g' |\
	sed "/^;User/{/User $DEVUSER.*/!d}" |\
	sed '/^;Package\|^;userId=\|^;pkg=\|^;codePath=\|^;dataDir=\|^;pkgFlags=\|^;User/!d' |\
	sed 's/;Package\s\[\(\S\+\)\]/\1/g' |\
	sed 's/Package{\(\S\+\)\s\S\+}/\1/g' |\
	sed 's/User\s/User=/g' |\
	sed 's/:\|{\|}//g;s/\[\s/[/g;s/\s\]/]/g' |\
	sed '/\[.\+\]/s/,\s\|\s/,/g' |\
	sed 's/true/1/g;s/false/0/g;s/\s/;/g;s/$/;/g' |\
	sed -e :a -e '$!N;s/\n;//;ta' -e 'P;D' |\
	sort -t ';' -k1);
	# duplicate consecutive only
	PKGDUPS=$(echo "$PKGDUMP" |\
	sed -n '$!N; /^\(.*;(\).*\n\1.*$/p;D');
	if [ -n "$PKGDUPS" ]; then
		# remove duplicate consecutive
		PKGDUMP=$(echo "$PKGDUMP" |\
		sed '$!N; /^\(.*;(\).*\n\1.*$/d;P;D');
		PKGDUMP+=$'\n';
		# remove duplicates
		PKGDUMP+=$(echo "$PKGDUPS" |\
		sed -n '$!N; /^\(.*;(\).*\n\1.*$/D;P;D');
		PKGDUMP=$(sort -t ';' -k1 <<<"$PKGDUMP");
	fi
	# Total App Count
	APPLTN=$(sed '$=;d' <<<"$PKGDUMP");
}
_tifu _adbman_dumppackages

#»ADBMAN CONFIG READ
#»Reads user variables from config file
function _adbman_config_read(){
	local OPS OPT
	if [ -f "$ADBMANC" ]; then
		OPT='filterstatus'
		OPS="$(sed -n "s|^$OPT≈\(.*\)$|\1|p" "$ADBMANC")"
		[ -n "$OPS" ] && APPFSD="${OPS//';'/$'\n'}"
		APPFSN=$(sed '$=;d' <<<"$APPFSD");
		OPT='filtercustom'
		OPS="$(sed -n "s|^$OPT≈\(.*\)$|\1|p" "$ADBMANC")"
		[ -n "$OPS" ] && APPFCD="${OPS//';'/$'\n'}"
		APPFCN=$(sed '$=;d' <<<"$APPFCD");
		OPT='filterbackup'
		OPS="$(sed -n "s|^$OPT≈\(.*\)$|\1|p" "$ADBMANC")"
		[ -n "$OPS" ] && APPFBD="${OPS//';'/$'\n'}"
		OPT='backupdir'
		OPS="$(sed -n "s|^$OPT≈\(.*\)$|\1|p" "$ADBMANC")"
		[ -n "$OPS" ] && ADBMANB="$OPS"
		OPT='backupfile'
		OPS="$(sed -n "s|^$OPT≈\(.*\)$|\1|p" "$ADBMANC")"
		[ -n "$OPS" ] && ADBMANF="$OPS"
	fi
	eval "$SETADBMANA"
	unset OPS OPT;
}
_tifu _adbman_config_read

#»ADBMAN CONFIG WRITE
#»Saves filters to config file
function _adbman_config_write(){
	local OPC OPS OPT
	OPC='if [ -n "$(sed -n "/^$OPT≈/p" "$ADBMANC")" ];
then sed -i "s|^$OPT≈.*$|$OPT≈$OPS|" "$ADBMANC";
else echo "$OPT≈$OPS" >>"$ADBMANC"; fi'
	if [ -f "$ADBMANC" ]; then
		OPT='filterstatus'
		OPS="${APPFSD//$'\n'/';'}"
		eval "$OPC"
		OPT='filtercustom'
		OPS="${APPFCD//$'\n'/';'}"
		eval "$OPC"
		OPT='filterbackup'
		OPS="${APPFBD//$'\n'/';'}"
		eval "$OPC"
		OPT='backupdir'
		OPS="$ADBMANB"
		eval "$OPC"
		OPT='backupfile'
		OPS="$ADBMANF"
		eval "$OPC"
	fi
	unset OPC OPS OPT;
}
# _adbman_config_write

#»APP FILTER
#»Filters App list based on status and custom filters
function _adbman_appfilter(){
	local INCL EXCL l;
	# Filter Status
	PKGLIST="$PKGDUMP"; # Initialize filtered app list: PKGLIST
	# Filter PKGLIST per APPFSD App Status 
	[ -n "$(echo "$APPFSD" | sed -n "/D${chs}\S\+${chs}off/p")" ] &&\
	PKGLIST=$(echo "$PKGLIST" | sed -n '/installed=1.*enabled=[234]/!p')
	[ -n "$(echo "$APPFSD" | sed -n "/E${chs}\S\+${chs}off/p")" ] &&\
	PKGLIST=$(echo "$PKGLIST" | sed -n '/installed=1.*enabled=[01]/!p')
	[ -n "$(echo "$APPFSD" | sed -n "/F${chs}\S\+${chs}off/p")" ] &&\
	PKGLIST=$(echo "$PKGLIST" | sed -n '/suspended=1/!p')
	[ -n "$(echo "$APPFSD" | sed -n "/H${chs}\S\+${chs}off/p")" ] &&\
	PKGLIST=$(echo "$PKGLIST" | sed -n '/hidden=1/!p')
	[ -n "$(echo "$APPFSD" | sed -n "/U${chs}\S\+${chs}off/p")" ] &&\
	PKGLIST=$(echo "$PKGLIST" | sed -n '/installed=0/!p')
	[ -n "$(echo "$APPFSD" | sed -n "/S${chs}\S\+${chs}off/p")" ] &&\
	PKGLIST=$(echo "$PKGLIST" | sed -n '/SYSTEM/!p')
	[ -n "$(echo "$APPFSD" | sed -n "/T${chs}\S\+${chs}off/p")" ] &&\
	PKGLIST=$(echo "$PKGLIST" | sed -n '/SYSTEM/p')
	eval "$SETAPPOSL" # Update APPOSL Label
	# Filter Custom
	l=$(echo "$APPFCD" | sed '$=;d'); # Check number of custom filters
	# Apply custom filters if last APPFSD option is o'n' and #(APPFCD)>0
	if [ "${APPFSD:(-1)}" == "n" ] && [ $l -gt 0 ];
	then
		INCL=$(echo "$APPFCD" | sed -n "s/.${chs}\(\S\+\)${chs}on/\1.*;(/p")
		EXCL=$(echo "$APPFCD" | sed -n "s/.${chs}\(\S\+\)${chs}off/\1.*;(/p")
		INCL="${INCL//$'\n'/'\|'}"
		EXCL="${EXCL//$'\n'/'\|'}"
		[ -n "$EXCL" ] &&\
			PKGLIST=$(echo "$PKGLIST" | sed -n "/$EXCL/!p");
		[ -n "$INCL" ] &&\
			PKGLIST=$(echo "$PKGLIST" | sed -n "/$INCL/p");
	fi
	PKGLIST=$(echo "$PKGLIST" | sort -t ';' -k1)
	# Filtered App Count
	APPLFN=$(sed '$=;d' <<<"$PKGLIST")
	eval "$SETAPPOCL" # Update APPOCL Label
	unset INCL EXCL l
}
_tifu _adbman_appfilter

#»APP LIST
#»Create App List for dialog
function _adbman_applist(){
	case "$1" in
	"$SORTAZ")
		APPLFD="$(echo "$PKGLIST" | sort -t ';' -k1 )";;
	"$SORTZA")
		APPLFD="$(echo "$PKGLIST" | sort -r -t ';' -k1 )";;
	"$SORT09")
		APPLFD="$(echo "$PKGLIST" |\
			sed 's/userId=/userId;/g' |\
			sort -n -t ';' -k4 |\
			sed 's/userId;/userId=/g')";;
	"$SORT90")
		APPLFD="$(echo "$PKGLIST" |\
			sed 's/userId=/userId;/g' |\
			sort -n -r -t ';' -k4 |\
			sed 's/userId;/userId=/g')";;
	*)
		APPLFD="$PKGLIST"
	esac
	APPLFD="$(echo "$APPLFD" |\
	sed 's/^\(\S\+\);(.*);userId=\([0-9]\+\);.*;pkgFlags=\(\[\S*\]\);.*\(installed=.\);\(hidden=.\);\(suspended=.\);.*;\(enabled=.\);.*/\2:\4:\7:\5:\6:\3:\1/' |\
	sed -e "s/:\[SYSTEM,.*\]:/\t$APPCHS/" \
	-e "s/:\[.*\]:/\t$APPCHT/" \
	-e "s/installed=0:enabled=./$APPCHU/" \
	-e "s/installed=1:enabled=[01]/$APPCHE/" \
	-e "s/installed=1:enabled=[234]/$APPCHD/" \
	-e "s/:hidden=1/$APPCHH/g" -e "s/:hidden=0/ /" \
	-e "s/:suspended=1/$APPCHF/" -e "s/:suspended=0/ /" \
	-e 's/^\([0-9]\{5,\}\):/\1/' \
	-e 's/^\([0-9]\{4\}\):/ \1/' \
	-e 's/^\([0-9]\{,3\}\):/  \1/' |\
	sed "=;s/^/${chs}/" | sed '$!N;s/\n//')"; # Add line numbers '#:'
}
# _tifu _adbman_applist

#»APP FILTER EDIT
#»Custom filter editor dialog
function _adbman_appfilter_edit(){
	eval "$CLEARDIAVARS"
	local TMPFCD="$APPFCD" l='';
	while true; do
		DTITLE="Custom Filters";
		DIABOX='--inputmenu'; DIALID='AppFilterEdit'
		BTLXT='Edit'; BTLHL='Clear';
		LABEL=""; #"Edit Custom Filters:"
		eval "$APPFCDMENU";
		eval "$LOADDIASTATE";
		_adbman_dialog;
		case $DIACODE in
		0)#OK
			break
			;;
		2)#HELP:Clear filter
			APPFCD=$(echo "$APPFCD" | sed "/^${DITAG}/d")
			;;
		3)#EXTRA:Edit filter
			eval "$CHECKDINPUT";
			if [ $DINPUTOK -eq 1 ]; then
				l=$(echo "$APPFCD" | sed -n "/^$DITAG/p");
				[ -n "$l" ] &&\
					APPFCD=$(echo "$APPFCD" |\
						sed "s/^$DITAG${chs}.*${chs}\(.*\)\$/$DITAG${chs}$DINPUT${chs}\1/") ||\
					APPFCD+="${nln}$DITAG${chs}$DINPUT${chs}on";
				APPFCD=$(echo "$APPFCD" | sort -n -t "${chs}" -k1);
			fi;
			;;
		*)#Back
			APPFCD="$TMPFCD";
			break
			;;
		esac
		eval "$SAVEDIASTATE";
	done
	eval "$CLEARDIASTATE"
	eval "$CLEARDIAVARS";
}
# _adbman_appfilter_edit

#»APP FILTER CHECKLIST
#»App Filter Checklist Dialog
function _adbman_appfilter_checklist(){
eval "$CLEARDIAVARS";
# Save Custom filters in case of Cancel
local TMPFSD="$APPFSD" TMPFCD="$APPFCD";
while true; do
	DTITLE="Filters";
	DIABOX='--checklist'; DIALID='AppFilter'; BTLXT='Custom';
	LABEL='Select Filters:';
	MENU="$APPFSD$nln$APPFCD"
	_adbman_dialog;
	case $DIACODE in
	0)#${DIALOG_OK-0})
		MENU="$APPFSD"; eval "$SETCHECKLIST"; APPFSD="$MENU";
		MENU="$APPFCD";	eval "$SETCHECKLIST";	APPFCD="$MENU";
		_tifu _adbman_appfilter;
		if [ -n "$PKGLIST" ]; then
			# CHECKER=1
			_tifu _adbman_config_write;
			break;
		else
			dialog --title "No apps found!"\
				--msgbox 'Please set filters to include at least one app.\n(Include either Installed or Uninstalled apps,\nand either System or ThirdParty apps.)' 10 55;
		fi
		;;
	3)#${DIALOG_EXTRA-3})
		_adbman_appfilter_edit;
		;;
	*)#Cancel
		APPFSD="$TMPFSD"; APPFCD="$TMPFCD";
		# _tifu _adbman_appfilter;
		break
		;;
	esac
done;
unset TMPFSD TMPFCD;
eval "$CLEARDIAVARS";
}

#»APP DUMP VIEW
#»App dump export and viewer
function _adbman_appinfo_dumpview(){
	eval "$CLEARDIAVARS";
	if [ "${APP_sys}" == "SYSTEM" ];
		then DTITLE="Package Dump:${APPCHS}$APPNAME";
		else DTITLE="Package Dump:${APPCHT}$APPNAME";
	fi
	if [ -f "$ADBMANP/$APPNAME" ]; then
		DIABOX='--yesno'; DIALID='DumpSelect'
		BTLYS='View'; BTLNO='reDump'
		LABEL="Dump already exist:\n$ADBMANP/$APPNAME"
		_adbman_dialog
		if [ $DIACODE -ne 0 ]; then
			ADBOPT="rm $ADBMANP/$APPNAME"
			ADBOUT="$($ADBOPT 2>&1)";
			DIACODE=$?;
			_adbman_log "[\$]$ADBOPT"
			_adbman_log "[$DIACODE]$ADBOUT"
		fi
	fi
	BTLYS=''; BTLNO='';
	while true; do
	if [ ! -f "$ADBMANP/$APPNAME" ]; then
		ADBOPT="adb shell pm dump $APPNAME >$ADBMANP/$APPNAME"
		eval "$ADBOPT"
		DIACODE=$?;
		_adbman_log "[\$]$ADBOPT"
		_adbman_log "[$DIACODE]$ADBOUT"
		DIACODE=$?
		if [ $DIACODE -ne 0 ]; then
			DIABOX='--msgbox'; DIALID='Message'; LABEL='Dump error!'
			_adbman_dialog
		fi
	else
		DIABOX='--textbox'; DIALID='DumpView'
		LABEL="$ADBMANP/$APPNAME";
		_adbman_dialog;
		DIABOX='--yesno'; DIALID='Choice'; BTDEF='cancel';
		LABEL="Remove file:\n$ADBMANP/$APPNAME"
		_adbman_dialog
		if [ $DIACODE -eq 0 ]; then
			ADBOPT="rm $ADBMANP/$APPNAME"
			ADBOUT="$($ADBOPT 2>&1)";
			DIACODE=$?;
			_adbman_log "[\$]$ADBOPT"
			_adbman_log "[$DIACODE]$ADBOUT"
			if [ $DIACODE -eq 0 ]; then
				DIABOX='--msgbox'; DIALID='Message';
				LABEL="File removed:\n$ADBMANP/$APPNAME"
				_adbman_dialog
			fi
		fi
		break;
	fi
	done
}

#»APP SIZE
#»Get App info from: adb shell dumpsys diskstats
#»Called from _adbman_appinfo
function _adbman_appinfo_size(){
	local DS="$(adb shell dumpsys diskstats)";
	local -a DSN DSA DSD DSC;
	local -i DSI=0;
	# Parse App size data
	DN=$(echo "$DS" |\
		sed -n '/^Package Names:/{s/","/ /g;s/.*\["//g;s/"\]//g;p}')
	DSN=($(echo "$DS" |\
		sed -n '/^Package Names:/p'|\
		sed 's/","/ /g;s/.*\["//g;s/"\]//g'))
	DSA=($(echo "$DS" |\
		sed -n '/^App Sizes:/p' |\
		sed 's/,/ /g;s/.*\[//g;s/\]//g'))
	DSD=($(echo "$DS" |\
		sed -n '/^App Data Sizes:/p' |\
		sed 's/,/ /g;s/.*\[//g;s/\]//g'))
	DSC=($(echo "$DS" |\
		sed -n '/^Cache Sizes:/p' |\
		sed 's/,/ /g;s/.*\[//g;s/\]*//g'))
	DSI=-1;
	for ((i=0;i<${#DSN[@]};i++)); do
		[ "$APPNAME" == "${DSN[$i]}" ] && DSI=$i && break;
	done
	# App size
	if [ $DSI -ge 0 ]; then
		APP_sta=${DSA[$DSI]}
		APP_std=${DSD[$DSI]}
		APP_stc=${DSC[$DSI]}
		APP_stt=$(($APP_sta+$APP_std+$APP_stc))
	else
		APP_sta=0
		APP_std=0
		APP_stc=0
		APP_stt=0
	fi
	# Export all package sizes
	if [ -n "$2" ]; then
	echo "Package:AppSize:DataSize:CacheSize:TotalSize" >"$ADBMANP/appsize"
	for i in ${!DSN[@]}; do
	echo "${DSN[$i]}:${DSA[$i]}:${DSD[$i]}:${DSC[$i]}:$((${DSA[$i]}+${DSD[$i]}+${DSC[$i]}))" >>"$ADBMANP/appsize";
	done
	exit
	fi
	unset DS DSN DSA DSD DSC DSI;
}

#»APP PERMS
#»Create App Permission List
#»Called from _adbman_appinfo
function _adbman_appinfo_perms(){
	local PDC PRQ PIN PRT;
	PDC="$(echo "$APPSTATS" |\
		sed -n '/declared permissions:/,/requested permissions:/p' |\
		sed '1d;s/^\s*//;s/$/:dec;/;$d' |\
		sed 's/:\s\(.*\)\(:dec;\)$/\2\1/' |\
		sed 's/prot=\S\+//;s/\s[A-Z]\+//')"
	PRQ="$(echo "$APPSTATS" |\
		sed -n '/requested permissions:/,/install permissions:/p' |\
		sed '1d;s/^\s*//;s/$/:req;/;$d' |\
		sed 's/:\s\(.*\)\(:req;\)$/\2\1/')"
	PIN="$(echo "$APPSTATS" |\
		sed -n '/install permissions:/,/User/p' |\
		sed '1d;s/^\s*//;s/$/:ins;/;$d' |\
		sed 's/:\s\(.*\)\(:ins;\)$/\2\1/')"
	PRT="$(echo "$APPSTATS" |\
		sed -n '/runtime perissions:/,/bledComponents:/p' |\
		sed '1d;s/^\s*//;s/$/:run;/;/bledComponents/d' |\
		sed 's/:\s\(.*\)\(:run;\)$/\2\1/' |\
		sed 's/,\sflags=.*\]//')"
	APP_prm="$([ -n "$PDC" ] && echo "$PDC"
	[ -n "$PRQ" ] && echo "$PRQ"
	[ -n "$PIN" ] && echo "$PIN"
	[ -n "$PRT" ] && echo "$PRT")"
	APP_prm="$(echo "${APP_prm}" |\
		sed 's/restricted=true/R;/;s/granted=true/on;/;s/granted=false/off;/' |\
		sort -t ':' -k1 |\
		sed -n '$!N; s/^\(.*\):\(.*\)\n\1:\(.*\)/\1:\3\2/; P; D' |\
		sed -n '$!N; s/^\(.*\):\(.*\)\n\1:\(.*\)/\1:\3\2/; P; D' |\
		sed 's/\(on;\|off;\)\(..*\)$/\2\1/' |\
		sed '/on;\|off;/!s/;$/;off;/;s/;$//')"
	if [ -n "${APP_prm}" ]; then
		# List for App Permissions Menu
		APPPERMS="$(echo "${APP_prm}" |\
		sed 's/^\(\S\+\):\(\S\+\)\(on\|off\)$/\2\t\1:\3/' |\
		sed '/\t/!s/^/\t/' |\
		sed -e "s/dec;/\\\Z4$PRMCHD\\\Zn/" \
				-e "s/ins;/\\\Z2$PRMCHI\\\Zn/" \
				-e "s/run;/\\\Z5$PRMCHN\\\Zn/" \
				-e "s/R;/\\\Z1$PRMCHR\\\Zn/" \
				-e 's/req;//' \
				-e "s/:/${chs}/g" |\
		sed "s/^/${chs}/;=" | sed '$!N;s/\n//')"; # Number each line
		# Permission count
		APP_prn=$(echo "${APP_prm}" | sed -n '$=;d');
	else
		APPPERMS=""
		APP_prn=0
	fi
	unset PDC PRQ PIN PRT;
}

#»APP INFO
#»Create App info from dump
function _adbman_appinfo(){
	# Get backups from backup folder ADBMANA
	APP_bak="$(_adbman_flist "$ADBMANB" |\
		sed -n "/$APPNAME[^\\.].*.adb$/p")"
	# Dump Package
	[ -z "$APPNAME" ] && echo "APPNAME empty!" && exit 1;
	APPSTATS="$(adb shell pm dump $APPNAME |\
		sed '/^Queries/q')";
	APPACTTS="$(echo "$APPSTATS" |\
		sed -n '/^Activity Resolver/,/^Packages/{p;!q}' |\
		sed '/^$/d;$d')";
	APPSTATS="$(echo "$APPSTATS" |\
		sed '1,/^Packages/d' |\
		sed '/^$/d;/^Hidden/q;' |\
		sed -e :a -e '$!N;s/\n\s*gids=/ gids=/;ta' -e 'P;D' |\
		sed '/^$/d;$d;/User/{s/true/1/g;s/false/0/g}')"
	# Extract App Status
	APP_apk=$(echo "$APPSTATS" |\
		sed -n 's/^\s*Package\s\[\(.*\)\].*/\1/p')
	APP_uid=$(echo "$APPSTATS" |\
		sed -n 's/^\s*userId=\([0-9]*\)/\1/p')
	APP_cpa=$(echo "$APPSTATS" |\
		sed -n 's/^\s*codePath=\(\S*\)/\1/p')
	APP_rpa=$(echo "$APPSTATS" |\
		sed -n 's/^\s*resourcePath=\(\S*\)/\1/p')
	APP_dpa=$(echo "$APPSTATS" |\
		sed -n 's/^\s*dataDir=\(\S*\)/\1/p')
	APP_fla=$(echo "$APPSTATS" |\
		sed -n 's/^\s*flags=\[\s\(.*\)\s\]/\1/p' | sed 's/\s/,/g')
	APP_enb=$(echo "$APPSTATS" |\
		sed -n "/^\s*User $DEVUSER/s/.*enabled=\(\S*\)\s.*/\1/p")
	APP_hid=$(echo "$APPSTATS" |\
		sed -n "/^\s*User $DEVUSER/s/.*hidden=\(\S*\)\s.*/\1/p")
	APP_ins=$(echo "$APPSTATS" |\
		sed -n "/^\s*User $DEVUSER/s/.*installed=\(\S*\)\s.*/\1/p")
	APP_sus=$(echo "$APPSTATS" |\
		sed -n "/^\s*User $DEVUSER/s/.*suspended=\(\S*\)\s.*/\1/p")
	APP_gid=$(echo "$APPSTATS" |\
		sed -n 's/^\s*gids=\s*\[\(.*\)\]/\1/p')
	APP_ver=$(echo "$APPSTATS" |\
		sed -n 's/^\s*versionName=\(.*\)/\1/p')
	APP_sys=$(echo "$APPSTATS" |\
		sed -n 's/^\s*pkgFlags.*\(SYSTEM\).*$/\1/p')
	_tifu _adbman_appinfo_perms; # Get permissions
	_tifu _adbman_appinfo_size; # Get storage size
}

#»SIZE FORMAT
#»Format data size to B/MB/GB
function _adbman_sizeformat(){
	if [ $1 -gt 999999999 ]; then
		bc <<<"scale=2; $1 / 1000000000" | sed 's/$/GB/';
	elif [ $1 -gt 999999 ]; then
		bc <<<"scale=2; $1 / 1000000" | sed 's/$/MB/';
	elif [ $1 -gt 999 ]; then
		bc <<<"scale=2; $1 / 1000" | sed 's/$/kB/';
	else echo "$1B";
	fi
}

#»LOG
# Log adb executions
function _adbman_log(){
	local AL="$1"
	local TIME="$(date +'[%F-%Z:%T]')"
	if [ -f "$ADBMANL" ]; then
		echo "${TIME}${AL}" >>"$ADBMANL";
	fi;
}

#»ADB EXEC
#»Execute (multiline) command list stored in ADBOPT string var
# Logs history to $ADBMANP/$ADBMANL
# Echoes list of command stdouts, use: LABEL="$(_adbman_exec)"
# Returns error code stored in $DIACODE
function _adbman_exec(){
	eval "$CLEARDIAVARS";
	local ADBCOM ADBOUT LOG OUT='';
	local -i ADBCODE;
	j=$(sed '$=;d' <<<"$ADBOPT");
	for ((i=1; i<=$j; i++)); do
		ADBCOM=$(sed -n "${i}p" <<<"$ADBOPT");
		OUT+="\$>$ADBCOM\n";
		ADBOUT="$($ADBCOM 2>&1)";
		ADBCODE=$?;
		[ -n "$ADBOUT" ] && ADBOUT=$(echo "$ADBOUT" |\
			sed '1,3!d;1{/^$/d};') &&\
			LOG="${ADBOUT//$'\n'/ }" &&\
			ADBOUT=$(echo "$LOG" |\
				sed 's/for /&\\n/;s/has /&\\n/');
		if [ $ADBCODE -eq 0 ]; then
			DIACODE=1; # App Menu Modified switch
			[ -z "$ADBOUT" ] &&\
				OUT+="\Z2Success!\Zn\n" ||\
				OUT+="\Z2\$>${ADBOUT//':'/':\n '}\Zn\n";
		else
			[ -z "$ADBOUT" ] &&\
				OUT+="\Z1Failed!\Zn\n" ||\
				OUT+="\Z1\$>${ADBOUT//':'/':\n '}\Zn\n";
		fi
		_adbman_log "[\$]$ADBCOM"
		_adbman_log "[$ADBCODE]$LOG"
	done
	echo "$OUT"
	return $DIACODE
}

#»SELECT/CREATE DIRECTORY
#»Browse and Create dircreate dir
#»Call: _adbman_dselect '/path/to/dir'
function _adbman_dselect(){
eval "$CLEARDIAVARS";
DTITLE='Choose Directory'; 
DIABOX='--dselect'; DIALID='DirSelect' LABEL="$1";
# HGHT=30; WDTH=50;
_adbman_dialog
if [ ! -d "$DINPUT" ]; then
	DIABOX='--yesno'; DIALID='DirCreate'
	LABEL="Create Directory:\n$DINPUT"
	_adbman_dialog;
	DINPUT="$DIAOUT";
	if [ $DIACODE -eq 0 ]; then
		DIAOUT=$(mkdir "$DINPUT" 2>&1);
		if [ $? -eq 0 ]; then
			LABEL="Directory created:\n$DINPUT";
		else
			LABEL="Error:\n$DIAOUT";
		fi
		DIABOX='--msgbox'; DIALID='Message'
		_adbman_dialog
	fi
fi
eval "$CLEARDIAVARS";
echo "$DINPUT";
}

#»APP BACKUP OPTIONS
#»Backup and Restore Options
function _adbman_appback_options(){
	while true; do
		eval "$CLEARDIAVARS";
		DTITLE="Backup Options";
		DIABOX='--checklist'; DIALID='BackupOptions'
		LABEL="Directory:$ADBMANA/\nFile Name:$ADBMANF"
		BTDEF='ok'; BTLXT='Dir/File';
		# Remove short options (:apk:) from APPFBD for MENU
		MENU="$APPFBD" && MENU="$(echo "$MENU" |\
			sed -n "s/^\(.\)${chs}\S\+${chs}\(.*\)$/\1${chs}\2/p")"
		eval "$LOADDIASTATE"; _adbman_dialog; eval "$SAVEDIASTATE";
		case $DIACODE in
		0)#OK
			MENU="$APPFBD"; eval "$SETCHECKLIST"; APPFBD="$MENU";
			eval "$SETADBMANA"
			_adbman_config_write
			break
			;;
		3)#Directory/File Name
			local TMPADBMB="$ADBMANB" TMPADBMF="$ADBMANF";
			while true; do
				eval "$CLEARDIAVARS"
				DTITLE="Backup Directory and File Name"
				BTDEF='cancel'; BTLXT='Edit'; BTLHL='Reset';
				MENU="Directory${chs}$ADBMANB${nln}File-Name${chs}$ADBMANF"
				DIABOX='--inputmenu'; DIALID='BackupDir'
				eval "$LOADDIASTATE"; _adbman_dialog; eval "$SAVEDIASTATE";
				case $DIACODE in
				0)#OK
					eval "$SETADBMANA";
					break
					;;
				2)#Clear input
					case "$DITAG" in
					'Directory')	ADBMANB="$ADBMANP/backup";;
					'File-Name')	ADBMANF="<package>-<time>";;
					esac
					;;
				3)#Edit input
					case "$DITAG" in
					'Directory')
						ADBMANB=$(_adbman_dselect "$ADBMANB")
						;;
					'File-Name')
						eval "$CHECKDINPUT";
						[ $DINPUTOK -eq 1 ] && ADBMANF="$DINPUT";;
					esac
					;;
				*)#Cancel
					ADBMANB="$TMPADBMB"; ADBMANF="$TMPADBMF";
					eval "$SETADBMANA";
					break
					;;
				esac
			done
			unset TMPADBMB TMPADBMF;
			eval "$CLEARDIASTATE";
			;;
		*)#Cancel
			break
			;;
		esac
	done
	eval "$CLEARDIASTATE";
}

#»APP BACKUP
#»Backup app menu
function _adbman_appback_menu(){
# backup/restore:
# backup [-f FILE] [-apk|-noapk] [-obb|-noobb] [-shared|-noshared] [-all] [-system|-nosystem] [PACKAGE...]
# write an archive of the device's data to FILE [default=backup.adb] package list optional if -all/-shared are supplied
#   -apk/-noapk: do/don't back up .apk files (default -noapk)
#   -obb/-noobb: do/don't back up .obb files (default -noobb)
#   -shared|-noshared: do/don't back up shared storage (default -noshared)
#   -all: back up all installed applicationsd
#   -system|-nosystem: include system apps in -all (default -system)
# restore FILE   restore device contents from FILE
	while true; do
		eval "$CLEARDIAVARS";
		DTITLE="App Backup & Restore";
		DIABOX='--menu'; DIALID='AppBackup'
		MENU="$APPBOD"; BTLXT='Options'; BTLCL='Back'
		eval "$SETLABELAPP"
		LABEL="$LABEL\nDirectory:$ADBMANA/\nFile Name:$ADBMANF"
		# Refresh Option list, remove last 'include system'
		eval "$SETAPPOBL" && APPOBL=$(sed '$d' <<<"$APPOBL")
		LABEL="$LABEL\nOptions: ${APPOBL//$'\n'/'  '}"
		_adbman_dialog;
		case $DIACODE in
		0)#Backup&Restore
			case "$DITAG" in
			1)#Backup
				eval "$CLEARDIAVARS"
				# Prepare backup arguments (first 3) per user options in APPFBD
				ADBOPT="$(echo "$APPFBD" | sed -n '1,3p' |\
					sed -n "s/.${chs}\(\S\+\)${chs}.*${chs}on/-\1/p")"
				# If split option is off: all args on 1 line; else: each line)
				[ -n "$(sed -n "/E${chs}.*${chs}off/p" <<<"$APPFBD")" ] &&\
					ADBOPT="adb backup ${ADBOPT//$'\n'/' '} -f <file>${ADBOPT//$'\n'/}.adb <package>" ||\
					ADBOPT="$(echo "$ADBOPT" |\
						sed 's/\(-\S\+\)/adb backup \1 -f <file>\1.adb <package>/')";
				# Set <package> and <time>
				ADBOPT="$(echo "$ADBOPT" |\
					sed "s+<file>+$ADBMANA/$ADBMANF+g" |\
					sed "s/<time>/$(date +'%Y%m%d%H%M')/g" |\
					sed "s+<package>+$APPNAME+g")"
				# Add Create Folder to ADBOPT command list
				[ ! -d "${ADBMANA//<package>/$APPNAME}" ] && ADBOPT="mkdir ${ADBMANA//<package>/$APPNAME}${nln}${ADBOPT}"
				# Confirm Dialog
				DTITLE="App Backup";
				eval "$SETLABELAPP"
				LABEL="$LABEL\nDirectory:$ADBMANA/"
				LABEL="$LABEL\n\nBackup:"
				LABEL="$LABEL\n${ADBOPT//$'\n'/'\n'}"
				DIABOX='--yesno'; DIALID='Confirm'; _adbman_dialog;
				if [ $DIACODE -eq 0 ]; then
					eval "$SETLABELAPP"
					LABEL="$LABEL\nDirectory:$ADBMANA/"
					LABEL="$LABEL\n\nPress OK to start.\nNow unlock your device and confirm the backup operation..."
					DIABOX='--msgbox'; DIALID='Message'; _adbman_dialog;
					LABEL="$(_adbman_exec)"
					DIACODE=$?
					DIABOX='--msgbox'; DIALID='Message'; _adbman_dialog;
				fi
				;;
			2)#Restore
				while true; do
					eval "$CLEARDIAVARS"
					DTITLE="App Restore"; BTLCL='Back'; BTLXT='Options';
					eval "$SETLABELAPP"
					LABEL="$LABEL\nDirectory:$ADBMANB/"
					LABEL="$LABEL\nSelect backup(s) to restore:"
					MENU="$(echo "$APP_bak" |\
						sed "s+$ADBMANB+.+" |\
						sed "s/$/${chs}off/;=;s/^/${chs}/" |\
						sed '$!N;s/\n//')";
					eval "$SETCHECKLIST"; # Convert MENU list to checklist
					DIABOX='--checklist'; DIALID='Restore'; _adbman_dialog;
					case $DIACODE in
					0)#OK
						BTLXT='';
						LABEL="$(echo "${LABEL//'\n'/$'\n'}" | sed '$d')";
						LABEL="${LABEL//$'\n'/'\n'}"
						if [ -n "$DITAG" ]; then
							eval "$RETCHECKLIST"; # Get selected Backups as MENU list 
							ADBOPT="$(echo "$MENU" |\
								sed "s![0-9]\\+${chs}.!adb restore $ADBMANB/!g;s/${chs}on$//g")"
							LABEL="$LABEL\n\nRestore:"
							LABEL="$LABEL\n${ADBOPT//$'\n'/'\n'}"
							DIABOX='--yesno'; DIALID='Confirm'; _adbman_dialog;
							if [ $DIACODE -eq 0 ]; then
								LABEL="$(_adbman_exec)"
								DIACODE=$?
								DIABOX='--msgbox'; DIALID='Message'; _adbman_dialog;
							fi
						else
							LABEL="$LABEL\n\nNothing selected."
							DIABOX='--msgbox'; DIALID='Message'; _adbman_dialog;
						fi
						;;
					3)#Options
						# No subshell!
						_adbman_appback_options
						;;
					*)#Cancel
						break;;
					esac
				done;;
			esac
			;;
		3)#Options
			# No subshell!
			_adbman_appback_options
			;;
		*)#Cancel
			break
			;;
		esac
	done
	# echo "${DIAOUT[@]}"
	# return $DIACODE
}

#»APP PERMS
#»App Permissions Dialog
function _adbman_appperms_menu(){
	eval "$CLEARDIAVARS"
	local CURPERMS ALLPERMS NONPERMS STATE='Current';
	# Check if All/None permissions are already set
	[ -z "$(echo "$APPPERMS" | sed -n '/on$/p')" ] &&\
		BTLXT='All' && STATE='None';
	[ -z "$(echo "$APPPERMS" | sed -n '/off$/p')" ] &&\
	BTLXT='None' && STATE='All';
	BTLXT='All';
	CURPERMS="$APPPERMS";
	ALLPERMS=$(echo "$APPPERMS" | sed 's/off$/on/');
	NONPERMS=$(echo "$APPPERMS" | sed 's/on$/off/');
	while true; do
		DTITLE="App Permissions [${APP_prn}]"
		DIABOX='--checklist'; DIALID='AppPerms'; BTLCL='Back';
		eval "$SETLABELAPP"; # LABEL=[sys|user]<package>
		LABEL="$LABEL\n${APPOPL//$'\n'/'  '}";
		MENU="$APPPERMS"; # Create checklist MENU
		_adbman_dialog;
		case $DIACODE in
		0)#${DIALOG_OK-0})
			eval "$CLEARDIABTTN"; ADBOPT='';
			DTITLE='Modify App Permissions';
			DIABOX='--yesno'; DIALID='Confirm'
			# Create list of permissions to modify
			MENU=$(echo "$APP_prm" | sed "s/:.*;/${chs}/");
			eval "$RETCHECKLIST";
			# If any permission on list: YESNO DIALOG
			if [ -n "$MENU" ]; then
				ADBOPT="$(echo "$MENU" |\
				sed -e "s/^\(\S\+\)${chs}.*on$/grant <package> \1/" \
						-e "s/^\(\S\+\)${chs}.*off$/revoke <package> \1/")"
				MENU='';
				eval "$SETLABELAPP"
				LABEL="$LABEL\n\nPermissions:"
				LABEL="$LABEL\n$(echo "${ADBOPT//$'\n'/'\n'}" |\
					sed 's/grant/\\Z2grant\\Zn /g' |\
					sed 's/revoke/\\Z1revoke\\Zn/g')"
				_adbman_dialog
				# Exec perms if DIACODE = 0
				if [ $DIACODE -eq 0 ]; then
					ADBOPT=$(echo "$ADBOPT" |\
						sed -e 's/^/adb shell pm /' \
								-e "s/<package>/$APPNAME/");
					ADBOPT=$(_adbman_exec);
					APPIX=$?;
					ADBOPT=$(echo "$ADBOPT" |\
						sed "s/$APPNAME/<package>/g");
					eval "$SETLABELAPP"
					LABEL="$LABEL\n\nPermissions:"
					LABEL="$LABEL\n${ADBOPT//$'\n'/'\n'}";
					DIABOX='--msgbox'; DIALID='Message';
					_adbman_dialog;
				fi;
				# After Execution
				# Refresh APPINFO if APPIX changed & reset APPIX
				if [ $APPIX -eq 1 ]; then
					_adbman_appinfo;
					APPIX=0;
					CURPERMS="$APPPERMS";
				fi
				STATE='Current'; BTLXT='All';
			fi
			;;
		3)#${DIALOG_EXTRA-3})
			case "$BTLXT" in
			'All')
				APPPERMS="$ALLPERMS"
				[ "$STATE" == 'None' ] && \
					BTLXT='Current' || BTLXT='None'
				;;
			'None')
				APPPERMS="$NONPERMS"
				BTLXT='Current'
				;;
			'Current')
				APPPERMS="$CURPERMS"
				[ "$STATE" == 'All' ] && \
					BTLXT='None' || BTLXT='All'
				;;
			esac
			;;
		*)#Cancel
			break;;
		esac
	done
}

#»APP MODIFY
#»Modify App state; Called from _adbman_appinfo_menu
#»requres: DTITLE, DIABOX, ADBOPT, APPNAME set
function _adbman_appmod(){
if [ -n "$ADBOPT" ]; then
	MENU=''; DITAG=''; BTLCL='';
	eval "$SETLABELAPP";
	[ "$DIABOX" == '--menu' ] && MENU="$ADBOPT";
	_adbman_dialog;
	[ -n "$DITAG" ] && ADBOPT=$(echo "$ADBOPT" |\
			sed -n "/$DITAG/s/.*(\(.*\)).*/\1/p")
	# Execute ADBOPT and display output msgbox
	if [ $DIACODE -eq 0 ]; then
		ADBOPT="adb shell pm $ADBOPT $APPNAME"
		MENU=''; DIABOX='--msgbox'; DIALID='Message'
		eval "$SETLABELAPP"
		LABEL="$LABEL\n$(_adbman_exec)"
		APPIX=$?
		[ "$APPIX" -eq 1 ] &&\
			[ -z "$(sed -n '/ clear /p' <<<"$ADBOPT")" ] &&\
			APPLX=1;
		_adbman_dialog
	fi
fi
}

#»APP MENU
#»App Menu Dialog
function _adbman_appinfo_menu(){
	APPLX=0; APPIX=1;
	while true; do
		eval "$CLEARDIAVARS";
		# Refresh APPINFO only if APPIX changed and reset APPIX
		if [ $APPIX -eq 1 ]; then
		_tifu _adbman_appinfo; APPIX=0; fi;
		DTITLE="Application Menu [User:$DEVUSER]"
		DIABOX='--menu'; DIALID='AppInfo'; BTLCL='Back'
		eval "$APPMLDLABEL"; # LABEL for App Menu
		eval "$APPMLDMENU"; # MENU from APPMLD
		eval "$LOADDIASTATE"; _adbman_dialog; eval "$SAVEDIASTATE";
		case $DIACODE in
		0) #${DIALOG_OK-0})
			#===DISPLAY APP DIALIST
			ADBOPT='';
			#Set ADBOPT per DITAG, see Menu Lists Parafunc
			eval "$APPMLDOPT"
			case "$DITAG" in
			"B")#Backup / Restore App
				_adbman_appback_menu;;
			"C")#Clear App Data
				DIABOX='--yesno'; DTITLE='Clear App Data';
				DIALID=$(echo "$DTITLE" | sed 's/\s.*//')
				_adbman_appmod;;
			"D")#Dump:App dump view
				_adbman_appinfo_dumpview;;
			"E")#Enable/Disable package
				DIABOX='--menu';
				[ ${APP_enb} -le 1 ] &&\
					DTITLE='Disable App' || DTITLE='Enable App';
				DIALID=$(echo "$DTITLE" | sed 's/\s.*//')
				_adbman_appmod;;
			"F")#Suspend/Unsuspend package
				DIABOX='--yesno';
				[ ${APP_sus} -eq 1 ] &&\
					DTITLE='Unsuspend App' || DTITLE='Suspend App';
				DIALID=$(echo "$DTITLE" | sed 's/\s.*//')
				_adbman_appmod;;
			"H")#Hide/Unhide package
				DIABOX='--yesno';
				[ ${APP_hid} -eq 1 ] &&\
					DTITLE='Unhide App [root]' || DTITLE='Hide App [root]';
				DIALID=$(echo "$DTITLE" | sed 's/\s.*//')
				_adbman_appmod;;
			"I")#Install/Uninstall package
				DIABOX='--menu';
				[ ${APP_ins} -eq 1 ] &&\
					DTITLE='Uninstall App' || DTITLE='Install App';
				DIALID=$(echo "$DTITLE" | sed 's/\s.*//')
				_adbman_appmod;;
			"P")#App Permissions
				[ -n "$APPPERMS" ] &&\
					_adbman_appperms_menu;;
			"R")#App Permissions Reset
				[ -n "$APPPERMS" ] &&\
					_adbman_appperms_menu;;
			"U")#App User Select
					_adbman_user;;
			esac;;
		3)#${DIALOG_EXTRA-3})
			break;;
		*)#Cancel
			break;;
		esac
	done
	# If APPLX changed then refresh PKGLIST, set APPLX=0
	if [ $APPLX -eq 1 ]; then
		_tifu _adbman_dumppackages
		_tifu _adbman_appfilter
		APPLX=0
	fi
	eval "$CLEARDIASTATE";
}

#»APP LIST MENU
#»Apps List Menu Dialog
function _adbman_applist_menu(){
	local s=0; # SORT array counter
	SORT=("$SORTAZ" \
				"$SORTZA" \
				"$SORT09" \
				"$SORT90" \
				"$SORTAZ");
	# _tifu _adbman_appfilter
	while true; do
		eval "$CLEARDIAVARS";
		_tifu _adbman_applist "${SORT[$s]}"
		DTITLE="Application List [User:$DEVUSER|Apps:$APPLFN/$APPLTN] ${SORT[$s]}"
		DIABOX='--menu'; DIALID='AppList';
		BTLXT='Filter'; BTLCL='Back';
		# WDTH=-1; HGHT=-1;
		BTLHL="${SORT[$(($s+1))]}";
		MENU="$APPLFD"
		LABEL="\ZuStatus Filters\Zn:$APPCH1"
		LABEL="$LABEL\n${APPOSL//$'\n'/' '}"
		LABEL="$LABEL\n\ZuCustom filters\Zn:"
		[ "${APPFSD:(-1)}" == "n" ] && LABEL="$LABEL$APPCH1";
		[ "${APPFSD:(-1)}" == "f" ] && LABEL="$LABEL$APPCH0";
		[ $APPFCN -gt 0 ] && LABEL="$LABEL\n${APPOCL//$'\n'/'  '}"
		# eval "$LOADDIASTATE"
		# If APPNAME selected find DITAG from MENU
		[ -n "$APPNAME" ] &&\
			DITAG=$(sed -n "/\t.$APPNAME$/=" <<<"$MENU");
		_adbman_dialog; # 'noWH';
		# If DITAG find number DITAG as APPNAME in MENU list
		[ -n "$DITAG" ] &&\
			APPNAME=$(sed -n "${DITAG}s/.*\t.//p" <<<"$MENU")
		# eval "$SAVEDIASTATE"
		case $DIACODE in
		0)#${DIALOG_OK-0})
			_adbman_appinfo_menu;
			;;
		2)#${DIALOG_HELP-2}
			[ $s -lt "$((${#SORT[@]}-2))" ] && ((s+=1)) || ((s=0));
			;;
		3)#${DIALOG_EXTRA-3})
			_adbman_appfilter_checklist;
			;;
		*)#Cancel
			break;
			;;
		esac
	done
	unset s;
}

#»OPTIONS MENU
#»ADBman options
function _adbman_options(){
	eval "$CLEARDIAVARS";
	DTITLE='ADBman Options';
	DIABOX='--menu'; DIALID='Options';
	MENU="$MANOPT"
	while true; do
		_adbman_dialog
		case $DIACODE in
		0)#OK
			break
			;;
		*)#CANCEL
			break
			;;
		esac
	done
}

#»ADB SETTINGS MULTILINE PARSER
#»Parse multiline to singleline settings
function _adbman_settings_parse(){
	local PARSEL='' PARSEF=''
	PARSEF="$(echo "$1" | sed -n '/^"\|^\s\|^}\|^\]\|\[$\|{$\|"$/p')"
	if [ -n "$PARSEF" ]; then
		PARSEL="$(echo "$1" | sed -n '/^"\|^\s\|^}\|^\]\|\[$\|{$\|"$/!p')"
		PARSEF="$(echo "$PARSEF" | sed '/^"$\|^}$\|^\]$/s/$/¶/')"
		PARSEF="${PARSEF//$'\n'/}"
		PARSEF="$(echo "${PARSEF//'¶'/$'\n'}" | sed 's/\s//g;/^\s*$/d')"
		PARSEL="$(echo "$PARSEL${nln}$PARSEF" | LC_ALL=C sort)"
		echo "$PARSEL"
	else
		echo "$1";
	fi
}

#»ADB SETTINGS
#»ADB Settings Menu Dialog
function _adbman_settings_menu(){
	eval "$CLEARDIAVARS"
	APPSX=1;
	local -a BTLIST=( 'GLOBAL' 'SECURE' 'SYSTEM' );
	local -a STLIST=( 'DEVSGLO' 'DEVSSEC' 'DEVSSYS' );
	local -i BSTATE=1 LSTATE=0
	local CURSET='' CURVAL=''
	local STATESW=\
'((LSTATE++)); [ $LSTATE -eq 3 ] && LSTATE=0;
((BSTATE++)); [ $BSTATE -eq 3 ] && BSTATE=0;'
	while true; do
		eval "$CLEARDIABTTN"
		DTITLE="Device Settings [${BTLIST[$LSTATE]}] Demo"
		DIABOX='--menu'; DIALID='AppSettings'; BTLCL='Back';
		BTLXT="${BTLIST[$BSTATE]}";
		LABEL="\Zu\Z1WARNING: Editing device settings can be dangerous!\Zn"
		LABEL+="\n\Z3This is a work in progress. Only browsing is currently available. Changing is not available yet!\Zn"
		if [ $APPSX -ne 0 ]; then
			DEVSGLO="$(adb shell settings list --user $DEVUSER global)";
			DEVSSEC="$(adb shell settings list --user $DEVUSER secure)";
			DEVSSYS="$(adb shell settings list --user $DEVUSER system)";
			APPSX=0;
		fi
		MENU="$(_adbman_settings_parse "${!STLIST[$LSTATE]}")"
		MENU="$(echo "$MENU" |\
			sed "s/^\([0-9A-Za-z_\.]\+\)=/\1${chc}/" |\
			sed "s/^/${chs}/;=" | sed '$!N;s/\n//')"; # Number each line
		_adbman_dialog;
		case $DIACODE in
		0)#${DIALOG_OK-0})
			eval "$CLEARDIABTTN";
			BTLXT='Edit'; BTLHL='Clear';
			MENU="$(echo "$MENU" |\
				sed -n "/^$DITAG${chs}/{s/^$DITAG${chs}//;s/${chc}/${chs}/;p}")"
			CURSET="${MENU//$chs*/}"
			CURVAL="${MENU//*$chs/}"
			LABEL="$LABEL\n\nCurrent [${BTLIST[$LSTATE]}] setting:\n$CURSET=$CURVAL"
			DINPUT="$CURVAL";
			while true; do
				DIABOX='--inputmenu'; DIALID='Edit'; _adbman_dialog;
				case $DIACODE in
				0)#OK
					break
					;;
				2)#HELP:Clear
					DINPUT="";
					[ "$DINPUT" != "$CURVAL" ] && APPSX=1;
					MENU="$DITAG${chs}$DINPUT"
					;;
				3)#EXTRA:Edit
					[ "$DINPUT" != "$CURVAL" ] && APPSX=1;
					MENU="$DITAG${chs}$DINPUT"
					;;
				*)#CANCEL
					APPSX=0;
					break;;
				esac
			done
			if [ $APPSX -ne 0 ]; then
			eval "$CLEARDIABTTN";
				ADBOPT="adb shell settings put --user $DEVUSER ${BTLIST[$LSTATE]} $DITAG $DINPUT"
				LABEL="$LABEL\n\nModify  [${BTLIST[$LSTATE]}] setting:\n$CURSET=$DINPUT"
				LABEL="$LABEL\n\nExecute:\n>$ADBOPT"
				DIABOX="--msgbox"; DIALID='Message'; _adbman_dialog;
			fi
			;;
		3)#${DIALOG_EXTRA-3})
			eval "$STATESW";
			;;
		*)#Cancel
			break
			;;
		esac
	done
}

#»USER MENU
#»Select User Dialog
function _adbman_user(){
	APPLX=0;
	eval "$CLEARDIAVARS";
	DTITLE="User List [User:$DEVUSER]"
	DIABOX='--radiolist'; DIALID='User';
	BTLCL='Back'; APPLX=0;
	eval "$MANUSRMENU" # Create MENU from MANUSR
	LABEL="\ZuChoose User\Zn:"
	while true; do
		_adbman_dialog;
		case $DIACODE in
		0)#${DIALOG_OK-0})
			if [ "$DEVUSER" != "$DIAOUT" ]; then
				APPLX=1; APPIX=1;
				DEVUSER=$DIAOUT;
			fi
			;;
		*)#Cancel
			break
			;;
		esac
		# If APPLX changed then refresh PKGLIST, set APPLX=0
		if [ $APPLX -eq 1 ]; then
			_tifu _adbman_dumppackages
			_tifu _adbman_appfilter
			APPLX=0
			break
		fi;
	done
}

#»EXIT
function _adbman_exit(){
if [ -n "$1" ]; then
	clear;
	echo "$1";
	exit 1;
else
	clear;
	exit 0;
fi
}

#»MAIN MENU
#»Main Menu Dialog
function _adbman_main_menu(){
	while true; do
		eval "$CLEARDIAVARS";
		BTITLE="ADBman - ADB Manager";
		DTITLE="ADBman Menu";
		DIABOX='--menu'; DIALID='Main';
		BTDEF='ok' BTLCL='Exit';
		LABEL="Select Option:"
		eval "$MANMLDMENU"; # Create MENU from MANMLD
		eval "$LOADDIASTATE"; _adbman_dialog; eval "$SAVEDIASTATE"
		case $DIACODE in
		0)#${DIALOG_OK-0})
			case "$DITAG" in
			'A')#Applications
				_adbman_applist_menu;
				;;
			'B')#Backup and Restore
				;;
			'H')#History Log
				eval "$CLEARDIAVARS";
				DTITLE='History Log';
				if [ -f "$ADBMANL" ]; then
					DIABOX='--textbox'; DIALID='HistoryLog';
					LABEL="$ADBMANL";
				else
					DIABOX='--msgbox'; DIALID='Message';
					LABEL='No history found.';
				fi
				_adbman_dialog;
				;;
			'L')#Log
				;;
			'O')#Options
				_adbman_options;
				;;
			'P')#Permissions
				;;
			'S')#Settings
				_adbman_settings_menu;
				;;
			'T')#Tasks
				;;
			'U')#User
				_adbman_user;
				;;
			*)#Unknown
				echo "Unknown Choice in Main Menu:$DITAG" &&\
					exit 1;;
			esac;;
		2)#${DIALOG_HELP-2}
			;;
		3)#${DIALOG_EXTRA-3})
			;;
		*)#Cancel
			_adbman_exit;
			;;
		esac
	done
}
_adbman_main_menu

# END
echo "Function break!"
exit
echo "Exitcode: $EX"
echo "APPFSD=${APPFSD[@]}"
echo "APPFCD=${APPFCD[@]}"
echo "APPFBD=${APPFBD[@]}"
if  [ -n "${APP_apk}" ]; then
echo "APPLFD:"
cat -n <<<"$APPLFD" | sed -n "/${APP_apk}/p"
echo "APPINFO:"
echo "APP_apk=${APP_apk}"
echo "APP_cpa=${APP_cpa}"
echo "APP_rpa=${APP_rpa}"
echo "APP_dpa=${APP_dpa}"
echo "APP_enb=${APP_enb}"
echo "APP_hid=${APP_hid}"
echo "APP_ins=${APP_ins}"
echo "APP_sus=${APP_sus}"
echo "APP_uid=${APP_uid}"
echo "APP_gid=${APP_gid}"
echo "APP_ver=${APP_ver}"
echo "APP_sys=${APP_sys}"
echo "APP_sta=${APP_sta}"
echo "APP_std=${APP_std}"
echo "APP_stc=${APP_stc}"
echo "APP_stt=${APP_stt}"
echo "APP_prm:"
cat -n <<<"${APP_prm}"
echo "APP_prn=${APP_prn}"
echo "--------"
echo "PKGDUMP:"
cat -n <<<"$PKGLIST" | sed -n "/${APP_apk};/p"
fi
exit
#



