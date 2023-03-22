script_authors('Yondime')
script_version('2.3')
script_description('Автоматическое Выставление товаров на скупку и продажу')

local imgui = require 'imgui'
local encoding = require 'encoding'
local sampev = require 'lib.samp.events'
local inicfg = require 'inicfg'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local itemsBuy, inputs, itemsSell, inputsSell = ({}), {}, ({}), {}

local cfg = inicfg.load(itemsBuy,'Central Market\\ARZCentral')
local cfgsell = inicfg.load({
    itemsSellm = {}
},'Central Market\\ARZCentral-sell')
local settings = inicfg.load({
    main = {
        delayParse = 200,
        delayVist = 400,
        delayDelete = 1500,
        color = '9a9a9a',
        colormsg = 0xFF9a9a9a,
        stylemode = 0
    }
}, 'Central Market\\ARZCentral-settings')

local allWindow = imgui.ImBool(false)
local last_list = nil
local mainWindowState, sellWindowState, settingWindowState, secondarySellWindowState, secondaryWindowState, presetWindowState, delprod = true, false, false, false, false, false, false, false
local rbut, findBuf, findBufInt, parserBuf, delayInt, delayDelete, afilename, selectPresetMode, selectStyle = imgui.ImInt(1), imgui.ImBuffer(124), imgui.ImInt(0), imgui.ImInt(settings.main.delayParse), imgui.ImInt(settings.main.delayVist), imgui.ImInt(settings.main.delayDelete), imgui.ImBuffer(200), imgui.ImInt(1), imgui.ImInt(-1)

function main()
    while not isSampAvailable() do wait(0) end
    if not doesDirectoryExist(getWorkingDirectory()..'/config/Central Market/preset-sell') or not doesDirectoryExist(getWorkingDirectory()..'/config/Central Market/preset-buy') then createDirectory('moonloader\\config\\Central Market\\preset-sell') createDirectory('moonloader\\config\\Central Market\\preset-buy') end
    if not doesFileExist('moonloader/config/Central Market/ARZCentral.ini') or not doesFileExist('moonloader/config/Central Market/ARZCentral-sell.ini') or not doesFileExist('moonloader/config/Central Market/ARZCentral-settings.ini') then inicfg.save(itemsBuy, 'Central Market\\ARZCentral.ini') inicfg.save(cfgsell, 'Central Market\\ARZCentral-sell.ini') inicfg.save(settings, 'Central Market\\ARZCentral-settings') end
    sampAddChatMessage('[ Central Market ]: {FFFFFF}Скрипт загружен. Команда активации: {'..settings.main.color..'}/crmenu{FFFFFF}. Автор: {'..settings.main.color..'}Yondime', settings.main.colormsg)
    sampRegisterChatCommand('crmenu', function( )
        allWindow.v = not allWindow.v imgui.Process = allWindow.v
    end)
    wait(-1)
end

function sampev.onServerMessage(color, text)
    if delprod and text:find('У вас нет выставленного товара') then
        sampAddChatMessage('[ Central Market ]: {FFFFFF}Товары сняты. Можете просканировать заново или выставить товар.', settings.main.colormsg)   
        delprod = not delprod
    end
end

function sampev.onShowDialog(id, style, title, button1, button2, text) -- хук диалога
    if id == 3050 and check then -- тут мы парсим список товаров на скуп
        lua_thread.create(parserPage, text, title) 
        sampShowDialog(1235, '{'..settings.main.color..'}[ Central Market ]: {FFFFFF}CHECKING', '{02c733}Идёт проверка предметов! Нужно чуть подождать :)', 'Ждём!')
        return false
    end
    if id == 3040 then
        if delprod then
            sampSendDialogResponse(id, 1, delprodc)
        end
        text = text .. '\n \n{'.. settings.main.color .. "}Central Market - Menu"
        last_list = select(2, string.gsub(text, "\n", "\n")) -- get lines count
        return {id, style, title, button1, button2, text}
    end
    if id == 3050 and delprod then
        local i = 0
        for n in text:gmatch('[^\r\n]+') do
            if n:match('%{FFFFFF%}(.+)') then
                lua_thread.create(function()
                    while pause do wait(0) end
                    wait(delayDelete.v)
                    sampSendDialogResponse(3050, 1, i-1)
                end)
                break
            end
            if n:find(">>>") then 
                lua_thread.create(function()
                    while pause do wait(0) end
                    wait(parserBuf.v) 
                    sampSendDialogResponse(3050, 1, i-1) 
                end)
                break
            end
            i = i + 1
        end
        sampShowDialog(1235, '{'..settings.main.color..'}[ Central Market ]: {FFFFFF}PURCHASE', '{02c733}Идёт удаление предметов! Нужно чуть подождать :)', 'Ждём!')
        return false
    end
    if title:find('Поиск товара') and text:find('Введите наименование товара') and buyProc then
        lua_thread.create(function()
            wait(parserBuf.v)
            sampSendDialogResponse(id, 1, 1, itemsBuy[inputs[idt][3]][1])
        end)
        return false
    end
    if title:find('Поиск товара') and not text:find('Введите наименование товара') and buyProc then
        lua_thread.create(function()
            local ditem = 0
            for n in text:gmatch('[^\r\n]+') do
                if n:find(itemsBuy[inputs[idt][3]][1], 0, true) and inputs[idt][4] == false then
                    bName, idt = idt, idt + 1
                    wait(delayInt.v)
                    sampSendDialogResponse(id, 1, ditem)
                    break
                end
            end
        end)
        return false
    end
    if id == 3050 and buyProc then
        sampShowDialog(1235, '{'..settings.main.color..'}[ Central Market ]: {FFFFFF}PURCHASE', '{02c733}Идёт выставление предметов! Нужно чуть подождать :)', 'Ждём!')
        lua_thread.create(function()
            local skip, isFound, i = true, false, 0
            for n in text:gmatch('[^\r\n]+') do
                if shopMode == 2 then
                    for t, a in pairs(inputsSell) do if n:find('{777777}'..itemsSell[inputsSell[t][3]][1], 0, true) and inputsSell[t][4] == false then wait(delayInt.v) bName = t sampSendDialogResponse(3050, 1, i - 1) isFound = true break end end
                end
                if n:find(">>>") then wait(parserBuf.v) sampSendDialogResponse(3050, 1, i - 1) end
                if isFound then break end
                i = i + 1
            end
        end)
        return false
    end
    if id == 3060 and bName ~= nil and buyProc then
        if shopMode == 1 then
            if text:find('Введите%sцену%sза%sтовар%s%(%s') then sampSendDialogResponse(3060, 1, 0, inputs[bName][2].v) else sampSendDialogResponse(3060, 1, 0, inputs[bName][1].v..", "..inputs[bName][2].v) end
            inputs[bName][4] = true
            local isEndBuy = true
            for i, d in pairs(inputs) do if not inputs[i][4] then isEndBuy = false end end 
            if not isEndBuy then sampSendDialogResponse(3040, 1, 3) else sampAddChatMessage('[ Central Market ]: {FFFFFF}Товары успешно выставлены! Удачи', settings.main.colormsg) skip = false buyProc = false end
        elseif shopMode == 2 then
            if inputsSell[bName][5].v then sampSendDialogResponse(3060, 1, 0, inputsSell[bName][2].v) else sampSendDialogResponse(3060, 1, 0, inputsSell[bName][1].v..", "..inputsSell[bName][2].v) end
            inputsSell[bName][4] = true
            local isEndSell = true
            for i, d in pairs(inputsSell) do if not inputsSell[i][4] then isEndSell = false end end 
            if not isEndSell then sampSendDialogResponse(3040, 1, 0) else sampAddChatMessage('[ Central Market ]: {FFFFFF}Товары успешно выставлены! Удачи', settings.main.colormsg)  skip = false buyProc = false end
        end
        return false
    end
