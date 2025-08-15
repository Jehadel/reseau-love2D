import socket

localIP = '127.0.0.1'
localPort = 54321
buffersize = 1024

udp = socket.socket(family=socket.AF_INET, type=socket.SOCK_DGRAM)
try:
    udp.bind((localIP, localPort))

    print("Serveur en écoute sur port 54321")

    while(True):

        data = udp.recvfrom(buffersize)
        client_msg = data[0]
        client_ip = data[1]

        print(f'Message reçu de {client_ip} : {client_msg.decode("utf-8")}')

        udp.sendto('Hello client!'.encode("utf-8"),client_ip)

except KeyboardInterrupt:
    print("\nArrêt du serveur...")
finally:
    # Fermeture propre du socket
    udp.close()
print("Socket fermé.")