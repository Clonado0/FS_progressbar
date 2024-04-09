local Action = {
    name = "",
    duration = 0,
    label = "",
    useWhileDead = false,
    canCancel = true,
	disarm = true,
    controlDisables = {
        disableMovement = false,
        disableCarMovement = false,
        disableMouse = false,
        disableCombat = false,
    },
    animation = {
        animDict = nil,
        anim = nil,
        flags = 0,
        task = nil,
    },
    prop = {
        model = nil,
        bone = nil,
        coords = { x = 0.0, y = 0.0, z = 0.0 },
        rotation = { x = 0.0, y = 0.0, z = 0.0 },
    },
    propTwo = {
        model = nil,
        bone = nil,
        coords = { x = 0.0, y = 0.0, z = 0.0 },
        rotation = { x = 0.0, y = 0.0, z = 0.0 },
    },
}

local isDoingAction = false
local disableMouse = false
local wasCancelled = false
local isAnim = false
local isProp = false
local isPropTwo = false
local prop_net = nil
local propTwo_net = nil
local runProgThread = false

RegisterNetEvent('progressbar:client:ToggleBusyness')
AddEventHandler('progressbar:client:ToggleBusyness', function(bool)
    isDoingAction = bool
end)

function Progress(action, finish)
	Process(action, nil, nil, finish)
end

function ProgressWithStartEvent(action, start, finish)
	Process(action, start, nil, finish)
end

function ProgressWithTickEvent(action, tick, finish)
	Process(action, nil, tick, finish)
end

function ProgressWithStartAndTick(action, start, tick, finish)
	Process(action, start, tick, finish)
end

function Process(action, start, tick, finish)
	ActionStart()
    Action = action
    local ped = PlayerPedId()
    if not IsEntityDead(ped) or Action.useWhileDead then
        if not isDoingAction then
            isDoingAction = true
            wasCancelled = false
            isAnim = false
            isProp = false
            
			TriggerEvent("NUI:ProgressBar", Action.duration, Action.label)

            Citizen.CreateThread(function ()
                if start ~= nil then
                    start()
                end
                while isDoingAction do
                    Citizen.Wait(1)
                    if tick ~= nil then
                        tick()
                    end
                    if IsControlJustPressed(0, `INPUT_FRONTEND_PAUSE_ALTERNATE`) and Action.canCancel then
                        TriggerEvent("progressbar:client:cancel")
                    end

                    if IsEntityDead(ped) and not Action.useWhileDead then
                        TriggerEvent("progressbar:client:cancel")
                    end
                end
                if finish ~= nil then
                    finish(wasCancelled)
                end
            end)
        else
            TriggerEvent("texas:notify:native", "Você já está fazendo algo!", 5000)
        end
    else
        TriggerEvent("texas:notify:native", "Não posso fazer essa ação!", 5000)
    end
end

