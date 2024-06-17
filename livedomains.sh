###########################################################################
#!/bin/bash
#-------------------
#LiveDomains
#SIMPLY CHECKS WHICH DOMAINS ARE LIVE ON THE SERVER AND WHICH ARE NOT
#Author: Jeremy J Butler
LDVersion=0.6
GetBashVersion=$(bash -version|head -n1|cut -d\. -f1|awk -F"version" '{print $2}'|sed -e 's/^[ \t]*//')
#We get the bash version for compatibillity issues with some checks later.
###########################################################################
if [ "$#" -ne 0 ]; then
    echo "LiveDomains "${LDVersion}""
    echo "Usage: $0 ";
    echo "No arguments are supported just run the script"
    exit 1;
fi


#################################################################################
#Main
#
##################################################################################
Main() {
declare -a thedoms
local checkforapache=$(pidof httpd|wc -w)
if [ "${checkforapache}" -eq 0 ];
   then
        echo  "Apache is not running here, I am too dumb to figure this out, quitting"
        exit 1;
fi

echo "Warning: Domains in servers other then apache and nginx are not parsed by this script";
echo "Always Double Check before pulling any IP addresses"
echo "-------------------------------------------------------------------------------------"

local APACHE=$(ps aux|awk '{print $11}'|grep httpd|head -1)

for x in `netstat -an|grep -qw :443
 if [ $? -gt 0 ];
                then
        $APACHE -S 2>&1 | grep -oP '\(.+\)' | tr -d '()' | cut -d: -f1 | sort | uniq
                else
        $APACHE -S -DSSL -DHAVE_SSL -DHAVESSL 2>&1 | grep -oP '\(.+\)' | tr -d '()' | cut -d: -f1 | sort | uniq
                fi`
do
for i in `cat $x|sed 's/^[ \t]*//'|egrep -i 'ServerAlias|servername' | grep -v ^\#|tr 'A-Z' 'a-z' | sed 's/serveralias //' | sed 's/servername //'|sed -e 's/www\.//g'|sort|uniq`;

        do thedoms=("${thedoms[@]}" $i); ##For Bash 3.0 and below (centos 4 compatibillity)
                                         ##we have to do it this way in violation of bashims and at cost of speed
        done
done

for r in "${!thedoms[@]}"
do


                      ##Check if its a CNAME or not to determine how we will parse the output of dig
        if [ `dig cname @8.8.8.8 "${thedoms[$r]}" +short|wc -l` -gt 0 ]; #If its a cname
                then
                local thedigger=$(dig @8.8.8.8 "${thedoms[$r]}" +short|tail -n1|sed -e 's/^[ \t]*//'|sed '/^$/d');
                ##its a cname so instead of first line from dig +short we grab the last(the destination A record)
                else
                local thedigger=$(dig @8.8.8.8 "${thedoms[$r]}" +short|head -n1|sed -e 's/^[ \t]*//'|sed '/^$/d')
                fi ##else parse dig normally

local checkdigger=$(echo "${thedigger}"|wc -l)
local checklocalip=$(ifconfig -a|grep "inet addr"|awk '{print $2}'| awk -F ":" '{print $2}'|grep "${thedigger}"|wc -l);


#Check that we have actually gotten a valid IP Address
        if [[ "${thedigger}" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]
                then
                checkdigger2=1;
                else
                checkdigger2=2;
                fi
        if [ "${checkdigger}" -eq 0 ] || [ "${checkdigger2}" -eq 2 ];
                then
                     echo ""${thedoms[$r]}" has possible DNS/Registrar issues or is not returning a valid IP, check manually"                       

          ##If we don't have a valid IP or dig returned nothing at all then call it a day before we do anything else
                elif [ $checklocalip -gt "0" ] && [ "${checkdigger2}" -eq 1 ];
                        then
                                echo ""${thedoms[$r]}" is live here @ "${thedigger}""  #dig returned valid Ip and its on the box

                  elif [ $checklocalip -eq "0" ] && [ "${checkdigger2}" -eq 1 ];
                then
                   echo ""${thedoms[$r]}" is NOT live here" #Dig returned Valid IP but the IP is not on the box, call it "not live"
                else
                ##Not sure how someone can make it this far with all the checks and sedding the crap out of everything
                ##only plausible reason I can come up with
                echo "a severe error has occured for "${thedoms[$r]}", by some Miracle you made it to this Error, You have attained the GoatWizard level of 99"
                fi
done
}

Main
