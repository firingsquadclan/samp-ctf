#include <a_samp>
#include <core>
#include <float>
#include <streamer>
#include <ysf>
#include <GPS>
#include <mapandreas>

main()
{
	print("\n----------------------------------");
	print("  TwisT3R's Capture the Flag\n");
	print("----------------------------------\n");
}

#define POWERUPAMOUNT 100
new Float:death_x, Float:death_y, Float:death_z;
new MapNode:nodeid, MapNode:nodeid2, MapNode:spawnnode;
new car[MAX_PLAYERS], chee[MAX_PLAYERS], bool:died[MAX_PLAYERS] = false, bool:captured[MAX_PLAYERS] = false, bool:debugmode = false;
new InvisibilityTimer[MAX_PLAYERS], AntiramTimer[MAX_PLAYERS];

/*{44.60, -2892.90, 2997.00, -768.00}, // Los Santos
{-2997.40, -1115.50, -1213.90, 1659.60}, // San Fierro
{869.40, 596.30, 2997.00, 2993.80} // Las Venturas*/

//new Float:mapminx = -2997.40, Float:mapminy = -1115.50, Float:mapmaxx = -1213.90, Float:mapmaxy = 1659.60; // SET MAP

enum PowerUPE {
	Pickup,
    Float:PUX,
    Float:PUY,
    Float:PUZ,
};

enum CheckpointE {
	Checkpoint,
    MapIcon,
    Float:CPX,
    Float:CPY,
    Float:CPZ,
};

enum FlagE {
	Flag,
    MapIcon,
    Float:FX,
    Float:FY,
    Float:FZ,
};

new powerups[POWERUPAMOUNT][PowerUPE];
new checkpoint[1][CheckpointE];
new flag[1][FlagE];

public OnPlayerConnect(playerid)
{
    SetPlayerColor(playerid, -1);
    
	new string[128];
    format(string, sizeof(string), "%s has joined the server.", pName(playerid));
    SendClientMessageToAll(-1, string);
    SendDeathMessage(INVALID_PLAYER_ID, playerid, 200);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	new string[128];
    switch(reason)
    {
        case 0: format(string, sizeof(string), "%s has left the server. (crashed)", pName(playerid));
        case 1: format(string, sizeof(string), "%s has left the server.", pName(playerid));
        case 2: format(string, sizeof(string), "%s has left the server. (kick / ban)", pName(playerid));
    }
    SendClientMessageToAll(-1, string);
    SendDeathMessage(INVALID_PLAYER_ID, playerid, 201);

	died[playerid] = false;
    DropFlagBehavior(playerid);
	DestroyVehicle(car[playerid]);
	return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    if(!strcmp(cmdtext, "/chee", true))
    {
        new Float:spawn_x, Float:spawn_y, Float:spawn_z, Float:spawn_a;
		GetPlayerPos(playerid, spawn_x, spawn_y, spawn_z);
		GetPlayerFacingAngle(playerid, spawn_a);
		chee[playerid] = AddStaticVehicle(415, spawn_x, spawn_y, spawn_z, spawn_a, 1, 1);
		PutPlayerInVehicle(playerid, chee[playerid], 0);
    	return 1;
    }
    if(!strcmp(cmdtext, "/jp", true))
    {
		SetPlayerSpecialAction(playerid, SPECIAL_ACTION_USEJETPACK);
    	return 1;
    }
    if(!strcmp(cmdtext, "/kill", true))
    {
		SetPlayerHealth(playerid, 0);
    	return 1;
    }
    if(!strcmp(cmdtext, "/grctf", true))
    {
		GenerateRandomCTF();
    	return 1;
    }
    if(!strcmp(cmdtext, "/nextround", true))
    {
        DestroyDynamicRaceCP(checkpoint[0][Checkpoint]);
        DestroyDynamicMapIcon(checkpoint[0][MapIcon]);
        DestroyDynamicPickup(flag[0][Flag]);
        DestroyDynamicMapIcon(flag[0][MapIcon]);
		GenerateCTFRound();
    	return 1;
    }
    if(!strcmp(cmdtext, "/spawn", true))
    {
		SpawnPlayer(playerid);
    	return 1;
    }
    if(!strcmp(cmdtext, "/dropflag", true))
    {
		DropFlagBehavior(playerid);
    	return 1;
    }
    if(!strcmp(cmdtext, "/captureflag", true))
    {
		FlagPickupBehavior(playerid);
    	return 1;
    }
    if(!strcmp(cmdtext, "/escortflag", true))
    {
		CapturedBehavior(playerid);
    	return 1;
    }
    if(!strcmp(cmdtext, "/debugmode", true))
    {
		if (debugmode) debugmode = false;
		else debugmode = true;
		return 1;
    }
    if(!strcmp(cmdtext, "/powerup", true))
    {
        new putype = random(6);
    	PowerUpPickUp(playerid, putype);
		return 1;
    }
	return 0;
}

