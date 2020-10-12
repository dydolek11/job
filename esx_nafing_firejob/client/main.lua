local CurrentActionData, blipsFires, currentTask = {}, {}, {}
local HasAlreadyEnteredMarker, isDead, hasAlreadyJoined, playerInService, useSaw = false, false, false, false, false
local LastStation, LastPart, LastPartNum, LastEntity, CurrentAction, CurrentActionMsg
isInShopMenu = false
ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	ESX.PlayerData = ESX.GetPlayerData()
end)

function cleanPlayer(playerPed)
	SetPedArmour(playerPed, 0)
	ClearPedBloodDamage(playerPed)
	ResetPedVisibleDamage(playerPed)
	ClearPedLastWeaponDamage(playerPed)
	ResetPedMovementClipset(playerPed, 0)
end

function setUniform(uniform, playerPed)
	TriggerEvent('skinchanger:getSkin', function(skin)
		local uniformObject

		if skin.sex == 0 then
			uniformObject = Config.Uniforms[uniform].male
		else
			uniformObject = Config.Uniforms[uniform].female
		end

		if uniformObject then
			TriggerEvent('skinchanger:loadClothes', skin, uniformObject)
		else
			ESX.ShowNotification(_U('no_outfit'))
		end
	end)
end

function OpenCloakroomMenu()
	local playerPed = PlayerPedId()
	local grade = ESX.PlayerData.job.grade_name

	local elements = {
		{label = _U('citizen_wear'), value = 'citizen_wear'},
		{label = _U('fire_wear'), uniform = grade},
		{label = _U('equip'), value = 'equip'}
	}
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'cloakroom', {
		title    = _U('cloakroom'),
		align    = Config.Align,
		elements = elements
	}, function(data, menu)
		cleanPlayer(playerPed)
		if data.current.value == 'citizen_wear' then
			ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
				TriggerEvent('skinchanger:loadSkin', skin)
			end)
			TriggerEvent('esx_nafing_firejob:updateBlip')
			playerInService = false
		elseif data.current.uniform then
			setUniform(data.current.uniform, playerPed)
			playerInService = true
		elseif data.current.value == 'equip' then
			TriggerServerEvent('esx_nafing_firejob:server:equip')
		end

	end, function(data, menu)
		menu.close()

		CurrentAction     = 'menu_cloakroom'
		CurrentActionMsg  = _U('open_cloackroom')
		CurrentActionData = {}
	end)
end

