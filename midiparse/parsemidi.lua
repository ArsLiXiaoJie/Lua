--时间差 转 十六进制
--首先把时间转换成 128^n 的和
--比如 65535 = 128^2*3 + 128^1*127 + 128^0*127
--240 = 128^1*1 + 128^0*112
-- 可以分成一块块 128^n*m
--有多少块就代表有多少个字符代表了时间差，比如 65535 有3块，而转成十六进制就是 83 FF 7F 三块
--240 = 81 70 两块
--m 代表后面的数是多少，128^2 大于127，所以是 10000000 + 3 = 10000011 = 83
--128^1 大于127，所以是10000000 + 127 = 11111111 = FF
--128^0小于127， 所以是 00000000 + 127 = 0111111 = 7F
--而反过来通过十六进制得到时间差，只要标志位为0，则表示结束读取时间差
--比如 82 C0 03 表示 128^2*2 + 128^1*64 + 128^0*3 = 40493，如果基本时间为120，则有341：043个四分音符


local MidiDecode = {}

--每次读多少字节
local BLOCK = 1;

--字节转成数字
local function b2n( byte )
	return string.byte( byte );
end

local function print16( byte )
	print( string.format( "%02x", b2n(byte) ) )
end

--外部调用，传文件路径名称
function MidiDecode:decode( file )
	local f = io.open( --[["sea-sky.mid"]] file, "rb" );
	--存放解析后的数据
	local midi_data = {};
	midi_data.byte_table = {};	--存放全部字节
	midi_data.orbital_table = {};	--存放音轨

	self.m_cur_orbital_num = 0;

	self:deal_data( f, midi_data );

	midi_data.byte_table = {}
	printtable( midi_data );
end

--开始处理数据
function MidiDecode:deal_data( ffile, midi_data )
	local function get_byte(  )
		local b = ffile:read( BLOCK );
		if b then
			table.insert( midi_data.byte_table, b2n(b) );
		end
		return b;
	end

	--midi文件的前八个字节，判断是不是midi文件
	--前四个字节表示 "MThd"， 后四个总是 00 00 00 06
	local head = {0x4d, 0x54, 0x68, 0x64, 0x00, 0x00, 0x00, 0x06}
	local n = 1
	local bytes = get_byte();
	while true do
		if b2n(bytes) ~= head[n] then
			print("is not midi file");
			return;
		end
		n = n+1;
		if n > #head then
			break;
		end
		bytes = get_byte();
	end

	--获取Midi的格式，音轨数量
	--0 代表单音轨，1 代表多音轨且同步，2 代表多音轨但不同步
	bytes = get_byte();
	if b2n(bytes) ~= 0x00 then
		print( "yin gui read error" );
		return;
	end
	bytes = get_byte();
	if b2n(bytes) == 0x00 then
		midi_data.music_orbital = 0;
	elseif b2n(bytes) == 0x01 then
		midi_data.music_orbital = 1;
	elseif b2n(bytes) == 0x02 then
		midi_data.music_orbital = 2;
	else
		print("yin gui read error 2");
		return;
	end

	--获取指定轨道数，实际音轨数加上一个全局音轨
	--应该不会超过127个音轨，不对第一个字节处理
	bytes = get_byte();
	bytes = get_byte();
	midi_data.orbital_num = b2n( bytes );

	--获取指定基本时间
	local bt = 0;
	bytes = get_byte();
	bt = b2n(bytes) * 256;
	bytes = get_byte();
	bt = bt + b2n(bytes);
	midi_data.base_time = bt;

	--是否开始新音轨
	self.m_is_new_orbital = false;
	--新音轨当前的进度
	self.m_new_orbital_head = 0;
	while true do
		bytes = get_byte();
		if not bytes then
			break;
		end
		self:deal_byte( b2n(bytes), midi_data );
	end
end

--处理一个字节
function MidiDecode:deal_byte( byte, mdd )
	--byte是number类型

	local function normal_deal( bt )
		--正常处理
		if self.m_is_new_orbital then
			self.m_new_orbital_head = self.m_new_orbital_head + 1;

			--这是读取新音轨前四个字节，标志了该轨道的字节数
			local orbital = mdd.orbital_table[self.m_cur_orbital_num];
			--每个音轨的字节数
			orbital.byte_num = orbital.byte_num or 0;
			orbital.byte_num = orbital.byte_num + bt * math.pow(256,4-self.m_new_orbital_head)

			if self.m_new_orbital_head >= 4 then
				self.m_is_new_orbital = false;
				self.m_new_orbital_head = 0;
			end
		end
	end



	--特殊处理，判断是否音轨开头
	if byte == 0x4d then
	elseif byte == 0x54 then
		local len = #mdd.byte_table;
		if mdd.byte_table[len-1] == 0x4d then

		else
			normal_deal( mdd.byte_table[len-1] );
			normal_deal( mdd.byte_table[len] );
		end

	elseif byte == 0x72 then
		local len = #mdd.byte_table;
		if mdd.byte_table[len-2] == 0x54 and mdd.byte_table[len-3] then
		else
			normal_deal( mdd.byte_table[len-2] );
			normal_deal( mdd.byte_table[len-1] );
			normal_deal( mdd.byte_table[len] );
		end

	elseif byte == 0x6b then
		local len = #mdd.byte_table;
		if mdd.byte_table[len-1] == 0x72 and mdd.byte_table[len-2] == 0x54 and mdd.byte_table[len-3] == 0x4d then
			self.m_is_new_orbital = true;
			self.m_new_orbital_head = 0;

			self.m_cur_orbital_num = self.m_cur_orbital_num + 1;
			mdd.orbital_table[self.m_cur_orbital_num] = {};
		else
			normal_deal( mdd.byte_table[len-3] );
			normal_deal( mdd.byte_table[len-2] );
			normal_deal( mdd.byte_table[len-1] );
			normal_deal( mdd.byte_table[len] );
		end
	else
		normal_deal(byte);
	end

end



return MidiDecode