public OnPlayerSpawn(playerid)
{
	new string[256];
	new Float:distflag;
    new Float:spawn_x, Float:spawn_y, Float:spawn_z, Float:spawn_a;
    if (!died[playerid])
    {
        SpawnPoint:
        RandPosInArea(869.40, 596.30, 2997.00, 2993.80, spawn_x, spawn_y);
        MapAndreas_FindZ_For2DCoord(spawn_x, spawn_y, spawn_z);
        GetClosestMapNodeToPoint(spawn_x, spawn_y, spawn_z, spawnnode);
        GetMapNodePos(spawnnode, spawn_x, spawn_y, spawn_z);
        GetMapNodeAngleFromPoint(nodeid2, spawn_x, spawn_y, spawn_a);
        GetDistanceBetweenMapNodes(nodeid, spawnnode, distflag);
        spawn_a = spawn_a+90;
        if (distflag >= 500.0)
        {
            if (debugmode) SendClientMessage(playerid, -1, "Spawn position is too far, finding a new position.");
            goto SpawnPoint;
        }
        else
        {
            DestroyVehicle(car[playerid]);
            SetPlayerPos(playerid, spawn_x, spawn_y, spawn_z+1);
            car[playerid] = AddStaticVehicle(415, spawn_x, spawn_y, spawn_z+1, spawn_a, 1, 1);
            PutPlayerInVehicle(playerid, car[playerid], 0);
        }
    }
    else
    {
        died[playerid] = false;
        DestroyVehicle(car[playerid]);
        GetClosestMapNodeToPoint(death_x, death_y, death_z, spawnnode);
        GetMapNodePos(spawnnode, spawn_x, spawn_y, spawn_z);
        GetMapNodeAngleFromPoint(nodeid2, spawn_x, spawn_y, spawn_a);
        spawn_a = spawn_a+90;
        SetPlayerPos(playerid, spawn_x, spawn_y, spawn_z+1);
        car[playerid] = AddStaticVehicle(415, spawn_x, spawn_y, spawn_z+1, spawn_a, 1, 1);
        PutPlayerInVehicle(playerid, car[playerid], 0);

    }
	format(string, sizeof(string), "Spawn distance from CP: %f, X: %f, Y: %f, Z: %f, A: %f", distflag, spawn_x, spawn_y, spawn_z+1, spawn_a);
	if (debugmode) SendClientMessage(playerid, -1, string);
	return 1;
}

public OnPlayerDeath(playerid, killerid, reason)
{
    died[playerid] = true;
    GetPlayerPos(playerid, death_x, death_y, death_z);
    DestroyVehicle(car[playerid]);
    if (captured[playerid]) DropFlagBehavior(playerid);
    SendDeathMessage(INVALID_PLAYER_ID, playerid, reason);
   	return 1;
}

public OnVehicleDeath(vehicleid, killerid)
{
    return 1;
}

public OnPlayerRequestClass(playerid, classid)
{
	SpawnPlayer(playerid);
	return 1;
}

public OnPlayerPickUpDynamicPickup(playerid, pickupid)
{
	new Float:carhp;
	GetVehicleHealth(car[playerid], carhp);
	
	if (pickupid == flag[0][Flag] && carhp >= 300) return FlagPickupBehavior(playerid);
	
	new putype = random(6);
	new putype2 = random(2);
	if (putype == 0 && carhp >= 1000) putype++;
	if (putype == 1)
	{
 		if (carhp == 2000) putype = putype2 + 1;
 		if (carhp < 1000) putype--;
	}
	if (putype == 4 && GetVehicleComponentInSlot(car[playerid], CARMODTYPE_HYDRAULICS) == 1087) putype = putype+1;
	
	for (new i = 0; i < POWERUPAMOUNT; i++) { if (pickupid == powerups[i][Pickup]) PowerUpPickUp(playerid, putype); }
	return 1;
}