function ActionStart()
    runProgThread = true
    LocalPlayer.state:set("inv_busy", true, true) -- Busy
    Citizen.CreateThread(function()
        while runProgThread do
            if isDoingAction then
                if not isAnim then
                    if Action.animation ~= nil then
                        if Action.animation.task ~= nil then
                            TaskStartScenarioInPlace(PlayerPedId(), Action.animation.task, 0, true)
                        elseif Action.animation.animDict ~= nil and Action.animation.anim ~= nil then
                            if Action.animation.flags == nil then
                                Action.animation.flags = 1
                            end

                            local player = PlayerPedId()
                            if (DoesEntityExist(player) and not IsEntityDead(player)) then
                                loadAnimDict( Action.animation.animDict)
                                TaskPlayAnim(player, Action.animation.animDict, Action.animation.anim, 3.0, 3.0, -1, Action.animation.flags, 0, 0, 0, 0 )     
                            end
                        else
                            --TaskStartScenarioInPlace(PlayerPedId(), 'PROP_HUMAN_BUM_BIN', 0, true)
                        end
                    end

                    isAnim = true
                end
                if not isProp and Action.prop ~= nil and Action.prop.model ~= nil then
                    local ped = PlayerPedId()
                    RequestModel(Action.prop.model)

                    while not HasModelLoaded(GetHashKey(Action.prop.model)) do
                        Citizen.Wait(0)
                    end

                    local pCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, 0.0)
                    local modelSpawn = CreateObject(GetHashKey(Action.prop.model), pCoords.x, pCoords.y, pCoords.z, true, true, true)

                    local netid = ObjToNet(modelSpawn)
                    SetNetworkIdExistsOnAllMachines(netid, true)
                    NetworkSetNetworkIdDynamic(netid, true)
                    SetNetworkIdCanMigrate(netid, false)
                    if Action.prop.bone == nil then
                        Action.prop.bone = 60309
                    end

                    if Action.prop.coords == nil then
                        Action.prop.coords = { x = 0.0, y = 0.0, z = 0.0 }
                    end

                    if Action.prop.rotation == nil then
                        Action.prop.rotation = { x = 0.0, y = 0.0, z = 0.0 }
                    end

                    AttachEntityToEntity(modelSpawn, ped, GetPedBoneIndex(ped, Action.prop.bone), Action.prop.coords.x, Action.prop.coords.y, Action.prop.coords.z, Action.prop.rotation.x, Action.prop.rotation.y, Action.prop.rotation.z, 1, 1, 0, 1, 0, 1)
                    prop_net = netid

                    isProp = true
                    
                    if not isPropTwo and Action.propTwo ~= nil and Action.propTwo.model ~= nil then
                        RequestModel(Action.propTwo.model)

                        while not HasModelLoaded(GetHashKey(Action.propTwo.model)) do
                            Citizen.Wait(0)
                        end

                        local pCoords = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, 0.0)
                        local modelSpawn = CreateObject(GetHashKey(Action.propTwo.model), pCoords.x, pCoords.y, pCoords.z, true, true, true)

                        local netid = ObjToNet(modelSpawn)
                        SetNetworkIdExistsOnAllMachines(netid, true)
                        NetworkSetNetworkIdDynamic(netid, true)
                        SetNetworkIdCanMigrate(netid, false)
                        if Action.propTwo.bone == nil then
                            Action.propTwo.bone = 60309
                        end

                        if Action.propTwo.coords == nil then
                            Action.propTwo.coords = { x = 0.0, y = 0.0, z = 0.0 }
                        end

                        if Action.propTwo.rotation == nil then
                            Action.propTwo.rotation = { x = 0.0, y = 0.0, z = 0.0 }
                        end

                        AttachEntityToEntity(modelSpawn, ped, GetPedBoneIndex(ped, Action.propTwo.bone), Action.propTwo.coords.x, Action.propTwo.coords.y, Action.propTwo.coords.z, Action.propTwo.rotation.x, Action.propTwo.rotation.y, Action.propTwo.rotation.z, 1, 1, 0, 1, 0, 1)
                        propTwo_net = netid

                        isPropTwo = true
                    end
                end

                DisableActions(ped)
            end
            Citizen.Wait(0)
        end
    end)
end

function Cancel()
    isDoingAction = false
    wasCancelled = true
    LocalPlayer.state:set("inv_busy", false, true) -- Not Busy
    ActionCleanup()

    DisplayElemet = 100
end

function Finish()
    isDoingAction = false
    ActionCleanup()
    LocalPlayer.state:set("inv_busy", false, true) -- Not Busy
end

function ActionCleanup()
    local ped = PlayerPedId()

    if Action.animation ~= nil then
        if Action.animation.task ~= nil or (Action.animation.animDict ~= nil and Action.animation.anim ~= nil) then
            ClearPedSecondaryTask(ped)
            StopAnimTask(ped, Action.animDict, Action.anim, 1.0)
        else
            ClearPedTasks(ped)
        end
    end

    DetachEntity(NetToObj(prop_net), 1, 1)
    DeleteEntity(NetToObj(prop_net))
    DetachEntity(NetToObj(propTwo_net), 1, 1)
    DeleteEntity(NetToObj(propTwo_net))
    prop_net = nil
    propTwo_net = nil
    runProgThread = false
end

function loadAnimDict(dict)
	while (not HasAnimDictLoaded(dict)) do
		RequestAnimDict(dict)
		Citizen.Wait(5)
	end
end

