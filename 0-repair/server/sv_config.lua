------------------------------
-- VARIABLES
------------------------------

local ESX = exports['es_extended']:getSharedObject()
local config = {}

config.progressBar = {
    ['duration'] = 8000,
    ['label'] = 'Ajoneuvoasi korjataan..'
}

config.settings = {
    ['esxLegacy'] = true
}

config.locations = {
    [1] = {
        ['pos'] = vector4(533.81, -179.43, 54.38, 338.1),
        ['pedPos'] = vector4(548.48, -173.45, 54.48, 123.43),
        ['model'] = 'mp_m_waremech_01',
        ['minPrice'] = 300,
        ['fixEngine'] = true,
        ['fixBody'] = false,
        ['blip'] = {
            toggle = true,
            sprite = 544,
            scale = 0.8,
            colour = 38,
            text = 'Korjaamo kaupunki'
        }
    }
}

------------------------------
-- THREADS
------------------------------

CreateThread(function()
    ESX.RegisterServerCallback('0-repair:server:config:getConfig', function(source, cb)
        cb(config)
    end)

    ESX.RegisterServerCallback('0-repair:server:config:moneyCheck', function(source, cb, location, price)
        local state = false
        local player = ESX.GetPlayerFromId(source)
        if player.getAccount('money').money >= price then
            player.removeAccountMoney('money', price)
            state = true
        elseif player.getAccount('bank').money >= price then
            player.removeAccountMoney('bank', price)
            state = true
        else
            state = false
        end
        cb(state)
    end)

    ESX.RegisterServerCallback('0-repair:server:config:employeeCheck', function(source, cb, location)
        if config.containers['esxLegacy'] then
            cb(#ESX.GetExtendedPlayers('job', 'mechanic'))
        else
            local mechanicAmount = 0
            local players = ESX.GetPlayers()
            
            for i=1, #players, 1 do
                local source = players[i]
                local player = ESX.GetPlayerFromId(source)
                
                if player.job and player.job.name == 'mechanic' then
                    mechanicAmount = mechanicAmount + 1
                end
            
            end
            cb(mechanicAmount)
        end
    end)
end)

