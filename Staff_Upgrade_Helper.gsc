#include maps/mp/zombies/_zm_utility;
#include common_scripts/utility;
#include maps/mp/_utility;
#include maps/mp/zm_tomb_craftables;
#include maps/mp/zombies/_zm_laststand;
#include maps/mp/gametypes_zm/_hud_util;
#include maps/mp/zm_tomb_teleporter;
#include maps/mp/zm_tomb_quest_fire;
#include maps/mp/zm_tomb_chamber;
#include maps/mp/zm_tomb_utility;
#include maps/mp/zm_tomb_quest_crypt;
#include maps/mp/zm_tomb_quest_air;

main(){
	replaceFunc(maps/mp/zm_tomb_quest_crypt::run_crypt_gem_pos, ::CUSTOM_run_crypt_gem_pos);
	level init_shaders();
	level element_enums();
	level thread fire_quest_notifications();
	level thread air_quest_notifications();
	level thread lightning_quest_notifications();
	level thread ice_quest_notifications();
	level thread init_teleporter_locations();
    level thread staff_player_loop();

	level thread command();
	level thread onplayerconnect();
}

command(){
	for(;;){
		level endon("end_game");
		for(;;){
			level waittill("say", message, player);
			message = toLower(message);
			if(message == "staffhelper"){
				player.activeHelper = abs(player.activeHelper - 1);
				level notify("helpertoggle", player);
			}
		}
	}
}

onplayerconnect(){
	for(;;){
		level waittill( "connecting", player );
		player.activeHelper = 1;
	}
}

init_shaders(){
	precacheshader( "zom_hud_craftable_element_fire" );
	precacheshader( "zom_hud_craftable_element_wind" );
	precacheshader( "zom_hud_craftable_element_lightning" );
	precacheshader( "zom_hud_craftable_element_water" );
}

init_teleporter_locations(){
	flag_wait("initial_blackscreen_passed");
	teleporter2 = array();
	exits = getstructarray( "trigger_teleport_pad", "targetname" );
	exits_keys = getFirstArrayKey( exits );
	while ( isDefined( exits_keys ) )
	{
		teleporter2[teleporter2.size] = exits[ exits_keys ];
		exits_keys = getNextArrayKey( exits, exits_keys );
	}
	level.teleporter = [];
	level.teleporter["fire"] = teleporter2[level.element_enum["fire"]].origin;
	level.teleporter_exit["fire"] = level.a_portal_exit_frames[teleporter2[level.element_enum["fire"]].script_int].origin;
	level.teleporter["air"] = teleporter2[level.element_enum["air"]].origin;
	level.teleporter_exit["air"] = level.a_portal_exit_frames[teleporter2[level.element_enum["air"]].script_int].origin;
	level.teleporter["lightning"] = teleporter2[level.element_enum["lightning"]].origin;
	level.teleporter_exit["lightning"] = level.a_portal_exit_frames[teleporter2[level.element_enum["lightning"]].script_int].origin;
	level.teleporter["ice"] = teleporter2[level.element_enum["ice"]].origin;
	level.teleporter_exit["ice"] = level.a_portal_exit_frames[teleporter2[level.element_enum["ice"]].script_int].origin;
}

element_enums(){
	level.element_enum = [];
	level.element_enum["fire"] = 3;
	level.element_enum["air"] = 2;
	level.element_enum["lightning"] = 1;
	level.element_enum["ice"] = 0;
}

staff_player_loop(){
	staff_array = array("fire", "air", "lightning", "ice");
	level.staff_players = [];
	for(i = 0; i < staff_array.size; i++){
		staff = staff_array[i];
		level.staff_players[staff] = spawnstruct();
	}
	while(1){
		wait 0.05;
		foreach(player in level.players){
			player.had_staff = 0;
		}
		for(i = 0; i < staff_array.size; i++){
            staff = staff_array[i];
			if(staff_array[i] == "ice"){
				staff = "water";
			}
            current_staff = staff_array[i];
			staff = "staff_" + staff + "_zm";
			anyone_has_staff = 0;
			foreach(player in level.players){
				if(player hasWeapon(staff) && !player.had_staff){
					player.had_staff = 1;
					anyone_has_staff = 1;
					tempplayer = level.staff_players[current_staff];
					level.staff_players[current_staff] = player;
					if(isdefined(tempplayer) && tempplayer != level.staff_players[current_staff]){
						level notify("staff_player_changed_" + staff, player);
					}
					break;
				}
			}
			if(anyone_has_staff == 0){
				tempplayer = level.staff_players[current_staff];
				level.staff_players[current_staff] = undefined;
				if(tempplayer != level.staff_players[current_staff]){
					level notify("staff_player_changed_" + staff, level.staff_players[current_staff]);
				}

			}
		}
	}
}

// QUEST MONITOR
fire_quest_notifications(){
	flag_wait("initial_blackscreen_passed");
	array_thread( level.sacrifice_volumes, ::fire_quest_1_monitor );

	flag_wait( "fire_puzzle_1_complete" );
	level notify("fire_puzzle_1_complete");
	level.fire_quest_1_hud1 CUSTOM_destroy();
	level.fire_quest_1_hud2 CUSTOM_destroy();
	level.fire_quest_1_hud1 structdelete();
	level.fire_quest_1_hud2 structdelete();
	
	level thread fire_quest_2_monitor();
	flag_wait( "fire_puzzle_2_complete" );
	level.fire_quest_2_hud1 CUSTOM_destroy();
	level.fire_quest_2_hud2 CUSTOM_destroy();
	array_thread(self.fire_torches_hud_array, ::CUSTOM_destroy);
	level.fire_quest_2_hud1 structdelete();
	level.fire_quest_2_hud2 structdelete();
	array_thread(self.fire_torches_hud_array, ::structdelete);
}

