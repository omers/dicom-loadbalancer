-- DICOM Tag Constants
local DICOM_TAGS = {
    MODALITY = 0x00080060,
    STUDY_INSTANCE_UID = 0x0020000D,
    SERIES_INSTANCE_UID = 0x0020000E,
    SOP_CLASS_UID = 0x00080016,
    PATIENT_ID = 0x00100020,
    INSTANCE_NUMBER = 0x00200013
}

-- Helper function to read Little Endian values from DICOM
local function read_uint16(data, offset)
    local b1, b2 = data:byte(offset, offset + 1)
    return b1 + (b2 * 256)
end

local function read_uint32(data, offset)
    local b1, b2, b3, b4 = data:byte(offset, offset + 3)
    return b1 + (b2 * 256) + (b3 * 65536) + (b4 * 16777216)
end

-- Read a DICOM string value
local function read_string(data, offset, length)
    return data:sub(offset, offset + length - 1)
end

-- Extract DICOM tag value
local function extract_tag_value(data, tag)
    local offset = 132  -- Start after preamble and DICOM prefix
    
    while offset < #data do
        local group = read_uint16(data, offset)
        local element = read_uint16(data, offset + 2)
        local current_tag = (group * 65536) + element
        
        -- VR (Value Representation)
        local vr = read_string(data, offset + 4, 2)
        local value_length = 0
        local value_offset = 0
        
        if vr == "OB" or vr == "OW" or vr == "SQ" or vr == "UN" then
            -- Skip 2 reserved bytes
            value_length = read_uint32(data, offset + 8)
            value_offset = offset + 12
        else
            value_length = read_uint16(data, offset + 6)
            value_offset = offset + 8
        end
        
        if current_tag == tag then
            return read_string(data, value_offset, value_length)
        end
        
        offset = value_offset + value_length
        -- Ensure alignment on even boundary
        if offset % 2 ~= 0 then
            offset = offset + 1
        end
    end
    
    return nil
end

-- Function to extract all relevant metadata from DICOM
local function extract_dicom_metadata(data)
    local metadata = {}
    
    for name, tag in pairs(DICOM_TAGS) do
        metadata[name] = extract_tag_value(data, tag)
    end
    
    return metadata
end

-- Backend selection based on metadata
local function select_backend(metadata)
    -- Route by modality
    if metadata.MODALITY then
        if metadata.MODALITY == "CT" then
            return "ct_servers"
        elseif metadata.MODALITY == "MR" then
            return "mr_servers"
        elseif metadata.MODALITY == "US" then
            return "ultrasound_servers"
        elseif metadata.MODALITY == "CR" or metadata.MODALITY == "DX" then
            return "xray_servers"
        end
    end
    
    -- Route by SOP Class UID for specialized processing
    if metadata.SOP_CLASS_UID then
        -- Storage commitment
        if metadata.SOP_CLASS_UID == "1.2.840.10008.1.20.1" then
            return "storage_servers"
        end
        -- Structured reporting
        if metadata.SOP_CLASS_UID:match("^1.2.840.10008.5.1.4.1.1.88") then
            return "reporting_servers"
        end
    end
    
    -- Route by patient ID for load balancing
    if metadata.PATIENT_ID then
        local patient_hash = 0
        for i = 1, #metadata.PATIENT_ID do
            patient_hash = patient_hash + metadata.PATIENT_ID:byte(i)
        end
        
        -- Simple hash-based routing to one of three general backends
        local backend_idx = (patient_hash % 3) + 1
        return "general_server_" .. backend_idx
    end
    
    -- Default backend if no routing rules matched
    return "default_backend"
end

-- Main function called by HAProxy
function dicom_route(txn)
    local data = txn.sf:req_body()
    
    -- Check if we have a valid DICOM file (look for DICM prefix after 128-byte preamble)
    if #data < 132 or data:sub(129, 132) ~= "DICM" then
        core.Warning("Not a valid DICOM file")
        return "default_backend"
    end
    
    local metadata = extract_dicom_metadata(data)
    local backend = select_backend(metadata)
    
    -- Log the decision for debugging
    core.Debug("DICOM routing: " .. (metadata.MODALITY or "unknown modality") .. 
               " to backend " .. backend)
    
    txn:set_var("txn.backend", backend)
    return backend
end

-- Register the function with HAProxy correctly for version 3.0
core.register_action("dicom_route", {"tcp-req", "tcp-res"}, dicom_route)
core.register_service("dicom_route", "tcp", function(applet)
    -- Read the DICOM data from the client
    local data = ""
    local size = 0
    
    -- Read at least 132 bytes to check DICOM header
    while size < 132 do
        local block = applet:receive()
        if block == nil then break end
        data = data .. block
        size = #data
    end
    
    -- Process the DICOM data
    if size < 132 or data:sub(129, 132) ~= "DICM" then
        core.Warning("Not a valid DICOM file")
        applet:set_var("txn.backend", "default_backend")
    else
        local metadata = extract_dicom_metadata(data)
        local backend = select_backend(metadata)
        applet:set_var("txn.backend", backend)
        
        -- Forward to the selected backend
        local server = core.backend(backend):pick_server()
        if server then
            applet:connect(server)
            applet:send(data)
            
            -- Pass remaining data between client and server
            while true do
                local client_data = applet:receive()
                if client_data == nil then break end
                applet:send(client_data)
            end
        end
    end
end)