--[[
    Created by Cannonballdex, BandoGear - Gear Swapper
--]]
---@type Mq
local mq = require('mq')
local LIP = require('LIP')
local ICONS = require('mq.Icons')
local args = {'BandoGear.ini'}
local settings = {}
local output = function(msg) print('\a-t[BandoGear] '..msg) end
---@type ImGui
require 'ImGui'

-- GUI
local openGUI = true
local shouldDrawGUI = true
local SaveSet = ""
local DeleteSet = ""

-- Split
---@param inputstr string
---@param sep string
---@return table

local function report_error(s, ...)
    print('Utils: ' .. string.format(s, ...))
end

local function pack_open(i)
    return mq.TLO.Me.Inventory(i).Open() == 1
end

local function get_pack_name(i)
    local pack_num = i - 22
    return 'pack'..pack_num
end

local function top_slot_is_pack(i)
    if i > 22 and i < 35 then
        local container = mq.TLO.Me.Inventory(i).Container()
        if container ~= nil and container > 0 then
            return true
        end
    end
    return false
end
--Picking up same item from worn inventory slot instead of bag
local function select_first_item_from_bags(name)
    local found_inv_top = mq.TLO.FindItem('=' .. name).ItemSlot()
    local found_inv_slot = mq.TLO.FindItem('=' .. name).ItemSlot2() + 1
    if found_inv_top ~= nil then
        if top_slot_is_pack(found_inv_top) then
            if not pack_open(found_inv_top) then
                mq.cmdf('/nomodkey /itemnotify %s rightmouseup', found_inv_top)
                while not pack_open(found_inv_top) do
                    mq.delay(100)
                end
            end
            mq.cmdf('/shift /itemnotify in %s %s leftmouseup', get_pack_name(found_inv_top), found_inv_slot)
        else
            mq.cmdf('/shift /itemnotify %s leftmouseup', found_inv_top)
        end
    else
        report_error('Item Not Found (%s)', name)
    end
end

local function split(inputstr, sep)
   if type(inputstr) == 'string' then
      sep = sep or '%s'
      local t = {}
      for field, s in string.gmatch(inputstr, "([^" .. sep .. "]*)(" .. sep .. "?)") do
         table.insert(t, field)
         if s == "" then
            return t
         end
      end
   end
   return {}
end

local sections = split(mq.TLO.Ini(args[1])(), '|')

local function HelpMarker(desc)
    if ImGui.IsItemHovered() then
        ImGui.BeginTooltip()
        ImGui.PushTextWrapPos(ImGui.GetFontSize() * 35.0)
        ImGui.Text(desc)
        ImGui.PopTextWrapPos()
        ImGui.EndTooltip()
    end
end

local function file_exists(path)
    local f = io.open(path, "r")
    if f ~= nil then io.close(f) return true else return false end
end

local save_settings = function()
    LIP.save(Settings_Path, settings)
end