air_quest_notifications(){
	flag_wait("initial_blackscreen_passed");

	level thread air_quest_1_monitor();
	flag_wait( "air_puzzle_1_complete" );
	level notify("air_puzzle_1_complete");
	level.air_quest_1_hud1 CUSTOM_destroy();
	array_thread(level.ceiling_rings_hud_array, ::CUSTOM_destroy);
	level.ceiling_rings_text CUSTOM_destroy();
	level.air_quest_1_hud1 structdelete();
	array_thread(level.ceiling_rings_hud_array, ::structdelete);
	level.ceiling_rings_text structdelete();

	level thread air_quest_2_monitor();
	flag_wait( "air_puzzle_2_complete" );
	level.air_quest_2_hud1 CUSTOM_destroy();
	array_thread(level.smoke_ballz_hud_array, ::CUSTOM_destroy);
	level.smoke_ballz_text CUSTOM_destroy();
	level.air_quest_2_hud1 structdelete();
	array_thread(level.smoke_ballz_hud_array, ::structdelete);
	level.smoke_ballz_text structdelete();
}

lightning_quest_notifications(){
	flag_wait("initial_blackscreen_passed");

	level thread lightning_quest_1_monitor();
	flag_wait( "electric_puzzle_1_complete" );
	level.lightning_quest_1_hud1 CUSTOM_destroy();
	array_thread(level.piano_keys_hud_array, ::CUSTOM_destroy);
	level.piano_keys_text CUSTOM_destroy();
	level.lightning_quest_1_hud1 structdelete();
	array_thread(level.piano_keys_hud_array, ::structdelete);
	level.piano_keys_text structdelete();

	level thread lightning_quest_2_monitor();
	flag_wait( "electric_puzzle_2_complete" );
	level.lightning_quest_2_hud1 CUSTOM_destroy();
	array_thread(level.power_relays_hud_array, ::CUSTOM_destroy);
	level.power_relays_text CUSTOM_destroy();
	level.lightning_quest_2_hud1 structdelete();
	array_thread(level.power_relays_hud_array, ::structdelete);
	level.power_relays_text structdelete();
}

ice_quest_notifications(){
	flag_wait("initial_blackscreen_passed");

	level thread ice_quest_1_monitor();
	flag_wait( "ice_puzzle_1_complete" );
	level.ice_quest_1_hud1 CUSTOM_destroy();
	array_thread(level.ceiling_gem_hud_array, ::CUSTOM_destroy);
	level.ceiling_gem_text CUSTOM_destroy();
	level.ice_quest_1_hud1 structdelete();
	array_thread(level.ceiling_gem_hud_array, ::structdelete);
	level.ceiling_gem_text structdelete();

	level thread ice_quest_2_monitor();
	flag_wait( "ice_puzzle_2_complete" );
	level.ice_quest_2_hud1 CUSTOM_destroy();
	array_thread(level.ice_stones_hud_array, ::CUSTOM_destroy);
	level.ice_stones_text CUSTOM_destroy();
	level.ice_quest_2_hud1 structdelete();
	array_thread(level.ice_stones_hud_array, ::structdelete);
	level.ice_stones_text structdelete();
}

// GENERIC QUESTS
orb_shoot_monitor(str_targetname, element){
	self endon(str_targetname);
    levers_origin = get_lever_array(str_targetname, "origin");

	self.orb_shoot_hud1 = spawnstruct();
	self.disc_lever_hud1 = spawnstruct();
	self.disc_lever_hud2 = spawnstruct();
	self.disc_lever_hud3 = spawnstruct();
	self.disc_lever_hud4 = spawnstruct();
	self.disc_lever_text = spawnstruct();
	self.orb_shoot_hud2 = spawnstruct();

	self.disc_lever_hud_array = array(self.disc_lever_hud1, self.disc_lever_hud2, self.disc_lever_hud3, self.disc_lever_hud4);

	while(1){

		self.orb_shoot_hud1 CUSTOM_destroy();
		self.orb_shoot_hud2 CUSTOM_destroy();
		self.disc_lever_text CUSTOM_destroy();
		array_thread(self.disc_lever_hud_array, ::CUSTOM_destroy);
		wait 0.05;
		if(!isdefinedStaffPlayer(element)){
            while(!isdefinedStaffPlayer(element)){
                wait 0.05;
            }
			continue;
		}
		if(is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
			self.orb_shoot_hud1 create_waypoint(element, level.staff_players[element], level.teleporter_exit[element]);
			self.orb_shoot_hud1 createtext(element, level.staff_players[element], "Leave the Crazyplace");
			while(is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
				wait 0.05;
			}
			continue;
		} else {
			if(chamber_disc_gem_has_clearance( str_targetname ) && !is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
				self.orb_shoot_hud2 create_waypoint(element, level.staff_players[element], self.origin);
				self.orb_shoot_hud2 createtext(element, level.staff_players[element], "Shoot the Marked Orb");
				while(chamber_disc_gem_has_clearance( str_targetname ) && !is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
					wait 0.05;
				}
			} else {
                array_thread(self.disc_lever_hud_array, ::CUSTOM_destroy);
				self.disc_lever_text createtext(element, level.staff_players[element], "Rotate the Discs until they show the respective Lighting");
				last_invalid_levers = array();
				while(!chamber_disc_gem_has_clearance( str_targetname ) && !is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){ 
					invalid_levers = get_lever_array(str_targetname, "state");
					if(!same_array(invalid_levers, last_invalid_levers)){
						array_thread(self.disc_lever_hud_array, ::CUSTOM_destroy);
						for(i = 0; i < invalid_levers.size; i++){
							if(invalid_levers[i] == 1){
								self.disc_lever_hud_array[i] create_waypoint(element, level.staff_players[element], levers_origin[i]);
							} else {

							}
						}
						last_invalid_levers = invalid_levers;
					}
					wait 0.2;
				}
			}
			continue;
		}
	}
}

