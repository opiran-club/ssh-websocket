#!/usr/bin/env python
# encoding: utf-8
import socket, threading, thread, select, signal, sys, time, getopt

PASS = ''
LISTENING_ADDR = '0.0.0.0'
try:
   LISTENING_PORT = int(sys.argv[1])
except:
   LISTENING_PORT = 80
SSH_PORT = 22  # Default SSH port
BUFLEN = 4096 * 4
TIMEOUT = 60
MSG = ''
COR = '<font color="null">'
FTAG = '</font>'
DEFAULT_HOST = "127.0.0.1"
RESPONSE = (
    "HTTP/1.1 101 Switching Protocols\r\n"
    "Upgrade: websocket\r\n"
    "Connection: Upgrade\r\n\r\n"
)

def hash_password(password):
    # You can use a better hashing algorithm (e.g., bcrypt) for stronger security
    return hashlib.sha256(password.encode()).hexdigest()

class Server(threading.Thread):
    def __init__(self, host, port, ssh_port):
        threading.Thread.__init__(self)
        self.running = False
        self.host = host
        self.port = port
        self.ssh_port = ssh_port
        self.threads = []
        self.threadsLock = threading.Lock()
        self.logLock = threading.Lock()


    async def handle_connection(self, websocket, path):
        try:
            client_buffer = await websocket.recv()
            host_port = self.find_header(client_buffer, 'X-Real-Host')

            if not host_port:
                host_port = DEFAULT_HOST

            split = self.find_header(client_buffer, 'X-Split')

            if split:
                await websocket.recv(BUFLEN)

            if host_port:
                passwd = self.find_header(client_buffer, 'X-Pass')

                if len(PASS) != 0 and passwd == PASS:
                    await self.method_CONNECT(host_port, websocket)
                elif len(PASS) != 0 and passwd != PASS:
                    await websocket.send('HTTP/1.1 400 WrongPass!\r\n\r\n')
                elif host_port.startswith('127.0.0.1') or host_port.startswith('localhost'):
                    await self.method_CONNECT(host_port, websocket)
                else:
                    await websocket.send('HTTP/1.1 403 Forbidden!\r\n\r\n')
            else:
                print('- No X-Real-Host!')
                await websocket.send('HTTP/1.1 400 NoXRealHost!\r\n\r\n')
        except Exception as e:
            print("Error:", e)
        finally:
            await websocket.close()

    async def method_CONNECT(self, path, websocket):
        print('CONNECT', path)
        target = await self.connect_target(path)
        await websocket.send(RESPONSE)

        try:
            while True:
                data = await websocket.recv()
                if data:
                    await target.send(data)
        except:
            pass
        finally:
            target.close()

    async def connect_target(self, host):
        i = host.find(':')
        if i != -1:
            port = int(host[i + 1:])
            host = host[:i]
        else:
            if host.startswith('wss'):
                port = 443
            else:
                port = 80

        context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
        target = await websockets.connect(f"{host}:{port}", ssl=context)
        return target

    @staticmethod
    def find_header(head, header):
        aux = head.find(header + ': ')

        if aux == -1:
            return ''

        aux = head.find(':', aux)
        head = head[aux + 2:]
        aux = head.find('\r\n')

        if aux == -1:
            return ''

        return head[:aux]

def print_usage():
    print('Use: proxy.py -p <port>')
    print('       proxy.py -b <ip> -p <porta>')
    print('       proxy.py -b 0.0.0.0 -p 22')

def parse_args(argv):
    global LISTENING_ADDR
    global LISTENING_PORT
    global SSH_PORT
    
    try:
        opts, args = getopt.getopt(argv, "hb:p:s:", ["bind=", "port=", "sshport="])
    except getopt.GetoptError:
        print_usage()
        sys.exit(2)
    for opt, arg in opts:
        if opt == '-h':
            print_usage()
            sys.exit()
        elif opt in ("-b", "--bind"):
            LISTENING_ADDR = arg
        elif opt in ("-p", "--port"):
            LISTENING_PORT = int(arg)
        elif opt in ("-s", "--sshport"):
            SSH_PORT = int(arg)

def main(host=LISTENING_ADDR, port=LISTENING_PORT, ssh_port=SSH_PORT):
    print("\033[0;34m━" * 8, "\033[1;32m PROXY WEBSOCKET", "\033[0;34m━" * 8, "\n")
    print("\033[1;33mIP:\033[1;32m", LISTENING_ADDR)
    print("\033[1;33mPORTA:\033[1;32m", str(LISTENING_PORT), "\n")
    print("\033[0;34m━" * 10, "\033[1;32m────────────ㅤㅤOPIran Panel ㅤㅤ────────────", "\033[0;34m━\033[1;37m" * 11, "\n")

    server = Server(LISTENING_ADDR, LISTENING_PORT)
    asyncio.get_event_loop().run_until_complete(
        websockets.serve(server.handle_connection, LISTENING_ADDR, LISTENING_PORT)
    )

    try:
        asyncio.get_event_loop().run_forever()
    except KeyboardInterrupt:
        print('stopping...')
        sys.exit(0)

if __name__ == '__main__':
    parse_args(sys.argv[1:])
    main()