-- loadset
local function loadset(name, action)
    if action == 'save' then
        settings[name] = {}
        -- start from 0 - 22 worn inventory slots
        for i = 0, 22 do
            local worn_gear = mq.TLO.InvSlot(i).Item.ID
            settings[name]['GearSlot'..i] = worn_gear
        end
        save_settings()

        -- output after successful save
        output('\aySaved Set \"'..name..'\"...\ax')
        sections = split(mq.TLO.Ini(args[1])(), '|')

    elseif action == 'delete' then
        settings[name] = nil
        save_settings()
        output('\ayDeleted Set \"'..name..'\"...\ax')

    else
        -- if not saving and want to load set
        if settings[name] ~= nil then
            if mq.TLO.InvSlot(14).Item.ID() ~= nil then
                mq.cmd('/itemnotify offhand leftmouseup')
            end
            for i = 0, 22 do
                if mq.TLO.FindItem(settings[name]['GearSlot'..i])() then
                    local gear_id = settings[name]['GearSlot'..i]
                    if gear_id ~= mq.TLO.InvSlot(i).Item.ID() then
                        select_first_item_from_bags(mq.TLO.FindItem(gear_id).Name())
                        --mq.cmdf('/shift /itemnotify "%s" leftmouseup', mq.TLO.FindItem(gear_id).Name())
                        mq.delay(500)
                        mq.cmdf('/shift /itemnotify %s leftmouseup', mq.TLO.InvSlot(i))
                        mq.delay(500)
                        mq.cmd('/autoinventory')
                        mq.delay(1)
                        end
                    end
                end
                printf('\a-t[BandoGear] \atArmor Set \ag"%s" \athas been loaded',name)
                -- Output warnings if specific items were not loaded NEEDS FIXED
                if mq.TLO.InvSlot(1).Item.ID() == nil then
                    output('\ayLEFT EAR EARRING DUPLICATE NOT LOADED')
                end
                if mq.TLO.InvSlot(9).Item.ID() == nil then
                    output('\ayLEFT WRIST BRACER DUPLICATE NOT LOADED')
                end
                if mq.TLO.InvSlot(15).Item.ID() == nil then
                    output('\ayLEFT FINGER RING DUPLICATE NOT LOADED')
                end

        else
            output('\aySet \at\"'..name..'\" \ardoes not exist... \aytry again.')
            output('\aySpecify \ata \agSet Name \ayfrom the list')
            for index, value in ipairs(sections) do
                if settings[value] ~= nil then
                    print('\at-----------------------')
                    printf('\a-t[BandoGear] \aySet \atName: \ag"%s"',value)
                    print('\at-----------------------')
                    -- make the set (start from 0, max sets 22)
                    local count = 0
                    for i = 0, 22 do
                        local set = settings[value]['set'..i]
                        if set ~= nil then
                            printf('\a-t[BandoGear] \atSet Armor: \ao"%s"',set)
                            count = count + 1
                        end
                    end
                end
            end
        end
    end
    mq.cmd('/keypress CLOSE_INV_BAGS')
end

-- ImGui bandogear function for rendering the UI window
local function bandogear()
    openGUI, shouldDrawGUI = ImGui.Begin('BandoGear - Gear Swapper', openGUI)
        ImGui.Text('Add Set: ')
        ImGui.SameLine()
        ImGui.SetCursorPosX(85)
        ImGui.PushItemWidth(125)
        SaveSet,_ = ImGui.InputText('##SaveSet', SaveSet)
        ImGui.SameLine()
        if ImGui.Button(string.format(ICONS.FA_USER_PLUS)) then mq.cmdf('/loadset %s save', SaveSet) end HelpMarker('Save Set')
        ImGui.Text('Rem Set: ')
        ImGui.SameLine()
        ImGui.SetCursorPosX(85)
        ImGui.PushItemWidth(125)
        DeleteSet,_ = ImGui.InputText('##DeleteSet', DeleteSet)
        ImGui.SameLine()
        if ImGui.Button(string.format(ICONS.FA_USER_TIMES)) then mq.cmdf('/loadset %s delete', DeleteSet) end HelpMarker('Delete Group')
        ImGui.Text('Existing Sets')
        if shouldDrawGUI then
        for index, value in ipairs(sections) do
        if settings[value] ~= nil then
            for _ = 0, index do
                if value ~= nil then
                        ImGui.Separator()
                        if ImGui.Button(value) then mq.cmdf('/loadset %s',value) end HelpMarker('Equip Set')
                        break
                    end
                end
            end
        end
    end
    ImGui.End()
end

local function load_settings()
    Conf_Dir = mq.configDir:gsub('\\', '/') .. '/'
    Settings_File = 'BandoGear.ini'
    Settings_Path = Conf_Dir..Settings_File

    if file_exists(Settings_Path) then
        settings = LIP.load(Settings_Path)
    else
        settings = {}
        save_settings()
    end
end

local function setup()
    mq.bind('/ls', loadset)
    mq.bind('/loadset', loadset)

    load_settings()
    output('\ayBandoGear \atBy \agCannonballdex - \atLoaded \ap'..Settings_File)
    output('\ayUsage: \at/loadset <name> \awor \at/ls <name> [save|delete]')
end

local function loop()
    while openGUI do mq.delay(100) end
end
mq.imgui.init('bandogear', bandogear)

setup()
loop()