get_lever_array(str_targetname, type){
	levers_array = array();
	gem_position = chamber_disc_get_gem_position( str_targetname );
	discs =  getentarray( "crypt_puzzle_disc", "script_noteworthy" );
	discs_keys = getFirstArrayKey( discs );
    switch(type){
        case "origin":
            while ( isDefined( discs_keys ) )
	        {
                disc = discs[ discs_keys ];
                if ( !isDefined( disc.targetname ) || !isDefined( "crypt_puzzle_disc_main" ) && isDefined( disc.targetname ) && isDefined( "crypt_puzzle_disc_main" ) && disc.targetname == "crypt_puzzle_disc_main" )
                {

                }
                else
                {
                    lever = disc insert_lever_in_array();
                    levers_array[levers_array.size] = lever.origin;
                }
                discs_keys = getNextArrayKey( discs, discs_keys );
            }
            break;
        case "state":
            while ( isDefined( discs_keys ) )
	        {
				disc = discs[ discs_keys ];
                if ( !isDefined( disc.targetname ) || !isDefined( "crypt_puzzle_disc_main" ) && isDefined( disc.targetname ) && isDefined( "crypt_puzzle_disc_main" ) && disc.targetname == "crypt_puzzle_disc_main" )
                {

                }
				else
				{
					if ( isdefined(disc.position) && disc.position != gem_position )
					{
						levers_array[levers_array.size] = 1;
					} else {
						levers_array[levers_array.size] = 0;
					}
				}
				discs_keys = getNextArrayKey( discs, discs_keys );
            }
			levers_array2 = array();
			for(i = 1; i < levers_array.size; i++){// idk but here it just has 1 element more than the other case at index 0 for whatever reason
				levers_array2[levers_array2.size] = levers_array[i];
			}
			levers_array = levers_array2;
			break;
    }
    return levers_array;
}

insert_lever_in_array(){
	lever_array = array();
	levers = getentarray( self.target, "targetname" );
	levers_keys = getFirstArrayKey( levers );
	while ( isDefined( levers_keys ) )
	{
		lever_array[lever_array.size] = levers[levers_keys];
		levers_keys = getNextArrayKey( levers, levers_keys );
	}
	return lever_array[0];
}

orb_soul_box_monitor(staff, element){
	self endon("staff_inserted");

	self.orb_soul_box_hud1 = spawnstruct();
	self.orb_soul_box_hud2 = spawnstruct();

	while(1){
		self.orb_soul_box_hud1 CUSTOM_destroy();
		self.orb_soul_box_hud2 CUSTOM_destroy();
		wait 0.05;
		if(!isdefinedStaffPlayer(element)){
			while(isdefinedStaffPlayer(element)){
                wait 0.05;
            }
		}
		if(is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
			self.orb_soul_box_hud2 create_waypoint(element, level.staff_players[element], staff.origin);
			self.orb_soul_box_hud2 createtext(element, level.staff_players[element], "Place your Staff in the Marked Pillar and Kill Zombies in the Crazypalce to fill the Staff with Souls");
			while(is_point_in_chamber(level.staff_players[element].origin)  && isdefinedStaffPlayer(element) && staff.charger.is_inserted != 1){
				if(isdefined(staff.charger.is_inserted) && staff.charger.is_inserted == 1){
					self notify("staff_inserted");
				}
				wait 0.05;
			}
		} else {
			self.orb_soul_box_hud1 create_waypoint(element, level.staff_players[element], level.teleporter[element]);
			self.orb_soul_box_hud1 createtext(element, level.staff_players[element], "Enter the Crazyplace");
			while(!is_point_in_chamber(level.staff_players[element].origin)  && isdefinedStaffPlayer(element)){
				wait 0.05;
			}
		}
	}
}

CUSTOM_run_crypt_gem_pos(){
	str_weapon = undefined;
	complete_flag = undefined;
	str_orb_path = undefined;
	str_glow_fx = undefined;
	n_element = self.script_int;
	switch( self.targetname )
	{
		case "crypt_gem_air":
			str_weapon = "staff_air_zm";
			complete_flag = "staff_air_zm_upgrade_unlocked";
			str_orb_path = "air_orb_exit_path";
			str_final_pos = "air_orb_plinth_final";
			break;
		case "crypt_gem_ice":
			str_weapon = "staff_water_zm";
			complete_flag = "staff_water_zm_upgrade_unlocked";
			str_orb_path = "ice_orb_exit_path";
			str_final_pos = "ice_orb_plinth_final";
			break;
		case "crypt_gem_fire":
			str_weapon = "staff_fire_zm";
			complete_flag = "staff_fire_zm_upgrade_unlocked";
			str_orb_path = "fire_orb_exit_path";
			str_final_pos = "fire_orb_plinth_final";
			break;
		case "crypt_gem_elec":
			str_weapon = "staff_lightning_zm";
			complete_flag = "staff_lightning_zm_upgrade_unlocked";
			str_orb_path = "lightning_orb_exit_path";
			str_final_pos = "lightning_orb_plinth_final";
			break;
		default:
			return;
	}

	e_gem_model = puzzle_orb_chamber_to_crypt( str_orb_path, self );
	e_main_disc = getent( "crypt_puzzle_disc_main", "targetname" );
	e_gem_model linkto( e_main_disc );
	str_targetname = self.targetname;
	element = strTok(str_orb_path, "_")[0];
	e_gem_model thread orb_shoot_monitor(str_targetname, element);
	self delete();
	e_gem_model setcandamage( 1 );
	while ( 1 )
	{
		e_gem_model waittill( "damage", damage, attacker, direction_vec, point, mod, tagname, modelname, partname, weaponname );
		if ( weaponname == str_weapon )
		{
			break;
		}
		else
		{
		}
	}
	e_gem_model setclientfield( "element_glow_fx", n_element );
	e_gem_model playsound( "zmb_squest_crystal_charge" );
	e_gem_model playloopsound( "zmb_squest_crystal_charge_loop", 2 );
	while ( 1 )
	{
		if ( chamber_disc_gem_has_clearance( str_targetname ) )
		{
			break;
		}
		else level waittill( "crypt_disc_rotation" );
	}
	flag_set( "disc_rotation_active" );
	e_gem_model notify(str_targetname);
	level thread maps/mp/zombies/_zm_audio::sndmusicstingerevent( "side_sting_5" );
    //delete hud elements for disc step
	e_gem_model.orb_shoot_hud1 CUSTOM_destroy();
	e_gem_model.disc_lever_text CUSTOM_destroy();
	array_thread(e_gem_model.disc_lever_hud_array, ::CUSTOM_destroy);
	e_gem_model.orb_shoot_hud2 CUSTOM_destroy();
	e_gem_model.orb_shoot_hud1 structdelete();
	e_gem_model.disc_lever_text structdelete();
	array_thread(e_gem_model.disc_lever_hud_array, ::structdelete);
	sele_gem_modelf.orb_shoot_hud2 structdelete();

	light_discs_bottom_to_top();
	level thread puzzle_orb_pillar_show();
	e_gem_model unlink();
	s_ascent = getstruct( "orb_crypt_ascent_path", "targetname" );
	v_next_pos = ( e_gem_model.origin[ 0 ], e_gem_model.origin[ 1 ], s_ascent.origin[ 2 ] );
	e_gem_model setclientfield( "element_glow_fx", n_element );
	playfxontag( level._effect[ "puzzle_orb_trail" ], e_gem_model, "tag_origin" );
	e_gem_model playsound( "zmb_squest_crystal_leave" );
	e_gem_model puzzle_orb_move( v_next_pos );
	flag_clear( "disc_rotation_active" );
	level thread chamber_discs_randomize();
	e_gem_model puzzle_orb_follow_path( s_ascent );
	v_next_pos = ( e_gem_model.origin[ 0 ], e_gem_model.origin[ 1 ], e_gem_model.origin[ 2 ] + 2000 );
	e_gem_model puzzle_orb_move( v_next_pos );
	s_chamber_path = getstruct( str_orb_path, "targetname" );
	str_model = e_gem_model.model;
	e_gem_model delete();
	e_gem_model = puzzle_orb_follow_return_path( s_chamber_path, n_element );
	s_final = getstruct( str_final_pos, "targetname" );
	e_gem_model puzzle_orb_move( s_final.origin );
	e_new_gem = spawn( "script_model", s_final.origin );
	e_new_gem setmodel( e_gem_model.model );
	e_new_gem.script_int = n_element;
	e_new_gem setclientfield( "element_glow_fx", n_element );
	e_gem_model delete();
	e_new_gem playsound( "zmb_squest_crystal_arrive" );
	e_new_gem playloopsound( "zmb_squest_crystal_charge_loop", 0.1 );
	flag_set( complete_flag );
	for(i = 0; i < level.a_elemental_staffs.size; i++){
		if(level.a_elemental_staffs[i].element == strTok(str_weapon, "_")[1]){
			staff = level.a_elemental_staffs[i];
		}
	}
	e_new_gem thread orb_soul_box_monitor(staff, element);//Soulbox orb
	while(staff.charger.is_inserted != 1){
		wait 0.05;
	}
	e_new_gem notify("staff_inserted");
	e_new_gem.orb_soul_box_hud1 CUSTOM_destroy();
	e_new_gem.orb_soul_box_hud2 CUSTOM_destroy();
	e_new_gem.orb_soul_box_hud1 structdelete();
	e_new_gem.orb_soul_box_hud2 structdelete();
}

