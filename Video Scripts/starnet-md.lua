-- видеоскрипт для плейлиста "StarNet" https://www.starnet.md (1/4/21)
-- Copyright © 2017-2021 Nexterr | https://github.com/Nexterr-origin/simpleTV-Scripts
-- ## необходим ##
-- скрапер TVS: starnet-md_pls.lua
-- ## открывает подобные ссылки ##
-- http://starnet-md.CANAL2_H264
-- ##
		if m_simpleTV.Control.ChangeAddress ~= 'No' then return end
		if not m_simpleTV.Control.CurrentAddress:match('^https?://starnet%-md%.') then return end
	if m_simpleTV.Control.MainMode == 0 then
		m_simpleTV.Interface.SetBackground({BackColor = 0, PictFileName = '', TypeBackColor = 0, UseLogo = 0, Once = 1})
	end
	local inAdr = m_simpleTV.Control.CurrentAddress
	m_simpleTV.Control.ChangeAddress = 'Yes'
	m_simpleTV.Control.CurrentAddress = 'error'
	local session = m_simpleTV.Http.New('Mozilla/5.0 (Linux; U; Android 4.1.1; POV_TV-HDMI-200BT Build/JRO03H) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Safari/534.30')
		if not session then return end
	m_simpleTV.Http.SetTimeout(session, 8000)
	local id = inAdr:gsub('^.-%.', '')
	local url = decode64('aHR0cDovL3Rva2VuLnN0Yi5tZC9hcGkvRmx1c3NvbmljL3N0cmVhbS8') .. id .. '/metadata.json'
	local rc, answer = m_simpleTV.Http.Request(session, {url = url})
	m_simpleTV.Http.Close(session)
		if rc ~= 200 then return end
	local retAdr = answer:match('"url":"([^"]+)')
		if not retAdr then return end
	retAdr = retAdr .. '$OPT:adaptive-logic=highest'
	m_simpleTV.Control.CurrentAddress = retAdr
-- debug_in_file(retAdr .. '\n')