function OpenFireActionsMenu()
	ESX.UI.Menu.CloseAll()

	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'fire_actions', {
		title    = 'fire',
		align    = Config.Align,
		elements = {
			{label = _U('vehicle_interaction'), value = 'vehicle_interaction'},
			{label = _U('object_spawner'), value = 'object_spawner'}
	}}, function(data, menu)
		if data.current.value == 'vehicle_interaction' then
			local elements  = {}
			local playerPed = PlayerPedId()
			local vehicle = ESX.Game.GetVehicleInDirection()
			local useLadders = exports['inferno-ladders']:TruckTest()

			if DoesEntityExist(vehicle) and vehicle then
				table.insert(elements, {label = _U('pick_lock'), value = 'hijack_vehicle'})
				table.insert(elements, {label = _U('flip'), value = 'flip'})
				if useSaw then
					table.insert(elements, {label = _U('cut_doors'), value = 'cut_doors'})
				end
				if useLadders then
					table.insert(elements,	{label = _U('collect_ladder'), value = 'collect_ladder'})
					table.insert(elements,	{label = _U('store_ladder'), value = 'store_ladder'})
					table.insert(elements,	{label = _U('collect_saw'), value = 'collect_saw'})
					table.insert(elements,	{label = _U('store_saw'), value = 'store_saw'})
				end
			else
				ESX.ShowNotification(_U('no_vehicles_nearby'))
			end

			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'vehicle_interaction', {
				title    = _U('vehicle_interaction'),
				align    = Config.Align,
				elements = elements
			}, function(data2, menu2)
				local coords  = GetEntityCoords(playerPed)
				vehicle = ESX.Game.GetVehicleInDirection()
				action  = data2.current.value

				if DoesEntityExist(vehicle) then
					if action == 'hijack_vehicle' then
						if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 3.0) then
							TaskStartScenarioInPlace(playerPed, 'WORLD_HUMAN_WELDING', 0, true)
							Citizen.Wait(20000)
							ClearPedTasksImmediately(playerPed)
		
							SetVehicleDoorsLocked(vehicle, 1)
							SetVehicleDoorsLockedForAllPlayers(vehicle, false)
							ESX.ShowNotification(_U('vehicle_unlocked'))
						end
					elseif action == 'cut_doors' then
						TriggerEvent('esx_nafing_firejob:CutChainsaw')
					elseif action == 'flip' then
						TriggerEvent('esx_nafing_firejob:flipVehicle')
					elseif action == 'collect_ladder' then
						TriggerEvent('Ladders:Client:Show', true)
					elseif action == 'store_ladder' then
						TriggerEvent('Ladders:Client:Show', false)
					elseif action == 'collect_saw' then
						SawAnim(true)
					elseif action == 'store_saw' then
						SawAnim(false)
					end
				else
					ESX.ShowNotification(_U('no_vehicles_nearby'))
				end

			end, function(data2, menu2)
				menu2.close()
			end)
		elseif data.current.value == 'object_spawner' then
			ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'object', {
				title    = _U('traffic_interaction'),
				align    = Config.Align,
				elements = {
					{label = _U('cone'), model = 'prop_roadcone02b'},
					{label = _U('conelight'), model = 'prop_air_conelight'},
					{label = _U('barrier'), model = 'prop_barrier_work06a'},
					{label = _U('barrier'), model = 'prop_barrier_work06b'},
					{label = _U('med'), model = 'xm_prop_x17_bag_med_01a'},
					{label = _U('fireexh'), model = 'prop_air_fireexting'}
			}}, function(data2, menu2)
				local playerPed = PlayerPedId()
				local coords, forward = GetEntityCoords(playerPed), GetEntityForwardVector(playerPed)
				local objectCoords = (coords + forward * 1.0)

				ESX.Game.SpawnObject(data2.current.model, objectCoords, function(obj)
					SetEntityHeading(obj, GetEntityHeading(playerPed))
					PlaceObjectOnGroundProperly(obj)
				end)
			end, function(data2, menu2)
				menu2.close()
			end)
		end
	end, function(data, menu)
		menu.close()
	end)
end

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job

	Citizen.Wait(5000)
	TriggerServerEvent('esx_nafing_firejob:forceBlip')
end)

AddEventHandler('esx_nafing_firejob:hasEnteredMarker', function(station, part, partNum)
	if part == 'Cloakroom' then
		CurrentAction     = 'menu_cloakroom'
		CurrentActionMsg  = _U('open_cloackroom')
		CurrentActionData = {}
	elseif part == 'Vehicles' then
		CurrentAction     = 'menu_vehicle_spawner'
		CurrentActionMsg  = _U('garage_prompt')
		CurrentActionData = {station = station, part = part, partNum = partNum}
	elseif part == 'BossActions' then
		CurrentAction     = 'menu_boss_actions'
		CurrentActionMsg  = _U('open_bossmenu')
		CurrentActionData = {}
	end
end)

AddEventHandler('esx_nafing_firejob:hasExitedMarker', function(station, part, partNum)
	if not isInShopMenu then
		ESX.UI.Menu.CloseAll()
	end

	CurrentAction = nil
end)

AddEventHandler('esx_nafing_firejob:hasEnteredEntityZone', function(entity)
	local playerPed = PlayerPedId()

	if ESX.PlayerData.job and ESX.PlayerData.job.name == 'fire' and IsPedOnFoot(playerPed) then
		CurrentAction     = 'remove_entity'
		CurrentActionMsg  = _U('remove_prop')
		CurrentActionData = {entity = entity}
	end
end)

AddEventHandler('esx_nafing_firejob:hasExitedEntityZone', function(entity)
	if CurrentAction == 'remove_entity' then
		CurrentAction = nil
	end
end)