// FIRE QUESTS
fire_quest_1_monitor(){
	level endon("fire_puzzle_1_complete");
	element = "fire";
	area = level.sacrifice_volumes;
	area_keys = getFirstArrayKey( area );
	fire_staff_zone = area[area_keys];

	level.fire_quest_1_hud1 = spawnstruct();
	level.fire_quest_1_hud2 = spawnstruct();

	while(1){
		level.fire_quest_1_hud1 CUSTOM_destroy();
		level.fire_quest_1_hud2 CUSTOM_destroy();

		wait 0.05;
		if(!isdefinedStaffPlayer(element)){
			while(!isdefinedStaffPlayer(element)){
				wait 0.05;
			}
			continue;
		}
		if(is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
			if(level.craftables_crafted[ "elemental_staff_fire" ] != 1){
				level.craftables_crafted[ "elemental_staff_fire" ] = 1;
			}
			level.fire_quest_1_hud1 create_waypoint(element, level.staff_players[element], self.origin);
			level.fire_quest_1_hud1 createtext(element, level.staff_players[element], "Kill Zombies in the Burning Area, with the Staff of Fire");

			while(is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
				wait 0.05;
			}
			continue;
		}
		if(!is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
			level.fire_quest_1_hud2 create_waypoint(element, level.staff_players[element], level.teleporter["fire"]);
			level.fire_quest_1_hud2 createtext(element, level.staff_players[element], "Enter the Crazyplace");
			while(!is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
				wait 0.05;
			}
			continue;
		}
	}
}

fire_quest_2_monitor(){
	level endon("fire_puzzle_2_complete");
	element = "fire";
	level.torches = array();
	ternary = getentarray( "fire_torch_ternary", "script_noteworthy" );
	ternary_keys = getFirstArrayKey( ternary );
    while ( isDefined( ternary_keys ) )
	{
		e_target_torch = getstruct( ternary[ ternary_keys ].target, "targetname" );
		level.torches[level.torches.size] = e_target_torch.origin;
		ternary_keys = getNextArrayKey( ternary, ternary_keys );
	}
	level.fire_quest_2_hud1 = spawnstruct();
	level.fire_quest_2_hud2 = spawnstruct();
	level.fire_torches_hud1 = spawnstruct();
	level.fire_torches_hud2 = spawnstruct();
	level.fire_torches_hud3 = spawnstruct();
	level.fire_torches_hud4 = spawnstruct();
    
	level.fire_torches_hud_array = array(level.fire_torches_hud1, level.fire_torches_hud2, level.fire_torches_hud3, level.fire_torches_hud4);
	while(1){
		level.fire_quest_2_hud1 CUSTOM_destroy();
		level.fire_quest_2_hud2 CUSTOM_destroy();
		array_thread(level.fire_torches_hud_array, ::CUSTOM_destroy);
		wait 0.05;
		if(!isdefinedStaffPlayer(element)){
			while(!isdefinedStaffPlayer(element)){
                wait 0.05;
            }
			continue;
		}
		if(is_point_in_chamber(level.staff_players[element].origin) ){

			level.fire_quest_2_hud2 create_waypoint(element, level.staff_players[element], level.teleporter_exit["fire"]);
			level.fire_quest_2_hud2 createtext(element, level.staff_players[element], "Leave the Crazyplace");

			while(is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
				wait 0.05;
			}
		} else {
			if(distance((400, -2900, 0), level.staff_players[element].origin) <= 900 ){
				
				level.fire_torches_hud1 create_waypoint(element, level.staff_players[element], level.torches[0]);
				level.fire_torches_hud1 createtext(element, level.staff_players[element], "Light the Marked Torches with the Staff of Fire");
				level.fire_torches_hud2 create_waypoint(element, level.staff_players[element], level.torches[1]);
				level.fire_torches_hud3 create_waypoint(element, level.staff_players[element], level.torches[2]);
				level.fire_torches_hud4 create_waypoint(element, level.staff_players[element], level.torches[3]);

				while(distance((400, -2900, 0), level.staff_players[element].origin) <= 900 && !is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
					wait 0.05;
				}
			} else {
				
				level.fire_quest_2_hud1 create_waypoint(element, level.staff_players[element], (1032, -2200, 110));
				level.fire_quest_2_hud1 createtext(element, level.staff_players[element], "Go to the Church");

				while(!distance((400, -2900, 0), level.staff_players[element].origin) <= 900 && !is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
					wait 0.05;
				}
			}
			continue;
		}
	}
}