end

function sampev.onSendDialogResponse(id, but, list, input)
    if id == 3040 and but == 1 and list == last_list then
        allWindow.v = not allWindow.v imgui.Process = allWindow.v
	end
end

function parserPage(text, title) -- переделал функу Devilov'a
    skip = true
	local isNext,i = false, 0
    local cur, max = title:match('(%d+)/(%d+)')
    for n in text:gmatch('[^\r\n]+') do -- чек построчно 
        if checkmode == 1 then 
            local item = n:match("%{777777%}(.+)%s%{B6B425%}")
            if item ~= "Название" and item ~= nil then
                local isFound = false
                for g, f in pairs(itemsBuy) do 
                    if item == itemsBuy[g][1] then
                        isFound = true
                    end
                end
                if not isFound then table.insert(itemsBuy, {item, 0, 0, false, false}) end
            end
        elseif checkmode == 2 then
            local item, ic = n:match("%{777777%}(.+)%s%{777777%}(.+)%s%{B6B425%}")
            if item ~= "Название" and item ~= nil and ic ~= ' ' and ic ~= '1 шт.' then
                itemc = ic:match('(%d+)%sшт.')
                table.insert(itemsSell, {item, tonumber(itemc), 0, false, false})
            elseif item ~= "Название" and item ~= nil and (ic == ' ' or ic == '1 шт.') then
                table.insert(itemsSell, {item, 1, 0, false, true})  
            end
        end
		if n:find(">>>") and (cur ~= max) then wait(parserBuf.v) sampSendDialogResponse(3050, 1, i-1) isNext = true end -- следующая страничка
        i = i + 1
	end
    if not isNext then check = false sampAddChatMessage('[ Central Market ]: {FFFFFF}Проверка списков прошла успешно! Откройте меню по команде: {'..settings.main.color..'}/crmenu', settings.main.colormsg) inicfg.save(itemsBuy, 'Central Market\\ARZCentral.ini') sampSendDialogResponse(3050, 0) skip = false end
end

local fontsize = nil
function imgui.BeforeDrawFrame()
    if fontsize == nil then
        fontsize = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 20.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
        logosize = imgui.GetIO().Fonts:AddFontFromFileTTF(getFolderPath(0x14) .. '\\trebucbd.ttf', 25.0, nil, imgui.GetIO().Fonts:GetGlyphRangesCyrillic())
    end
end

