-- Local-only composition root. Game-facing compatibility modules retain their provenance.
local source=debug.getinfo(1,'S').source:gsub('^@',''):gsub('\\','/')
local root=assert(source:match('^(.*)/Scripts/[^/]+$'))..'/'
-- Stale panel flags must not cause the input worker to free/click the mouse.
os.remove(root..'pads_watch.txt');os.remove(root..'pads_want.txt')
os.remove(root..'local_base_status.txt')
local function load(name)return dofile(root..'Scripts/'..name..'.lua')end
local api=load('engine_bridge')()
api.modDir=function()return root end;api.modRoot=api.modDir
api.trace={on=function()return false end}
-- No online coordinator: the retained adapter's optional network branches stay off.
api.coop=nil
api.panel={open=false,start=function()end}
api.lifecycle=load('local_lifecycle')()
RegisterLoadMapPreHook(function()api.lifecycle.leave()end)
RegisterLoadMapPostHook(function()api.lifecycle.enter()end)
api.lang=load('lang')(root..'Scripts/');api.lang.set('Chinese')
api.game=load('pbz')(api)
api.status=load('status')(api);api.hud=load('hud')(api)
api.localfour=load('localfour')(api)
local config={}
local f=io.open(root..'PhantomPact.ini','rb')
if f then for line in f:lines()do local k,v=line:match('^%s*([%w_]+)%s*=%s*(.-)%s*$');if k then config[k:lower()]=v end end;f:close()end
-- 1.7.3 loads these local helpers even with networking disabled. Preserve their
-- original implementation and config semantics; they do not control map layout.
api.freetravel=load('freetravel')(api)
api.freetravel.on=(config.freebelltravel or 'on'):lower()~='off'
api.prologue=load('prologue')(api)
local count=tonumber(config.localplayers)or 1
local mode=config.localinput or 'four_pads'
local requested=(config.role or 'off'):lower()=='local' and count>=2 and count<=4 and count%1==0
if mode~='four_pads' and mode~='keyboard_three_pads'then requested=false;api.log('Invalid input mode; multiplayer refused')end
-- Publish the single-player choice only for this launch. The native worker
-- supplies a new per-process token, so stale multiplayer/previous-run files
-- cannot activate this filter. Never start localfour or alter the main pawn.
if not requested then
 local chosen=nil
 LoopInGameThreadWithDelay(250,function()
  local ready=io.open(root..'single_input_ready.txt','rb')
  local text=ready and ready:read(160)or '';if ready then ready:close()end
  local token=text:match('^PBZSINGLE1 ([%d]+%-[%d]+)%s*$')
  if not token then return false end
  if chosen==nil then
   local binds=io.open(root..'four_bindings.txt','rb')
   local first=binds and binds:read('*l')or '';if binds then binds:close()end
   local device=tonumber(first)
   if device and device>=0 and device<=4 and device%1==0 then chosen=device end
  end
  if chosen~=nil then
   local out=io.open(root..'single_input_request.txt','wb')
   if out then out:write('PBZSINGLE1 '..token..' '..chosen..'\n');out:close()end
  end
  return false
 end)
end
-- Consume the launch choice, preserving personal configuration and single-player default.
if requested then
 local file=assert(io.open(root..'PhantomPact.ini','rb'));local ini=file:read('a');file:close()
 ini=ini:gsub('([^\r\n]+)',function(line)
  local key=line:match('^%s*([%w_]+)%s*=')
  if key and key:lower()=='role' then return 'Role = Off' end
  if key and key:lower()=='localplayers' then return 'LocalPlayers = 1' end
  return line
 end)
 file=assert(io.open(root..'PhantomPact.ini','wb'));file:write(ini);file:close()
end
-- UE4SS/MSVC may print table addresses with uppercase hex; the native protocol is lowercase.
local nonce=(string.format('%x',os.time())..'-'..tostring({}):gsub('[^%x]','')):lower()
local probe=assert(io.open(root..'local_base_probe.txt','wb'));probe:write(nonce);probe:close()
local started,failed=false,false;local attempts=0
LoopInGameThreadWithDelay(250,function()
 if started or failed then return false end
 attempts=attempts+1
 local file=io.open(root..'local_base_native.txt','rb');local reply=file and file:read(200)or '';if file then file:close()end
 if reply=='PBZLOCAL1 '..nonce..' local-0.1.0' then
  local ok,err=pcall(function()if requested then api.localfour.start(mode,count)end end)
  started=ok;failed=not ok
  local status=assert(io.open(root..'local_base_status.txt','wb'))
  status:write('PBZLOCAL1 local-0.1.0 '..nonce..' '..(ok and(requested and 'started' or 'single')or 'failed'));status:close()
  api.log(ok and 'Local-only base started; network transport absent' or ('Local base failed: '..tostring(err)))
 elseif attempts>=40 then failed=true;api.log('Native local-base handshake failed; multiplayer refused')end
 return false
end)