Citizen.CreateThread(function()
	for k,v in pairs(Config.FireStations) do
		local blip = AddBlipForCoord(v.Blip.Coords)

		SetBlipSprite (blip, v.Blip.Sprite)
		SetBlipDisplay(blip, v.Blip.Display)
		SetBlipScale  (blip, v.Blip.Scale)
		SetBlipColour (blip, v.Blip.Colour)
		SetBlipAsShortRange(blip, true)

		BeginTextCommandSetBlipName('STRING')
		AddTextComponentSubstringPlayerName(_U('map_blip'))
		EndTextCommandSetBlipName(blip)
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'fire' then
			local playerPed = PlayerPedId()
			local playerCoords = GetEntityCoords(playerPed)
			local isInMarker, hasExited, letSleep = false, false, true
			local currentStation, currentPart, currentPartNum

			for k,v in pairs(Config.FireStations) do
				for i=1, #v.Cloakrooms, 1 do
					local distance = #(playerCoords - v.Cloakrooms[i])

					if distance < Config.DrawDistance then
						DrawMarker(Config.MarkerType.Cloakrooms, v.Cloakrooms[i], 0.0, 0.0, 0.0, 0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
						letSleep = false

						if distance < Config.MarkerSize.x then
							isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Cloakroom', i
						end
					end
				end
				if playerInService then
					for i=1, #v.Vehicles, 1 do
						local distance = #(playerCoords - v.Vehicles[i].Spawner)

						if distance < Config.DrawDistance then
							DrawMarker(Config.MarkerType.Vehicles, v.Vehicles[i].Spawner, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
							letSleep = false

							if distance < Config.MarkerSize.x then
								isInMarker, currentStation, currentPart, currentPartNum = true, k, 'Vehicles', i
							end
						end
					end

					if ESX.PlayerData.job.grade_name == 'boss' then
						for i=1, #v.BossActions, 1 do
							local distance = #(playerCoords - v.BossActions[i])

							if distance < Config.DrawDistance then
								DrawMarker(Config.MarkerType.BossActions, v.BossActions[i], 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, Config.MarkerColor.r, Config.MarkerColor.g, Config.MarkerColor.b, 100, false, true, 2, true, false, false, false)
								letSleep = false

								if distance < Config.MarkerSize.x then
									isInMarker, currentStation, currentPart, currentPartNum = true, k, 'BossActions', i
								end
							end
						end
					end
				end
			end

			if isInMarker and not HasAlreadyEnteredMarker or (isInMarker and (LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum)) then
				if
					(LastStation and LastPart and LastPartNum) and
					(LastStation ~= currentStation or LastPart ~= currentPart or LastPartNum ~= currentPartNum)
				then
					TriggerEvent('esx_nafing_firejob:hasExitedMarker', LastStation, LastPart, LastPartNum)
					hasExited = true
				end

				HasAlreadyEnteredMarker = true
				LastStation             = currentStation
				LastPart                = currentPart
				LastPartNum             = currentPartNum

				TriggerEvent('esx_nafing_firejob:hasEnteredMarker', currentStation, currentPart, currentPartNum)
			end

			if not hasExited and not isInMarker and HasAlreadyEnteredMarker then
				HasAlreadyEnteredMarker = false
				TriggerEvent('esx_nafing_firejob:hasExitedMarker', LastStation, LastPart, LastPartNum)
			end

			if letSleep then
				Citizen.Wait(500)
			end
		else
			Citizen.Wait(500)
		end
	end
end)

Citizen.CreateThread(function()
	local trackedEntities = {
		'prop_roadcone02b',
		'prop_air_fireexting',
		'prop_air_conelight',
		'prop_barrier_work06a',
		'prop_barrier_work06b',
		'xm_prop_x17_bag_med_01a'
	}

	while true do
		Citizen.Wait(500)

		local playerPed = PlayerPedId()
		local playerCoords = GetEntityCoords(playerPed)

		local closestDistance = -1
		local closestEntity   = nil

		for i=1, #trackedEntities, 1 do
			local object = GetClosestObjectOfType(playerCoords, 3.0, GetHashKey(trackedEntities[i]), false, false, false)

			if DoesEntityExist(object) then
				local objCoords = GetEntityCoords(object)
				local distance = #(playerCoords - objCoords)

				if closestDistance == -1 or closestDistance > distance then
					closestDistance = distance
					closestEntity   = object
				end
			end
		end

		if closestDistance ~= -1 and closestDistance <= 3.0 then
			if LastEntity ~= closestEntity then
				TriggerEvent('esx_nafing_firejob:hasEnteredEntityZone', closestEntity)
				LastEntity = closestEntity
			end
		else
			if LastEntity then
				TriggerEvent('esx_nafing_firejob:hasExitedEntityZone', LastEntity)
				LastEntity = nil
			end
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)

		if CurrentAction then
			ESX.ShowHelpNotification(CurrentActionMsg)

			if IsControlJustReleased(0, 38) and ESX.PlayerData.job and ESX.PlayerData.job.name == 'fire' then

				if CurrentAction == 'menu_cloakroom' then
					OpenCloakroomMenu()
				elseif CurrentAction == 'menu_vehicle_spawner' then
					OpenVehicleSpawnerMenu('car', CurrentActionData.station, CurrentActionData.part, CurrentActionData.partNum)
				elseif CurrentAction == 'menu_boss_actions' then
					ESX.UI.Menu.CloseAll()
					TriggerEvent('esx_society:openBossMenu', 'fire', function(data, menu)
						menu.close()

						CurrentAction     = 'menu_boss_actions'
						CurrentActionMsg  = _U('open_bossmenu')
						CurrentActionData = {}
					end, { wash = false })
				elseif CurrentAction == 'remove_entity' then
					DeleteEntity(CurrentActionData.entity)
				end

				CurrentAction = nil
			end
		end

		if IsControlJustReleased(0, 167) and not isDead and ESX.PlayerData.job and ESX.PlayerData.job.name == 'fire' and not ESX.UI.Menu.IsOpen('default', GetCurrentResourceName(), 'fire_actions') and playerInService then
			OpenFireActionsMenu()
		end

		if IsControlJustReleased(0, 38) and currentTask.busy then
			ESX.ShowNotification(_U('impound_canceled'))
			ESX.ClearTimeout(currentTask.task)
			ClearPedTasks(PlayerPedId())

			currentTask.busy = false
		end
	end
end)

function createBlip(id)
	local ped = GetPlayerPed(id)
	local blip = GetBlipFromEntity(ped)

	if not DoesBlipExist(blip) then
		blip = AddBlipForEntity(ped)
		SetBlipSprite(blip, 1)
		ShowHeadingIndicatorOnBlip(blip, true)
		SetBlipRotation(blip, math.ceil(GetEntityHeading(ped)))
		SetBlipNameToPlayerName(blip, id)
		SetBlipScale(blip, 0.85)
		SetBlipAsShortRange(blip, true)

		table.insert(blipsFires, blip)
	end
end

RegisterNetEvent('esx_nafing_firejob:updateBlip')
AddEventHandler('esx_nafing_firejob:updateBlip', function()

	for k, existingBlip in pairs(blipsFires) do
		RemoveBlip(existingBlip)
	end

	blipsFires = {}

	if not playerInService then
		return
	end

	if not Config.EnableJobBlip then
		return
	end

	if ESX.PlayerData.job and ESX.PlayerData.job.name == 'fire' then
		ESX.TriggerServerCallback('esx_society:getOnlinePlayers', function(players)
			for i=1, #players, 1 do
				if players[i].job.name == 'fire' then
					local id = GetPlayerFromServerId(players[i].source)
					if NetworkIsPlayerActive(id) and GetPlayerPed(id) ~= PlayerPedId() then
						createBlip(id)
					end
				end
			end
		end)
	end
end)

AddEventHandler('playerSpawned', function(spawn)
	isDead = false

	if not hasAlreadyJoined then
		TriggerServerEvent('esx_nafing_firejob:spawned')
	end
	hasAlreadyJoined = true
end)

AddEventHandler('esx:onPlayerDeath', function(data)
	isDead = true
end)

function SawAnim(show)
	if show then
		if not useSaw then
			ESX.Streaming.RequestAnimDict('weapons@heavy@minigun', cb)
			local player = PlayerPedId()
			ad = 'weapons@heavy@minigun'
			anim = 'idle'
			TaskPlayAnim(player, ad, anim, 4.0, 1.0, -1, 49, 0, 0, 0, 0)
			local x,y,z = table.unpack(GetEntityCoords(player))
			prop = CreateObject(GetHashKey('prop_tool_consaw'), x, y, z+0.2, true, true, true)
			AttachEntityToEntity(prop, player, GetPedBoneIndex(player, 57005), 0.15, 0.02, -0.01, 105.0, 20.0, 215.0, true, true, false, true, 1, true)
			useSaw = true
		end
	else
		if useSaw then
			ESX.Game.DeleteObject(prop)
			ClearPedTasks(PlayerPedId())
			useSaw = false
		end
	end
end

RegisterNetEvent('esx_nafing_firejob:CutChainsaw')
AddEventHandler('esx_nafing_firejob:CutChainsaw', function()
    if useSaw then
        local playerPed		= PlayerPedId()
        local coords		= GetEntityCoords(playerPed)
        local closestDoor 	= GetClosestVehicleDoor(vehicle)
        
        if IsAnyVehicleNearPoint(coords.x, coords.y, coords.z, 5.0) then
            local vehicle
        end	
    
        if IsPedInAnyVehicle(playerPed, false) then
            vehicle = GetVehiclePedIsIn(playerPed, false)
        else
            vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 5.0, 0, 71)
        end
    
        if DoesEntityExist(vehicle) and IsPedOnFoot(playerPed) and closestDoor ~= nil then
			FreezeEntityPosition(playerPed, true)
			TaskPlayAnim(PlayerPedId(), 'weapons@heavy@minigun', 'fire_med', 4.0, 1.0, -1, 49, 0, 0, 0, 0)
            Citizen.CreateThread(function()
                ThreadID2 = GetIdOfThisThread()
                CurrentAction = 'useSaw'
                Citizen.Wait(10000)
                
                if CurrentAction ~= nil then
					SetVehicleDoorBroken(vehicle, closestDoor.doorIndex, false)
					TaskPlayAnim(PlayerPedId(), 'weapons@heavy@minigun', 'idle', 4.0, 1.0, -1, 49, 0, 0, 0, 0)
					FreezeEntityPosition(playerPed, false)
                    CurrentAction = nil
                    TerminateThisThread()
                end
            end)
        end
    end
end)

function GetClosestVehicleDoor(vehicle)
	local doorBones = {'door_dside_f', 'door_dside_r', 'door_pside_f', 'door_pside_r'}
	local doorIndex = {['door_dside_f'] = 0, ['door_dside_r'] = 2, ['door_pside_f'] = 1, ['door_pside_r'] = 3}
	local plyPed = GetPlayerPed(PlayerId())
	local plyPos = GetEntityCoords(plyPed, false)
	local minDistance = 1.0
	local closestDoor
	
	for a = 1, #doorBones do
		local bonePos = GetWorldPositionOfEntityBone(vehicle, GetEntityBoneIndexByName(vehicle, doorBones[a]))
		local distance = Vdist(plyPos.x, plyPos.y, plyPos.z, bonePos.x, bonePos.y, bonePos.z)

		if closestDoor == nil then
			if distance <= minDistance then
				closestDoor = {bone = doorBones[a], boneDist = distance, bonePos = bonePos, doorIndex = doorIndex[doorBones[a]]}
			end
		else
			if distance < closestDoor.boneDist then
				closestDoor = {bone = doorBones[a], boneDist = distance, bonePos = bonePos, doorIndex = doorIndex[doorBones[a]]}
			end
		end
	end

	return closestDoor
end
