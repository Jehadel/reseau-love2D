local socket = require 'socket'

-- création canaux de communication main <--> thread
local channel_fromMain = love.thread.getChannel('send')
local channel_toMain = love.thread.getChannel('receive')

-- création socket
local udp = socket.udp4()
udp:settimeout(0)

local server_ip = '127.0.0.1'
local server_port = 54321

print('Thread réseau démarré')

while true do
    -- Vérifier si on doit quitter
    local main_message = channel_fromMain:pop()
    -- s’il y a un message
    if main_message then
        -- envoyer ce message au serveur
        local success, errorMsg = udp:sendto(main_message, server_ip, server_port)
        if success then 
            print('Message envoyé au serveur: ' .. main_message)
        else
            print('Erreur d’envoi '..errorMsg)
            -- on peut en avertir le main thread

        end
        -- si ce message est un message de déconnexion, sortir de la boucle
        if string.sub(main_message, 1, 4) == 'QUIT' then
            print('Arrêt du thread réseau')
            break
        end
    end
    
    -- Vérifier les réponses du serveur
    local data, ip, port = udp:receivefrom()
    if data then
        channel_toMain:push(data)
        print('Réponse reçue du serveur: ' .. data)
    end
    
    socket.sleep(0.1)
end

-- On ferme proprement
udp:close()
print('Thread client: Fermé')
