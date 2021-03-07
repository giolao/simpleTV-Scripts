-- видеоскрипт для плейлиста "Страх ТВ" https://strah.video (15/2/21)
-- Copyright © 2017-2021 Nexter | https://github.com/Nexterr-origin/simpleTV-Scripts
-- ## необходим ##
-- скрапер TVS: strah_pls.lua
-- модуль: /core/playerjs.lua
-- открывает подобные ссылки:
-- https://strah.video/id/1
		if m_simpleTV.Control.ChangeAddress ~= 'No' then return end
		if not m_simpleTV.Control.CurrentAddress:match('^https?://strah%.video/id/%d') then return end
	if m_simpleTV.Control.MainMode == 0 then
		m_simpleTV.Interface.SetBackground({BackColor = 0, PictFileName = 'https://strah.video/style/strah.png', TypeBackColor = 0, UseLogo = 1, Once = 1})
	end
	local inAdr = m_simpleTV.Control.CurrentAddress
	require 'playerjs'
	m_simpleTV.Control.ChangeAdress = 'Yes'
	m_simpleTV.Control.CurrentAdress = 'error'
	local userAgent = 'Mozilla/5.0 (Windows NT 10.0; rv:85.0) Gecko/20100101 Firefox/85.0'
	local session = m_simpleTV.Http.New(userAgent)
		if not session then return end
	m_simpleTV.Http.SetTimeout(session, 12000)
	local function showErr(str)
		m_simpleTV.OSD.ShowMessageT({text = 'strah ошибка: ' .. str, showTime = 1000 * 5, color = ARGB(255, 255, 102, 0), id = 'channelName'})
	end
	local id = inAdr:match('%d+')
	local host = inAdr:match('^https?://[^/]+')
	local url = 'https://strah.video/stream?if=' .. id
	local headers = 'Referer: ' .. inAdr
	local rc, answer = m_simpleTV.Http.Request(session, {url = url, headers = headers})
		if rc ~= 200 then
			m_simpleTV.Http.Close(session)
			showErr('1')
		 return
		end
	answer = answer:gsub('%s+', '')
	answer = answer:gsub('<!%-%-.-%-%->', ''):gsub('/%*.-%*/', '')
	local retAdr = answer:match('[\'"]:[\'"](#[^\'"]+)')
		if not retAdr then
			showErr('2')
		 return
		end
	local playerjs_url = answer:match('"text/javascript"src="(/[^"]+)')
		if not playerjs_url then
			showErr('3')
		 return
		end
	playerjs_url = host .. playerjs_url
	local rc, answer = m_simpleTV.Http.Request(session, {url = playerjs_url, headers = headers})
	m_simpleTV.Http.Close(session)
		if rc ~= 200 then
			showErr('4')
		 return
		end
	retAdr = playerjs.decode(retAdr, playerjs_url)
		if not retAdr
			or retAdr == ''
		then
			showErr('5')
		 return
		end
	local v1 = answer:match('StrahVideoStreamHttp%s*=%s*"([^"]+)') or ''
	local v2 = answer:match('StrahVideoStreamPort%s*=%s*"([^"]+)') or ''
	local v3 = answer:match('StrahVideoStreamLive%s*=%s*"([^"]+)') or ''
	local v4 = answer:match('StrahVideoStreamPlaylist%s*=%s*"([^"]+)') or ''
	local v5 = answer:match('StrahVideoStreamOther%s*=%s*"([^"]+)') or ''
	retAdr = retAdr:gsub('{v1}', v1):gsub('{v2}', v2):gsub('{v3}', v3):gsub('{v4}', v4):gsub('{v5}', v5)
	retAdr = retAdr:gsub('%[%d+%]', ''):gsub('amp;', '')
	retAdr = retAdr .. '$OPT:http-referrer=' .. inAdr .. '$OPT:http-user-agent=' .. userAgent
	m_simpleTV.Control.CurrentAddress = retAdr
-- debug_in_file(retAdr .. '\n')