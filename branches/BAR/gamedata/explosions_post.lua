-- BA does not use explosions_post, see alldefs_post.lua 
-- basically, DONT TOUCH this! 


-- see alldefs.lua for documentation
-- load the games _Post functions for defs, and find out if saving to custom params is wanted
VFS.Include("gamedata/alldefs_post.lua")
-- load functionality for saving to custom params
VFS.Include("gamedata/post_save_to_customparams.lua")

-- handle unitdefs and the weapons they contain
for name,ed in pairs(ExplosionDefs) do
  ExplosionDef_Post(name,ed)
  
  if SaveDefsToCustomParams then
      SaveDefToCustomParams("ExposionDefs", name, ed)    
  end
end