//AIR QUESTS
air_quest_1_monitor(){
	level endon("air_puzzle_1_complete");
	element = "air";
    rings_origins = get_ceiling_ring_array("origin");

	level.air_quest_1_hud1 = spawnstruct();
	level.ceiling_rings_hud1 = spawnstruct();
	level.ceiling_rings_hud2 = spawnstruct();
	level.ceiling_rings_hud3 = spawnstruct();
	level.ceiling_rings_hud4 = spawnstruct();
	level.ceiling_rings_text = spawnstruct();

	level.ceiling_rings_hud_array = array(level.ceiling_rings_hud1, level.ceiling_rings_hud2, level.ceiling_rings_hud3, level.ceiling_rings_hud4);
	while(1){
		level.air_quest_1_hud1 CUSTOM_destroy();
		array_thread(level.ceiling_rings_hud_array, ::CUSTOM_destroy);
		level.ceiling_rings_text CUSTOM_destroy();
		wait 0.05;
		if(!isdefinedStaffPlayer(element)){
            while(!isdefinedStaffPlayer(element)){
                wait 0.05;
            }
		}
		if(is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
			level.ceiling_rings_text createtext(element, level.staff_players[element], "Shoot the Marked Ceiling Rings in the Crazyplace, until the Symbols are in the correct Order");
			last_invalid_rings = array();
			while(is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
				invalid_rings = get_ceiling_ring_array("state");
				if(!same_array(invalid_rings, last_invalid_rings)){
					array_thread(level.ceiling_rings_hud_array, ::CUSTOM_destroy);
					for(i = 0; i < invalid_rings.size; i++){
						if(invalid_rings[i] == 1){
							level.ceiling_rings_hud_array[i] create_waypoint(element, level.staff_players[element], rings_origins[i] + (0, -90 + (i * -55), 400));
						} else {

						}
					}
					last_invalid_rings = invalid_rings;
				}
				wait 0.05;
			}
		} else {
			level.air_quest_1_hud1 create_waypoint(element, level.staff_players[element], level.teleporter["air"]);
			level.air_quest_1_hud1 createtext(element, level.staff_players[element], "Enter the Crazyplace");
			while(!is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
				wait 0.05;
			}
		}
	}
}

get_ceiling_ring_array(type){
	rings_array = array();
	rings = level.a_ceiling_rings;
	rings_keys = getFirstArrayKey( rings );
    switch(type){
        case "origin":
            while ( isDefined( rings_keys ) )
            {
                rings_array[rings_array.size] = rings[ rings_keys ].origin;
                rings_keys = getNextArrayKey( rings, rings_keys );
            }
            break;
        case "state":
            while ( isDefined( rings_keys ) )
            {
                if ( rings[ rings_keys ].script_int != rings[ rings_keys ].position )
                {
                    rings_array[rings_array.size] = 1;
                } else {
                    rings_array[rings_array.size] = 0;
                }
                rings_keys = getNextArrayKey( rings, rings_keys );
            }
            break;
    }
    true_rings_array = array(rings_array[3], rings_array[0], rings_array[1], rings_array[2]);// for some reason they arent ordered by their radius
	return true_rings_array;
}

air_quest_2_monitor(){
	element = "air";
	level endon("air_puzzle_2_complete");
    smoke_ballz_origins = get_smoke_ballz_array("origin");

	level.air_quest_2_hud1 = spawnstruct();
	level.smoke_ballz_hud1 = spawnstruct();
	level.smoke_ballz_hud2 = spawnstruct();
	level.smoke_ballz_hud3 = spawnstruct();
	level.smoke_ballz_text = spawnstruct();

	level.smoke_ballz_hud_array = array(level.smoke_ballz_hud1, level.smoke_ballz_hud2, level.smoke_ballz_hud3);
	while(1){
		level.air_quest_2_hud1 CUSTOM_destroy();
		array_thread(level.smoke_ballz_hud_array, ::CUSTOM_destroy);
		level.smoke_ballz_text CUSTOM_destroy();
		wait 0.05;
		if(!isdefinedStaffPlayer(element)){
			while(!isdefinedStaffPlayer(element)){
                wait 0.05;
            }
		}
		if(!is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
			level.smoke_ballz_text createtext(element, level.staff_players[element], "Shoot the Marked Smoking Spheres, until their Smoke points towards the Center of the Map");
			last_invalid_ballz = array();
			while(!is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
				invalid_ballz = get_smoke_ballz_array("state");
				if(!same_array(invalid_ballz, last_invalid_ballz)){
					array_thread(level.smoke_ballz_hud_array, ::CUSTOM_destroy);
					for(i = 0; i < invalid_ballz.size; i++){
						if(invalid_ballz[i] == 1){
							level.smoke_ballz_hud_array[i] create_waypoint(element, level.staff_players[element], smoke_ballz_origins[i]);
						} else {

						}
					}
					last_invalid_ballz = invalid_ballz;
				}
				wait 0.05;
			}
		} else {
			level.air_quest_2_hud1 create_waypoint(element, level.staff_players[element], level.teleporter_exit["air"]);
			level.air_quest_2_hud1 createtext(element, level.staff_players[element], "Leave the Crazyplace");
			while(is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
				wait 0.05;
			}
		}
	}
}

