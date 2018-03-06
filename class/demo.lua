require "class2"

local Sprite = {};


Sprite.type = "Sprite"
Sprite.mark1 = 111
Sprite[".isclass"] = true

function Sprite:create( o )
	print("Sprite:create")
	o = o or {};
	setmetatable( o, self );
	self.__index = self;
	return o;
end

function Sprite:ctor( ... )
	print("Sprite:ctor")
end


GameSprite = class("GameSprite", Sprite)
GameSprite.type = "GameSprite"
GameSprite.mark2 = 222

function GameSprite:ctor( ... )
	print("GameSprite:ctor")
end


testClass = class( "testClass", GameSprite );
testClass.type = "testClass"
testClass.mark3 = 333

function GameSprite:ctor( ... )
	print("testClass:ctor")
end


local test = testClass:new()
print(test.mark1)
print(test.mark2)
print(test.mark3)