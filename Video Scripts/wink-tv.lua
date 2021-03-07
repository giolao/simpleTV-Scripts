-- видеоскрипт для плейлиста "Wink TV" https://wink.rt.ru (12/1/21)
-- Copyright © 2017-2021 Nexterr | https://github.com/Nexterr-origin/simpleTV-Scripts
-- в архиве не переключает качество
-- ## необходим ##
-- расширение дополнения httptimeshift: wink-tv-timeshift_ext.lua
-- скрапер TVS: wink-tv_pls.lua
-- ## открывает подобные ссылки ##
-- https://zabava-htlive.cdn.ngenix.net/hls/CH_MATCHTVHD/variant.m3u8
-- http://hlsstr03.svc.iptv.rt.ru/hls/CH_TNTHD/variant.m3u8
-- http://rt-vlg-samara-htlive-lb.cdn.ngenix.net/hls/CH_R03_OTT_VLG_SAMARA_M1/variant.m3u8
-- http://s91412.cdn.ngenix.net/mdrm/CH_UFCHD_HLS/bw5000000/variant.m3u8
-- http://a787201472-s91412.cdn.ngenix.net/mdrm/CH_UFCHD_HLS/bw5000000/manifest.mpd
-- http://s91412.cdn.ngenix.net/mdrm/CH_UFCHD_HLS/bw5000000/variant.m3u8
-- http://hlsstr03.svc.iptv.rt.ru/hls/CH_TNTHD/variant.m3u8?offset=-14400
-- ## юзер агент ##
local userAgent = 'Mozilla/5.0 (SMART-TV; Linux; Tizen 4.0.0.2) AppleWebkit/605.1.15 (KHTML, like Gecko) SamsungBrowser/9.2 TV Safari/605.1.15'
-- ## Пртокол ##
local http = 1
-- 0 - httpS
-- 1 - http
-- ## Прокси ##
local proxy = ''
-- '' - нет
--'http://217.150.200.152:8081' - (пример)
-- ##
		if m_simpleTV.Control.ChangeAddress ~= 'No' then return end
		if not m_simpleTV.Control.CurrentAddress:match('rt%.ru/hls/CH_')
			and not m_simpleTV.Control.CurrentAddress:match('ngenix%.net[:%d]*/hls/CH_')
			and not m_simpleTV.Control.CurrentAddress:match('ngenix%.net/mdrm/CH_')
		then
		 return
		end
		if m_simpleTV.Control.CurrentAddress:match('PARAMS=wink_tv') then return end
	if m_simpleTV.Control.MainMode == 0 then
		m_simpleTV.Interface.SetBackground({BackColor = 0, PictFileName = '', TypeBackColor = 0, UseLogo = 0, Once = 1})
	end
	local inAdr = m_simpleTV.Control.CurrentAddress
	m_simpleTV.Control.ChangeAddress = 'Yes'
	m_simpleTV.Control.CurrentAddress = 'error'
	if http == 0 then
		inAdr = inAdr:gsub('^http://', 'https://')
	else
		inAdr = inAdr:gsub('^https://', 'http://')
	end
	local host = inAdr:match('https?://.-/')
	local extOpt = '$OPT:INT-SCRIPT-PARAMS=wink_tv$OPT:http-user-agent=' .. userAgent
	if proxy ~= '' then
		extOpt = extOpt .. '$OPT:http-proxy=' .. proxy
	end
	local session = m_simpleTV.Http.New(userAgent, proxy, false)
		if not session then return end
	m_simpleTV.Http.SetTimeout(session, 8000)
	local function play(adr, offset)
		if offset then
			m_simpleTV.Control.SetNewAddressT({address = adr, timeshiftOffset = offset * 1000})
		else
			m_simpleTV.Control.CurrentAddress = adr
		end
	 return
	end
	local function streamsTab(answer, host, extOpt)
		local t, i = {}, 1
			for w in answer:gmatch('EXT%-X%-STREAM%-INF(.-\n.-)\n') do
				local adr = w:match('\n(.+)')
				local name = w:match('BANDWIDTH=(%d+)')
				if adr and name then
					name = tonumber(name)
					adr = adr:gsub('/playlist%.', '/variant.')
					adr = adr:gsub('https?://.-/', host)
					adr = adr:gsub('%?.-$', '')
					t[i] = {}
					t[i].Id = name
					t[i].Name = math.ceil(name / 10000) * 10 .. ' кбит/с'
					t[i].Address = adr .. extOpt
					i = i + 1
				end
			end
			if #t > 0 then
			 return t
			end
			for bandwidth in answer:gmatch('id="(bw%d+/)video"') do
				local name = bandwidth:match('%d+')
				name = tonumber(name)
				t[i] = {}
				t[i].Id = name
				t[i].Name = math.ceil(name / 10000) * 10 .. ' кбит/с'
				t[i].Address = inAdr:gsub('manifest.mpd', bandwidth .. 'manifest.mpd') .. extOpt
				i = i + 1
			end
	 return t
	end
	function winkSaveQuality(obj, id)
		m_simpleTV.Config.SetValue('wink_qlty', tostring(id))
	end
	local offset = inAdr:match('offset=%-(%d+)')
	inAdr = inAdr:gsub('$OPT:.+', '')
	inAdr = inAdr:gsub('bw%d+/', '')
	inAdr = inAdr:gsub('%?.-$', '')
	local rc, answer = m_simpleTV.Http.Request(session, {url = inAdr})
	m_simpleTV.Http.Close(session)
		if rc ~= 200 then return end
	local t = streamsTab(answer, host, extOpt)
		if #t == 0 then
			play(inAdr .. extOpt, offset)
		 return
		end
	table.sort(t, function(a, b) return a.Id < b.Id end)
	local lastQuality = tonumber(m_simpleTV.Config.GetValue('wink_qlty') or 100000000)
	t[#t + 1] = {}
	t[#t].Id = 100000000
	t[#t].Name = '▫ всегда высокое'
	t[#t].Address = t[#t - 1].Address
	t[#t + 1] = {}
	t[#t].Id = 500000000
	t[#t].Name = '▫ адаптивное'
	t[#t].Address = inAdr .. extOpt
	local index = #t
		for i = 1, #t do
			if t[i].Id >= lastQuality then
				index = i
			 break
			end
		end
	if index > 1 then
		if t[index].Id > lastQuality then
			index = index - 1
		end
	end
	if m_simpleTV.Control.MainMode == 0 then
		t.ExtButton1 = {ButtonEnable = true, ButtonName = '✕', ButtonScript = 'm_simpleTV.Control.ExecuteAction(37)'}
		t.ExtParams = {LuaOnOkFunName = 'winkSaveQuality'}
		m_simpleTV.OSD.ShowSelect_UTF8('⚙ Качество', index - 1, t, 5000, 32 + 64 + 128)
	end
	play(t[index].Address, offset)
-- debug_in_file(m_simpleTV.Control.CurrentAddress .. '\n')