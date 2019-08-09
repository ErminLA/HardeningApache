import subprocess
from flask import Flask
from flask import request
from flask_cors import CORS
import json
import psutil
import socket

app = Flask(__name__)
CORS(app)

# TEST
@app.route("/")
def helloWorld():
        return "TEST"


# LOGS
@app.route('/log_messages')
def print_log():
        return subprocess.check_output(['tail', '-n', '50',  '/var/log/messages'], stdin=None, stderr=None, shell=False, universal_newlines=False)

@app.route('/log_secure')
def print_secure():
        return subprocess.check_output(['tail', '-n', '50', '/var/log/secure'], stdin=None, stderr=None, shell=False, universal_newlines=False)

@app.route('/log_access_log')
def print_access_log():
        return subprocess.check_output(['tail', '-n', '50', '/var/log/httpd/access_log'], stdin=None, stderr=None, shell=False, universal_newlines=False)

@app.route('/log_error_log')
def print_error_log():
        return subprocess.check_output(['tail', '-n', '50', '/var/log/httpd/error_log'], stdin=None, stderr=None, shell=False, universal_newlines=False)

# COMMANDS
@app.route('/logged_in_users')
def print_logged_in_users():
        return subprocess.check_output(['last', '-a'], stdin=None, stderr=None, shell=False, universal_newlines=False)

@app.route('/process_list')
def process_list():
        return subprocess.check_output(['ps', 'aux'], stdin=None, stderr=None, shell=False, universal_newlines=True)

@app.route('/apache_version')
def apache_version():
        return subprocess.check_output(['httpd', '-V'], stdin=None, stderr=None, shell=False, universal_newlines=False)

def get_Src_Path():
        access_log = open("/var/log/httpd/access_log")
        line = access_log.readline()

        DATA = dict()

        while line:
                srcIp = line[:line.find(" ")]
                path = line[line.find('\"')+1:line.find('\"', line.find('\"')+1)]

                DATA.update({srcIp:path})

                line = access_log.readline()
        access_log.close()

        return DATA

@app.route('/src_path')
def src_path():
        return get_Src_Path()



# SERVER RESOURCES

## Network Data

### Connections
@app.route('/connections')
def connections():
        netstat = subprocess.check_output(['netstat', '-at'], stdin=None, stderr=None, shell=False, universal_newlines=True)
        return netstat

### Get all
@app.route('/network_traffic_all')
def network_traffic_all():
        cmd = ['tcpdump', '-i', 'any', '-c', '10']
        netData =  subprocess.check_output(cmd, stdin=None, stderr=None, shell=False, universal_newlines=False)
        return netData

### Check if IP is valid
def validateIP(addr):
        try:
                socket.inet_aton(addr)
                return True
        except socket.error:
                return False

def validatePort(port):
        port = int(port)
        try:
                if(1 <= port <= 65535):
                        return True
        except ValueError:
                return False
        else:
                return False

### Exclude IP
@app.route('/network_traffic_exclude_ip')
def network_traffic_exclude_ip():
        if(validateIP(request.args.get('ip'))):
                cmd = ['timeout', '--preserve-status', '-k', '5', '5','tcpdump', '-i', 'any', '-c', '10', 'not', 'host', request.args.get('ip')]
                return subprocess.check_output(cmd, stdin=None, stderr=None, shell=False, universal_newlines=False)
        else:
                return "INVALID INPUT"

### Exclude port
@app.route('/network_traffic_exclude_port')
def network_traffic_exclude_port():
        if(validatePort(request.args.get('port'))):
                cmd = ['timeout', '--preserve-status', '-k', '5', '5', 'tcpdump', '-i', 'any', '-c', '10', 'not', 'port', request.args.get('port')]
                return subprocess.check_output(cmd, stdin=None, stderr=None, shell=False, universal_newlines=False)
        else:
                return "INVALID INPUT"

### Specific port
@app.route('/network_traffic_port')
def network_traffic_port():
        if(validatePort(request.args.get('port'))):
                cmd = ['timeout', '--preserve-status', '-k', '5', '5', 'tcpdump', '-i', 'any', '-c', '10', 'port', request.args.get('port')]
                return subprocess.check_output(cmd, stdin=None, stderr=None, shell=False, universal_newlines=False)
        else:
                return "INVALID INPUT"

### Specific IP
@app.route('/network_traffic_ip')
def network_traffic_ip():
        IP = request.args.get('ip')
        test = validateIP(IP)

        if(test):
                cmd = ['timeout', '--preserve-status', '-k', '5', '5', 'tcpdump', '-i', 'any', '-c', '10', 'host', IP]
                return subprocess.check_output(cmd, stdin=None, stderr=None, shell=False, universal_newlines=False)
        else:
                retMsg = "INVALID INPUT"
                return retMsg

## DISK USAGE
@app.route('/disk_usage')
def disk_usage():
        cmd = ['df', '-h']
        return subprocess.check_output(cmd, stdin=None, stderr=None, shell=False, universal_newlines=False)

## CPU INFO
@app.route('/cpu_info')
def cpu_info():
        cpuinfo = subprocess.check_output(['cat', '/proc/cpuinfo'], stdin=None, stderr=None, shell=False, universal_newlines=True)
        return(cpuinfo)

@app.route('/mem_virt_info')
def mem_virt_info():
        meminfo = subprocess.check_output(['cat', '/proc/meminfo'], stdin=None, stderr=None, shell=False, universal_newlines=True) 
        return meminfo