function DisableActions(ped)
    if Action.controlDisables.disableMouse then
        DisableControlAction(0, `INPUT_LOOK_LR`, true) -- LookLeftRight
        DisableControlAction(0, `INPUT_LOOK_UD`, true) -- LookUpDown
        DisableControlAction(0, `INPUT_VEH_MOUSE_CONTROL_OVERRIDE`, true) -- VehicleMouseControlOverride
    end

    if Action.controlDisables.disableMovement then
        DisableControlAction(0, `INPUT_MOVE_LR`, true) -- disable left/right
        DisableControlAction(0, `INPUT_MOVE_UD`, true) -- disable forward/back
        DisableControlAction(0, `INPUT_DUCK`, true) -- INPUT_DUCK
        DisableControlAction(0, `INPUT_SPRINT`, true) -- disable sprint
    end

    if Action.controlDisables.disableCarMovement then
        DisableControlAction(0, `INPUT_VEH_MOVE_LEFT_ONLY`, true) -- veh turn left
        DisableControlAction(0, `INPUT_VEH_MOVE_RIGHT_ONLY`, true) -- veh turn right
        DisableControlAction(0, `INPUT_VEH_ACCELERATE`, true) -- veh forward
        DisableControlAction(0, `INPUT_VEH_BRAKE`, true) -- veh backwards
        DisableControlAction(0, `INPUT_VEH_EXIT`, true) -- disable exit vehicle
    end

    if Action.controlDisables.disableCombat then
        DisablePlayerFiring(PlayerId(), true) -- Disable weapon firing
        DisableControlAction(0, `INPUT_ATTACK`, true) -- disable attack
        DisableControlAction(0, `INPUT_AIM`, true) -- disable aim
        DisableControlAction(1, `INPUT_SELECT_WEAPON`, true) -- disable weapon select
        DisableControlAction(0, `INPUT_DETONATE`, true) -- disable weapon
        DisableControlAction(0, `INPUT_THROW_GRENADE`, true) -- disable weapon
        DisableControlAction(0, `INPUT_MELEE_BLOCK`, true) -- disable melee
        DisableControlAction(0, `INPUT_RELOAD`, true) -- disable melee
        DisableControlAction(0, `INPUT_MELEE_ATTACK`, true) -- disable melee
        DisableControlAction(0, `INPUT_RADIAL_MENU_SLOT_NAV_PREV`, true) -- disable melee
    end
end

RegisterNetEvent("progressbar:client:progress")
AddEventHandler("progressbar:client:progress", function(action, finish)
	Process(action, nil, nil, finish)
end)

RegisterNetEvent("progressbar:client:ProgressWithStartEvent")
AddEventHandler("progressbar:client:ProgressWithStartEvent", function(action, start, finish)
	Process(action, start, nil, finish)
end)

RegisterNetEvent("progressbar:client:ProgressWithTickEvent")
AddEventHandler("progressbar:client:ProgressWithTickEvent", function(action, tick, finish)
	Process(action, nil, tick, finish)
end)

RegisterNetEvent("progressbar:client:ProgressWithStartAndTick")
AddEventHandler("progressbar:client:ProgressWithStartAndTick", function(action, start, tick, finish)
	Process(action, start, tick, finish)
end)

RegisterNetEvent("progressbar:client:cancel")
AddEventHandler("progressbar:client:cancel", function()
	Cancel()
end)

RegisterNUICallback('FinishAction', function(data, cb)
	Finish()
end)

local TextureDicts = {"rpg_meter", "rpg_meter_track", "generic_textures"}

function RequestDict(dicts)
    for k, v in pairs(dicts) do
        while not HasStreamedTextureDictLoaded(v) do
            Wait(0)
            RequestStreamedTextureDict(v, true)
        end
    end
end

DisplayProgressBar = function(time, desciption, isDisabledControlAction,cb)
    RequestDict(TextureDicts)
    local timer = (time / 100)
    local DisplayElemet = 0
    
    Citizen.CreateThread(function()
        while DisplayElemet < 99 do
            Wait(1)
            if isDisabledControlAction then
                DisableAllControlActions(0, true)
            end
            DrawSprite("generic_textures", "counter_bg_1b", 0.5, 0.9, 0.023, 0.04, 0.0, 0, 0, 0, 255)
            DrawSprite("rpg_meter_track", "rpg_meter_track_9", 0.5, 0.9, 0.03, 0.05, 0.0, 176, 176, 176, 120)
            DrawSprite("rpg_meter", "rpg_meter_" .. DisplayElemet, 0.5, 0.9, 0.03, 0.05, 0.0, 225, 225, 225, 255)
            Text(0.5001, 0.89, 0.28, tostring(DisplayElemet + 1), {225, 225, 225}, false, true)
            Text(0.5001, 0.93, 0.28, desciption, {255, 255, 255}, false, true)
        end
    end)
    
    if cb then
        Citizen.CreateThread(function()
            cb()
        end)
    end

    while DisplayElemet < 100 do
        DisplayElemet = DisplayElemet + 1
        Wait(timer)
    end
end


exports('DisplayProgressBar', DisplayProgressBar)
RegisterNetEvent("NUI:ProgressBar", DisplayProgressBar)

function Text(x, y, scale, text, colour, align, force, w)
    local colour = colour or Config.GUI.TextColor
    local str = CreateVarString(10, "LITERAL_STRING", text)
    SetTextFontForCurrentCommand(7)
    SetTextScale(scale, scale)
    Citizen.InvokeNative(1758329440 & 0xFFFFFFFF, align)
    SetTextColor(colour[1], colour[2], colour[3], 255)
    if w then
        Citizen.InvokeNative(1868606292 & 0xFFFFFFFF, w.x, w.y)
    end
    SetTextDropshadow(3, 0, 0, 0, 255)
    DisplayText(str, x, y)
end
