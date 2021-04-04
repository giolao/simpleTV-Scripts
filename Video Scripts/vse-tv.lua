-- видеоскрипт для сайта https://vse-tv.net (5/4/21)
-- Copyright © 2017-2021 Nexterr | https://github.com/Nexterr-origin/simpleTV-Scripts
-- ## авторизация ##
-- логин, пароль установить в дополнении 'Password Manager', для id - vsetv
-- ## открывает подобные ссылки ##
-- https://vse-tv.net/tv_channel/4-made_in_ussr.html
-- ##
		if m_simpleTV.Control.ChangeAddress ~= 'No' then return end
		if not m_simpleTV.Control.CurrentAddress:match('^https?://vse%-tv%.net/.+') then return end
	if m_simpleTV.Control.MainMode == 0 then
		m_simpleTV.Interface.SetBackground({BackColor = 0, PictFileName = '', TypeBackColor = 0, UseLogo = 0, Once = 1})
	end
	local inAdr = m_simpleTV.Control.CurrentAddress
	m_simpleTV.Control.ChangeAddress = 'Yes'
	m_simpleTV.Control.CurrentAddress = 'error'
	local session = m_simpleTV.Http.New('Mozilla/5.0 (Windows NT 10.0; rv:86.0) Gecko/20100101 Firefox/86.0')
		if not session then return end
	m_simpleTV.Http.SetTimeout(session, 8000)
	if not m_simpleTV.User then
		m_simpleTV.User = {}
	end
	if not m_simpleTV.User.vsetv then
		m_simpleTV.User.vsetv = {}
	end
	local function showMsg(str)
		local t = {text = 'vse-tv ошибка: ' .. str, showTime = 1000 * 8, color = ARGB(255, 255, 102, 0), id = 'channelName'}
		m_simpleTV.OSD.ShowMessageT(t)
	end
	local function getCookies()
		local error_text, pm = pcall(require, 'pm')
			if not package.loaded.pm then return end
		local ret, login, pass = pm.GetTestPassword('vsetv', 'vsetv', true)
			if not login
				or not pass
				or login == ''
				or pass == ''
			then
			 return
			end
		login = m_simpleTV.Common.toPercentEncoding(login)
		pass = m_simpleTV.Common.toPercentEncoding(pass)
		local body = string.format('login_name=%s&login_password=%s&login=submit', login, pass)
		local headers = 'Content-Type: application/x-www-form-urlencoded\nReferer: Referer: https://vse-tv.net/login.html\nOrigin: https://vse-tv.net'
		local url = 'https://vse-tv.net/login.html'
		local rc, answer = m_simpleTV.Http.Request(session, {body = body, url = url, method = 'post', headers = headers})
			if rc ~= 200 then
			 return ''
			end
	 return m_simpleTV.Http.GetCookies(session, url, '')
	end
	if not m_simpleTV.User.vsetv.cookies then
		local cookies = getCookies()
			if not cookies then
				showMsg('1\nлогин, пароль установить в дополнении "Password Manager"\nдля id - vsetv')
			 return
			end
		m_simpleTV.User.vsetv.cookies = cookies:gsub('__cfduid=[^;]+;', '')
	end
	m_simpleTV.Http.SetCookies(session, inAdr, '', m_simpleTV.User.vsetv.cookies)
	local rc, answer = m_simpleTV.Http.Request(session, {url = inAdr, headers = 'Referer: https://vse-tv.net/tv_channel/\nAlt-Used: vse-tv.net'})
	m_simpleTV.Http.Close(session)
		if rc ~= 200 then
			showMsg('2')
		 return
		end
	local retAdr = answer:match('file:%s*["\']([^"\']+)')
		if not retAdr then
			m_simpleTV.User.vsetv.cookies = nil
			showMsg('3')
		 return
		end
	if retAdr:match('%.mp4') then
		m_simpleTV.User.vsetv.cookies = nil
	end
	retAdr = retAdr .. '$OPT:http-referrer=' .. inAdr
	m_simpleTV.Control.CurrentAddress = retAdr
-- debug_in_file(retAdr .. '\n')