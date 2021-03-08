-- видеоскрипт для плейлиста "corntv" http://corntv.ru (7/3/21)
-- Copyright © 2017-2021 Nexterr | https://github.com/Nexterr-origin/simpleTV-Scripts
-- ## необходим ##
-- скрапер TVS: corntv_pls.lua
-- видеоскрипт: mediavitrina.lua
-- ## открывает подобные ссылки ##
-- http://corntv.ru/live-tv/ru-tv.html
-- http://corntv.ru/live-tv/sts.html
-- ##
		if m_simpleTV.Control.ChangeAddress ~= 'No' then return end
		if not m_simpleTV.Control.CurrentAddress:match('^https?://corntv%.ru/live') then return end
	if m_simpleTV.Control.MainMode == 0 then
		m_simpleTV.Interface.SetBackground({BackColor = 0, PictFileName = '', TypeBackColor = 0, UseLogo = 0, Once = 1})
	end
	local inAdr = m_simpleTV.Control.CurrentAddress
	m_simpleTV.Control.ChangeAddress = 'Yes'
	m_simpleTV.Control.CurrentAddress = 'error'
	local session = m_simpleTV.Http.New('Mozilla/5.0 (Windows NT 10.0; rv:83.0) Gecko/20100101 Firefox/83.0')
		if not session then return end
	m_simpleTV.Http.SetTimeout(session, 16000)
	local rc, answer = m_simpleTV.Http.Request(session, {url = inAdr})
	m_simpleTV.Http.Close(session)
		if rc ~= 200 then return end
	answer = answer:gsub('%s+', '')
	local retAdr = answer:match('http[^\'\"<>]+%.m3u8[^<>\'\"]*')
					or answer:match('http[^\'\"<>]+%.mediavitrina[^<>\'\"]*')
		if not retAdr then return end
		if retAdr:match('mediavitrina') then
			m_simpleTV.Control.ChangeAddress = 'No'
			m_simpleTV.Control.CurrentAddress = retAdr
			dofile(m_simpleTV.MainScriptDir .. 'user\\video\\video.lua')
		 return
		end
	m_simpleTV.Control.CurrentAddress = retAdr
-- debug_in_file(retAdr .. '\n')