get_smoke_ballz_array(type){
	smoke_ballz_array = array();
	smoke_ballz = getstructarray( "puzzle_smoke_origin", "targetname" );
	smoke_ballz_keys = getFirstArrayKey( smoke_ballz );
    switch(type){
        case "origin":
            while ( isDefined( smoke_ballz_keys ) )
            {
                smoke_ballz_array[smoke_ballz_array.size] = smoke_ballz[ smoke_ballz_keys ].origin;
                smoke_ballz_keys = getNextArrayKey( smoke_ballz, smoke_ballz_keys );
            }
            break;
        case "state":
            while ( isDefined( smoke_ballz_keys ) )
            {
                if ( smoke_ballz[ smoke_ballz_keys ].solved )
                {
                    smoke_ballz_array[smoke_ballz_array.size] = 0;
                } else {
                    smoke_ballz_array[smoke_ballz_array.size] = 1;
                }
                smoke_ballz_keys = getNextArrayKey( smoke_ballz, smoke_ballz_keys );
            }
            break;
    }
	return smoke_ballz_array;
}

getstaffplayer(staff){
	if(staff == "ice"){
		staff = "water";
	}
	staff = "staff_" + staff + "_zm";
	foreach(player in level.players){
		if(player hasweapon(staff)){
			return player;
		}
	}
	return undefined;
}

//LIGHTNING QUESTS
lightning_quest_1_monitor(){
	level endon("electric_puzzle_1_complete");
	element = "lightning";
	level.chord_order = array( "a_minor", "e_minor", "d_minor" );
	level.chord_order_counter = 0;

	level.lightning_quest_1_hud1 = spawnstruct();
	level.piano_keys_hud1 = spawnstruct();
	level.piano_keys_hud2 = spawnstruct();
	level.piano_keys_hud3 = spawnstruct();
	level.piano_keys_hud4 = spawnstruct();
	level.piano_keys_hud5 = spawnstruct();
	level.piano_keys_hud6 = spawnstruct();
	level.piano_keys_hud7 = spawnstruct();
	level.piano_keys_hud8 = spawnstruct();
	level.piano_keys_hud9 = spawnstruct();
	level.piano_keys_hud10 = spawnstruct();
	level.piano_keys_hud11 = spawnstruct();
	level.piano_keys_hud12 = spawnstruct();
	level.piano_keys_text = spawnstruct();

	level.piano_keys_hud_array = array(level.piano_keys_hud1, level.piano_keys_hud2, level.piano_keys_hud3, level.piano_keys_hud4, level.piano_keys_hud5, level.piano_keys_hud6, level.piano_keys_hud7, level.piano_keys_hud8, level.piano_keys_hud9, level.piano_keys_hud10, level.piano_keys_hud11, level.piano_keys_hud12);
	for(i = 0; i < level.piano_keys_hud_array.size; i++){
		level.piano_keys_hud_array[i].height_offset = 0;
		level.piano_keys_hud_array[i].color = (0.5, 0, 0.5);
	}
	while(1){
		level.lightning_quest_1_hud1 CUSTOM_destroy();
		array_thread(level.piano_keys_hud_array, ::CUSTOM_destroy);
		level.piano_keys_text CUSTOM_destroy();
		wait 0.05;
		if(!isdefinedStaffPlayer(element)){
            while(!isdefinedStaffPlayer(element)){
                wait 0.05;
            }
		}
		if(is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
			level.piano_keys_text createtext(element, level.staff_players[element], "Shoot the Correct Notes");
			last_invalid_notes = array();
			while(is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
				invalid_notes = get_invalid_notes_origins();
				if(!same_array(invalid_notes, last_invalid_notes)){
					array_thread(level.piano_keys_hud_array, ::CUSTOM_destroy);
					if(invalid_notes.size == 0){
						level.chord_order_counter++;
						wait 4;
					} 
					for(i = 0; i < invalid_notes.size; i++){
						level.piano_keys_hud_array[i] create_waypoint(element, level.staff_players[element], invalid_notes[i]);
					}
					last_invalid_notes = invalid_notes;
				}
				wait 0.05;
			}
		} else {
			level.lightning_quest_1_hud1 create_waypoint(element, level.staff_players[element], level.teleporter["lightning"]);
			level.lightning_quest_1_hud1 createtext(element, level.staff_players[element], "Enter the Crazyplace");
			while(!is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
				wait 0.05;
			}
		}
	}
}

get_invalid_notes_origins(){
	if(!isdefined(level.chord_order)){
		level.chord_order = array( "a_minor", "e_minor", "d_minor" );
		level.chord_order_counter = 0;
	}
	notes = array();
	chord = getstruct( "piano_chord_" + level.chord_order[level.chord_order_counter], "script_noteworthy" );
	chord_keys = getFirstArrayKey( chord.notes );
	while ( isDefined( chord_keys ) )
	{
		requested_note = chord.notes[ chord_keys ];
		if(isdefined(level.a_piano_keys_playing) && isinarray(level.a_piano_keys_playing, requested_note)){
			next_chord_checker++;
		} else {
			requested_note_object = get_note_object(requested_note);
			notes[notes.size] = requested_note_object.origin;
		}
		chord_keys = getNextArrayKey( chord.notes, chord_keys );
	}
	return notes;
}

get_note_object(requested_note){
	piano = getstructarray( "piano_key", "script_noteworthy" );
	piano_keys = getFirstArrayKey( piano );
	while ( isDefined( piano_keys ) )
	{
		if(piano[piano_keys].script_string == requested_note){
			return piano[piano_keys];
		}
		piano_keys = getNextArrayKey( piano, piano_keys );
	}
	return undefined;
}

