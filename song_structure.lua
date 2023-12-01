-- This script creates a basic song structure with tracks, regions, and items

-- Define song length templates
local templates = {
    ["3:30"] = {0, 30, 60, 150, 180, 240, 300, 330, 360}, -- Region lengths: 30, 30, 90, 30, 60, 60, 30, 30
    ["5:15"] = {0, 45, 90, 225, 270, 360, 450, 495, 540}, -- Region lengths: 45, 45, 135, 45, 90, 90, 45, 45
    ["7:30"] = {0, 60, 120, 300, 360, 480, 600, 660, 720} -- Region lengths: 60, 60, 180, 60, 120, 120, 60, 60
}

-- Define a function that scales the region lengths based on the user input and the template
local function scaleRegionLengths(userInput, template)
    local ratio = userInput / template[#template] -- Calculate the ratio between the user input and the template total length
    local scaledTimestamps = {} -- Create an empty table to store the scaled timestamps
    for i, time in ipairs(template) do -- Loop over the template timestamps
        local scaledTime = time * ratio -- Multiply the timestamp by the ratio
        table.insert(scaledTimestamps, scaledTime) -- Insert the scaled timestamp into the table
    end
    return scaledTimestamps -- Return the table of scaled timestamps
end

-- Define region names
local regionNames = {"Intro", "Beat", "Melody", "Build-up", "Climax", "Breakdown", "Rebuilding", "Final Climax", "Cooldown"}

-- Define instrument names
local instrumentNames = {"Drums", "Bass", "Synth", "Guitar", "Piano", "Strings", "Brass", "Vocals"}

-- Define some common values
local project = 0 -- The project index
local itemLength = 10 -- The default item length in seconds
local note = 36 -- The MIDI note number
local velocity = 127 -- The MIDI note velocity

-- Get the project tempo from the user
local tempo = reaper.GetUserInputs("Set project tempo", 1, "Enter tempo in BPM", "120")
if not tempo then return end -- Exit if the user cancels the input

tempo = tonumber(tempo) -- Convert the input to a number
reaper.SetTempo(tempo) -- Set the project tempo

-- Get the number of tracks from the user
local numTracks = reaper.GetUserInputs("Set number of tracks", 1, "Enter number of tracks", "8")
if not numTracks then return end -- Exit if the user cancels the input

numTracks = tonumber(numTracks) -- Convert the input to a number

-- Get the track layout from the user
local layout = reaper.GetUserInputs("Set track layout", 1, "Enter track layout", "Large")
if not layout then return end -- Exit if the user cancels the input

-- Get the song length from the user
local songLength = reaper.GetUserInputs("Set song length", 1, "Enter song length in seconds", "210")
if not songLength then return end -- Exit if the user cancels the input

songLength = tonumber(songLength) -- Convert the input to a number

-- Choose a template based on the closest song length
local template
if songLength <= 255 then -- If the song length is less than or equal to 4:15
    template = templates["3:30"] -- Use the 3:30 template
elseif songLength > 255 and songLength <= 375 then -- If the song length is between 4:15 and 6:15
    template = templates["5:15"] -- Use the 5:15 template
else -- If the song length is greater than 6:15
    template = templates["7:30"] -- Use the 7:30 template
end

-- Scale the region lengths based on the user input and the template
local scaledTimestamps = scaleRegionLengths(songLength, template)

-- Create tracks, regions, and items
for i = 1, numTracks do
    -- Create a new track at the end of the track list
    local track = reaper.InsertTrackAtIndex(i - 1, true)

    -- Set the track name, color, and layout
    local name = instrumentNames[i] or "Track " .. i -- Get the instrument name or use a default name
    local color = reaper.ColorToNative(0, i * 20, i * 40) -- Generate the track color
    reaper.GetSetMediaTrackInfo_String(track, "P_NAME", name, true) -- Set the track name
    reaper.GetSetMediaTrackInfo_String(track, "P_CUSTOMCOLOR", color, true) -- Set the track color
    reaper.GetSetMediaTrackInfo_String(track, "P_TCP_LAYOUT", layout, true) -- Set the track layout

    -- Get the region start and end times from the scaled timestamps table
    local regionStart = scaledTimestamps[i] or (i - 1) * itemLength -- Use the timestamp or a multiple of the item length
    local regionEnd = (i < #scaledTimestamps) and scaledTimestamps[i + 1] or regionStart + itemLength -- Use the next timestamp or add the item length

    -- Add a region at the region start and end times
    reaper.AddProjectMarker(project, true, regionStart, regionEnd, regionNames[i] or "Region " .. i, -1)

    -- Create a new MIDI item on the track
    local item = reaper.CreateNewMIDIItemInProj(track, regionStart, regionEnd)

    -- Get the active take of the item
    local take = reaper.GetActiveTake(item)

    -- Insert a note on the take
    reaper.MIDI_InsertNote(take, false, false, 0, 960, 0, velocity, note, false)

    -- Alternatively, you could use reaper.InsertMedia to insert an audio file from your computer or the web, for example:
    -- reaper.InsertMedia("C:\\Users\\YourName\\Music\\Sample.wav", 0) -- Insert an audio file from your computer
    -- reaper.InsertMedia("https://www.bing.com/sounds/search?q=sample+audio", 0) -- Insert an audio file from the web
end
