-- видеоскрипт для плейлиста "TV+ HD" http://www.tvplusonline.ru (20/3/21)
-- Copyright © 2017-2021 Nexterr | https://github.com/Nexterr-origin/simpleTV-Scripts
-- ## необходим ##
-- скрапер TVS: tv+hd_pls.lua
-- расширение дополнения httptimeshift: tvhd-timeshift_ext.lua
-- ## открывает подобные ссылки ##
-- https://tv+hd.perviyhd
-- ##
		if m_simpleTV.Control.ChangeAddress ~= 'No' then return end
		if not m_simpleTV.Control.CurrentAddress:match('^https?://tv%+hd%.(%w+)') then return end
	local inAdr = m_simpleTV.Control.CurrentAddress
	if m_simpleTV.Control.MainMode == 0 then
		m_simpleTV.Interface.SetBackground({BackColor = 0, TypeBackColor = 0, PictFileName = '', UseLogo = 0, Once = 1})
	end
	m_simpleTV.Control.ChangeAddress = 'Yes'
	m_simpleTV.Control.CurrentAddress = 'error'
	local userAgent = 'Mozilla/5.0 (Windows NT 10.0; rv:86.0) Gecko/20100101 Firefox/86.0'
	local session = m_simpleTV.Http.New(userAgent)
		if not session then return end
	m_simpleTV.Http.SetTimeout(session, 8000)
	local id = inAdr:match('%.(%w+)')
	local url
	if inAdr:match('&plus=true') then
		url = string.format(decode64('aHR0cHM6Ly93d3cudHZwbHVzb25saW5lLnJ1L2dldHNpZ25lZGR2ci5waHA/ZHVyYXRpb249NjAwJnN0cmVhbT0lcyZ0aW1lPSVz'), id, os.time() - 600)
		-- url = decode64('aHR0cHM6Ly93d3cudHZwbHVzc3RyZWFtaW5nLnJ1L2dldHNpZ25lZHVybGNkbnY0LnBocD9xPTAmcD1hJnM9MCZjPQ') .. id
	else
		url = decode64('aHR0cHM6Ly93d3cudHZwbHVzb25saW5lLnJ1L2FwaS9jaGFubmVscy9obHMv') .. id
	end
	local rc, answer = m_simpleTV.Http.Request(session, {url = url})
	m_simpleTV.Http.Close(session)
		if rc ~= 200 then return end
	answer = answer:gsub('\\/', '/')
	local retAdr = answer:match('https?://[^%s"]+')
		if not retAdr then return end
	retAdr = retAdr:gsub('^(.+)%-dvr/.-(%..-)$', '%1-dvr/timeshift_rel-20%2')
	retAdr = retAdr:gsub('/index.-%.m3u8', '/index.m3u8')
	m_simpleTV.Control.CurrentAddress = retAdr
-- debug_in_file(retAdr .. '\n')
