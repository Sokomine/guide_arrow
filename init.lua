
-- TODO: stop if player is idle

minetest.register_entity( "guide_arrow:arrow", {
   hp_max = 1,
   physical = false,

   collisionbox = {-0.4, -1, -0.4, 0.4, 1, 0.4},
   visual = "cube", --"upright_sprite",
   visual_size = {x=1, y=2},
   textures = {"signsplus_wooden_arrow_right.png","default_mese.png","default_mese.png","default_mese.png","default_mese.png","default_mese.png"},
   makes_footstep_sound = true,

   target = nil,
   speed = nil,
   range = nil,
   range_y = nil,
   after = nil,
   after_param = nil,

   sum_dtime = 0;

   guide_owner = 0; -- player whose guide this is
   guide_owner_name = 0;
   has_sent_init_message = 0;

   on_step = function(self, dtime)
      -- it is enough to look about once per second if there is anything to do
      self.sum_dtime = self.sum_dtime + dtime;

      if( self.has_sent_init_message ~= 1 and self.guide_owner_name ~= nil ) then

         self.guide_owner      = minetest.env:get_player_by_name(self.guide_owner_name);
         self.dtime_sum        = 100; -- force guide to check positions

         if( self.guide_owner ~= nil ) then
            self.target = self.object:getpos(); -- has been created at the target position
            minetest.chat_send_player(self.guide_owner_name, "guide_arrow: Hello "..tostring(self.guide_owner_name)..". I am your guide. Please follow me to coordinates "..
                     tostring( math.floor(self.target.x ))..","..tostring( math.floor(self.target.y ))..","..tostring( math.floor(self.target.z ))..
                  ". If you loose sight of me, just wait until I reappear. You have to take care of the surrounding area on your own. "..
                  "If you want to get rid of me, just punch me once.");
            self.has_sent_init_message = 1;
         end
      end

      if( (self.guide_owner == nil or self.target == nil or self.guide_owner == 0)) then
         self.object:remove();
      else 
         if( self.sum_dtime > 1 and self.has_sent_init_message == 1 and self.guide_owner ~= nil and self.target ~= nil ) then

            --minetest.chat_send_player("singleplayer", "guide_arrow: on_step called after "..tostring( self.sum_dtime ));
            self.sum_dtime = 0;

            -- get the location of the player
            local pos = self.guide_owner:getpos();
            local my_pos = self.object:getpos();

            local dist_to_owner = ( (pos.x-my_pos.x)^2 + (pos.y-my_pos.y)^2 + (pos.z-my_pos.z)^2)^0.5; 

            -- if we got too far from the owner then beam back to him
            if( dist_to_owner > 10 ) then
               --minetest.chat_send_player(self.guide_owner_name, "guide_arrow: Please follow me.");
               --minetest.chat_send_player(name, "guide_arrow: ".." You are at position "..
               --         tostring( pos.x )..","..tostring( pos.y )..","..tostring( pos.z )..".");
   
               -- at which direction is the player looking? after all he ought to see the arrow
               local dir = self.guide_owner:get_look_dir(); -- getjaw() does not seem to work for players
      
               --minetest.chat_send_player(name, "guide_arrow: ".." You are looking in direction "..
               --         tostring( dir.x )..","..tostring( dir.y )..","..tostring( dir.z )..".");
      
      
               -- get a place 3 nodes directly in front of the placer
               local arrow_place_dist = 3;
               local arrow_place_pos  = {x=0, y=0, z=0};
               arrow_place_pos.x = ( pos.x + (dir.x * arrow_place_dist ));
               arrow_place_pos.y = ( pos.y+1 ); --+ (dir.y * arrow_place_dist ));
               arrow_place_pos.z = ( pos.z + (dir.z * arrow_place_dist ));
   
               --minetest.chat_send_player(name, "guide_arrow: ".." You are looking at point "..
               --         tostring( arrow_place_pos.x )..","..tostring( arrow_place_pos.y )..","..tostring( arrow_place_pos.z )..".");
      
               -- now we have to get a free node the arrow can appear at (inside a node would be impractical);
               -- but going too high doesn't help either
               local nt;
               local offset = 0;
               while(  (nt == nil or nt.name ~= "air") and (offset<3) ) do
                  arrow_place_pos.y = arrow_place_pos.y + offset;
                  nt =  minetest.env:get_node( arrow_place_pos );
                  offset = offset+1;
               end

               self.object:setpos( arrow_place_pos );

               --minetest.chat_send_player(name, "guide_arrow: ".." First node that is not air (or as high above as we go) "..
               --            tostring( arrow_place_pos.x )..","..tostring( arrow_place_pos.y )..","..tostring( arrow_place_pos.z )..".");
      
               -- rotate guide so that it "faces" a direction 90 degree from its target
   
               local diff = {x=self.target.x-arrow_place_pos.x, y=self.target.y-arrow_place_pos.y, z=self.target.z-arrow_place_pos.z};
   
               local yaw = math.atan(diff.z/diff.x); --+math.pi/2;
               if diff.z ~= 0 or diff.x > 0 then
                  yaw = yaw+math.pi;
               end
      
               self.object:setyaw( yaw ); 
               --minetest.chat_send_player(name, "guide_arrow: ".." Guide rotating to "..tostring( yaw ).." degree.");
                
               -- set speed
               local vec = {x=0, y=0, z=0};
               local amount = (diff.x^2+diff.y^2+diff.z^2)^0.5;
               local speed  = 3.0;
               vec.x = diff.x*speed/amount;
               vec.y = diff.y*speed/amount;
               vec.z = diff.z*speed/amount;
   
               self.object:setvelocity( vec ); 
               --minetest.chat_send_player(name, "guide_arrow: ".." Guide starting to move.");
            end


            -- have we reached the target?
            my_pos = self.object:getpos();
            local dist_to_target = ((self.target.x-my_pos.x)^2 + (self.target.y-my_pos.y)^2 + (self.target.z-my_pos.z)^2)^0.5;
            if( dist_to_target < 5 ) then
                 self.object:setvelocity( {x=0, y=0, z=0} );
                 minetest.chat_send_player(self.guide_owner_name, "guide_arrow: We have reached the target "..
                        tostring( math.floor(self.target.x ))..","..tostring( math.floor(self.target.y ))..","..tostring( math.floor(self.target.z ))..
                     ", "..tostring( self.guide_owner_name )..". Thank you for having followed me!");
                 self.object:remove();
            end
   
          end
      end
   end;

});




minetest.register_chatcommand("guide", {
   privs       = {interact=true},
   params      = "[on|off|<target position>]",
   description = "Show an arrow that guides you to your destination",
   func = function(name,  param)

      -- actually place the guiding arrow
      local target_pos = {x=100, y=15, z=120}; -- TODO: just a suitable testpos
--      local start_pos =  minetest.env:get_player_by_name(name):getpos();
      local arrow_entity = minetest.env:add_entity( target_pos, "guide_arrow:arrow");
      minetest.chat_send_player(name, "guide_arrow: ".." Guide placed.");

      -- initialize guide
      arrow_entity:get_luaentity().guide_owner_name = name;
--      arrow_entity:get_luaentity().target           = target_pos;

    end
});

