------------------------------
-- VARIABLES
------------------------------

local ESX = exports['es_extended']:getSharedObject()
local fixVehicle = false
local config = {}

------------------------------
-- FUNCTIONS
------------------------------

local function CreateBlips(config)
    for k, v in pairs(config.locations) do
        if v.blip.toggle then
            local blip = AddBlipForCoord(vector3(v.pos.x, v.pos.y, v.pos.z))
            SetBlipSprite(blip, v.blip.sprite)
            SetBlipDisplay(blip, 4)
            SetBlipScale(blip, v.blip.scale)
            SetBlipAsShortRange(blip, true)
            SetBlipColour(blip, v.blip.colour)
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(v.blip.text)
            EndTextCommandSetBlipName(blip)
        end
    end
end

local function Text(pos, text)
	SetTextScale(0.35, 0.35)
    SetTextFont(4)
    SetTextProportional(1)
    SetTextColour(255, 255, 255, 215)
    SetTextEntry('STRING')
    SetTextCentre(true)
    AddTextComponentString(text)
    SetDrawOrigin(vector3(pos.x, pos.y, pos.z + 0.25), 0)
    DrawText(0.0, 0.0)
    local factor = (string.len(text)) / 370
    DrawRect(0.0, 0.0 + 0.0125, 0.005 + factor, 0.03, 0, 0, 0, 75)
    ClearDrawOrigin()
end

local function FixVehicle(config, v)
    local ped = PlayerPedId()
    local veh = GetVehiclePedIsIn(ped, false)
    local engineCache = GetVehicleEngineHealth(veh)
    local bodyCache = GetVehicleBodyHealth(veh)
    local petrolCache = GetVehiclePetrolTankHealth(veh)
    local percentage = engineCache / 1000 / 2 + bodyCache / 1000 / 2
    fixVehicle = true

    FreezeEntityPosition(veh, true)
    SetVehicleEngineOn(veh, false, false, true)
    RequestModel(v.model)
    repeat Wait(100) until HasModelLoaded(v.model)

    local npc = CreatePed(0, v.model, v.pedPos.x, v.pedPos.y, v.pedPos.z -1, v.pedPos.w, false, false)
    SetEntityInvincible(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)
    local pos = GetWorldPositionOfEntityBone(veh, GetEntityBoneIndexByName(veh, 'engine'))
    TaskGoToCoordAnyMeans(npc, pos.x, pos.y, pos.z, 1.0)
    repeat Wait(500) until #(GetEntityCoords(npc) - pos) < 1.75

    TaskTurnPedToFaceCoord(npc, pos.x, pos.y, pos.z, -1)
    Wait(1000)
    TaskStartScenarioInPlace(npc, 'PROP_HUMAN_BUM_BIN', 0, true)
    Wait(1000)
    SetVehicleDoorOpen(veh, 4, false)

    TriggerEvent('mythic_progbar:client:progress', {
        name = 'fixing_vehicle',
        duration = math.floor(config.progressBar['duration'] / percentage),
        label = config.progressBar['label'],
        useWhileDead = false,
        canCancel = false,
        controlDisables = {
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
        },
    }, function(status)
        if not status then
            SetVehicleDoorShut(veh, 4, false)
            Wait(100)
            TaskGoToCoordAnyMeans(npc, v.pedPos.x, v.pedPos.y, v.pedPos.z, 1.0, 0, 0, 786603, 0xbf800000)
            FreezeEntityPosition(veh, false)

            repeat Wait(500) until #(GetEntityCoords(npc) - vector3(v.pedPos.x, v.pedPos.y, v.pedPos.z)) < 1.0
            DeleteEntity(npc)

            if v.fixEngine then
                SetVehicleEngineHealth(veh, 1000.0)
                SetVehiclePetrolTankHealth(veh, 1000.0)
            end

            if v.fixBody then
                SetVehicleFixed(veh)
                SetVehicleEngineHealth(veh, engineCache)
                SetVehiclePetrolTankHealth(veh, petrolCache)
                SetVehicleBodyHealth(veh, 1000.0)
            end

            fixVehicle = false

            SetVehicleEngineOn(veh, true, false, true)
            TriggerEvent('mythic_notify:client:SendAlert', {
                type = 'inform',
                length = 4000,
                text = 'Ajoneuvo korjattu!',
            })
        end
    end)
end

------------------------------
-- THREADS
------------------------------

CreateThread(function()
    repeat Wait(1000) until ESX.IsPlayerLoaded()
    ESX.TriggerServerCallback('0-repair:server:config:getConfig', function(data)
        local config = data

        CreateBlips(config)

        while ESX do
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            local veh = GetVehiclePedIsIn(ped, false)
            local w = 1500

            if veh ~= 0 then
                for k, v in pairs(config.locations) do
                    if not fixVehicle then
                        if #(coords - vector3(v.pos.x, v.pos.y, v.pos.z)) < 10.0 then
                            w = 5
                            DrawMarker(2, v.pos.x, v.pos.y, v.pos.z, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.2, 0.2, 0.1, 255, 255, 255, 150, true, true, 5, nil, nil, false)
                            if #(coords - vector3(v.pos.x, v.pos.y, v.pos.z)) < 5.0 then
                                local engineHealth = GetVehicleEngineHealth(veh) / 1000 / 2
                                local bodyHealth = GetVehicleBodyHealth(veh) / 1000 / 2
                                Text(v.pos, '~g~E~w~ - Korjaa ajoneuvo ' .. math.floor(v.minPrice / (engineHealth + bodyHealth)) .. '€')
            
                                if IsControlJustPressed(0, 38) then
                                    ESX.TriggerServerCallback('0-repair:server:config:employeeCheck', function(amount)
                                        if amount > 0 then
                                            TriggerEvent('mythic_notify:client:SendAlert', {
                                                type = 'error',
                                                length = 4000,
                                                text = 'Korjaajaa ei saatavilla',
                                            })
                                            return
                                        end

                                        ESX.TriggerServerCallback('0-repair:server:config:moneyCheck', function(state)
                                            if not state then
                                                TriggerEvent('mythic_notify:client:SendAlert', {
                                                    type = 'error',
                                                    length = 4000,
                                                    text = 'Sinulla ei ole tarpeaksi rahaa!',
                                                })
                                                return
                                            end
                     
                                            FixVehicle(config, v)
                                        end, k, math.floor(v.minPrice / (engineHealth + bodyHealth)))
                                    end, k)
                                end
                            end
                        end
                    end
                end
            else
                w = 2500
            end

            Wait(w)
        end
    end)
end)

