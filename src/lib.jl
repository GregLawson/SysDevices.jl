module SysDevices
using Glob
using DataFrames
using FreqTables
struct ClassRoot
    path::String
end

syses = readdir("/sys")
devs = readdir("/sys/dev")
block_devices = ClassRoot("/sys/dev/block/")
loops = SysDevices.ClassRoot("/sys/devices/virtual/block/")
char_devices = ClassRoot("/sys/dev/char/")
usb_devices = ClassRoot("/sys/bus/usb/devices")

function devices(class_root::ClassRoot)::Vector{DeviceRoot}
    map(readdir(class_root.path)) do device
        DeviceRoot(class_root, device)
    end
end # devices

struct DeviceRoot
    class_root::ClassRoot
    device::String
end

function path(device_root::DeviceRoot)::String
    joinpath(device_root.class_root.path, device_root.device)
end # path

function paths(device_root::DeviceRoot)::Vector{String}
    readdir(path(device_root); join = true)
end

struct Attribute
    device_root::DeviceRoot
    subpath::String
end

function path(attribute::Attribute)::String
    joinpath(path(attribute.device_root), attribute.subpath)
end # Attribute.path

function paths(attribute::Attribute)::Vector{String}
    readdir(path(attribute); join = true)
end


function attribute_value(attribute::Attribute)
    attribute_path = path(attribute)
    if islink(attribute_path)
        replace(readlink(attribute_path), r"\.\./" => "") # remove long strings of parent directories (i.e. ../)
    else
        if isfile(attribute_path)
            chomp(read(attribute_path, String))
        else
            if isdir(attribute_path)
                sub_directory_files = readdir(attribute_path)
                if sub_directory_files == []
                    nothing
                else
                    attribute_path * " is a directory containing: " * join(sub_directory_files, ", ")
                end
            else
                nothing
            end
        end
    end
end


function subpath(parent_attribute::Attribute, added_filename::String)::String
    parent_attribute.subpath * "/" * added_filename
end # subpath

function attribute_name_from_path(attribute_path::String, device_root::DeviceRoot)::Attribute
    sub_path = attribute_path[length(path(device_root))+1:end]
    Attribute(device_root, sub_path)
end # attribute_name_from_path

function find_all(root::String, filename::String)::Vector{Union{Nothing,String}}
    map(readdir(root)) do path
        if filename == basename(path)
            path
        elseif isdir(path)
            find_all(path, filename)
        end
    end
end

function attribute_names(device_root::DeviceRoot, path = "")::Vector{String}
    attributes_dir = joinpath(SysDevices.path(device_root), path)
    ret = map(readdir(attributes_dir)) do sub_attribute
        sub_attribute_path = joinpath(attributes_dir, sub_attribute)
        if islink(sub_attribute_path)
            joinpath(path, sub_attribute)
        else
            if isfile(sub_attribute_path)
                joinpath(path, sub_attribute)
            else
                if isdir(sub_attribute_path)
                    attribute_names(device_root, joinpath(path, sub_attribute))
                else
                    nothing
                end
            end
        end
    end
    vcat(ret...)
end # attribute_names

function dict(device_root::DeviceRoot, subpaths::Vector{String})
    ret = Dict()
    for attribute_name in subpaths
        attribute = Attribute(device_root, attribute_name)
        ret[attribute_name] = attribute_value(attribute)
    end
    ret
end # dict

function data_frame(class_root::ClassRoot, subpaths::Vector{String})
    data_frame = DataFrame()
    for device in devices(class_root)
        append!(data_frame, dict(device, subpaths), cols = :union)
    end
    data_frame
end

function column_type(data_frame::DataFrame, column_name::String)
    frequencies = freqtable(data_frame, column_name)
    #frequencies = freqtable(column)
    (size(data_frame)[1], length(frequencies))
    if length(frequencies) == 1
        :constant
    elseif length(frequencies) == size(data_frame)[1]
        :unique
    else
        length(frequencies) / size(data_frame)[1]
    end
end

function column_types(data_frame::DataFrame, subpaths::Vector{String})
    map(subpaths) do subpath
        (subpath, column_type(data_frame, subpath))
    end
end

function classify_columns(data_frame::DataFrame, subpaths::Vector{String})
    uniques = getindex.(filter(column_types(data_frame, subpaths)) do tuple
        tuple[2] == :unique
    end, 1)
    constants = getindex.(filter(column_types(data_frame, subpaths)) do tuple
        tuple[2] == :constant
    end, 1)
    discriminants = setdiff(subpaths, union(uniques, constants))
    Dict(:unique => uniques, :constant => constants, :discriminant => discriminants)
end

function unique(data_frame::DataFrame, subpaths::Vector{String})
    unique_columns = classify_columns(data_frame, subpaths)[:unique]
    data_frame[:, unique_columns]
end

function constant(data_frame::DataFrame, subpaths::Vector{String})
    constant_columns = classify_columns(data_frame, subpaths)[:constant]
    data_frame[:, constant_columns]
end

function discriminant(data_frame::DataFrame, subpaths::Vector{String})
    constant_columns = classify_columns(data_frame, subpaths)[:discriminant]
    data_frame[:, constant_columns]
end
end # SysDevices
