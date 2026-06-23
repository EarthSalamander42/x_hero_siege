NOTIFICATIONS_VERSION = "0.89"

--[[
  Sample Panorama Notifications Library by BMD

  Installation
  -"require" this file inside your code in order to gain access to the Notifications class for sending notifications to players, teams, or all clients.
  -Additionally, ensure that you have the xhs_notifications.xml, xhs_notifications.js, and xhs_notifications.css files in your panorama content folder.

  Usage
  -Notifications can be sent to the Top or Bottom notification panel of an individual player, a whole team, or all clients at once.
  -Notifications can be sent as a single piece or as one payload with multiple segments consisting of Labels, Images, HeroImages, AbilityImages, and ItemImages.
  -Notifications are specified by a table which has these potential parameters:
    -duration: The duration to display the notification for on screen.
    -class: An optional (leave as nil for default) string which will be used as the class to add to the notification piece.
    -style: An optional (leave as nil for default) table of css properties to add to this notification, such as {["font-size"]="60px", color="green"}.
    -segments: An optional array of notification pieces to render on the same notification line.
  -For Labels, there is one additional mandatory parameter:
    -text:  The text to display in the notification.  Can provide localization tokens ("#addonname") or non-localized text.
  -For HeroImages, there is two additional parameters:
    -hero:  (Mandatory) The hero name, e.g. "npc_dota_hero_axe".
    -imagestyle:  (Optional)  The image style to display for this hero image.  Default when 'nil' is 'icon'.  'portrait' and 'landscape' are two other options.
  -For AboilityImages, there is one additional mandatory parameter:
    -ability:  The ability name, e.g. "lina_fiery_soul".
  -For Images, there is one additional mandatory parameter:
    -image:  The image src string, e.g. "file://{images}/status_icons/dota_generic.psd".
  -For ItemImages, there is one additional mandatory parameter:
    -item:  The item name, e.g. "item_force_staff".

  -Notifications can be removed from the Top/Bottom or cleared

  -Call the Notifications:Top, Notifications:TopToAll, or Notifications:TopToTeam to send a top-area notification to the appropriate players 
  -Call the Notifications:Bottom, Notifications:BottomToAll, or Notifications:BottomToTeam to send a bottom-area notifications to the appropriate players 
  -Call the Notifications:ClearTop, Notifications:ClearTopFromAll, or Notifications:ClearTopFromTeam to clear all existing top-area notifications from appropriate players
  -Call the Notifications:ClearBottom, Notifications:ClearBottomFromAll, or Notifications:ClearBottomFromTeam to clear all existing bottom-area notifications from appropriate players
  -Call the Notifications:RemoveTop, Notifications:RemoveTopFromAll, or Notifications:RemoveTopFromTeam to remove all existing top-area notifications from appropriate players up to the provided count of notifications
  -Call the Notifications:RemoveBottom, Notifications:RemoveBottomFromAll, or Notifications:RemoveBottomFromTeam to remove all existing bottom-area notifications from appropriate players up to the provided count of notifications
  
  Examples:

  -- Send a notification to all players that displays up top for 5 seconds
  Notifications:TopToAll({text="Top Notification for 5 seconds ", duration=5.0})
  -- Send a notification to playerID 0 which will display up top for 9 seconds and be green
  Notifications:Top(0, {text="GREEEENNNN", duration=9, style={color="green"}})

  -- Display 3 styles of hero icons on the same line for 5 seconds.
  Notifications:TopToAll({
    duration=5.0,
    segments={
      {hero="npc_dota_hero_axe"},
      {hero="npc_dota_hero_axe", imagestyle="landscape"},
      {hero="npc_dota_hero_axe", imagestyle="portrait"},
    }
  })

  -- Display a generic image and then 2 ability icons and an item on the same line for 5 seconds
  Notifications:TopToAll({
    duration=5.0,
    segments={
      {image="file://{images}/status_icons/dota_generic.psd"},
      {ability="nyx_assassin_mana_burn"},
      {ability="lina_fiery_soul"},
      {item="item_force_staff"},
    }
  })


  -- Send a notification to all players on radiant (GOODGUYS) that displays near the bottom of the screen for 10 seconds to be displayed with the NotificationMessage class added
  Notifications:BottomToTeam(DOTA_TEAM_GOODGUYS, {text="AAAAAAAAAAAAAA", duration=10, class="NotificationMessage"})
  -- Send a notification to player 0 which will display near the bottom a large red notification with a solid blue border for 5 seconds
  Notifications:Bottom(PlayerResource:GetPlayer(0), {text="Super Size Red", duration=5, style={color="red", ["font-size"]="110px", border="10px solid blue"}})


  -- Remove 1 bottom and 2 top notifications 2 seconds later
  Timers:CreateTimer(2,function()
    Notifications:RemoveTop(0, 2)
    Notifications:RemoveBottomFromTeam(DOTA_TEAM_GOODGUYS, 1)

    -- Add 1 more notification to the bottom
    Notifications:BottomToAll({text="GREEEENNNN again", duration=9, style={color="green"}})
  end)

  -- Clear all notifications from the bottom
  Timers:CreateTimer(7, function()
    Notifications:ClearBottomFromAll()
  end)
]]

