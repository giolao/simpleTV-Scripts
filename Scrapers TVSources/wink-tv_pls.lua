-- скрапер TVS для загрузки плейлиста "Wink TV" https://wink.rt.ru (7/3/21)
-- Copyright © 2017-2021 Nexterr | https://github.com/Nexterr-origin/simpleTV-Scripts
-- ## необходим ##
-- видоскрипт: wink-tv.lua
-- расширение дополнения httptimeshift: wink-tv-timeshift_ext.lua
-- ## переименовать каналы ##
local filter = {
	{'360 Подмосковье HD', '360 Подмосковье HD (Москва)'},
	{'5 канал', 'Пятый канал'},
	{'BOLT', 'BOLT HD'},
	{'CGTN Russian', 'CGTN Русский'},
	{'MTV', 'MTV Russia'},
	{'REN-TV HD', 'РЕН ТВ HD'},
	{'REN-TV', 'РЕН ТВ'},
	{'Sony Entertainment Television HD', 'SET HD'},
	{'Star Cinema HD', 'Star Cinema HD (Россия)'},
	{'Star Cinema', 'Star Cinema (Россия)'},
	{'Star Family HD', 'Star Family HD (Россия)'},
	{'Star Family', 'Star Family (Россия)'},
	{'Время далекое и близкое', 'Время'},
	{'Деда Мороза', 'Телеканал Деда Мороза'},
	{'Доверие', 'Москва. Доверие (Москва)'},
	{'КИНОУЖАС', 'Киноужас'},
	{'МАТЧ ПРЕМЬЕР', 'Матч! Премьер HD'},
	{'МАТЧ! ФУТБОЛ 1', 'Матч! Футбол 1 HD'},
	{'МАТЧ! ФУТБОЛ 2', 'Матч! Футбол 2 HD'},
	{'МАТЧ! ФУТБОЛ 3', 'Матч! Футбол 3 HD'},
	{'О, кино!', 'О!КИНО'},
	{'Общественное телевидение России', 'ОТР'},
	{'ПОБЕДА', 'Победа HD'},
	{'Россия-1 HD', 'Россия 1 HD'},
	{'Русский экстрим', 'Russian Extreme'},
	{'Телекомпания ПЯТНИЦА', 'Пятница'},
	}
