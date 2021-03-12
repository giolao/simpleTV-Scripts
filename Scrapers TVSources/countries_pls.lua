-- скрапер TVS для загрузки плейлиста "Countries" https://github.com/Free-IPTV/Countries (12/3/21)
-- Copyright © 2017-2021 Nexterr | https://github.com/Nexterr-origin/simpleTV-Scripts
-- ## Переименовать каналы ##
local filter = {
	{'', ''},
	}
-- ##
	module('countries_pls', package.seeall)
	local my_src_name = 'Countries'
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
	 return {name = my_src_name, sortname = '', scraper = '', m3u = 'out_' .. my_src_name .. '.m3u', logo = '..\\Channel\\logo\\Icons\\countries.png', TypeSource = 1, TypeCoding = 1, DeleteM3U = 1, RefreshButton = 1, show_progress = 1, AutoBuild = 0, AutoBuildDay = {0, 0, 0, 0, 0, 0, 0}, LastStart = 0, TVS = {add = 0, FilterCH = 0, FilterGR = 0, GetGroup = 1, LogoTVG = 1}, STV = {add = 1, ExtFilter = 1, FilterCH = 0, FilterGR = 0, GetGroup = 1, HDGroup = 0, AutoSearch = 1, AutoNumber = 1, NumberM3U = 0, GetSettings = 1, NotDeleteCH = 0, TypeSkip = 1, TypeFind = 1, TypeMedia = 0, RemoveDupCH = 1}}
	end
	function GetVersion()
	 return 2, 'UTF-8'
	end
	function GetList(UpdateID, m3u_file)
			if not UpdateID then return end
			if not m3u_file then return end
			if not TVSources_var.tmp.source[UpdateID] then return end
		local Source = TVSources_var.tmp.source[UpdateID]
		local url = 'https://raw.githubusercontent.com/Free-IPTV/Countries/master/ZZ_PLAYLIST_ALL_TV.m3u'
		local outm3u, err = tvs_func.get_m3u(url)
		if err ~= '' then
			tvs_core.tvs_ShowError(err)
			m_simpleTV.Common.Sleep(1000)
		end
			if not outm3u or outm3u == '' then
			 return ''
			end
		outm3u = outm3u:gsub('tvg%-id="%s', '')
		outm3u = outm3u:gsub('",group%-', '" group-')
		local t_pls = tvs_core.GetPlsAsTable(outm3u)
			for i = 1, #t_pls do
				t_pls[i].name = t_pls[i].name:gsub('[%s%-]*github%.com/Free%-IPTV', '')
				if t_pls[i].address == 'https://'
					or t_pls[i].address == 'http://'
					or t_pls[i].address:match('plugin://')
					or t_pls[i].name:match('^%*%*')
					or t_pls[i].group:match('Radio')
					or t_pls[i].group:match('RADIO')
				then
					t_pls[i].skip = true
				end
				if t_pls[i].group == 'GERMANY'
					and t_pls[i].address:match('%.akamai')
				then
					t_pls[i].address = t_pls[i].address .. '$OPT:http-ext-header=X-Forwarded-For:157.90.148.138'
				end
			end
		t_pls = ProcessFilterTableLocal(t_pls)
		local m3ustr = tvs_core.ProcessFilterTable(UpdateID, Source, t_pls)
		local handle = io.open(m3u_file, 'w+')
			if not handle then return end
		handle:write(m3ustr)
		handle:close()
	 return 'ok'
	end
-- debug_in_file(#t_pls .. '\n')