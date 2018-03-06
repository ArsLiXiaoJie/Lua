function printtable( t, prefix )
	if type(t) == "userdata" then
		t = tolua.getpeer(t);
	end

	prefix = prefix or "";

	print(prefix.."{");
	for k,v in pairs(t) do
		if type(v) == "table" then
			print(prefix .. "  " .. tostring(k) .. " = ")
			if v ~= t then
				printtable( v, prefix.."  " )
			end
		elseif type(v) == "string" then
			print(prefix .. "  "..tostring(k).." = \"" ..v .."\"")
		elseif type(v) == "number" then
			print(prefix .. "  "..tostring(k).." = ".. v)
		elseif type(v) == "userdata" then
			print(prefix.."  "..tostring(k).." = "..tolua.type(v).."  "..tostring(v))
			local pt = tolua.getpeer(v)
			if pt ~= nil and pt ~= t then
				printtable(pt, prefix.."  ")
			end
		else
			print(prefix.."  "..tostring(k).." = "..tostring(v))
		end
	end
	print(prefix.."}")
end
