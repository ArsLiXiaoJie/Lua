local base = {
	hello = "world";
	name = "base";
}


function base:new( name )
	local t = {
		world = "hello";
		name = "t"
	};
	setmetatable( t, {__index = base} );

	return t;
end


local sub = base:new("subclass");
print( sub.hello );
print( sub.world );
print( sub.can )




local sub2 = base:new("sub2")
print(sub2.hello)

print( type(sub) )
print( type(base) )

print("--------")
local sub3 = {hell = "arsenal"}
setmetatable( sub3, {__index = sub} )
print(sub3.world)
print(sub3.hello)