public OnPlayerEnterDynamicRaceCP(playerid, checkpointid)
{
    if (checkpointid == checkpoint[0][Checkpoint]) return CapturedBehavior(playerid);
	else return 0;
}

public OnPlayerExitVehicle(playerid, vehicleid)
{
	SetPlayerHealth(playerid, 0);
    SendClientMessage(playerid, -1, "Don't leave the car nigga");
    return 1;
}

public OnVehicleDamageStatusUpdate(vehicleid, playerid)
{
    new Float:carhp;
	GetVehicleHealth(car[playerid], carhp);
	if (carhp >= 300)
	{
		new panels, doors, lights, tires;
	    GetVehicleDamageStatus(vehicleid, panels, doors, lights, tires);
	    panels = doors = lights = tires = 0;
	    UpdateVehicleDamageStatus(vehicleid, panels, doors, lights, tires);
    }
    if (captured[playerid]) DropFlagBehavior(playerid);
    return 1;
}

public OnGameModeInit()
{
	SetGameModeText("Capture the Flag");
	ShowPlayerMarkers(1);
	ShowNameTags(1);
	DisableInteriorEnterExits();

	AddPlayerClass(0,1958.3783,1343.1572,15.3746,270.1425,0,0,0,0,-1,-1);

	GenerateRandomCTF();
    GenerateCTFRound();
	return 1;
}

stock Float:PointDistanceToPoint(Float:x, Float:y, Float:z, Float:_x, Float:_y, Float:_z)
{
    return floatsqroot(((x - _x) * (x - _x)) + ((y - _y) * (y - _y)) + ((z - _z) * (z - _z)));
}

stock GenerateRandomCTF()
{
    new string[256];
 	new MapNode:nodes[POWERUPAMOUNT];
    new db = 0;
    
    //Generate powerups
    for (new i = 0; i < POWERUPAMOUNT; i++)
    {
        Repeat:
        RandPosInArea(869.40, 596.30, 2997.00, 2993.80, powerups[i][PUX], powerups[i][PUY]);
        MapAndreas_FindZ_For2DCoord(powerups[i][PUX], powerups[i][PUY], powerups[i][PUZ]);
        new Float:dist;
        new bool:fail = false;
        for (new j = 0; j < POWERUPAMOUNT; j++)
        {
            if(IsValidMapNode(nodes[j]))
            {
                new MapNode:tempnode;
                GetClosestMapNodeToPoint(powerups[i][PUX], powerups[i][PUY], powerups[i][PUZ], tempnode);
                GetMapNodeDistanceFromPoint(nodes[j], powerups[i][PUX], powerups[i][PUY], powerups[i][PUZ], dist);

                if(IsValidMapNode(tempnode))
                {
                    GetDistanceBetweenMapNodes(tempnode, nodes[j], dist);
                }
                if(dist <= 150.0)
                {
                    fail = true;
                    break;
                }
            }
        }
        if(!fail)
        {
            if(IsValidMapNode(nodes[i]))
            {
                GetClosestMapNodeToPoint(powerups[i][PUX], powerups[i][PUY], powerups[i][PUZ], nodes[i]);
                GetMapNodePos(nodes[i], powerups[i][PUX], powerups[i][PUY], powerups[i][PUZ]);
                powerups[i][Pickup] = CreateDynamicPickup(1240, 14, powerups[i][PUX], powerups[i][PUY], powerups[i][PUZ]+1);
                //CreateDynamicMapIcon(powerups[i][PUX], powerups[i][PUY], powerups[i][PUZ]+1, 21, -1, -1, -1, -1, 6000, MAPICON_GLOBAL);
                db++;
				printf("Number: %d, Distance: %f, X: %f, Y: %f, Z: %f", db, dist, powerups[i][PUX], powerups[i][PUY], powerups[i][PUZ]+1);
            }
        }
        else goto Repeat;
    }
	//SUM
	format(string,sizeof(string),"%d map nodes generated according to the data.", db);
	SendClientMessageToAll(-1, string);
	printf(string);
}