function imgui.OnDrawFrame()
    local cx, cy = select(1, getScreenResolution()), select(2, getScreenResolution())
	if allWindow.v then
        imgui.SetNextWindowPos(imgui.ImVec2(cx/3, cy / 3), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
        imgui.Begin('Central Market Helper || by Yondime', allWindow, 64+imgui.WindowFlags.MenuBar)
        if mainWindowState then
            if imgui.BeginMenuBar() then
                if imgui.MenuItem(u8'Скупка') then sampAddChatMessage('[ Central Market ]: {FFFFFF}Вы и так находитесь в этом меню.', settings.main.colormsg) end
                if imgui.MenuItem(u8'Продажа') then mainWindowState, sellWindowState = false, true end
                if imgui.MenuItem(u8'Настройки') then mainWindowState, settingWindowState = false, true end
                if imgui.MenuItem(u8'Пресеты') then presetWindowState, mainWindowState = true, false end
                if imgui.MenuItem(u8'Инфо') then mainWindowState, infoWindowState = false, true end
                imgui.EndMenuBar()
            end	
            if #itemsBuy ~= 0 then
                imgui.Text(u8"Все загруженные предметы:", imgui.SetCursorPosX(170))
                imgui.SameLine()
                imgui.Text(u8"Выбранные предметы:", imgui.SetCursorPosX(565))
                imgui.BeginChild("##1", imgui.ImVec2(500, 450))
                    imgui.RadioButton(u8"Искать по названию предмета", rbut, 1)
                    imgui.RadioButton(u8"Искать по номеру предмета", rbut, 2)
                    if rbut.v == 1 then imgui.InputText(u8'Поиск по названию', findBuf) end
                    if rbut.v == 2 then imgui.InputInt(u8'Поиск по номеру', findBufInt) end
                    for i, f in pairs(itemsBuy) do
                        local isFounded = false
                        if rbut.v == 1 then
                            local pat1 = string.rlower(itemsBuy[i][1])
                            local pat2 = string.rlower(u8:decode(findBuf.v))
                            if pat1:find(pat2, 0, true) then
                                if imgui.Button(tostring(i)) then 
                                    if itemsBuy[i][4] then itemsBuy[i][4] = false else itemsBuy[i][4] = true end
                                    inicfg.save(itemsBuy, 'Central Market\\ARZCentral.ini')
                                end
                                imgui.Text(u8(itemsBuy[i][1]), imgui.SameLine())
                                isFounded = true
                            end
                        end
                        if rbut.v == 2 then
                            if tostring(i):match(findBufInt.v, 0, true) then
                                if imgui.Button(tostring(i)) then stable(i) end
                                imgui.Text(u8(itemsBuy[i][1]), imgui.SameLine())
                                isFounded = true
                            end
                        end
                    end
                imgui.EndChild()
                imgui.BeginChild("##2", imgui.ImVec2(250, 450), imgui.SameLine())
                if imgui.Button(u8'Сканер', imgui.ImVec2(120, 25)) then
                    check, checkmode, itemsSell = not check, 1, ({})
                    sampAddChatMessage(check and '[ Central Market ]: {FFFFFF}Режим проверки товаров активирован.' or '[Central Market]: {FFFFFF}Режим проверки товаров деактивирован.', settings.main.colormsg)
                end
                if imgui.Button(u8"Очистить", imgui.ImVec2(120, 25), imgui.SameLine()) then for i=1, #itemsBuy do itemsBuy[i][4] = false end inicfg.save(itemsBuy, 'Central Market\\ARZCentral.ini') end
                    for i=1, #itemsBuy do
                        if itemsBuy[i][4] then
                            if imgui.Button("#"..i) then itemsBuy[i][4] = false inicfg.save(itemsBuy, 'Central Market\\ARZCentral.ini') end
                            imgui.SameLine()
                            imgui.Text(u8(" "..itemsBuy[i][1]))
                        end
                    end
                imgui.EndChild()
                if imgui.Button(u8"Продолжить", imgui.ImVec2(500, 40)) then mainWindowState = false secondaryWindowState = true inputs = {}
                    for i=1, #itemsBuy do
                        if itemsBuy[i][4] then table.insert(inputs, {imgui.ImInt(itemsBuy[i][2]), imgui.ImInt(itemsBuy[i][3]), i, false, imgui.ImBool(itemsBuy[i][5])}) end
                    end
                end
                imgui.SameLine()
                if imgui.Button(u8'Снять Скупку', imgui.ImVec2(250, 40)) then
                    delprod, delprodc = not delprod, 4
                    sampAddChatMessage(delprod and '[ Central Market ]: {FFFFFF}Нажмите на кнопку {'..settings.main.color..'}«Прекратить покупку товара»' or '[ Central Market ]: {FFFFFF}Отмена снятия с продажи', settings.main.colormsg)
                end
            else    
                imgui.Text(u8"К сожалению, у вас не загружены предметы\nЧто-бы загрузить нажмите на кнопку ниже! \nЗатем нажмите в лавке 'Выставить товар на покупку'!")
                if imgui.Button(u8'Сканер', imgui.ImVec2(330, 25)) then 
                    check, checkmode = not check, 1
                    sampAddChatMessage(check and '[ Central Market ]: {FFFFFF}Режим проверки товаров активирован.' or '[Central Market]: {FFFFFF}Режим проверки товаров деактивирован.', settings.main.colormsg)
                end
            end
        end
        if sellWindowState then
            if imgui.BeginMenuBar() then
                if imgui.MenuItem(u8'Скупка') then mainWindowState, sellWindowState = true, false end
                if imgui.MenuItem(u8'Продажа') then sampAddChatMessage('[ Central Market ]: {FFFFFF}Вы и так находитесь в этом меню.', settings.main.colormsg) end
                if imgui.MenuItem(u8'Настройки') then sellWindowState, settingWindowState = false, true end
                if imgui.MenuItem(u8'Пресеты') then presetWindowState, sellWindowState = true, false end
                if imgui.MenuItem(u8'Инфо') then sellWindowState, infoWindowState = false, true end
                imgui.EndMenuBar()
            end	
            if #itemsSell ~= 0 then
                imgui.Text(u8"Все загруженные предметы:", imgui.SetCursorPosX(100))
                imgui.SameLine()
                imgui.Text(u8"Выбранные предметы:", imgui.SetCursorPosX(500))
                imgui.BeginChild("##11", imgui.ImVec2(500, 450))
                    imgui.RadioButton(u8"Искать по названию предмета", rbut, 1)
                    imgui.RadioButton(u8"Искать по номеру предмета", rbut, 2)
                    if rbut.v == 1 then imgui.InputText(u8'Поиск по названию', findBuf) end
                    if rbut.v == 2 then imgui.InputInt(u8'Поиск по номеру', findBufInt) end
                    for i, f in pairs(itemsSell) do
                        local isFounded = false
                        if rbut.v == 1 then
                            local pat1 = string.rlower(itemsSell[i][1])
                            local pat2 = string.rlower(u8:decode(findBuf.v))
                            if pat1:find(pat2, 0, true) then
                                if imgui.Button(tostring(i)) then 
                                    if not itemsSell[i][4] then itemsSell[i][4] = true else itemsSell[i][4] = false end
                                end
                                imgui.Text(u8(itemsSell[i][1]), imgui.SameLine())
                                if itemsSell[i][2] ~= 1 then imgui.Text(u8(' - '..itemsSell[i][2]..' шт.'), imgui.SameLine()) end
                                isFounded = true
                            end
                        end
                        if rbut.v == 2 then
                            if tostring(i):match(findBufInt.v, 0, true) then
                                if imgui.Button(tostring(i)) then stable(i) end
                                if itemsSell[i][2] ~= 1 then  imgui.Text(u8(itemsSell[i][2]..' шт.'), imgui.SameLine()) end
                                imgui.Text(u8(itemsSell[i][1]), imgui.SameLine())
                                isFounded = true
                            end
                        end
                    end
                    imgui.EndChild()
                    imgui.BeginChild("##21", imgui.ImVec2(250, 450), imgui.SameLine())
                    if imgui.Button(u8'Сканер', imgui.ImVec2(120, 25)) then
                        check, checkmode, itemsSell = not check, 2, ({})
                        sampAddChatMessage(check and '[ Central Market ]: {FFFFFF}Режим проверки товаров активирован.' or '[Central Market]: {FFFFFF}Режим проверки товаров деактивирован.', settings.main.colormsg)
                    end
                    if imgui.Button(u8"Очистить", imgui.ImVec2(120, 25), imgui.SameLine()) then for i=1, #itemsSell do itemsSell[i][4] = false end end
                    for i=1, #itemsSell do
                        if itemsSell[i][4] then
                            if imgui.Button("#"..i) then itemsSell[i][4] = false end
                            imgui.Text(u8(" "..itemsSell[i][1]), imgui.SameLine())
                            if itemsSell[i][2] ~= 1 then imgui.Text(u8(' - '..itemsSell[i][2]..' шт.'), imgui.SameLine()) end
                        end
                    end
                imgui.EndChild()
                if imgui.Button(u8"Продолжить", imgui.ImVec2(500, 40)) then inputsSell = {} secondarySellWindowState = true sellWindowState = false
                    for i=1, #itemsSell do 
                        if itemsSell[i][4] then
                            local isFound = false 
                            for f, d in pairs(cfgsell.itemsSellm) do 
                                if f == itemsSell[i][1] then isFound = true end 
                            end
                            if not isFound then cena = itemsSell[i][3] else cena = cfgsell.itemsSellm[itemsSell[i][1]] end
                            table.insert(inputsSell, {imgui.ImInt(itemsSell[i][2]), imgui.ImInt(cena), i, false, imgui.ImBool(itemsSell[i][5])})  
                        end 
                    end
                end
                imgui.SameLine()
                if imgui.Button(u8'Снять Продажу', imgui.ImVec2(250, 40)) then
                    delprod, delprodc = not delprod, 1
                    sampAddChatMessage(delprod and '[ Central Market ]: {FFFFFF}Нажмите на кнопку {'..settings.main.color..'}«Удалить товар с продажи»' or '[ Central Market ]: {FFFFFF}Отмена снятия с продажи', settings.main.colormsg)
                end
            else    
                imgui.Text(u8"К сожалению, у вас не загружены предметы\nЧто-бы загрузить нажмите на кнопку ниже! \nЗатем нажмите в лавке 'Выставить товар на продажу'!")
                if imgui.Button(u8'Сканер', imgui.ImVec2(330, 25)) then 
                    check, checkmode = not check, 2
                    sampAddChatMessage(check and '[ Central Market ]: {FFFFFF}Режим проверки товаров активирован.' or '[Central Market]: {FFFFFF}Режим проверки товаров деактивирован.', settings.main.colormsg)
                end
            end
        end
        if secondarySellWindowState then
            local isWarning = false
                imgui.BeginChild("##31", imgui.ImVec2(460, 450))
                    for i, n in pairs(inputsSell) do 
                        if itemsSell[inputsSell[i][3]][4] then
                            imgui.Text(u8(" Предмет: "..itemsSell[inputsSell[i][3]][1]), imgui.Separator())
                            if not inputsSell[i][5].v then imgui.InputInt(u8("##sellc"..i), inputsSell[i][1]) imgui.SameLine() imgui.Text(u8("- "..inputsSell[i][1].v..' шт. / '..itemsSell[inputsSell[i][3]][2].." шт.")) end
                            imgui.InputInt(u8("##sell"..i), inputsSell[i][2])
                            imgui.SameLine()
                            imgui.Text(u8("- "..comma_value(inputsSell[i][2].v).."$"))
                            if inputsSell[i][2].v < 10 then imgui.TextColoredRGB("{FF2400}Минимальная цена товара 10$!") isWarning = true end
                            if inputsSell[i][1].v * inputsSell[i][2].v > 300000000 then imgui.TextColoredRGB("{FF2400}Максимальная цена товара 300.000.000$!") isWarning = true end
                            if inputsSell[i][1].v > itemsSell[inputsSell[i][3]][2] then imgui.TextColoredRGB("{FF2400}У вас нету столько товаров на продажу.") isWarning = true end
                            imgui.Separator()
                        end
                    end
                    imgui.EndChild()
                    imgui.BeginGroup(imgui.SameLine())
                    if imgui.Button(u8"Вернуться к выбору", imgui.ImVec2(240, 75)) then secondarySellWindowState = false sellWindowState = true end
                    if imgui.Button(u8"Начать Продажу", imgui.ImVec2(240, 75)) then  buyProc, shopMode = not buyProc, 2 for i=1, #inputsSell do itemsSell[inputsSell[i][3]][2] = inputsSell[i][1].v itemsSell[inputsSell[i][3]][3] = inputsSell[i][2].v itemsSell[inputsSell[i][3]][5] = inputsSell[i][5].v cfgsell.itemsSellm[itemsSell[inputsSell[i][3]][1]]=inputsSell[i][2].v inicfg.save(cfgsell, 'Central Market\\ARZCentral-sell.ini') end end
                    if imgui.Button(u8"Сохранить Конфиг", imgui.ImVec2(240, 75)) then for i=1, #inputsSell do cfgsell.itemsSellm[itemsSell[inputsSell[i][3]][1]]=inputsSell[i][2].v inicfg.save(cfgsell, 'Central Market\\ARZCentral-sell.ini') end end
                    if buyProc then if isWarning then imgui.TextColoredRGB("{ff2400}Проверьте цены!") else imgui.TextColoredRGB('{178f2b}Нажми "Добавить товар на продажу"!') end end
                imgui.EndGroup()
            local mon = 0
            for i, n in pairs(inputsSell) do 
                if inputsSell[i][5].v then mon = mon + inputsSell[i][2].v else
                mon = mon + (inputsSell[i][1].v * inputsSell[i][2].v) end
            end
            imgui.Text(u8("Вы можете выставить товара на: "..comma_value(mon).." вирт"))
        end
        if secondaryWindowState then
            local isWarning = false
                imgui.BeginChild("##3", imgui.ImVec2(460, 450))
                    for i, n in pairs(inputs) do 
                        if itemsBuy[inputs[i][3]][4] then
                            imgui.Text(u8(" Предмет: "..itemsBuy[inputs[i][3]][1]), imgui.Separator())
                            imgui.InputInt(u8("##buyc"..i), inputs[i][1]) imgui.SameLine() imgui.Text(u8("- "..comma_value(inputs[i][1].v).." шт"))
                            imgui.InputInt(u8("##buy"..i), inputs[i][2]) imgui.SameLine() imgui.Text(u8("- "..comma_value(inputs[i][2].v).."$"))
                            if inputs[i][2].v < 10 then imgui.TextColoredRGB("{FF2400}Минимальная цена товара 10$!") isWarning = true end
                            imgui.Separator()
                        end
                    end
                imgui.EndChild()
                imgui.BeginGroup(imgui.SameLine())
                    if imgui.Button(u8"Вернуться к выбору", imgui.ImVec2(240, 75)) then secondaryWindowState = false mainWindowState = true end
                    if imgui.Button(u8"Начать закупку", imgui.ImVec2(240, 75)) then 
                        idt = 1 
                        buyProc, shopMode = not buyProc, 1 
                        for i=1, #inputs do itemsBuy[inputs[i][3]][2] = inputs[i][1].v itemsBuy[inputs[i][3]][3] = inputs[i][2].v itemsBuy[inputs[i][3]][5] = inputs[i][5].v inicfg.save(itemsBuy, 'Central Market\\ARZCentral.ini') end 
                    end
                    if imgui.Button(u8"Сохранить Конфиг", imgui.ImVec2(240, 75)) then for i=1, #inputs do itemsBuy[inputs[i][3]][2] = inputs[i][1].v itemsBuy[inputs[i][3]][3] = inputs[i][2].v itemsBuy[inputs[i][3]][5] = inputs[i][5].v inicfg.save(itemsBuy, 'Central Market\\ARZCentral.ini') end end
                    if buyProc then if isWarning then imgui.TextColoredRGB("{ff2400}Проверьте цены!") else imgui.TextColoredRGB('{178f2b}Нажми "Добавить товар на покупку (поиск по предметам)"!') end end
                imgui.EndGroup()
            local mon = 0
            for i, n in pairs(inputs) do 
                if inputs[i][5].v then mon = mon + inputs[i][2].v else
                mon = mon + (inputs[i][1].v * inputs[i][2].v) end
            end
            if getPlayerMoney() < mon then color = "{ff2400}" else color = "{178f2b}" end
            imgui.Text(u8("Всего будет потрачено: "..comma_value(mon).." вирт"))
            imgui.TextColoredRGB("Ваши вирты: "..color..comma_value(getPlayerMoney()).." вирт")
        end
        if settingWindowState then
            if imgui.BeginMenuBar() then
                if imgui.MenuItem(u8'Скупка') then mainWindowState, settingWindowState = true, false end
                if imgui.MenuItem(u8'Продажа') then settingWindowState, sellWindowState = false, true end
                if imgui.MenuItem(u8'Настройки') then sampAddChatMessage('[ Central Market ]: {FFFFFF}Вы и так находитесь в этом меню.', settings.main.colormsg) end
                if imgui.MenuItem(u8'Пресеты') then settingWindowState, presetWindowState = false, true end
                if imgui.MenuItem(u8'Инфо') then settingWindowState, infoWindowState = false, true end
                imgui.EndMenuBar()
            end
            imgui.PushItemWidth(290)
            imgui.Text(u8'Задержка на парсер товаров ( смена странички )')
            if imgui.SliderInt('##delay2', parserBuf, 0, 2000) then settings.main.delayParse = parserBuf.v inicfg.save(settings, 'Central Market\\ARZCentral-settings') end 
            imgui.Text(u8'Задержка на выставление товаров')
            if imgui.SliderInt('##delay', delayInt, 0, 2000) then settings.main.delayVist = delayInt.v inicfg.save(settings, 'Central Market\\ARZCentral-settings') end 
            imgui.Text(u8'Задержка на удаление товара')
            if imgui.SliderInt('##delayDel', delayDelete, 0, 2000) then settings.main.delayDelete = delayDelete.v inicfg.save(settings, 'Central Market\\ARZCentral-settings') end 
            if imgui.ListBox('##styleBox', selectStyle, {'White Style', 'Dark Style', 'Purple Style'}, 3) then
                if selectStyle.v == 0 then setLightStyle() elseif selectStyle.v == 1 then setDarkStyle() elseif selectStyle.v == 2 then setPurpleStyle() end
            end
            imgui.PopItemWidth()
        end
        if presetWindowState then
            if imgui.BeginMenuBar() then
                if imgui.MenuItem(u8'Скупка') then mainWindowState, presetWindowState = true, false end
                if imgui.MenuItem(u8'Продажа') then presetWindowState, sellWindowState = false, true end
                if imgui.MenuItem(u8'Настройки') then settingWindowState, presetWindowState = true, false end
                if imgui.MenuItem(u8'Пресеты') then sampAddChatMessage('[ Central Market ]: {FFFFFF}Вы и так находитесь в этом меню.', settings.main.colormsg) end
                if imgui.MenuItem(u8'Инфо') then  infoWindowState, presetWindowState = true, false end
                imgui.EndMenuBar()
            end	
            imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8("Скупка Продажа")).x) / 3)
            imgui.RadioButton(u8"Скупка",selectPresetMode, 1) imgui.SameLine() imgui.RadioButton(u8"Продажа",selectPresetMode,2)
            if selectPresetMode.v == 1 then
                if imgui.Button(u8'Удалить конфиг скупки ( текущий )', imgui.ImVec2(-1, 25)) then sampAddChatMessage('[ Central Market ]: {FFFFFF}Удаление прошло успешно.', settings.main.colormsg) os.remove(getGameDirectory().."//moonloader//config//Central Market//ARZCentral.ini") itemsBuy = {} inicfg.save(itemsBuy, 'Central Market\\ARZCentral') end
                imgui.InputText(u8'- Название файла', afilename)
                if #itemsBuy ~= 0 then
                    if imgui.Button(u8'Сохранить текущую настройку', imgui.ImVec2(-1, 40)) then
                        inicfg.save(itemsBuy, 'Central Market\\ARZCentral.ini')
                        config = io.open(getGameDirectory().."//moonloader//config//Central Market//ARZCentral.ini", 'r+') a = config:read('*a') config:close()
                        if afilename.v == '' then t = os.date('%H.%M.%S_%d.%m.%Y') else t = afilename.v end
                        presetfile = io.open(getGameDirectory().."//moonloader//config//Central Market//preset-buy//ARZCentral_"..u8:decode(t)..".preset", 'a+') presetfile:write(a) presetfile:close()
                    end
                else
                    imgui.Text(u8'Сначала отсканируйте товары.')
                end
                local files = {}
                local handle, file = findFirstFile(getGameDirectory().."//moonloader//config//Central Market//preset-buy//ARZCentral_*.preset")
                while file do files[#files+1] = file  file = findNextFile(handle) end
                if file ~= nil then findClose(handle) end
                if files ~= nil then
                    for f, g in pairs(files) do
                        imgui.Text(u8(g))
                        if imgui.Button(u8('ЗАГРУЗИТЬ ##'..f), imgui.ImVec2(80, 20), imgui.SameLine()) then
                            lpreset = io.open(getGameDirectory().."//moonloader//config//Central Market//preset-buy//"..files[f], 'r+') g = lpreset:read('*a') lpreset:close()
                            os.remove(getGameDirectory().."//moonloader//config//Central Market//ARZCentral.ini")                    
                            ini = io.open(getGameDirectory().."//moonloader//config//Central Market//ARZCentral.ini", 'a+') ini:write(g) ini:close()
                            inicfg.load(itemsBuy, 'Central Market\\ARZCentral.ini')
                        end
                        if imgui.Button(u8('УДАЛИТЬ ##'..f), imgui.ImVec2(70, 20), imgui.SameLine()) then
                            os.remove(getGameDirectory().."//moonloader//config//Central Market//preset-buy//"..files[f])
                            table.remove( files,f)
                        end
                    end
                end
            elseif selectPresetMode.v == 2 then
                if imgui.Button(u8'Удалить конфиг продажи ( текущий )', imgui.ImVec2(-1, 25)) then sampAddChatMessage('[ Central Market ]: {FFFFFF}Удаление прошло успешно.', settings.main.colormsg) os.remove(getGameDirectory().."//moonloader//config//Central Market//ARZCentral-sell.ini") cfgsell.itemsSellm = {} itemsSell = {} inicfg.save(cfgsell, 'Central Market\\ARZCentral-sell') end
                imgui.InputText(u8'- Название файла', afilename)
                if #itemsSell ~= 0 then
                    if imgui.Button(u8'Сохранить текущую настройку', imgui.ImVec2(-1, 40)) then
                        inicfg.save(cfgsell, 'Central Market\\ARZCentral-sell.ini')
                        config = io.open(getGameDirectory().."//moonloader//config//Central Market//ARZCentral-sell.ini", 'r+') a = config:read('*a') config:close()
                        if afilename.v == '' then t = os.date('%H.%M.%S_%d.%m.%Y') else t = afilename.v end
                        presetfile = io.open(getGameDirectory().."//moonloader//config//Central Market//preset-sell//ARZCentral_"..u8:decode(t)..".preset", 'a+') presetfile:write(a) presetfile:close()
                    end
                else
                    imgui.Text(u8'Сначала отсканируйте товары.')
                end
                local files = {}
                local handle, file = findFirstFile(getGameDirectory().."//moonloader//config//Central Market//preset-sell//ARZCentral_*.preset")
                while file do files[#files+1] = file  file = findNextFile(handle) end
                if file ~= nil then findClose(handle) end
                if files ~= nil then
                    for f, g in pairs(files) do
                        imgui.Text(u8(g))
                        if imgui.Button(u8('ЗАГРУЗИТЬ ##'..f), imgui.ImVec2(80, 20), imgui.SameLine()) then
                            lpreset = io.open(getGameDirectory().."//moonloader//config//Central Market//preset-sell//"..files[f], 'r+') g = lpreset:read('*a') lpreset:close()
                            os.remove(getGameDirectory().."//moonloader//config//Central Market//ARZCentral-sell.ini")                    
                            ini = io.open(getGameDirectory().."//moonloader//config//Central Market//ARZCentral-sell.ini", 'a+') ini:write(g) ini:close()
                            inicfg.load(cfgsell, 'Central Market\\ARZCentral-sell.ini')
                        end
                        if imgui.Button(u8('УДАЛИТЬ ##'..f), imgui.ImVec2(70, 20), imgui.SameLine()) then
                            os.remove(getGameDirectory().."//moonloader//config//Central Market//preset-sell//"..files[f])
                            table.remove( files,f)
                        end
                    end
                end
            end
        end
        if infoWindowState then
            if imgui.BeginMenuBar() then
                if imgui.MenuItem(u8'Скупка') then mainWindowState, infoWindowState = true, false end
                if imgui.MenuItem(u8'Продажа') then infoWindowState, sellWindowState = false, true end
                if imgui.MenuItem(u8'Настройки') then settingWindowState, infoWindowState = true, false end
                if imgui.MenuItem(u8'Пресеты') then infoWindowState, presetWindowState = false, true end
                if imgui.MenuItem(u8'Инфо') then sampAddChatMessage('[ Central Market ]: {FFFFFF}Вы и так находитесь в этом меню.', settings.main.colormsg) end
                imgui.EndMenuBar()
            end
            imgui.PushFont(logosize)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8("Основные ссылочки")).x) / 2)
            imgui.TextColoredRGB('{'..settings.main.color..'}Основные ссылочки')
            imgui.PopFont()
            imgui.Separator()
            imgui.PushFont(fontsize)
            imgui.Text(u8'Тех. Поддержка VK -') imgui.SameLine()
            imgui.Link('https://vk.com/yondimescripts', u8'@yondimescripts')
            imgui.Text(u8'Тех. Поддержка TG -') imgui.SameLine()
            imgui.Link('https://t.me/yondime', u8'@yondime')
            imgui.PopFont()
            imgui.Separator()
            imgui.Text(u8'Если вы хотите связаться с автором, то настоятельно\nпрошу использовать для этого Группу ВК.')
        end
        imgui.End()
    end
    if not allWindow.v then
        imgui.Process = false
    end
