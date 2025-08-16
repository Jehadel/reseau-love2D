local socket = require 'socket'

--
-- SERVER INFO
--

local server = {}
server.maxClients = 4
server.clients = {} 
server.clientCount = #server.clients
server.ip = '127.0.0.1'
server.port = 54321
server.timeout = 0.001 -- on fixe un timeout non bloquant, mais pas à zéro pour économiser le cpu

function server:init_server()

    print('=== Serveur Lua Autonome ===')
    server.udp = socket.udp()
    if not server.udp then
        print('ERREUR: Impossible de créer le socket UDP IPv4')
        return
    end

    server.udp:settimeout(server.timeout) -- on définit par défaut (c‘est plus sûr) le timeout non bloquant choisi
    local success = server.udp:setsockname('*', server.port)
    if not success then
        print('Erreur : impossible de lier (bind) le socket')
    else
        print('Serveur en écoute sur port '..server.port)
    end

end


function server:send_message(pMsg, pIp, pPort)
    -- on on gère les erreur d’envoi de message

    local success, errorMsg = server.udp:sendto(pMsg, pIp, pPort)
    if not success then
        print('Erreur d’envoi : '..errorMsg)
    end

end


--
-- CLIENTS INFO
--

function newClient(pUuid, pIp, pPort)

    local client = {}
    client.connected = true 
    client.ip = pIp
    client.port = pPort
    client.update = false
    server.clients[pUuid] = client  

end


function parsing(pData)
    local info = {}
    local posKey = string.find(pData, ':')
    info.keyword = string.sub(pData, 1, posKey-1)
    info.value = string.sub(pData, posKey+1, #pData)
    return info
end

--
-- MAIN
--

server:init_server()

while true do

    -- avant toute chose on vérifie que on a « quelque chose dans les tuyaux »
    local ready_read, _, errorMsg = socket.select({server.udp}, nil, server.timeout) -- en UDP à part pour des envois massifs (60 fps pour des centaines de joueurs) on n’a pas besoin de ready_write
    -- ready_read est une table. Donc s’il y a au moins un élément, c’est qu’on a un message à récupérer 
    -- on peut aussi écrire if #ready_read > 0
    if errorMsg ~= nil then
        if errorMsg ~= 'timeout' then 
            print('Erreur lors de l’exécution de socket.select() : '..errorMsg)
        end
    end

    if ready_read[1] then
        local data, client_ip, client_port = server.udp:receivefrom()
        
        if data then

            print(string.format('Reçu: [%s] de %s:%s', data, client_ip, client_port))
            local data_parsed = parsing(data)

            if server.clients[data_parsed.value] ~= nil then

                -- si le client est connu (connecté) 
                if data_parsed.keyword == 'QUIT' then 
                    server.clients[data_parsed.value] = nil
                    print(data_parsed.value..' has quitted ! Removed from client list.')
                end

                if data_parsed.keyword == 'UPDATE' then
                    print('Updating '..data_parsed.value..'...')
                    server.clients[data_parsed.value].update = true
                    server:send_message('Updated '..data_parsed.value, client_ip, client_port)
                else
                    if server.clients[data_parsed.value] ~= nil then
                        server.clients[data_parsed.value].update = false
                    end
                end

            else
                if data_parsed.keyword == 'CONNECT' then

                    if server.clientCount < 4 then
                        newClient(data_parsed.value, client_ip, client_port)
                        server:send_message('ACCEPTED', client_ip, client_port)
                        print('Hello '..data_parsed.value..', added to client list !')
                    else
                        server:send_message('REFUSED', client_ip, client_port)
                        print('Connexion refusée, déjà '..server.clientCount..' clients')
                    end

                else
                    server:send_message('UNKNOWN', client_ip, client_port)
                    print('Client inconnu')
                end

            end

            print('\nListe des clients :')
            server.clientCount = 0
            for k, v in pairs(server.clients) do
                print('UUID : '..tostring(k)..' connected : '..tostring(v.connected)..' updated : '..tostring(v.update))
                server.clientCount = server.clientCount + 1
            end
            print('\nIl y a '..server.clientCount..' clients.')
        end
    end

end
