-->> Информация
script_name							('Logging Central Market')
script_author						('Rice.')
script_version					('12.02.2023')
script_version_number		(1)

-->> Зависимости
local samp 						= require('samp.events')
local imgui 					= require('mimgui')
local ffi 						= require('ffi')
local encoding 				= require('encoding')
encoding.default 			= 'CP1251'
u8 = encoding.UTF8

-->> Переменные
local window 					= imgui.new.bool(false)
local search_text 		= imgui.new.char[128]()
local date_select 		= nil

function main()
	if not isSampfuncsLoaded() or not isSampLoaded() then return end
	while not isSampAvailable() do wait(100) end

	-->> Log Json
	log_json = json(thisScript().name .. '.json'):Load({})

	-->> Others
	sms('Скрипт {mc}загружен{-1}!')
	sms('Активация: {mc}/logm{-1}.')
	sampRegisterChatCommand('logm', function() window[0] = not window[0] end)

	wait(-1)
end

imgui.OnInitialize(function()
	imgui.GetIO().Fonts:Clear(); imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 20, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
  imgui.GetIO().IniFilename = nil
  theme()
end)

local newFrame = imgui.OnFrame(
	function() return window[0] and not isPauseMenuActive() and not sampIsScoreboardOpen() end,
	function(player)
	  imgui.SetNextWindowPos(imgui.ImVec2(select(1, getScreenResolution()) / 2, select(2, getScreenResolution()) / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	  imgui.SetNextWindowSize(imgui.ImVec2(1000, 500), imgui.Cond.FirstUseEver)
		imgui.Begin(thisScript().name, window, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse)

		if imgui.Button(u8('Выбрать дату'), imgui.ImVec2(-1, 30)) then imgui.OpenPopup(u8('Выбор даты')) end; change_date()

		imgui.BeginChild('date_select', imgui.ImVec2(-1, 30), true)
			imgui.CenterText(u8(string.format('Выбранная дата: %s', date_select == nil and 'Не выбрано' or date_select)))
		imgui.EndChild()

		imgui.BeginChild('money_stats', imgui.ImVec2(-1, 80), true)
			imgui.CenterText(u8('Статистика:'))
			imgui.BeginChild('sub_money_stats', imgui.ImVec2(-1, -1), false)
				if log_json[date_select] == nil then
					local text = u8('Здесь пока ничего нету :(')
					imgui.SetCursorPos(imgui.ImVec2((imgui.GetWindowWidth() - imgui.CalcTextSize(text).x) / 2, (imgui.GetWindowHeight() - imgui.CalcTextSize(text).y) / 2))
					imgui.TextColored(imgui.ImVec4(0.50, 0.50, 0.50, 0.50), text)
				else
					imgui.BeginGroup()
						imgui.CenterText(u8('Получили с продажи: ') .. (log_json[date_select].table[2] ~= nil and ('$' .. money_separator(log_json[date_select].table[2])) or u8('Информация не получена')), imgui.GetWindowWidth() * 0.5)
						imgui.CenterText(u8('Потратили на покупку: ') .. (log_json[date_select].table[3] ~= nil and ('$' .. money_separator(log_json[date_select].table[3])) or u8('Информация не получена')), imgui.GetWindowWidth() * 0.5)
					imgui.EndGroup()
					imgui.SameLine()
					imgui.BeginGroup()
						imgui.CenterText(u8('Получили с продажи: ') .. (log_json[date_select].table[4] ~= nil and ('VC$' .. money_separator(log_json[date_select].table[4])) or u8('Информация не получена')), imgui.GetWindowWidth() * 1.5)
						imgui.CenterText(u8('Потратили на покупку: ') .. (log_json[date_select].table[5] ~= nil and ('VC$' .. money_separator(log_json[date_select].table[5])) or u8('Информация не получена')), imgui.GetWindowWidth() * 1.5)
					imgui.EndGroup()
				end
			imgui.EndChild()
		imgui.EndChild()

		imgui.PushItemWidth(-1); imgui.InputTextWithHint('##search_text', u8('Поиск по товарам'), search_text, ffi.sizeof(search_text)); imgui.PopItemWidth()

		imgui.BeginChild('log', imgui.ImVec2(-1, -1), true)
			imgui.CenterText(u8('Лог товаров:'))
			imgui.BeginChild('sub_log', imgui.ImVec2(-1, -1), false)
				if log_json[date_select] == nil then
					local text = u8('Здесь пока ничего нету :(')
					imgui.SetCursorPos(imgui.ImVec2((imgui.GetWindowWidth() - imgui.CalcTextSize(text).x) / 2, (imgui.GetWindowHeight() - imgui.CalcTextSize(text).y) / 2))
					imgui.TextColored(imgui.ImVec4(0.50, 0.50, 0.50, 0.50), text)
				else
					for i = #log_json[date_select].table[1], 1, -1 do
						if u8:decode(ffi.string(search_text)) ~= 0 and string.find(string.nlower(log_json[date_select].table[1][i]), string.nlower(u8:decode(ffi.string(search_text))), nil, true) then
							imgui.Text(u8(log_json[date_select].table[1][i]))
						end
					end
				end
			imgui.EndChild()
		imgui.EndChild()

		imgui.End()
	end
)

function change_date()
		if imgui.BeginPopupModal(u8('Выбор даты'), _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize) then
			imgui.SetWindowSizeVec2(imgui.ImVec2(300, 300))

			imgui.BeginChild('up', imgui.ImVec2(-1, imgui.GetWindowWidth() - 70), true)
				local temp_table = {}
				for k, v in pairs(log_json) do table.insert(temp_table, {key = k, date = v.date}) end
				table.sort(temp_table, function(a, b) return a.date > b.date end)

				for k, v in ipairs(temp_table) do
					if imgui.Button(v.key, imgui.ImVec2(-1)) then date_select = v.key; imgui.CloseCurrentPopup() end
				end
			imgui.EndChild()

			if imgui.Button(u8('Закрыть'), imgui.ImVec2(-1, -1)) then
				imgui.CloseCurrentPopup()
			end

			imgui.EndPopup()
		end
end

function samp.onServerMessage(color, text)
	local hook_central_market = {
		{hook = '^%s*(.+) купил у вас (.+), вы получили(.+)$(.+) от продажи', key = 2},
		{hook = '^%s*(.+) заказал у вас (.+), вы получили(.+)$(.+) от продажи', key = 2},
		{hook = '^%s*Вы купили (.+) у игрока (.+) за(.+)$(.+)', key = 3}
	}

	for k, v in ipairs(hook_central_market) do
		if string.find(text, v.hook) then

			if v.key == 2 then
				name, item, vc, money = text:match(v.hook)
			else
				item, name, vc, money = text:match(v.hook)
			end

			local money = string_to_count(money)

			if text:find('купил у вас') then
				text_log = string.format('%s %s купил "%s" за%s$%s', os.date('[%H:%M:%S]'), name, item, vc, money_separator(money))
			elseif text:find('заказал у вас') then
				text_log = string.format('%s %s заказал (GLOVO) "%s" за%s$%s', os.date('[%H:%M:%S]'), name, item, vc, money_separator(money))
			elseif text:find('Вы купили') then
				text_log = string.format('%s %s продал "%s" за%s$%s', os.date('[%H:%M:%S]'), name, item, vc, money_separator(money))
			end

			if log_json[os.date('%d.%m.%Y')] == nil then
				log_json[os.date('%d.%m.%Y')] = {
					date = tonumber(os.date('%Y%m%d')),
					table = {{}, 0, 0, 0, 0}
				}
			end

			table.insert(log_json[os.date('%d.%m.%Y')].table[1], text_log)
			log_json[os.date('%d.%m.%Y')].table[(#vc == 3 and v.key + 2 or v.key)] = log_json[os.date('%d.%m.%Y')].table[(#vc == 3 and v.key + 2 or v.key)] + money
			save()
		end
	end
end

function imgui.CenterText(text, size)
	local size = size or imgui.GetWindowWidth()
	imgui.SetCursorPosX((size - imgui.CalcTextSize(tostring(text)).x) / 2)
	imgui.Text(tostring(text))
end

function sms(text)
	local color_chat = '7172ee'
	local text = tostring(text):gsub('{mc}', '{' .. color_chat .. '}'):gsub('{%-1}', '{FFFFFF}')
	sampAddChatMessage(string.format('« %s » {FFFFFF}%s', thisScript().name, text), tonumber('0x' .. color_chat))
end

function money_separator(n)
    local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
    return left..(num:reverse():gsub('(%d%d%d)','%1.'):reverse())..right
end

function string_to_count(text)
	local count = ''
	for line in text:gmatch('%d') do
		count = count .. line
	end
	return tonumber(count)
end

function json(filePath)
    local filePath = getWorkingDirectory()..'\\config\\'..(filePath:find('(.+).json') and filePath or filePath..'.json')
    local class = {}
    if not doesDirectoryExist(getWorkingDirectory()..'\\config') then
        createDirectory(getWorkingDirectory()..'\\config')
    end
    function class:Save(tbl)
        if tbl then
            local F = io.open(filePath, 'w')
            F:write(encodeJson(tbl) or {})
            F:close()
            return true, 'ok'
        end
        return false, 'table = nil'
    end
    function class:Load(defaultTable)
        if not doesFileExist(filePath) then
        	class:Save(defaultTable or {})
        end
        local F = io.open(filePath, 'r+')
        local TABLE = decodeJson(F:read() or {})
        F:close()
        for def_k, def_v in next, defaultTable do
            if TABLE[def_k] == nil then
                TABLE[def_k] = def_v
            end
        end
        return TABLE
    end
    return class
end

function string.nlower(s)
	local line_lower = string.lower(s)
	for line in s:gmatch('.') do
		if (string.byte(line) >= 192 and string.byte(line) <= 223) or string.byte(line) == 168 then
			line_lower = string.gsub(line_lower, line, string.char(string.byte(line) == 168 and string.byte(line) + 16 or string.byte(line) + 32), 1)
		end
	end
	return line_lower
end

function save()
	local status, code = json(thisScript().name .. '.json'):Save(log_json)
	if not status then sms('Ошибка: {mc}' .. code) end
end

function theme()
	imgui.SwitchContext()
	local style = imgui.GetStyle()
	local colors = style.Colors
	local clr = imgui.Col
	local ImVec4 = imgui.ImVec4

	-->> Sizez
	imgui.GetStyle().WindowPadding = imgui.ImVec2(4, 4)
	imgui.GetStyle().FramePadding = imgui.ImVec2(4, 3)
	imgui.GetStyle().ItemSpacing = imgui.ImVec2(8, 4)
	imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(4, 4)
	imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(0, 0)

	imgui.GetStyle().IndentSpacing = 21
	imgui.GetStyle().ScrollbarSize = 14
	imgui.GetStyle().GrabMinSize = 10

	imgui.GetStyle().WindowBorderSize = 0
	imgui.GetStyle().ChildBorderSize = 1
	imgui.GetStyle().PopupBorderSize = 1
	imgui.GetStyle().FrameBorderSize = 1
	imgui.GetStyle().TabBorderSize = 0

	imgui.GetStyle().WindowRounding = 5
	imgui.GetStyle().ChildRounding = 5
	imgui.GetStyle().PopupRounding = 5
	imgui.GetStyle().FrameRounding = 5
	imgui.GetStyle().ScrollbarRounding = 5
	imgui.GetStyle().GrabRounding = 5
	imgui.GetStyle().TabRounding = 5

	imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.50, 0.50)

	-->> Colors
	colors[clr.Text]                   = ImVec4(1.00, 1.00, 1.00, 1.00)
	colors[clr.TextDisabled]           = ImVec4(0.50, 0.50, 0.50, 1.00)

	colors[clr.WindowBg]               = ImVec4(0.15, 0.16, 0.37, 1.00)
	colors[clr.ChildBg]                = ImVec4(0.17, 0.18, 0.43, 1.00)
	colors[clr.PopupBg]                = colors[clr.WindowBg]

	colors[clr.Border]                 = ImVec4(0.33, 0.34, 0.62, 1.00);
	colors[clr.BorderShadow]           = ImVec4(0.65, 0.60, 0.60, 0.00)

	colors[clr.TitleBg]                = ImVec4(0.18, 0.20, 0.46, 1.00)
	colors[clr.TitleBgActive]          = ImVec4(0.18, 0.20, 0.46, 1.00)
	colors[clr.TitleBgCollapsed]       = ImVec4(0.18, 0.20, 0.46, 1.00)
	colors[clr.MenuBarBg]              = ImVec4(1.00, 0.51, 0.51, 1.00)

	colors[clr.ScrollbarBg]            = ImVec4(0.14, 0.14, 0.36, 1.00)
	colors[clr.ScrollbarGrab]          = ImVec4(0.22, 0.22, 0.53, 1.00)
	colors[clr.ScrollbarGrabHovered]   = ImVec4(0.20, 0.21, 0.53, 1.00)
	colors[clr.ScrollbarGrabActive]    = ImVec4(0.25, 0.25, 0.58, 1.00)

	colors[clr.Button]                 = ImVec4(0.25, 0.25, 0.58, 1.00)
	colors[clr.ButtonHovered]          = ImVec4(0.23, 0.23, 0.55, 1.00)
	colors[clr.ButtonActive]           = ImVec4(0.27, 0.27, 0.62, 1.00)

	colors[clr.CheckMark]              = ImVec4(0.39, 0.39, 0.83, 1.00)
	colors[clr.SliderGrab]             = ImVec4(0.39, 0.39, 0.83, 1.00)
	colors[clr.SliderGrabActive]       = ImVec4(0.48, 0.48, 0.96, 1.00)

	colors[clr.FrameBg]                = colors[clr.Button]
	colors[clr.FrameBgHovered]         = colors[clr.ButtonHovered]
	colors[clr.FrameBgActive]          = colors[clr.ButtonActive]

	colors[clr.Header]                 = ImVec4(0.26, 0.59, 0.98, 0.31)
	colors[clr.HeaderHovered]          = ImVec4(0.26, 0.59, 0.98, 0.80)
	colors[clr.HeaderActive]           = ImVec4(0.26, 0.59, 0.98, 1.00)

	colors[clr.Separator]              = ImVec4(0.43, 0.43, 0.50, 0.50)
	colors[clr.SeparatorHovered]       = ImVec4(0.10, 0.40, 0.75, 0.78)
	colors[clr.SeparatorActive]        = ImVec4(0.10, 0.40, 0.75, 1.00)

	colors[clr.ResizeGrip]             = colors[clr.Button]
	colors[clr.ResizeGripHovered]      = colors[clr.ButtonHovered]
	colors[clr.ResizeGripActive]       = colors[clr.ButtonActive]

	colors[clr.Tab]                    = ImVec4(0.45, 0.49, 0.54, 0.86)
	colors[clr.TabHovered]             = ImVec4(0.45, 0.50, 0.54, 0.80)
	colors[clr.TabActive]              = ImVec4(0.60, 0.60, 0.60, 1.00)
	colors[clr.TabUnfocused]           = ImVec4(0.07, 0.10, 0.15, 0.97)
	colors[clr.TabUnfocusedActive]     = ImVec4(0.54, 0.59, 0.65, 1.00)

	colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00)
	colors[clr.PlotLinesHovered]       = ImVec4(1.00, 0.43, 0.35, 1.00)
	colors[clr.PlotHistogram]          = ImVec4(0.90, 0.70, 0.00, 1.00)
	colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 0.60, 0.00, 1.00)

	colors[clr.TextSelectedBg]         = ImVec4(0.64, 0.67, 0.71, 0.35)
	colors[clr.DragDropTarget]         = ImVec4(1.00, 1.00, 0.00, 0.90)

	colors[clr.NavHighlight]           = ImVec4(0.26, 0.59, 0.98, 1.00)
	colors[clr.NavWindowingHighlight]  = ImVec4(1.00, 1.00, 1.00, 0.70)
	colors[clr.NavWindowingDimBg]      = ImVec4(0.80, 0.80, 0.80, 0.20)

	colors[clr.ModalWindowDimBg]       = ImVec4(0.00, 0.00, 0.00, 0.90)
end