end 

function comma_value(n)
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

function imgui.Link(link,name,myfunc)
	local ImVec2 = imgui.ImVec2
	local ImVec4 = imgui.ImVec4
    myfunc = type(name) == 'boolean' and name or myfunc or false
    name = type(name) == 'string' and name or type(name) == 'boolean' and link or link
    local size = imgui.CalcTextSize(name)
    local p = imgui.GetCursorScreenPos()
    local p2 = imgui.GetCursorPos()
    local resultBtn = imgui.InvisibleButton('##'..link..name, size)
    if resultBtn then
        if not myfunc then
            os.execute('explorer '..link)
        end
    end
    imgui.SetCursorPos(p2)
    if imgui.IsItemHovered() then
        imgui.TextColored(imgui.ImVec4(0.916, 0.113, 0.863, 1), name)
        imgui.GetWindowDrawList():AddLine(imgui.ImVec2(p.x, p.y + size.y), imgui.ImVec2(p.x + size.x, p.y + size.y), imgui.GetColorU32(imgui.GetStyle().Colors[imgui.Col.ButtonHovered]))
    else
        imgui.TextColored(imgui.ImVec4(0.129, 0.710, 0.282, 1), name)
    end
    return resultBtn
end

function imgui.TextColoredRGB(text)
    local style = imgui.GetStyle()
    local colors = style.Colors
    local ImVec4 = imgui.ImVec4

    local explode_argb = function(argb)
        local a = bit.band(bit.rshift(argb, 24), 0xFF)
        local r = bit.band(bit.rshift(argb, 16), 0xFF)
        local g = bit.band(bit.rshift(argb, 8), 0xFF)
        local b = bit.band(argb, 0xFF)
        return a, r, g, b
    end

    local getcolor = function(color)
        if color:sub(1, 6):upper() == 'SSSSSS' then
            local r, g, b = colors[1].x, colors[1].y, colors[1].z
            local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
            return ImVec4(r, g, b, a / 255)
        end
        local color = type(color) == 'string' and tonumber(color, 16) or color
        if type(color) ~= 'number' then return end
        local r, g, b, a = explode_argb(color)
        return imgui.ImColor(r, g, b, a):GetVec4()
    end

    local render_text = function(text_)
        for w in text_:gmatch('[^\r\n]+') do
            local text, colors_, m = {}, {}, 1
            w = w:gsub('{(......)}', '{%1FF}')
            while w:find('{........}') do
                local n, k = w:find('{........}')
                local color = getcolor(w:sub(n + 1, k - 1))
                if color then
                    text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                    colors_[#colors_ + 1] = color
                    m = n
                end
                w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
            end
            if text[0] then
                for i = 0, #text do
                    imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                    imgui.SameLine(nil, 0)
                end
                imgui.NewLine()
            else imgui.Text(u8(w)) end
        end
    end
    render_text(text)
end
function setLightStyle()
    settings.main.color, settings.main.colormsg, settings.main.stylemode = '474646', 0xFF474646, 0
    inicfg.save(settings, 'Central Market\\ARZCentral-settings')
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    local ImVec2 = imgui.ImVec2
    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
    style.ChildWindowRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 15.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    colors[clr.Text]                   = ImVec4(0.05, 0.05, 0.05, 1.00);
    colors[clr.TextDisabled]           = ImVec4(0.29, 0.29, 0.29, 1.00);
    colors[clr.WindowBg]               = ImVec4(1.00, 1.00, 1.00, 1.00);
    colors[clr.ChildWindowBg]          = ImVec4(1.00, 1.00, 1.00, 1.00);
    colors[clr.PopupBg]                = ImVec4(1.00, 1.00, 1.00, 0.90);
    colors[clr.Border]                 = ImVec4(1.00, 1.00, 1.00, 1.00);
    colors[clr.BorderShadow]           = ImVec4(1.00, 1.00, 1.00, 0.10);
    colors[clr.FrameBg]                = ImVec4(0.90, 0.90, 0.90, 1.00);
    colors[clr.FrameBgHovered]         = ImVec4(0.80, 0.80, 0.80, 1.00);
    colors[clr.FrameBgActive]          = ImVec4(0.75, 0.75, 0.75, 1.00);
    colors[clr.TitleBg]                = ImVec4(1.00, 1.00, 1.00, 1.00);
    colors[clr.TitleBgActive]          = ImVec4(1.00, 1.00, 1.00, 1.00);
    colors[clr.TitleBgCollapsed]       = ImVec4(1.00, 1.00, 1.00, 1.00);
    colors[clr.MenuBarBg]              = ImVec4(1.00, 1.00, 1.00, 1.00);
    colors[clr.ScrollbarBg]            = ImVec4(1.00, 1.00, 1.00, 1.00);
    colors[clr.ScrollbarGrab]          = ImVec4(0.36, 0.36, 0.36, 1.00);
    colors[clr.ScrollbarGrabHovered]   = ImVec4(0.18, 0.22, 0.25, 1.00);
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.24, 0.24, 0.24, 1.00);
    colors[clr.ComboBg]                = ImVec4(0.61, 0.61, 0.61, 1.00);
    colors[clr.CheckMark]              = ImVec4(0.42, 0.42, 0.42, 1.00);
    colors[clr.SliderGrab]             = ImVec4(0.51, 0.51, 0.51, 1.00);
    colors[clr.SliderGrabActive]       = ImVec4(0.65, 0.65, 0.65, 1.00);
    colors[clr.Button]                 = ImVec4(0.52, 0.52, 0.52, 0.83);
    colors[clr.ButtonHovered]          = ImVec4(0.58, 0.58, 0.58, 0.83);
    colors[clr.ButtonActive]           = ImVec4(0.44, 0.44, 0.44, 0.83);
    colors[clr.Header]                 = ImVec4(0.65, 0.65, 0.65, 1.00);
    colors[clr.HeaderHovered]          = ImVec4(0.73, 0.73, 0.73, 1.00);
    colors[clr.HeaderActive]           = ImVec4(0.53, 0.53, 0.53, 1.00);
    colors[clr.Separator]              = ImVec4(0.46, 0.46, 0.46, 1.00);
    colors[clr.SeparatorHovered]       = ImVec4(0.45, 0.45, 0.45, 1.00);
    colors[clr.SeparatorActive]        = ImVec4(0.45, 0.45, 0.45, 1.00);
    colors[clr.ResizeGrip]             = ImVec4(0.23, 0.23, 0.23, 1.00);
    colors[clr.ResizeGripHovered]      = ImVec4(0.32, 0.32, 0.32, 1.00);
    colors[clr.ResizeGripActive]       = ImVec4(0.14, 0.14, 0.14, 1.00);
    colors[clr.CloseButton]            = ImVec4(0.40, 0.39, 0.38, 0.16);
    colors[clr.CloseButtonHovered]     = ImVec4(0.40, 0.39, 0.38, 0.39);
    colors[clr.CloseButtonActive]      = ImVec4(0.40, 0.39, 0.38, 1.00);
    colors[clr.PlotLines]              = ImVec4(0.61, 0.61, 0.61, 1.00);
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 1.00, 1.00, 1.00);
    colors[clr.PlotHistogram]          = ImVec4(0.70, 0.70, 0.70, 1.00);
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 1.00, 1.00, 1.00);
    colors[clr.TextSelectedBg]         = ImVec4(0.62, 0.62, 0.62, 1.00);
    colors[clr.ModalWindowDarkening]   = ImVec4(0.26, 0.26, 0.26, 0.60);
