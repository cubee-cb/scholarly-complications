pico-8 cartridge // http://www.pico-8.com
version 35
__lua__

-- load gfx data from carts
for i=0,0x8000-1 do poke(0x8000+i,0)end
reload(0x8000,0,0x2000,"beatem-gfx-actors.p8")
reload(0xa000,0,0x2000,"beatem-gfx-maps.p8")

reload(0x2000,0x2000,0x1100,"beatem-gfx-maps.p8")

y=0

function _update60()
	if(btn(2))y-=1
	if(btn(3))y+=1

 -- px9 compress the gfx data
 if btnp(4) or true then
	 
	 cls()
	 print("running px9...")
	 flip()



	 local offset=0
	 local offsets={}
	 local target=0xc000

	 ---[[ make data smol
	 for i=0,1 do
   memcpy(0,0x8000+i*0x2000,0x2000)

 	 offset=i*0x1000
 	 add(offsets,offset)
 	 ?offset
 	 px9_comp(0,0,128,128,target+offset,sget)
 	 flip()
	 end

  -- put gfx
  cstore(0,target,0x2000,"beatem.p8")

  -- put map/flags
  cstore(0x2000,0x2000,0x1100,"beatem.p8")

--]]
  
  
  --[[ mget-based version

  poke(0x5f56,0x80,0)
		offset=px9_comp(0,0,256,128,0,mget)

  -- put into compressed cart
  cstore(0,0,0x3000,"0ut_comp.p8")
--]]

	 --[[ make data smol (eget ver)

 	offset=px9_comp(0,0,128,512,0,eget)
  cstore(0,0,offset,"beatem_c.p8")

--]]

  cls()
  print("length: "..split(tostr(offset,1),".",false)[1])
  if offset>0x3000 then
   print("compressed size too big!!!\n(>0x3000)")
  elseif offset>0x2000 then
   print("overflowed past sprites!\n(>0x2000)")
  else
   print("it fits!\n(<=0x2000)")
  end
  print("saved to main cart")

  flip()
  
  ?"\noffsets:"
  for i=1,#offsets do
   ?"sheet "..i..": "..offsets[i]
  end
  
  repeat
   _update_buttons()
   if(btnp(4))run()
   flip()
  until btn(5)


 end

end

function _draw()
 cls()

 for i=0,3 do
  memcpy(0,0x8000+i*0x2000,0x2000)
  spr(0,0,i*128-y,16,16)
 end

 ?sget(0,0x8000/128)
end

-->8
-- px9 compress v9

-- x0,y0 where to read from
-- w,h   image width,height
-- dest  address to store
-- vget  read function (x,y)

function
	px9_comp(x0,y0,w,h,dest,vget)

	local dest0=dest
	local bit=1
	local byte=0

	local function vlist_val(l, val)
		-- find position and move
		-- to head of the list

--[ 2-3x faster than block below
		local v,i=l[1],1
		while v!=val do
			i+=1
			v,l[i]=l[i],v
		end
		l[1]=val
		return i
--]]