lightning_quest_2_monitor(){
	level endon("electric_puzzle_2_complete");
	element = "lightning";
	relays_origins = get_relays_array("origin");

	level.lightning_quest_2_hud1 = spawnstruct();
	level.power_relays_hud1 = spawnstruct();
	level.power_relays_hud2 = spawnstruct();
	level.power_relays_hud3 = spawnstruct();
	level.power_relays_hud4 = spawnstruct();
	level.power_relays_hud5 = spawnstruct();
	level.power_relays_hud6 = spawnstruct();
	level.power_relays_hud7 = spawnstruct();
	level.power_relays_hud8 = spawnstruct();
	level.power_relays_text = spawnstruct();

	level.power_relays_hud_array = array(level.power_relays_hud1, level.power_relays_hud2, level.power_relays_hud3, level.power_relays_hud4, level.power_relays_hud5, level.power_relays_hud6, level.power_relays_hud7, level.power_relays_hud8);
	for(i = 0; i < level.power_relays_hud_array.size; i++){
		level.power_relays_hud_array[i].height_offset = 0;
	}
	while(1){
		level.lightning_quest_2_hud1 CUSTOM_destroy();
		array_thread(level.power_relays_hud_array, ::CUSTOM_destroy);
		level.power_relays_text CUSTOM_destroy();
		wait 0.05;
		if(!isdefinedStaffPlayer(element)){
            while(!isdefinedStaffPlayer(element)){
                wait 0.05;
            }
		}
		if(!is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
			level.power_relays_text createtext(element, level.staff_players[element], "Flip the Marked Relay Switches until they have the Correct State");
			last_invalid_relays = array();
			while(!is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
				invalid_relays = get_relays_array("state");
				if(!same_array(invalid_relays, last_invalid_relays)){
					array_thread(level.power_relays_hud_array, ::CUSTOM_destroy);
					for(i = 0; i < invalid_relays.size; i++){
						if(invalid_relays[i] == 1){
							level.power_relays_hud_array[i] create_waypoint(element, level.staff_players[element], relays_origins[i]);
						} else {

						}
					}
					last_invalid_relays = invalid_relays;
				}
				wait 0.1;
			}
		} else {
			level.lightning_quest_2_hud1 create_waypoint(element, level.staff_players[element], level.teleporter_exit["lightning"]);
			level.lightning_quest_2_hud1 createtext(element, level.staff_players[element], "Leave the Crazyplace");
			while(is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
				wait 0.05;
			}
		}
	}
}

get_relays_array(type){
	relays = array();
	keys = getFirstArrayKey( level.electric_relays );
	switch(type){
		case "origin":
			while ( isDefined( keys ) )
			{
				relay = level.electric_relays[ keys ];
				relays[relays.size] = relay.e_switch.origin;
				keys = getNextArrayKey( level.electric_relays, keys );
			}
			break;
		case "state":
			while ( isDefined( keys ) )
			{
				relay = level.electric_relays[ keys ];
				if (isdefined(relay.connections[relay.position]) || relay == level.electric_relays[ "bunker" ]){
					relays[relays.size] = 0;
				} else {
					relays[relays.size] = 1;
				}
				keys = getNextArrayKey( level.electric_relays, keys );
			}
			break;
	}
	return relays;
}

//ICE QUESTS
ice_quest_1_monitor(){
	level endon("ice_puzzle_1_complete");
	element = "ice";
	ceiling_tiles_origins = get_ceiling_tiles("origin");

	level.ice_quest_1_hud1 = spawnstruct();
	level.ceiling_gem_hud1 = spawnstruct();
	level.ceiling_gem_hud2 = spawnstruct();
	level.ceiling_gem_hud3 = spawnstruct();
	level.ceiling_gem_hud4 = spawnstruct();
	level.ceiling_gem_hud5 = spawnstruct();
	level.ceiling_gem_hud6 = spawnstruct();
	level.ceiling_gem_text = spawnstruct();

	level.ceiling_gem_hud_array = array(level.ceiling_gem_hud1, level.ceiling_gem_hud2, level.ceiling_gem_hud3, level.ceiling_gem_hud4, level.ceiling_gem_hud5, level.ceiling_gem_hud6);
	while(1){
		level.ice_quest_1_hud1 CUSTOM_destroy();
		array_thread(level.ceiling_gem_hud_array, ::CUSTOM_destroy);
		level.ceiling_gem_text CUSTOM_destroy();
		wait 0.05;
		if(!isdefinedStaffPlayer(element)){
            while(!isdefinedStaffPlayer(element)){
                wait 0.05;
            }
		}
		if(is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
			level.ceiling_gem_text createtext(element, level.staff_players[element], "Shoot the Tiles in the Correct Order");
			last_invalid_tiles = array();
			while(is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
				invalid_tiles = get_ceiling_tiles("state");
				if(!same_array(invalid_tiles, last_invalid_tiles)){
					array_thread(level.ceiling_gem_hud_array, ::CUSTOM_destroy);
					for(i = 0; i < invalid_tiles.size; i++){
						if(invalid_tiles[i] == 1){
							level.ceiling_gem_hud_array[i] create_waypoint(element, level.staff_players[element], ceiling_tiles_origins[i]);
						} else {

						}
					}
					last_invalid_tiles = invalid_tiles;
				}
				wait 0.05;
			}
		} else {
			level.ice_quest_1_hud1 create_waypoint(element, level.staff_players[element], level.teleporter["ice"]);
			level.ice_quest_1_hud1 createtext(element, level.staff_players[element], "Enter the Crazyplace");
			while(!is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
				wait 0.05;
			}
		}
	}
}

get_ceiling_tiles(type){
	tile_array = array();
	ice_gem = getent( "ice_chamber_gem", "targetname" );
	ceiling_tile_brushes = getentarray( "ice_ceiling_tile", "script_noteworthy" );
	keys = getFirstArrayKey( ceiling_tile_brushes );
	switch(type){
		case "origin":
			while ( isDefined( keys ) )
			{
				tile = ceiling_tile_brushes[ keys ];
				tile_array[tile_array.size] = tile.origin;
				keys = getNextArrayKey( ceiling_tile_brushes, keys );
			}
			break;
		case "state":
			while ( isDefined( keys ) )
			{
				tile = ceiling_tile_brushes[ keys ];
				tile.value = int( tile.script_string );
				if(tile.value == ice_gem.value){
					tile_array[tile_array.size] = 1;
				} else {
					tile_array[tile_array.size] = 0;
				}
				keys = getNextArrayKey( ceiling_tile_brushes, keys );
			}
			break;

	}
	return tile_array;
}