-- ##
	module('wink-tv_pls', package.seeall)
	local my_src_name = 'Wink TV'
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
	 return {name = my_src_name, sortname = '', scraper = '', m3u = 'out_' .. my_src_name .. '.m3u', logo = '..\\Channel\\logo\\Icons\\wink.png', TypeSource = 1, TypeCoding = 1, DeleteM3U = 1, RefreshButton = 1, show_progress = 0, AutoBuild = 0, AutoBuildDay = {0, 0, 0, 0, 0, 0, 0}, LastStart = 0, TVS = {add = 1, FilterCH = 1, FilterGR = 1, GetGroup = 1, LogoTVG = 1}, STV = {add = 1, ExtFilter = 1, FilterCH = 1, FilterGR = 1, GetGroup = 1, HDGroup = 0, AutoSearch = 1, AutoNumber = 0, NumberM3U = 0, GetSettings = 1, NotDeleteCH = 0, TypeSkip = 1, TypeFind = 1, TypeMedia = 0, RemoveDupCH = 1}}
	end
	function GetVersion()
	 return 2, 'UTF-8'
	end
	local function showMess(str, color)
		local t = {text = str, color = color, showTime = 1000 * 5, id = 'channelName'}
		m_simpleTV.OSD.ShowMessageT(t)
	end
	local function wink_tv(w)
		local session = m_simpleTV.Http.New('Mozilla/5.0 (SmartHub; SMART-TV; U; Linux/SmartTV) AppleWebKit/531.2+ (KHTML, like Gecko) WebBrowser/1.0 SmartTV Safari/531.2+')
			if not session then return end
		m_simpleTV.Http.SetTimeout(session, 16000)
		require 'json'
		local t, i = {}, 1
			local function getTbl(t, k, tab, logoHost)
				local j = 1
					while tab.channels_list[j] do
						if tab.channels_list[j].isOttEncrypted == '0' then
							t[k] = {}
							t[k].name = tab.channels_list[j].bcname
							t[k].address = tab.channels_list[j].smlOttURL
							local logo
							if tab.channels_list[j].logo2 and tab.channels_list[j].logo2 ~= '' then
								logo = tab.channels_list[j].logo2
							elseif tab.channels_list[j].logo and tab.channels_list[j].logo ~= '' then
								logo = tab.channels_list[j].logo
							end
							if logo then
								t[k].logo = string.format('%s/images/%s', logoHost, logo)
							end
							k = k + 1
						end
						j = j + 1
					end
			 return t, k
			end
			for c = 1, #w do
				local url = decode64(w[c])
				local rc, answer = m_simpleTV.Http.Request(session, {url = url})
				if rc == 200 then
					answer = answer:gsub('%[%]', '""')
					local tab = json.decode(answer)
					local logoHost = url:match('^https?://[^/]+')
					if tab and tab.channels_list then
						t, i = getTbl(t, i, tab, logoHost)
					end
				end
			end
		m_simpleTV.Http.Close(session)
			if #t == 0 then return end
		local hash, t1 = {}, {}
			for i = 1, #t do
				if not hash[t[i].address] then
					t1[#t1 + 1] = t[i]
					hash[t[i].address] = true
				end
			end
		local t0 = {}
			for _, v in pairs(t1) do
				if v.address:match('^http')
					and v.address:match('/CH_')
					and not (
							v.address:match('TEST')
							or v.name:match('^Тест')
							or v.name:match('^Test')
							or v.name:match('Sberbank')
							or v.address:match('_OTT/')
							or v.address:match('_WINK')
							or v.address:match('_R%d+_') -- региональные
							)
					or v.address:match('rostelecom%.m3u8')
				then
					v.name = v.name:gsub('^Телеканал', '')
					v.name = v.name:gsub(' SD', '')
					v.name = v.name:gsub('«', '')
					v.name = v.name:gsub('»', '')
					v.name = v.name:gsub('"', '')
					v.name = v.name:gsub(':%s', ' ')
					v.name = v.name:gsub('^Канал', '')
					v.name = v.name:gsub('%.%s*$', '')
					if v.address:match('/CH_1TV/') then
						v.name = 'Первый канал HD'
					end
					if v.address:match('/CH_1TVSD/') then
						v.name = 'Первый канал'
					end
					if not v.address:match('rostelecom%.m3u8') then
						v.RawM3UString = 'catchup="append" catchup-days="3" catchup-source="?offset=-${offset}&utcstart=${timestamp}" catchup-record-source="?utcstart=${start}&utcend=${end}"'
					end
					t0[#t0 + 1] = v
				end
			end
			if #t0 == 0 then return end
	 return t0
	end
	function GetList(UpdateID, m3u_file)
			if not UpdateID then return end
			if not m3u_file then return end
			if not TVSources_var.tmp.source[UpdateID] then return end
		local Source = TVSources_var.tmp.source[UpdateID]
		local w = {
		'aHR0cHM6Ly9mZS1tb3Muc3ZjLmlwdHYucnQucnUvQ2FjaGVDbGllbnRKc29uL2pzb24vQ2hhbm5lbFBhY2thZ2UvbGlzdF9jaGFubmVscz9jaGFubmVsUGFja2FnZUlkPTg0NDE1OTU3JmxvY2F0aW9uSWQ9NzAwMDAxJmZyb209MCZ0bz0yMTQ3NDgzNjQ3',
		'aHR0cHM6Ly9mZS5zdmMuaXB0di5ydC5ydS9DYWNoZUNsaWVudEpzb24vanNvbi9DaGFubmVsUGFja2FnZS9saXN0X2NoYW5uZWxzP2NoYW5uZWxQYWNrYWdlSWQ9MTUyOTA4NCZsb2NhdGlvbklkPTEwMDAwMSZmcm9tPTAmdG89MjE0NzQ4MzY0Nw',
		}
		local t_pls = wink_tv(w)
			if not t_pls then
				showMess(Source.name .. ' ошибка загрузки плейлиста', ARGB(255, 255, 102, 0))
			 return
			end
		t_pls = ProcessFilterTableLocal(t_pls)
		showMess(Source.name .. ' (' .. #t_pls .. ')', ARGB(255, 153, 255, 153))
		local m3ustr = tvs_core.ProcessFilterTable(UpdateID, Source, t_pls)
		local handle = io.open(m3u_file, 'w+')
			if not handle then return end
		handle:write(m3ustr)
		handle:close()
	 return 'ok'
	end
-- debug_in_file(#t_pls .. '\n')