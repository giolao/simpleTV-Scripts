-- видеоскрипт для видеобалансера "CDN Movies" https://cdnmovies.net (22/3/21)
-- Copyright © 2017-2021 Nexterr | https://github.com/Nexterr-origin/simpleTV-Scripts
-- ## открывает подобные ссылки ##
-- https://700filmov.ru/film/637
-- https://700filmov.ru/serial/5
-- ##
		if m_simpleTV.Control.ChangeAddress ~= 'No' then return end
		if not m_simpleTV.Control.CurrentAddress:match('^https?://700filmov%.ru/')
			and not m_simpleTV.Control.CurrentAddress:match('^$cdnmovies')
		then
		 return
		end
	local inAdr = m_simpleTV.Control.CurrentAddress
	m_simpleTV.OSD.ShowMessageT({text = '', showTime = 1000, id = 'channelName'})
	if not inAdr:match('&kinopoisk') then
		if m_simpleTV.Control.MainMode == 0 then
			m_simpleTV.Interface.SetBackground({BackColor = 0, PictFileName = '', TypeBackColor = 0, UseLogo = 0, Once = 1})
		end
	end
	require 'json'
	inAdr = inAdr:gsub('&kinopoisk', '')
	m_simpleTV.Control.ChangeAddress = 'Yes'
	m_simpleTV.Control.CurrentAddress = 'error'
	if not m_simpleTV.User then
		m_simpleTV.User = {}
	end
	if not m_simpleTV.User.cdnmovies then
		m_simpleTV.User.cdnmovies = {}
	end
	local function cdnmoviesIndex(t)
		local lastQuality = tonumber(m_simpleTV.Config.GetValue('cdnmovies_qlty') or 5000)
		local index = #t
			for i = 1, #t do
				if t[i].qlty >= lastQuality then
					index = i
				 break
				end
			end
		if index > 1 then
			if t[index].qlty > lastQuality then
				index = index - 1
			end
		end
	 return index
	end
	local function cdnmoviesAdr(url)
		url = url:gsub('^$cdnmovies', '')
		local t, i = {}, 1
			for qlty, adr in url:gmatch('%[(%d+).-%]([^,]+)') do
				t[i] = {}
				t[i].Id = i
				t[i].qlty = tonumber(qlty)
				t[i].Address = adr .. '$OPT:NO-STIMESHIFT$OPT:demux=mp4,any'
				t[i].Name = qlty .. 'p'
				i = i + 1
			end
			if #t == 0 then return end
		table.sort(t, function(a, b) return a.qlty < b.qlty end)
		m_simpleTV.User.cdnmovies.Tab = t
		local index = cdnmoviesIndex(t)
		m_simpleTV.User.cdnmovies.Index = index
	 return t[index].Address
	end
	function Qlty_cdnmovies()
		local t = m_simpleTV.User.cdnmovies.Tab
			if not t then return end
		m_simpleTV.Control.ExecuteAction(37)
		local index = cdnmoviesIndex(t)
		t.ExtButton1 = {ButtonEnable = true, ButtonName = '✕', ButtonScript = 'm_simpleTV.Control.ExecuteAction(37)'}
		local ret, id = m_simpleTV.OSD.ShowSelect_UTF8('⚙ Качество', index - 1, t, 5000, 1 + 4)
		if ret == 1 then
			m_simpleTV.Control.SetNewAddress(t[id].Address, m_simpleTV.Control.GetPosition())
			m_simpleTV.Config.SetValue('cdnmovies_qlty', t[id].qlty)
		end
	end
	local function play(Adr)
		local retAdr = cdnmoviesAdr(Adr)
			if not retAdr then
				m_simpleTV.Control.CurrentAddress = 'http://wonky.lostcut.net/vids/error_getlink.avi'
			 return
			end
		m_simpleTV.Control.CurrentAddress = retAdr
-- debug_in_file(retAdr .. '\n')
	end
		if inAdr:match('^$cdnmovies') then
			play(inAdr)
		 return
		end
	local session = m_simpleTV.Http.New('Mozilla/5.0 (Windows NT 10.0; rv:86.0) Gecko/20100101 Firefox/86.0')
		if not session then return end
	m_simpleTV.Http.SetTimeout(session, 8000)
	local rc, answer = m_simpleTV.Http.Request(session, {url = inAdr})
	m_simpleTV.Http.Close(session)
		if rc ~= 200 then return end
	local title = m_simpleTV.Control.CurrentTitle_UTF8
	local answer = answer:match('file:\'([^\']+)')
		if not answer then return end
	answer = answer:gsub('%[%]', '""')
	local tab = json.decode(answer)
		if not tab then return end
	local tr
	local t, i = {}, 1
		while tab[i] do
			t[i] = {}
			t[i].Id = i
			t[i].Name = tab[i].title
			t[i].Address = i
			i = i + 1
		end
		if #t == 0 then return end
	if #t > 1 then
		local _, id = m_simpleTV.OSD.ShowSelect_UTF8('перевод - ' .. title, 0, t, 5000, 1)
		id = id or 1
		tr = t[id].Address
	else
		tr = t[1].Address
	end
	if answer:match('folder') then
		local season
		t, i = {}, 1
			while tab[tr].folder[i] do
				t[i] = {}
				t[i].Id = i
				t[i].Name = tab[tr].folder[i].title
				t[i].Address = i
				i = i + 1
			end
			if #t == 0 then return end
		if #t > 1 then
			local _, id = m_simpleTV.OSD.ShowSelect_UTF8('сезон - ' .. title, 0, t, 5000, 1)
			id = id or 1
		 	season = t[id].Address
		else
			season = t[1].Address
		end
		t, i = {}, 1
			while tab[tr].folder[season].folder[i] do
				t[i] = {}
				t[i].Id = i
				t[i].Name = tab[tr].folder[season].folder[i].title
				t[i].Address = '$cdnmovies' .. tab[tr].folder[season].folder[i].file
				i = i + 1
			end
			if #t == 0 then return end
		t.ExtButton1 = {ButtonEnable = true, ButtonName = '✕', ButtonScript = 'm_simpleTV.Control.ExecuteAction(37)'}
		t.ExtButton0 = {ButtonEnable = true, ButtonName = '⚙', ButtonScript = 'Qlty_cdnmovies()'}
		if #t > 1 then
			local _, id = m_simpleTV.OSD.ShowSelect_UTF8(title, 0, t, 5000)
			id = id or 1
		 	inAdr = t[id].Address
		else
			inAdr = t[1].Address
		end
	else
		inAdr = tab[tr].file
		local t1 = {}
		t1[1] = {}
		t1[1].Id = 1
		t1[1].Name = title
		t1[1].Address = inAdr
		t1.ExtButton0 = {ButtonEnable = true, ButtonName = '⚙', ButtonScript = 'Qlty_cdnmovies()'}
		t1.ExtButton1 = {ButtonEnable = true, ButtonName = '✕', ButtonScript = 'm_simpleTV.Control.ExecuteAction(37)'}
		m_simpleTV.OSD.ShowSelect_UTF8('CDN Movies', 0, t1, 5000, 64 + 32 + 128)
	end
	play(inAdr)