ice_quest_2_monitor(){
	level endon("ice_puzzle_2_complete");
	element = "ice";

	level.ice_quest_2_hud1 = spawnstruct();
	level.ice_stones_hud1 = spawnstruct();
	level.ice_stones_hud2 = spawnstruct();
	level.ice_stones_hud3 = spawnstruct();
	level.ice_stones_text = spawnstruct();

	level.ice_stones_hud_array = array(level.ice_stones_hud1, level.ice_stones_hud2, level.ice_stones_hud3);
	while(1){
		level.ice_quest_2_hud1 CUSTOM_destroy();
		array_thread(level.ice_stones_hud_array, ::CUSTOM_destroy);
		level.ice_stones_text CUSTOM_destroy();
		wait 0.05;
		if(!isdefinedStaffPlayer(element)){
            while(!isdefinedStaffPlayer(element)){
                wait 0.05;
            }
		}
		if(!is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
			level.ice_stones_text createtext(element, level.staff_players[element], "Shoot the Marked Stones with Bullets, after you Froze them with the Staff of Ice");
			last_stone_count = undefined;
			while(!is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
				if(!isdefined(last_stone_count) || last_stone_count != level.ice_stones_remaining){
					stone_positions = get_existing_stones_array();
					array_thread(level.ice_stones_hud_array, ::CUSTOM_destroy);
					for(i = 0; i < stone_positions.size; i++){
						level.ice_stones_hud_array[i] create_waypoint(element, level.staff_players[element], stone_positions[i].origin);
					}
					last_stone_count = level.ice_stones_remaining;
				}
				wait 0.05;
			}
		} else {
			level.ice_quest_2_hud1 create_waypoint(element, level.staff_players[element], level.teleporter_exit["ice"]);
			level.ice_quest_2_hud1 createtext(element, level.staff_players[element], "Leave the Crazyplace");
			while(is_point_in_chamber(level.staff_players[element].origin) && isdefinedStaffPlayer(element)){
				wait 0.05;
			}
		}
	}
}

get_existing_stones_array(){
	stone_array = array();
	stone_positions = getstructarray( "puzzle_stone_water", "targetname" );
	keys = getFirstArrayKey( stone_positions );
	while ( isDefined( keys ) )
	{
		stone = stone_positions[ keys ];
		if(isdefined(stone.e_model)){
			stone_array[stone_array.size] = stone;
		}
		wait_network_frame();
		keys = getNextArrayKey( stone_positions, keys );
	}
	return stone_array;
}


//WAYPOINTS AND TEXTS
watch_player_staff_change_waypoint(element, player, origin){
	self notify("destroy");
	self endon("destroy");
	for(;;){
		level waittill("staff_player_changed_" + element, player);
		self.waypoint destroy();
		self.waypoint = setup_waypoint(player, origin);
	}
}

watch_player_staff_change_text(element, player, text){
	self notify("destroy");
	self endon("destroy");
	for(;;){
		level waittill("staff_player_changed_" + element, player);
		self.text destroy();
		self.text = setup_text(player, text);
	}
}

watch_player_staff_change_helper_state(player){
	self notify("destroy");
	self endon("destroy");
	for(;;){
		wait 0.05;
		if(player.activeHelper){
			self.alpha = 1;
		} else {
			self.alpha = 0;
		}
	}
}

create_waypoint(element, player, origin){
	if(isdefined(self.waypoint)){
		self.waypoint destroy();
	}
	hud = setup_waypoint(element, player, origin);
	self.waypoint = hud;
	self thread watch_player_staff_change_waypoint(element, player, origin);
}

setup_waypoint(element, player, origin){
	if(element == "ice"){
		element = "water";
	}
	if(element == "air"){
		element = "wind";
	}
	height_offset = 30;
	if(isdefined(self.height_offset)){
		height_offset = self.height_offset;
	}
	index = player.clientid;
	hudelem = newclienthudelem(player);
	hudelem.x = origin[ 0 ];
	hudelem.y = origin[ 1 ];
	hudelem.z = origin[ 2 ] + height_offset;
	hudelem.alpha = 1;
	hudelem.archived = 1;
	hudelem setshader( "zom_hud_craftable_element_" + element, 6, 6 );
	hudelem setwaypoint( 1 );
	if(isdefined(self.color)){
		hudelem.color = self.color;
	} else {
		if(element == "lightning"){
			hudelem.color = (1, 0.2, 0.72);
		}
	}
	hudelem.hidewheninmenu = 1;
	hudelem.hidewhendead = 1;
	hudelem thread watch_player_staff_change_helper_state(player);
	return hudelem;
}

createtext(element, player, text){
	if(isdefined(self.text)){
		self.text destroy();
	}
	self.text = setup_text(player, text);
	self thread watch_player_staff_change_text(element, player, text);
}

setup_text(player, text){
	hudelem = createfontstring( "objective", 1.3, player );
	hudelem setpoint("CENTER", "CENTER", 0, -230);
	hudelem settext(text);
	hudelem.hidewheninmenu = 1;
	hudelem.hidewhendead = 1;
	hudelem thread watch_player_staff_change_helper_state(player);
	return hudelem;
}

createfontstring( font, fontscale, player ){
	fontelem = newclienthudelem( player );
	fontelem.elemtype = "font";
	fontelem.font = font;
	fontelem.fontscale = fontscale;
	fontelem.x = 0;
	fontelem.y = 0;
	fontelem.width = 0;
	fontelem.height = int( level.fontheight * fontscale );
	fontelem.xoffset = 0;
	fontelem.yoffset = 0;
	fontelem.children = [];
	fontelem setparent( level.uiparent );
	fontelem.hidden = 0;
	fontelem.hidewheninmenu = 1;
	fontelem.hidewhendead = 1;
	return fontelem;
}

isdefinedStaffPlayer(element){
	if(level.staff_players[element] != undefined){
		return 1;
	}
	return 0;
}

same_array(array1, array2){
	if(!isdefined(array1) || !isdefined(array2)){
		return 0;
	}
	if(array1.size != array2.size){
		return 0;
	}
	for(i = 0; i < array1.size; i++){
		if(array1[i] != array2[i]){
			return 0;
		}
	}
	return 1;
}

CUSTOM_destroy(){
	if(isdefined(self.waypoint)){
		self.waypoint destroy();
	}
	if(isdefined(self.text)){
		self.text destroy();
	}
}