if Notifications == nil then
  Notifications = class({})
end

local function BuildNotificationPayload(table)
  local text = table.text
  if text == nil and table.hero == nil and table.image == nil and table.ability == nil and table.item == nil and table.segments == nil then
    text = "No TEXT provided."
  end

  return {
    text = text,
    hero = table.hero,
    imagestyle = table.imagestyle,
    image = table.image,
    ability = table.ability,
    item = table.item,
    segments = table.segments,
    duration = table.duration,
    class = table.class,
    style = table.style,
    severity = table.severity,
    rewardType = table.rewardType,
    flyoutText = table.flyoutText,
  }
end

function Notifications:ClearTop(player)
  Notifications:RemoveTop(player, 50)
end

function Notifications:ClearBottom(player)
  Notifications:RemoveBottom(player, 50)
end

function Notifications:ClearTopFromAll()
  Notifications:RemoveTopFromAll(50)
end

function Notifications:ClearBottomFromAll()
  Notifications:RemoveBottomFromAll(50)
end

function Notifications:ClearTopFromTeam(team)
  Notifications:RemoveTopFromTeam(team, 50)
end

function Notifications:ClearBottomFromTeam(team)
  Notifications:RemoveBottomFromTeam(team, 50)
end


function Notifications:RemoveTop(player, count)
  if type(player) == "number" then
    player = PlayerResource:GetPlayer(player)
  end

  CustomGameEventManager:Send_ServerToPlayer(player, "top_remove_notification", {count=count} )
end

function Notifications:RemoveBottom(player, count)
  if type(player) == "number" then
    player = PlayerResource:GetPlayer(player)
  end

  CustomGameEventManager:Send_ServerToPlayer(player, "bottom_remove_notification", {count=count})
end

function Notifications:RemoveTopFromAll(count)
  CustomGameEventManager:Send_ServerToAllClients("top_remove_notification", {count=count} )
end

function Notifications:RemoveBottomFromAll(count)
  CustomGameEventManager:Send_ServerToAllClients("bottom_remove_notification", {count=count})
end

function Notifications:RemoveTopFromTeam(team, count)
  CustomGameEventManager:Send_ServerToTeam(team, "top_remove_notification", {count=count} )
end

function Notifications:RemoveBottomFromTeam(team, count)
  CustomGameEventManager:Send_ServerToTeam(team, "bottom_remove_notification", {count=count})
end


function Notifications:Top(player, table)
  if type(player) == "number" then
    player = PlayerResource:GetPlayer(player)
  end

  CustomGameEventManager:Send_ServerToPlayer(player, "top_notification", BuildNotificationPayload(table))
end

function Notifications:TopToAll(table)
  CustomGameEventManager:Send_ServerToAllClients("top_notification", BuildNotificationPayload(table))
end

function Notifications:TopToTeam(team, table)
  CustomGameEventManager:Send_ServerToTeam(team, "top_notification", BuildNotificationPayload(table))
end


function Notifications:Bottom(player, table)
  if type(player) == "number" then
    player = PlayerResource:GetPlayer(player)
  end

  CustomGameEventManager:Send_ServerToPlayer(player, "bottom_notification", BuildNotificationPayload(table))
end

function Notifications:BottomToAll(table)
  CustomGameEventManager:Send_ServerToAllClients("bottom_notification", BuildNotificationPayload(table))
end

function Notifications:BottomToTeam(team, table)
  CustomGameEventManager:Send_ServerToTeam(team, "bottom_notification", BuildNotificationPayload(table))
end
