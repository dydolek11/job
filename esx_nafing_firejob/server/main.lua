ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

TriggerEvent('esx_society:registerSociety', 'fire', 'fire', 'society_fire', 'society_fire', 'society_fire', {type = 'public'})

ESX.RegisterServerCallback('esx_nafing_firejob:buyJobVehicle', function(source, cb, vehicleProps, type)
	local xPlayer = ESX.GetPlayerFromId(source)
	local price = getPriceFromHash(vehicleProps.model, xPlayer.job.grade_name, type)

	if price == 0 then
		print(('esx_nafing_firejob: %s attempted to exploit the shop! (invalid vehicle model)'):format(xPlayer.identifier))
		cb(false)
	else
		if xPlayer.getMoney() >= price then
			xPlayer.removeMoney(price)

			MySQL.Async.execute('INSERT INTO owned_vehicles (owner, vehicle, plate, type, job, `stored`) VALUES (@owner, @vehicle, @plate, @type, @job, @stored)', {
				['@owner'] = xPlayer.identifier,
				['@vehicle'] = json.encode(vehicleProps),
				['@plate'] = vehicleProps.plate,
				['@type'] = type,
				['@job'] = xPlayer.job.name,
				['@stored'] = true
			}, function (rowsChanged)
				cb(true)
			end)
		else
			cb(false)
		end
	end
end)

ESX.RegisterServerCallback('esx_nafing_firejob:storeNearbyVehicle', function(source, cb, nearbyVehicles)
	local xPlayer = ESX.GetPlayerFromId(source)
	local foundPlate, foundNum

	for k,v in ipairs(nearbyVehicles) do
		local result = MySQL.Sync.fetchAll('SELECT plate FROM owned_vehicles WHERE owner = @owner AND plate = @plate AND job = @job', {
			['@owner'] = xPlayer.identifier,
			['@plate'] = v.plate,
			['@job'] = xPlayer.job.name
		})

		if result[1] then
			foundPlate, foundNum = result[1].plate, k
			break
		end
	end

	if not foundPlate then
		cb(false)
	else
		MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = true WHERE owner = @owner AND plate = @plate AND job = @job', {
			['@owner'] = xPlayer.identifier,
			['@plate'] = foundPlate,
			['@job'] = xPlayer.job.name
		}, function (rowsChanged)
			if rowsChanged == 0 then
				print(('esx_nafing_firejob: %s has exploited the garage!'):format(xPlayer.identifier))
				cb(false)
			else
				cb(true, foundNum)
			end
		end)
	end
end)

function getPriceFromHash(vehicleHash, jobGrade, type)
	local vehicles = Config.AuthorizedVehicles[type][jobGrade]

	for k,v in ipairs(vehicles) do
		if GetHashKey(v.model) == vehicleHash then
			return v.price
		end
	end

	return 0
end

AddEventHandler('playerDropped', function()
	local playerId = source

	if playerId then
		local xPlayer = ESX.GetPlayerFromId(playerId)

		if xPlayer and xPlayer.job.name == 'fire' then
			Citizen.Wait(5000)
			TriggerClientEvent('esx_nafing_firejob:updateBlip', -1)
		end
	end
end)

RegisterNetEvent('esx_nafing_firejob:spawned')
AddEventHandler('esx_nafing_firejob:spawned', function()
	local xPlayer = ESX.GetPlayerFromId(playerId)

	if xPlayer and xPlayer.job.name == 'fire' then
		Citizen.Wait(5000)
		TriggerClientEvent('esx_nafing_firejob:updateBlip', -1)
	end
end)

RegisterNetEvent('esx_nafing_firejob:forceBlip')
AddEventHandler('esx_nafing_firejob:forceBlip', function()
	TriggerClientEvent('esx_nafing_firejob:updateBlip', -1)
end)

AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		Citizen.Wait(5000)
		TriggerClientEvent('esx_nafing_firejob:updateBlip', -1)
	end
end)

RegisterServerEvent('esx_nafing_firejob:server:equip')
AddEventHandler('esx_nafing_firejob:server:equip', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    xPlayer.addWeapon('WEAPON_FLASHLIGHT', 1)
    xPlayer.addWeapon('WEAPON_FIREEXTINGUISHER', 1)
    xPlayer.addWeapon('WEAPON_CROWBAR', 1)
    xPlayer.addWeapon('WEAPON_HATCHET', 1)
end)