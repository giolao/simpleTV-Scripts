-- видеоскрипт для плейлиста "TV+ HD" http://www.tvplusonline.ru (7/3/21)
-- Copyright © 2017-2021 Nexterr | https://github.com/Nexterr-origin/simpleTV-Scripts
-- ## необходим ##
-- скрапер TVS: tv+hd_pls.lua
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
	local userAgent = 'Dalvik/2.1.0 (Linux; Android 7.1.2;)'
	local session = m_simpleTV.Http.New(userAgent)
		if not session then return end
	m_simpleTV.Http.SetTimeout(session, 8000)
	local id = inAdr:gsub('^.-%.(%w+)', '%1')
	local url = 'https://www.tvplusonline.ru/api/channels/hls/'.. id
	url = url:gsub('$OPT:.+', '')
	local rc, answer = m_simpleTV.Http.Request(session, {url = url})
	m_simpleTV.Http.Close(session)
		if rc ~= 200 then return end
	local retAdr = answer:match('"url":"([^"]+)')
	if retAdr then
		retAdr = string.format('%s$OPT:no-gnutls-system-trust$OPT:http-user-agent=%s', retAdr:gsub('\\/', '/'), userAgent)
		m_simpleTV.Control.CurrentAddress = retAdr
	end
-- debug_in_file(retAdr .. '\n')
