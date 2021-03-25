-- видеоскрипт для видеобалансера "CDN Movies" https://cdnmovies.net (25/3/21)
-- Copyright © 2017-2021 Nexterr | https://github.com/Nexterr-origin/simpleTV-Scripts
-- ## открывает подобные ссылки ##
-- https://700filmov.ru/film/637
-- http://700filmov.ru/serial/109
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
	m_simpleTV.Control.ChangeAddress = 'Yes'
	m_simpleTV.Control.CurrentAddress = 'error'
	if not m_simpleTV.User then
		m_simpleTV.User = {}
	end
	if not m_simpleTV.User.cdnmovies then
		m_simpleTV.User.cdnmovies = {}
	end
	local function showMsg(str)
		local t = {text = 'CDN Movies ошибка: ' .. str, showTime = 1000 * 8, color = ARGB(255, 255, 102, 0), id = 'channelName'}
		m_simpleTV.OSD.ShowMessageT(t)
	end
	local function getIndex(t)
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
	local function getAdr(url)
			if not url then return end
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
		local index = getIndex(t)
		m_simpleTV.User.cdnmovies.Index = index
	 return t[index].Address
	end
	local function trim(str)
		str = string.match(str,'^%s*(.-)%s*$')
	 return str
	end
	local function play(adr, title)
		local retAdr = getAdr(adr)
			if not retAdr then
				m_simpleTV.Control.CurrentAddress = 'http://wonky.lostcut.net/vids/error_getlink.avi'
			 return
			end
		if adr:match('^$cdnmovies') then
			retAdr = retAdr .. '$OPT:POSITIONTOCONTINUE=0'
		end
		m_simpleTV.Control.CurrentAddress = retAdr
-- debug_in_file(retAdr .. '\n')
		m_simpleTV.Control.CurrentTitle_UTF8 = title
		m_simpleTV.OSD.ShowMessageT({text = title, showTime = 1000 * 5, id = 'channelName'})
	end
	local function transl(tab, title)
		local tr, selected_dubl, selected_mnogoPro
		local t, i = {}, 1
			while tab[i] do
				local name = tab[i].title
				t[i] = {}
				t[i].Id = i
				t[i].Name = name
				t[i].Address = i
				if not selected_dubl
					and name:match('дублир')
				then
					selected_dubl = #t
				end
				if not selected_mnogoPro
					and name:match('много')
					and name:match('фессион')
				then
					selected_mnogoPro = #t
				end
				i = i + 1
			end
			if #t == 0 then return end
		local selected = selected_dubl or selected_mnogoPro or #t
		local id
		if #t > 1 then
			local _, d = m_simpleTV.OSD.ShowSelect_UTF8('перевод: ' .. title, selected - 1, t, 8000, 1 + 2 + 4 + 8)
			id = d
		end
		id = id or selected
	 return t[id].Address
	end
	local function seasons(tab, tr, title)
		local season
		local seasonName = ''
		local t, i = {}, 1
			while tab[tr].folder[i] do
				t[i] = {}
				t[i].Id = i
				t[i].Name = trim(tab[tr].folder[i].title)
				t[i].Address = i
				i = i + 1
			end
			if #t == 0 then return end
		local id
		if #t > 1 then
			local _, d = m_simpleTV.OSD.ShowSelect_UTF8('сезон: ' .. title, 0, t, 8000, 1 + 2)
			id = d
		end
		id = id or 1
	 return t[id].Address, ' (' .. t[id].Name .. ')'
	end
	local function episodes(tab, tr, title, season, seasonName)
		local t, i = {}, 1
			while tab[tr].folder[season].folder[i] do
				t[i] = {}
				t[i].Id = i
				t[i].Name = tab[tr].folder[season].folder[i].title
				t[i].Address = '$cdnmovies' .. tab[tr].folder[season].folder[i].file
				i = i + 1
			end
			if #t == 0 then return end
		t.ExtButton1 = {ButtonEnable = true, ButtonName = '✕', ButtonScript = 'm_simpleTV.Control.ExecuteAction(37)'}
		t.ExtButton0 = {ButtonEnable = true, ButtonName = '⚙', ButtonScript = 'qlty_cdnmovies()'}
		local pl = 0
		if #t == 1 then
			pl = 32
		end
		m_simpleTV.OSD.ShowSelect_UTF8(title .. seasonName, 0, t, 8000, pl + 64)
	 return t[1].Address, title .. seasonName .. ': ' .. t[1].Name
	end
	local function movie(tab, tr, title)
		local adr = tab[tr].file
		local t = {}
		t[1] = {}
		t[1].Id = 1
		t[1].Name = title
		t.ExtButton0 = {ButtonEnable = true, ButtonName = '⚙', ButtonScript = 'qlty_cdnmovies()'}
		t.ExtButton1 = {ButtonEnable = true, ButtonName = '✕', ButtonScript = 'm_simpleTV.Control.ExecuteAction(37)'}
		m_simpleTV.OSD.ShowSelect_UTF8('CDN Movies', 0, t, 8000, 64 + 32 + 128)
	 return adr, title
	end
	local function serials(tab, tr, title)
		local season, seasonName = seasons(tab, tr, title)
			if not season then return end
	 return episodes(tab, tr, title, season, seasonName)
	end
	local function getData()
		local session = m_simpleTV.Http.New('Mozilla/5.0 (Windows NT 10.0; rv:86.0) Gecko/20100101 Firefox/86.0')
			if not session then return end
		m_simpleTV.Http.SetTimeout(session, 8000)
		inAdr = inAdr:gsub('&kinopoisk', '')
		local rc, answer = m_simpleTV.Http.Request(session, {url = inAdr})
		m_simpleTV.Http.Close(session)
			if rc ~= 200 then
			 return 'это видео удалено'
			end
		answer = answer:match('file:\'([^\']+)')
			if not answer then return end
		answer = answer:gsub('%[%]', '""')
		local tab = json.decode(answer)
			if not tab then return end
		local title	= m_simpleTV.Control.CurrentTitle_UTF8
	 return tab, transl(tab, title), answer:match('folder'), title
	end
	function qlty_cdnmovies()
		local t = m_simpleTV.User.cdnmovies.Tab
			if not t then return end
		m_simpleTV.Control.ExecuteAction(37)
		local index = getIndex(t)
		t.ExtButton1 = {ButtonEnable = true, ButtonName = '✕', ButtonScript = 'm_simpleTV.Control.ExecuteAction(37)'}
		local ret, id = m_simpleTV.OSD.ShowSelect_UTF8('⚙ Качество', index - 1, t, 5000, 1 + 4)
		if ret == 1 then
			m_simpleTV.Control.SetNewAddress(t[id].Address, m_simpleTV.Control.GetPosition())
			m_simpleTV.Config.SetValue('cdnmovies_qlty', t[id].qlty)
		end
	end
		if inAdr:match('^$cdnmovies') then
			local title = ''
			local t = m_simpleTV.Control.GetCurrentChannelInfo()
			if t
				and t.MultiHeader
				and t.MultiName
			then
				title = t.MultiHeader .. ': ' .. t.MultiName
			end
			play(inAdr, title)
		 return
		end
	local tab, tr, ser, title = getData()
		if not tab or type(tab) ~= 'table' or not tr then
			showMsg(tab or 'нет данных')
		 return
		end
	if ser then
		play(serials(tab, tr, title))
	else
		play(movie(tab, tr, title))
	end