stock GenerateCTFRound()
{
	//Generate checkpoint
	RandPosInArea(869.40, 596.30, 2997.00, 2993.80, checkpoint[0][CPX], checkpoint[0][CPY]);
	MapAndreas_FindZ_For2DCoord(checkpoint[0][CPX], checkpoint[0][CPY], checkpoint[0][CPZ]);
    GetClosestMapNodeToPoint(checkpoint[0][CPX], checkpoint[0][CPY], checkpoint[0][CPZ], nodeid);
    GetMapNodePos(nodeid, checkpoint[0][CPX], checkpoint[0][CPY], checkpoint[0][CPZ]);
    checkpoint[0][Checkpoint] = CreateDynamicRaceCP(1, checkpoint[0][CPX], checkpoint[0][CPY], checkpoint[0][CPZ], checkpoint[0][CPX], checkpoint[0][CPY], checkpoint[0][CPZ], 10, -1, -1, -1, 6000);
	checkpoint[0][MapIcon] = CreateDynamicMapIcon(checkpoint[0][CPX], checkpoint[0][CPY], checkpoint[0][CPZ], 53, -1, -1, -1, -1, 6000, MAPICON_GLOBAL);

	//Generate flag
	new Float:distflag;
	FlagGenerate:
    RandPosInArea(869.40, 596.30, 2997.00, 2993.80, flag[0][FX], flag[0][FY]);
	MapAndreas_FindZ_For2DCoord(flag[0][FX], flag[0][FY], flag[0][FZ]);
    GetClosestMapNodeToPoint(flag[0][FX], flag[0][FY], flag[0][FZ], nodeid2);
    GetMapNodePos(nodeid2, flag[0][FX], flag[0][FY], flag[0][FZ]);
    GetDistanceBetweenMapNodes(nodeid, nodeid2, distflag);
    if (distflag <= 1500.0) goto FlagGenerate;
    else
	{
	    flag[0][Flag] = CreateDynamicPickup(19306 , 14, flag[0][FX], flag[0][FY], flag[0][FZ]+1);
		flag[0][MapIcon] = CreateDynamicMapIcon(flag[0][FX], flag[0][FY], flag[0][FZ]+1, 19, -1, -1, -1, -1, 6000, MAPICON_GLOBAL);
	}
	printf("Flag distance from CP: %f, X: %f, Y: %f, Z: %f", distflag, flag[0][FX], flag[0][FY], flag[0][FZ]+1);
	return 1;
}

Float:frandom(Float:max, Float:min = 0.0, dp = 4)
{
    new
        // Get the multiplication for storing fractional parts.
        Float:mul = floatpower(10.0, dp),
        // Get the max and min as integers, with extra dp.
        imin = floatround(min * mul),
        imax = floatround(max * mul);
    // Get a random int between two bounds and convert it to a float.
    return float(random(imax - imin) + imin) / mul;
}

stock RandPosInArea(Float:minx, Float:miny, Float:maxx, Float:maxy, &Float:fDestX, &Float:fDestY)
{
	fDestX = frandom(maxx, minx);
    fDestY = frandom(maxy, miny);
	//SendClientMessageToAllEx(-1, "%f %f %f", fDestX, fDestY, fRadius);
	//printf("%f %f", fDestX, fDestY);
}

stock pName(playerid)
{
	new name[MAX_PLAYER_NAME + 1];
    GetPlayerName(playerid, name, sizeof(name));
    return name;
}

stock FlagPickupBehavior(playerid)
{
	if (!captured[playerid])
	{
		captured[playerid] = true;
		DestroyDynamicMapIcon(flag[0][MapIcon]);
	    DestroyDynamicPickup(flag[0][Flag]);
		ChangeVehicleColor(car[playerid], 3, 3);
	    SetPlayerColor(playerid, 0xFF0000FF);
	    new string[128];
		format(string,sizeof(string),"%s captured the flag.", pName(playerid));
		SendClientMessageToAll(-1, string);
	}
	return 1;
}

