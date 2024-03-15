pico-8 cartridge // http://www.pico-8.com
version 38
__lua__
-- serialise table preprocessor
-- by cubee 🐱

function packfile(input,output)

	local serialised=tbl_serialize(input)
	
	-- check table
	tbl_serialize_validate(input,tbl_deserialize(serialised))
	
	
--	local escaped_string=escape_binary_str(serialised)
	local escaped_string=serialised
	
	printh('"'..escaped_string..'"',output,true)

end

function main()


-- pack object data
?"packing objects..."
#include object_data_raw.p8l
packfile(objects,"object_data.p8l")

--[[ pack stage data
?"packing stages..."
#include stage_data_raw.p8l
packfile(stages,"stage_data.p8l")
--]]

?"done"

end
-->8
-- functions

-- gpi's deserialiser
function str2table(str)
local out,s={}
add(out,{})
for l in all(split(str,"\n")) do
--db
if l[1]~="#" then
--dbe
while ord(l)==9 or ord(l)==32 do
l=sub(l,2)
end
if l~="" then
s=split(l,"=")
if(#s==1)s[1]=#out[#out]+1 s[2]=l
if(s[2]=="{")s[2]={}
if s[2]=="}" then
deli(out)
else
out[#out][s[1]]=s[2]
if(type(s[2])=="table")add(out,s[2])
end
end
--db
end
--dbe
end
return out[1]
end

-- ridgekuhn's (de)serialiser
--  https://www.lexaloffle.com/bbs/?tid=48023

---serialize lua table to string
--@param {table} tbl
--  input table
--
--@returns {string}
--  serialized table
function tbl_serialize(tbl)
    local function encode_value(value)
        --ascii unit separator
        --delimits number
        local value_token = "\31"

        --ascii acknowledge
        --delimits true boolean
        local bool_true = "\6"

        --ascii negative acknowledge
        --delimits false boolean
        local bool_false = "\21"

        --ascii start of text
        --delimits start of string
        local str_token = "\2"

        --end of string sequence
        --ascii end of text + x
        --ascii end of transmission block
        local str_end_token = "\3x\23"

        --asci group separator
        --delimits start of table
        local tbl_token = "\29"

        if type(value) == "boolean" then
            return value and bool_true or bool_false

        elseif type(value) == "string" then
            --check for
            --ascii control chars
            for i = 1, #value do
                if ord(sub(value, i, i)) < 32 then
                    --delimit binary string
                    return str_token .. value .. str_end_token
                end
            end

            --encode regular string
            return value_token .. value

        elseif type(value) == "table" then
            return tbl_token .. tbl_serialize(value)
        end

        return value_token .. value
    end

    local str = ""

    --ascii record separator
    --delimits table key
    local key_token = "\30"

    --ascii end of medium
    --delimits end of table
    local tbl_end_token = "\25"

    --get indexed values
    for _, v in ipairs(tbl) do
        str = str .. encode_value(v)
    end

    --get keyed values
    for k, v in pairs(tbl) do
        if type(k) ~= "number" then
            str = str .. key_token .. k .. encode_value(v)
        end
    end

    str = str .. tbl_end_token

    return str
end

---validate output
--@usage
--  output = tbl_serialize(my_table)
--
--  tbl_serialize_validate(
--      my_table,
--      tbl_deserialize(output)
--  )
--
--@param {table} tbl1
--  input table
--
--@param {table} tbl2
--  output table
function tbl_serialize_validate(tbl1, tbl2)
    for k, v in pairs(tbl1) do
        if type(v) == "table" then
            tbl_serialize_validate(tbl2[k], v)
        else
            assert(
                tbl2[k] == v,
                tostr(k) .. ": " .. tostr(v) .. ": " .. tostr(tbl2[k])
            )
        end
    end
end

---deserialize table
--@param {string} str
--  serialized table string
--
--@returns {table}
--  deserialized table
function tbl_deserialize(str)
    ---get encoded value
    --@param {string} str
    --  serialized table string
    --
    --@param {integer} i
    --  position of
    --  current delimiter
    --  in serialized table string
    local function get_value(str, i)
        local
            char,
            i_plus1
            =
            sub(str, i, i),
            i + 1

        --table
        if char == "\29" then
            local
                tbl,
                j
                =
                tbl_deserialize(
                    sub(str, i_plus1)
                )

            return tbl, i + j

        --binary string
        elseif char == "\2" then
            for j = i_plus1, #str do
                if sub(str, j, j + 2) == "\3x\23" then
                    return sub(str, i_plus1, j - 1), j + 2
                end
            end

        --bool true
        elseif char == "\6" then
            return true, i

        --bool false
        elseif char == "\21" then
            return false, i
        end

        --number, string,
        --or table key
        --("\30" or "\31")
        for j = i_plus1, #str do
            if ord(sub(str, j, j)) < 32 then
                local value = sub(str, i_plus1, j - 1)

                return tonum(value) or value, j - 1
            end
        end
    end

    local
        tbl,
        i
        =
        {},
        1

    --loop start
    ::parse::

    local char = sub(str, i, i)

    --end of table
    if char == "\25" then
        return tbl, i

    --table key
    elseif char == "\30" then
        local key, j = get_value(str, i)
        local value, k = get_value(str, j + 1)

        tbl[key] = value

        i = k + 1

    --value
    elseif ord(char) < 32 then
        local value, j = get_value(str, i)

        add(tbl, value)

        i = j + 1
    end

    --loop end
    goto parse

    return tbl
end

-- zep's binary string escaper
--  https://www.lexaloffle.com/bbs/?tid=38692
function escape_binary_str(s)
 local out=""
 for i=1,#s do
  local c  = sub(s,i,i)
  local nc = ord(s,i+1)
  local pr = (nc and nc>=48 and nc<=57) and "00" or ""
  local v=c
  if(c=="\"") v="\\\""
  if(c=="\\") v="\\\\"
  if(ord(c)==0) v="\\"..pr.."0"
  if(ord(c)==10) v="\\n"
  if(ord(c)==13) v="\\r"
  out..= v
 end
 return out
end

-->8
-- python moment
main()

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
