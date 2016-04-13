local lfs = love.filesystem

local function enu(folder, saveDir)
   local filesTable = lfs.getDirectoryItems(folder)
   if saveDir ~= "" and not lfs.isDirectory(saveDir) then lfs.createDirectory(saveDir) end
   
   for i,v in ipairs(filesTable) do
      local file = folder.."/"..v
      local saveFile = saveDir.."/"..v
      if saveDir == "" then saveFile = v end
      
      if lfs.isDirectory(file) then
         lfs.createDirectory(saveFile)
         enu(file, saveFile)
      else
         lfs.write(saveFile, tostring(lfs.read(file)))
      end
   end
end

function extractZIP(file, dir, delete)
   local dir = dir or ""
   local temp = tostring(math.random(1000, 2000))
   success = lfs.mount(file, temp)
      if success then enu(temp, dir) end
   lfs.unmount(file)
   if delete then lfs.remove(file) end
end
--Extractor by Davidobot @ love.2d forums. 

