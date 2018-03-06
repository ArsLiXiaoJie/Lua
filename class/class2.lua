setmetatableindex = function ( t, index )
	local mt = getmetatable( t );
	if not mt then
		mt = {};
		print("setmetatableindex0001")
	else
		print("mt.type",mt.type)
	end

	if not mt.__index then
		mt.__index = index;
		setmetatable(t, mt);
		print("setmetatableindex0002");
	elseif mt.__index ~= index then
		print( "setmetatableindex0003");
		setmetatableindex( mt, index );
	end
end



function class( classname, ... )
	local cls = {__cname = classname}

	local supers = {...}

	for _,super in ipairs(supers) do
		local superType = type( super );
		if superType == "function" then
			print( "super type is a function" );
			cls.__create = super;

		elseif superType == "table" then
			if super[".isclass"] then
				print("super is native class")
				cls.__create = function (  )
					return super:create();
				end

			else
				print("super is pure lua class");
				cls.__supers = cls.__supers or {};
				cls.__supers[#cls.__supers+1] = super;
				if not cls.super then
					cls.super = super;
				end
			end
		end
	end

	cls.__index = cls;

	if not cls.__supers or #cls.__supers == 1 then
		print("single inherit")
		setmetatable( cls, {__index = cls.super} );
	else
		print("multi inherit")
		setmetatable( cls, {__index = function ( _, key )
			local supers = cls.__supers;
			for i=1,#supers do
				local super = supers[i];
				if super[key] then
					return super[key]
				end
			end
		end} );
	end

	if not cls.ctor then
		cls.ctor = function (  )
			
		end
	end

	cls.new = function ( ... )
		print("go")

		local instance;
		if cls.__create then
			print("had create func");
			instance = cls.__create(...);
			print(instance.type)
		else
			print("no create func")
			instance = {};
		end
		setmetatableindex( instance, cls );
		instance.class = cls;
		instance:ctor(...);
		return instance;
	end

	cls.create = function ( _, ... )
		return cls.new(...);
	end

	return cls;
end