--[[ 8 tokens smaller than above
		for i,v in ipairs(l) do
			if v==val then
				add(l,deli(l,i),1)
				return i
			end
		end
--]]
	end

	local cache,cache_bits=0,0
	function putbit(bval)
	 cache=cache<<1|bval
	 cache_bits+=1
		if cache_bits==8 then
			poke(dest,cache)
			dest+=1
			cache,cache_bits=0,0
		end
	end

	function putval(val, bits)
		for i=bits-1,0,-1 do
			putbit(val>>i&1)
		end
	end

	function putnum(val)
		local bits = 0
		repeat
			bits += 1
			local mx=(1<<bits)-1
			local vv=min(val,mx)
			putval(vv,bits)
			val -= vv
		until vv<mx
	end


	-- first_used

	local el={}
	local found={}
	local highest=0
	for y=y0,y0+h-1 do
		for x=x0,x0+w-1 do
			c=vget(x,y)
			if not found[c] then
				found[c]=true
				add(el,c)
				highest=max(highest,c)
			end
		end
	end

	-- header

	local bits=1
	while highest >= 1<<bits do
		bits+=1
	end

	putnum(w-1)
	putnum(h-1)
	putnum(bits-1)
	putnum(#el-1)
	for i=1,#el do
		putval(el[i],bits)
	end


	-- data

	local pr={} -- predictions

	local dat={}

	for y=y0,y0+h-1 do
		for x=x0,x0+w-1 do
			local v=vget(x,y)

			local a=y>y0 and vget(x,y-1) or 0

			-- create vlist if needed
			local l=pr[a] or {unpack(el)}
			pr[a]=l

			-- add to vlist
			add(dat,vlist_val(l,v))
			
			-- and to running list
			vlist_val(el, v)
		end
	end

	-- write
	-- store bit-0 as runtime len
	-- start of each run

	local nopredict
	local pos=1

	while pos <= #dat do
		-- count length
		local pos0=pos

		if nopredict then
			while dat[pos]!=1 and pos<=#dat do
				pos+=1
			end
		else
			while dat[pos]==1 and pos<=#dat do
				pos+=1
			end
		end

		local splen = pos-pos0
		putnum(splen-1)

		if nopredict then
			-- values will all be >= 2
			while pos0 < pos do
				putnum(dat[pos0]-2)
				pos0+=1
			end
		end

		nopredict=not nopredict
	end

	if cache_bits>0 then
		-- flush
		poke(dest,cache<<8-cache_bits)
		dest+=1
	end

	return dest-dest0
end

-->8
-- escape binary string

-- https://www.lexaloffle.com/bbs/?tid=38692
function escape_binary_str(s)
 local out=""
 for i=1,#s do
  local c=sub(s,i,i)
  local nc=ord(s,i+1)
  local v=c
  if(c=="\"") v="\\\""
  if(c=="\\") v="\\\\"
  if(ord(c)==0) v=(nc and nc>=48 and nc<=57) and "\\x00" or "\\0"
  if(ord(c)==10) v="\\n"
  if(ord(c)==13) v="\\r"
  out..=v
 end
 return out
end

-->8

-- wooooo!
function eget(x,y)
 local addr=@(0x8000+x\2+y*64),0
 return x\2==x/2 and addr&0b00001111 or (addr&0b11110000)>>4
end

-->8
-- px9 compress v7

-- x0,y0 where to read from
-- w,h   image width,height
-- dest  address to store
-- vget  read function (x,y)

function 
px9_comp(x0,y0,w,h,dest,vget)

	local dest0=dest
	local bit=1 
	local byte=0

	local function vlist_val(l, val)
		-- find position and move
		-- to head of the list

--[ 2-3x faster than block below
		local v,i=l[1],1
		while v!=val do
			i+=1
			v,l[i]=l[i],v
		end
		l[1]=val
		return i
--]]

--[[ 8 tokens smaller than above
		for i,v in ipairs(l) do
			if v==val then
				add(l,deli(l,i),1)
				return i
			end
		end
--]]
	end

	function putbit(bval)
		if (bval) byte+=bit 
		poke(dest, byte) bit<<=1
		if (bit==256) then
			bit=1 byte=0
			dest += 1
		end
	end

	function putval(val, bits)
		for i=0,bits-1 do
			putbit(val&1<<i > 0)
		end
	end

	function putnum(val)
		local bits = 0
		repeat
			bits += 1
			local mx=(1<<bits)-1
			local vv=min(val,mx)
			putval(vv,bits)
			val -= vv
		until vv<mx
	end


	-- first_used

	local el={}
	local found={}
	local highest=0
	for y=y0,y0+h-1 do
		for x=x0,x0+w-1 do
			c=vget(x,y)
			if not found[c] then
				found[c]=true
				add(el,c)
				highest=max(highest,c)
			end
		end
	end

	-- header

	local bits=1
	while highest >= 1<<bits do
		bits+=1
	end

	putnum(w-1)
	putnum(h-1)
	putnum(bits-1)
	putnum(#el-1)
	for i=1,#el do
		putval(el[i],bits)
	end


	-- data

	local pr={} -- predictions

	local dat={}

	for y=y0,y0+h-1 do
		for x=x0,x0+w-1 do
			local v=vget(x,y)  

			local a=0
			if (y>y0) a+=vget(x,y-1)

			-- create vlist if needed
			local l=pr[a]
			if not l then
				l={}
				for i=1,#el do
					l[i]=el[i]
				end
				pr[a]=l
			end

			-- add to vlist
			add(dat,vlist_val(l,v))
			
			-- and to running list
			vlist_val(el, v)
		end
	end

	-- write
	-- store bit-0 as runtime len
	-- start of each run

	local nopredict
	local pos=1

	while pos <= #dat do
		-- count length
		local pos0=pos

		if nopredict then
			while dat[pos]!=1 and pos<=#dat do
				pos+=1
			end
		else
			while dat[pos]==1 and pos<=#dat do
				pos+=1
			end
		end

		local splen = pos-pos0
		putnum(splen-1)

		if nopredict then
			-- values will all be >= 2
			while pos0 < pos do
				putnum(dat[pos0]-2)
				pos0+=1
			end
		end

		nopredict=not nopredict
	end

	if (bit!=1) dest+=1 -- flush

	return dest-dest0
end

__gfx__
11223800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11223800000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