stock DropFlagBehavior(playerid)
{
	if (captured[playerid])
	{
		captured[playerid] = false;
	    GetPlayerPos(playerid, flag[0][FX], flag[0][FY], flag[0][FZ]);
		MapAndreas_FindZ_For2DCoord(flag[0][FX], flag[0][FY], flag[0][FZ]);
	    GetClosestMapNodeToPoint(flag[0][FX], flag[0][FY], flag[0][FZ], nodeid2);
	    GetMapNodePos(nodeid2, flag[0][FX], flag[0][FY], flag[0][FZ]);
		flag[0][Flag] = CreateDynamicPickup(19306, 14, flag[0][FX], flag[0][FY], flag[0][FZ]+1);
		flag[0][MapIcon] = CreateDynamicMapIcon(flag[0][FX], flag[0][FY], flag[0][FZ]+1, 19, -1, -1, -1, -1, 6000, MAPICON_GLOBAL);
	    SetPlayerColor(playerid, -1);
		ChangeVehicleColor(car[playerid], 1, 1);
		new string[128];
		format(string,sizeof(string),"%s dropped the flag.", pName(playerid));
		SendClientMessageToAll(-1, string);
	    format(string, sizeof(string), "Position of the dropped flag: X: %f, Y: %f, Z: %f", flag[0][FX], flag[0][FY], flag[0][FZ]+1);
		if (debugmode) SendClientMessage(playerid, -1, string);
	}
	return 1;
}

stock CapturedBehavior(playerid)
{
	if (captured[playerid])
	{
	    captured[playerid] = false;
		DestroyDynamicMapIcon(checkpoint[0][MapIcon]);
	    DestroyDynamicRaceCP(checkpoint[0][Checkpoint]);
	    ChangeVehicleColor(car[playerid], 1, 1);
	    SetPlayerColor(playerid, -1);
	    SetPlayerScore(playerid, GetPlayerScore(playerid) + 1);
	    new string[128];
		format(string,sizeof(string),"%s escorted the flag. (+1 score)", pName(playerid));
		SendClientMessageToAll(-1, string);
		return GenerateCTFRound();
	}
	else return 0;
}

stock PowerUpPickUp(playerid, type)
{
	switch(type)
	{
		case 0: SetVehicleHealth(car[playerid], 1000);
		case 1: SetVehicleHealth(car[playerid], 2000);
		case 2:
		{
		    KillTimer(InvisibilityTimer[playerid]);
  			InvisibilityTimer[playerid] = SetTimerEx("RemoveInvisibility", 15000, false, "i", playerid);
			LinkVehicleToInterior(car[playerid], 1);
		}
		case 3: AddVehicleComponent(car[playerid], 1008);
		case 4: AddVehicleComponent(car[playerid], 1087);
		case 5:
		{
  			KillTimer(AntiramTimer[playerid]);
  			AntiramTimer[playerid] = SetTimerEx("RemoveAntiram", 15000, false, "i", playerid);
			DisableRemoteVehicleCollisions(playerid, 1);
		}
	}
	PowerUpMessage(playerid, type);
	return 1;
}

stock PowerUpMessage(playerid, pumsg)
{
	new pumsgs[20];
	switch(pumsg)
	{
	    case 0: format(pumsgs,sizeof(pumsgs),"health");
	    case 1: format(pumsgs,sizeof(pumsgs),"armour");
	    case 2: format(pumsgs,sizeof(pumsgs),"invisibility");
	    case 3: format(pumsgs,sizeof(pumsgs),"nitrous");
        case 4: format(pumsgs,sizeof(pumsgs),"hydraulics");
        case 5: format(pumsgs,sizeof(pumsgs),"antiram");
	}
    new string[128];
	format(string,sizeof(string),"%s used a PowerUp. (%s)", pName(playerid), pumsgs);
	SendClientMessageToAll(-1, string);
}
forward RemoveInvisibility(playerid);
public RemoveInvisibility(playerid)
{
    LinkVehicleToInterior(car[playerid], 0);
}

forward RemoveAntiram(playerid);
public RemoveAntiram(playerid)
{
    DisableRemoteVehicleCollisions(playerid, 0);
}
