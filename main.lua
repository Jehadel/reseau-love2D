--
-- CLIENT
--

local client = {
thread,
channel_toClient,
channel_fromClient,
timer = 5,
UUID,
UPDATERATE = 5,
isConnected = false,
connectionAsked = false,
connectionAccepted = false,
msg = ''
}

local text = 'en attente...'
local text_y = 50

local function getSeed()

	local ost = os.time() * 1000
	local osc = os.clock() * 1000000
	return ost + osc

end


local function genUuid()

	local seed = getSeed()
	math.randomseed(seed)

	local uuid = ''

	for i = 1, 32 do
		if i == 9 or i == 14 or i == 19 or i == 24 then
            uuid = uuid .. "-"  -- Il y a des tirets à ces positions
        elseif i == 15 then
            uuid = uuid .. "4"  -- 4 pour indiquer v4 à la 13e position
        elseif i == 20 then
            -- Variant bits: 10xx (8-11 en décimal, 8-B en hex)
            local variant = math.random(8, 11)
            uuid = uuid .. string.format("%x", variant) -- %x pour charactère hexadécimal
        else
            -- Caractère aléatoire (0-F en hexadecimal, 
            local random_hex = math.random(0, 15)
            uuid = uuid .. string.format("%x", random_hex) -- %x pour charactère hexadécimal
        end
    end

	return uuid

end

SCREEN_W = 800
SCREEN_H = 600 

math.randomseed(getSeed()) 

local sprite = {}
sprite.position = {
    x = math.random(SCREEN_W/3, SCREEN_W * 2/3), 
    y = math.random(SCREEN_H/3, SCREEN_H * 2/3)}
sprite.size = 30
sprite.speed = 5

function pick_color(min, max)
    min = min or 100 
    max = max or 255
        return math.random(min, max)/255
end

sprite.color = {
    r = pick_color(),
    g = pick_color(), 
    b = pick_color() 
}


function love.load()

    print('=== Client Love2D avec Thread ===')

    client.UUID = genUuid()
    
    -- Créer les canaux de communication
    client.channel_toClient = love.thread.getChannel("send")
    client.channel_fromClient = love.thread.getChannel("receive")
    
    -- Créer et lancer le thread réseau
    client.thread = love.thread.newThread("client_thread.lua")
    client.thread:start()
end


function love.update(dt)

    
    -- Envoyer un message toutes les 5 secondes
    if client.timer == client.UPDATERATE then

        if client.connectionAccepted == false then 
            client.msg = 'CONNECT:'..client.UUID
            client.channel_toClient:push(client.msg)
            print('Demande de connexion au serveur envoyé au thread')
        else
            client.msg = 'UPDATE:'..client.UUID
            client.channel_toClient:push(client.msg)
            print('Update envoyé au thread')
        end
        
        -- tgraite message reçu 
        local message = client.channel_fromClient:pop()
        if message then
            text = 'répond : ' .. message
            text_y = 30
            print('Message reçu: ' .. message)
            if string.sub(message, 1, 8) == 'ACCEPTED' then
                client.connectionAccepted = true
            elseif string.sub(message, 1, 7) == 'UNKNOWN' or string.sub(message, 1, 7) == 'REFUSED' then
                client.connectionAccepted = false
            end
        else
            text = 'aucun message reçu'
            text_y = 50
        end

    end

    client.timer = client.timer - dt
    if client.timer < 0 then
        client.timer = client.UPDATERATE
    end
    
end


function love.draw()
    love.graphics.print('Client '..client.UUID, 10, 10)
    love.graphics.print('Serveur '..text, 10, text_y)
    love.graphics.print('timer '..client.timer, 300, 10)
    love.graphics.print('connecté '..tostring(client.connectionAccepted), 10, 70)

    love.graphics.setColor(sprite.color.r, sprite.color.g, sprite.color.b)
    love.graphics.rectangle('fill', sprite.position.x, sprite.position.y, sprite.size, sprite.size)
    love.graphics.setColor(1, 1, 1)
end


function love.quit()
    if client.thread then
        client.channel_toClient:push('QUIT:'..client.UUID)
        client.thread:wait()
    end
end