end
function setDarkStyle()
    settings.main.color, settings.main.colormsg, settings.main.stylemode = 'bdb7b7', 0xFFbdb7b7, 1
    inicfg.save(settings, 'Central Market\\ARZCentral-settings')
    imgui.SwitchContext()
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
    style.ChildWindowRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 15.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    colors[clr.Text]                   = ImVec4(0.90, 0.90, 0.90, 1.00)
    colors[clr.TextDisabled]           = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.WindowBg]               = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.ChildWindowBg]          = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.PopupBg]                = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.Border]                 = ImVec4(0.82, 0.77, 0.78, 1.00)
    colors[clr.BorderShadow]           = ImVec4(0.35, 0.35, 0.35, 0.66)
    colors[clr.FrameBg]                = ImVec4(1.00, 1.00, 1.00, 0.28)
    colors[clr.FrameBgHovered]         = ImVec4(0.68, 0.68, 0.68, 0.67)
    colors[clr.FrameBgActive]          = ImVec4(0.79, 0.73, 0.73, 0.62)
    colors[clr.TitleBg]                = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.TitleBgActive]          = ImVec4(0.46, 0.46, 0.46, 1.00)
    colors[clr.TitleBgCollapsed]       = ImVec4(0.00, 0.00, 0.00, 1.00)
    colors[clr.MenuBarBg]              = ImVec4(0.00, 0.00, 0.00, 0.80)
    colors[clr.ScrollbarBg]            = ImVec4(0.00, 0.00, 0.00, 0.60)
    colors[clr.ScrollbarGrab]          = ImVec4(1.00, 1.00, 1.00, 0.87)
    colors[clr.ScrollbarGrabHovered]   = ImVec4(1.00, 1.00, 1.00, 0.79)
    colors[clr.ScrollbarGrabActive]    = ImVec4(0.80, 0.50, 0.50, 0.40)
    colors[clr.ComboBg]                = ImVec4(0.24, 0.24, 0.24, 0.99)
    colors[clr.CheckMark]              = ImVec4(0.99, 0.99, 0.99, 0.52)
    colors[clr.SliderGrab]             = ImVec4(1.00, 1.00, 1.00, 0.42)
    colors[clr.SliderGrabActive]       = ImVec4(0.76, 0.76, 0.76, 1.00)
    colors[clr.Button]                 = ImVec4(0.51, 0.51, 0.51, 0.60)
    colors[clr.ButtonHovered]          = ImVec4(0.68, 0.68, 0.68, 1.00)
    colors[clr.ButtonActive]           = ImVec4(0.67, 0.67, 0.67, 1.00)
    colors[clr.Header]                 = ImVec4(0.72, 0.72, 0.72, 0.54)
    colors[clr.HeaderHovered]          = ImVec4(0.92, 0.92, 0.95, 0.77)
    colors[clr.HeaderActive]           = ImVec4(0.82, 0.82, 0.82, 0.80)
    colors[clr.Separator]              = ImVec4(0.73, 0.73, 0.73, 1.00)
    colors[clr.SeparatorHovered]       = ImVec4(0.81, 0.81, 0.81, 1.00)
    colors[clr.SeparatorActive]        = ImVec4(0.74, 0.74, 0.74, 1.00)
    colors[clr.ResizeGrip]             = ImVec4(0.80, 0.80, 0.80, 0.30)
    colors[clr.ResizeGripHovered]      = ImVec4(0.95, 0.95, 0.95, 0.60)
    colors[clr.ResizeGripActive]       = ImVec4(1.00, 1.00, 1.00, 0.90)
    colors[clr.CloseButton]            = ImVec4(0.45, 0.45, 0.45, 0.50)
    colors[clr.CloseButtonHovered]     = ImVec4(0.70, 0.70, 0.90, 0.60)
    colors[clr.CloseButtonActive]      = ImVec4(0.70, 0.70, 0.70, 1.00)
    colors[clr.PlotLines]              = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.PlotLinesHovered]       = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.PlotHistogram]          = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.PlotHistogramHovered]   = ImVec4(1.00, 1.00, 1.00, 1.00)
    colors[clr.TextSelectedBg]         = ImVec4(1.00, 1.00, 1.00, 0.35)
    colors[clr.ModalWindowDarkening]   = ImVec4(0.88, 0.88, 0.88, 0.35)
