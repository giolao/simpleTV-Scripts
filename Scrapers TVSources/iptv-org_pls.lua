-- скрапер TVS для загрузки плейлиста "Iptv-org" https://github.com/iptv-org/iptv (12/3/21)
-- Copyright © 2017-2021 Nexterr | https://github.com/Nexterr-origin/simpleTV-Scripts
-- ## Переименовать каналы ##
local filter = {
	{'', ''},
	}
-- ##
	module('iptv-org_pls', package.seeall)
	local my_src_name = 'Iptv-org'
	local function ProcessFilterTableLocal(t)
		if not type(t) == 'table' then return end
		for i = 1, #t do
			t[i].name = tvs_core.tvs_clear_double_space(t[i].name)
			for _, ff in ipairs(filter) do
				if (type(ff) == 'table' and t[i].name == ff[1]) then
					t[i].name = ff[2]
				end
			end
		end
	 return t
	end
	function GetSettings()
	 return {name = my_src_name, sortname = '', scraper = '', m3u = 'out_' .. my_src_name .. '.m3u', logo = '..\\Channel\\logo\\Icons\\iptv-org.png', TypeSource = 1, TypeCoding = 1, DeleteM3U = 1, RefreshButton = 1, show_progress = 1, AutoBuild = 0, AutoBuildDay = {0, 0, 0, 0, 0, 0, 0}, LastStart = 0, TVS = {add = 0, FilterCH = 0, FilterGR = 0, GetGroup = 1, LogoTVG = 1}, STV = {add = 1, ExtFilter = 1, FilterCH = 0, FilterGR = 0, GetGroup = 1, HDGroup = 0, AutoSearch = 1, AutoNumber = 0, NumberM3U = 0, GetSettings = 1, NotDeleteCH = 0, TypeSkip = 1, TypeFind = 1, TypeMedia = 0, RemoveDupCH = 0}}
	end
	function GetVersion()
	 return 2, 'UTF-8'
	end
	local function showMsg(str, color)
		local t = {text = str, showTime = 1000 * 5, color = color, id = 'channelName'}
		m_simpleTV.OSD.ShowMessageT(t)
	end
	local function LoadFromSite()
		local session = m_simpleTV.Http.New('Mozilla/5.0 (Windows NT 10.0; rv:86.0) Gecko/20100101 Firefox/86.0')
			if not session then return end
		m_simpleTV.Http.SetTimeout(session, 16000)
		local rc, answer = m_simpleTV.Http.Request(session, {url = 'https://github.com/iptv-org/iptv/blob/master/README.md'})
			if rc ~= 200 then
				m_simpleTV.Http.Close(session)
			 return
			end
			local function getTbl(t, group, answer)
					for w in answer:gmatch('#EXTINF:.-\n.-\n') do
						local title = w:match('.+,(.-)\n')
						local url = w:match('\n(.-)\n')
						if title and url then
							t[#t + 1] = {}
							t[#t].address = url
							t[#t].logo = w:match('tvg%-logo="([^"]+)')
							t[#t].group = group
							t[#t].name = title
						end
					end
			 return t
			end
		m_simpleTV.OSD.ShowMessageT({text = my_src_name .. ', загрузка ...', showTime = 1000 * 60, color = ARGB(255, 153, 255, 153), id = 'channelName', once = true})
		local t = {}
			for w in answer:gmatch('</g%-emoji>.-</code>') do
				local adr = w:match('<code>([^<]+)')
				local group = w:match('>([^<]+)')
				if adr and group then
					local rc, answer = m_simpleTV.Http.Request(session, {url = adr})
					if rc == 200 then
						group = group:gsub('amp;', '')
						group = group:upper()
						answer = answer:gsub('#EXTVLCOPT.-\n', '')
						t = getTbl(t, group, answer)
					end
				end
			end
		m_simpleTV.Http.Close(session)
			if #t == 0 then return end
	 return t
	end
	function GetList(UpdateID, m3u_file)
			if not UpdateID then return end
			if not m3u_file then return end
			if not TVSources_var.tmp.source[UpdateID] then return end
		local Source = TVSources_var.tmp.source[UpdateID]
		local t_pls = LoadFromSite()
			if not t_pls then
				showMsg(Source.name .. ' ошибка загрузки плейлиста', ARGB(255, 255, 102, 0))
			 return
			end
		t_pls = ProcessFilterTableLocal(t_pls)
		showMsg(Source.name .. ' (' .. #t_pls .. ')', ARGB(255, 153, 255, 153))
		local m3ustr = tvs_core.ProcessFilterTable(UpdateID, Source, t_pls)
		local handle = io.open(m3u_file, 'w+')
			if not handle then return end
		handle:write(m3ustr)
		handle:close()
	 return 'ok'
	end
-- debug_in_file(#t_pls .. '\n')