end
function setPurpleStyle()
    settings.main.color, settings.main.colormsg,settings.main.stylemode = '9720e6', 0xFF9720e6, 2 
    inicfg.save(settings, 'Central Market\\ARZCentral-settings')
    local style = imgui.GetStyle()
    local colors = style.Colors
    local clr = imgui.Col
    local ImVec4 = imgui.ImVec4
    style.WindowPadding = imgui.ImVec2(8, 8)
    style.WindowRounding = 6
    style.ChildWindowRounding = 5
    style.FramePadding = imgui.ImVec2(5, 3)
    style.FrameRounding = 3.0
    style.ItemSpacing = imgui.ImVec2(5, 4)
    style.ItemInnerSpacing = imgui.ImVec2(4, 4)
    style.IndentSpacing = 21
    style.ScrollbarSize = 15.0
    style.ScrollbarRounding = 13
    style.GrabMinSize = 8
    style.GrabRounding = 1
    style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    colors[clr.WindowBg]              = ImVec4(0.14, 0.12, 0.16, 1.00);
    colors[clr.ChildWindowBg]         = ImVec4(0.30, 0.20, 0.39, 0.00);
    colors[clr.PopupBg]               = ImVec4(0.05, 0.05, 0.10, 0.90);
    colors[clr.Border]                = ImVec4(0.89, 0.85, 0.92, 0.30);
    colors[clr.BorderShadow]          = ImVec4(0.00, 0.00, 0.00, 0.00);
    colors[clr.FrameBg]               = ImVec4(0.30, 0.20, 0.39, 1.00);
    colors[clr.FrameBgHovered]        = ImVec4(0.41, 0.19, 0.63, 0.68);
    colors[clr.FrameBgActive]         = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.TitleBg]               = ImVec4(0.41, 0.19, 0.63, 0.45);
    colors[clr.TitleBgCollapsed]      = ImVec4(0.41, 0.19, 0.63, 0.35);
    colors[clr.TitleBgActive]         = ImVec4(0.41, 0.19, 0.63, 0.78);
    colors[clr.MenuBarBg]             = ImVec4(0.30, 0.20, 0.39, 0.57);
    colors[clr.ScrollbarBg]           = ImVec4(0.30, 0.20, 0.39, 1.00);
    colors[clr.ScrollbarGrab]         = ImVec4(0.41, 0.19, 0.63, 0.31);
    colors[clr.ScrollbarGrabHovered]  = ImVec4(0.41, 0.19, 0.63, 0.78);
    colors[clr.ScrollbarGrabActive]   = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.ComboBg]               = ImVec4(0.30, 0.20, 0.39, 1.00);
    colors[clr.CheckMark]             = ImVec4(0.56, 0.61, 1.00, 1.00);
    colors[clr.SliderGrab]            = ImVec4(0.41, 0.19, 0.63, 0.24);
    colors[clr.SliderGrabActive]      = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.Button]                = ImVec4(0.41, 0.19, 0.63, 0.44);
    colors[clr.ButtonHovered]         = ImVec4(0.41, 0.19, 0.63, 0.86);
    colors[clr.ButtonActive]          = ImVec4(0.64, 0.33, 0.94, 1.00);
    colors[clr.Header]                = ImVec4(0.41, 0.19, 0.63, 0.76);
    colors[clr.HeaderHovered]         = ImVec4(0.41, 0.19, 0.63, 0.86);
    colors[clr.HeaderActive]          = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.ResizeGrip]            = ImVec4(0.41, 0.19, 0.63, 0.20);
    colors[clr.ResizeGripHovered]     = ImVec4(0.41, 0.19, 0.63, 0.78);
    colors[clr.ResizeGripActive]      = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.CloseButton]           = ImVec4(1.00, 1.00, 1.00, 0.75);
    colors[clr.CloseButtonHovered]    = ImVec4(0.88, 0.74, 1.00, 0.59);
    colors[clr.CloseButtonActive]     = ImVec4(0.88, 0.85, 0.92, 1.00);
    colors[clr.PlotLines]             = ImVec4(0.89, 0.85, 0.92, 0.63);
    colors[clr.PlotLinesHovered]      = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.PlotHistogram]         = ImVec4(0.89, 0.85, 0.92, 0.63);
    colors[clr.PlotHistogramHovered]  = ImVec4(0.41, 0.19, 0.63, 1.00);
    colors[clr.TextSelectedBg]        = ImVec4(0.41, 0.19, 0.63, 0.43);
    colors[clr.ModalWindowDarkening]  = ImVec4(0.20, 0.20, 0.20, 0.35);
end

if settings.main.stylemode == 0 then
    setLightStyle()
elseif settings.main.stylemode == 1 then
    setDarkStyle()
elseif settings.main.stylemode == 2 then 
    setPurpleStyle()
end 

local russian_characters = {
    [168] = 'Ё', [184] = 'ё', [192] = 'А', [193] = 'Б', [194] = 'В', [195] = 'Г', [196] = 'Д', [197] = 'Е', [198] = 'Ж', [199] = 'З', [200] = 'И', [201] = 'Й', [202] = 'К', [203] = 'Л', [204] = 'М', [205] = 'Н', [206] = 'О', [207] = 'П', [208] = 'Р', [209] = 'С', [210] = 'Т', [211] = 'У', [212] = 'Ф', [213] = 'Х', [214] = 'Ц', [215] = 'Ч', [216] = 'Ш', [217] = 'Щ', [218] = 'Ъ', [219] = 'Ы', [220] = 'Ь', [221] = 'Э', [222] = 'Ю', [223] = 'Я', [224] = 'а', [225] = 'б', [226] = 'в', [227] = 'г', [228] = 'д', [229] = 'е', [230] = 'ж', [231] = 'з', [232] = 'и', [233] = 'й', [234] = 'к', [235] = 'л', [236] = 'м', [237] = 'н', [238] = 'о', [239] = 'п', [240] = 'р', [241] = 'с', [242] = 'т', [243] = 'у', [244] = 'ф', [245] = 'х', [246] = 'ц', [247] = 'ч', [248] = 'ш', [249] = 'щ', [250] = 'ъ', [251] = 'ы', [252] = 'ь', [253] = 'э', [254] = 'ю', [255] = 'я',
}
function string.rlower(s)
    s = s:lower()
    local strlen = s:len()
    if strlen == 0 then return s end
    s = s:lower()
    local output = ''
    for i = 1, strlen do
        local ch = s:byte(i)
        if ch >= 192 and ch <= 223 then -- upper russian characters
            output = output .. russian_characters[ch + 32]
        elseif ch == 168 then -- Ё
            output = output .. russian_characters[184]
        else
            output = output .. string.char(ch)
        end
    end
    return output
end
function string.rupper(s)
    s = s:upper()
    local strlen = s:len()
    if strlen == 0 then return s end
    s = s:upper()
    local output = ''
    for i = 1, strlen do
        local ch = s:byte(i)
        if ch >= 224 and ch <= 255 then -- lower russian characters
            output = output .. russian_characters[ch - 32]
        elseif ch == 184 then -- ё
            output = output .. russian_characters[168]
        else
            output = output .. string.char(ch)
        end
    end
    return output
end
