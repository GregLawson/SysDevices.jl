module TableDirectories
using Glob
using DataFrames
using FreqTables
struct TableRoot
    path::String
    filter::Regex # make more general?
end

TableRoot(path) = TableRoot(path, r".+")

syses = readdir("/sys")
devs = readdir("/sys/dev")
block_devices = TableRoot("/sys/dev/block/")
loops = TableDirectories.TableRoot("/sys/devices/virtual/block/")
char_devices = TableRoot("/sys/dev/char/")
usb_devices = TableRoot("/sys/bus/usb/devices")
devices = TableRoot("/sys/devices/")
drivers = TableDirectories.TableRoot("/sys/bus/usb/drivers/")

all_regex = r"^.+$"
full_regex = r"^[-0-9.:]+$"
device_regex = r"^[-0-9.]+$"
top_regex = r"^[-0-9]+$"
bus_regex = r"usb([1-9]+)"
endpoint_regex = r"^[-0-9.]+:.+$"

function rows(table_root::TableRoot)::Vector{RowRoot}
    map(glob([table_root.filter], table_root.path)) do row_filename
        RowRoot(table_root, row_filename)
    end
end # rows

struct RowRoot
    table_root::TableRoot
    row_filename::String
end

function path(row_root::RowRoot)::String
    joinpath(row_root.table_root.path, row_root.row_filename)
end # path

function paths(row_root::RowRoot)::Vector{String}
    readdir(path(row_root); join = true)
end

struct Column
    row_root::RowRoot
    subpath::String
end

function path(column::Column)::String
    joinpath(path(column.row_root), column.subpath)
end # Column.path

function paths(column::Column)::Vector{String}
    readdir(path(column); join = true)
end


function column_value(column::Column)
    column_path = path(column)
    if islink(column_path)
        realpath(column_path)
    else
        if isfile(column_path)
            try
                chomp(read(column_path, String))
            catch error
                "not readable"
            end
        else
            if isdir(column_path)
                sub_directory_files = readdir(column_path)
                if sub_directory_files == []
                    nothing
                else
                    column_path * " is a directory containing: " * join(sub_directory_files, ", ")
                end
            else
                nothing
            end
        end
    end
end # column_value


function subpath(parent_column::Column, added_filename::String)::String
    parent_column.subpath * "/" * added_filename
end # subpath

function column_name_from_path(column_path::String, row_root::RowRoot)::Column
    sub_path = column_path[length(path(row_root))+1:end]
    Column(row_root, sub_path)
end # column_name_from_path

function find_all(root::String, filename::String)::Vector{Union{Nothing,String}}
    map(readdir(root)) do path
        if filename == basename(path)
            path
        elseif isdir(path)
            find_all(path, filename)
        end
    end
end

function column_names(row_root::RowRoot, path = "")::Vector{String}
    columns_dir = joinpath(TableDirectories.path(row_root), path)
    ret = map(readdir(columns_dir)) do sub_column
        sub_column_path = joinpath(columns_dir, sub_column)
        if islink(sub_column_path)
            joinpath(path, sub_column)
        else
            if isfile(sub_column_path)
                joinpath(path, sub_column)
            else
                if isdir(sub_column_path)
                    column_names(row_root, joinpath(path, sub_column))
                else
                    nothing
                end
            end
        end
    end
    vcat(ret...)
end # column_names

function dict(row_root::RowRoot, subpaths::Vector{String})
    ret = Dict()
    for column_subpath in subpaths
        column = Column(row_root, column_subpath)
        ret[column_subpath] = column_value(column)
    end
    ret
end # dict

function data_frame(table_root::TableRoot, subpaths::Vector{String})
    data_frame = DataFrame()
    for row_filename in rows(table_root)
        append!(data_frame, dict(row_filename, subpaths), cols = :union)
    end
    data_frame
end # data_frame

data_frame(table_root) = data_frame(table_root, column_names(rows(table_root)[1], ""))

function column_frequency_stats(data_frame::DataFrame, column_subpath::String)
    frequencies = freqtable(data_frame, column_subpath)
    number_nothing = sum(isnothing.(data_frame[!, column_subpath]))
    Dict(
        :number_nothing => number_nothing,
        :rows => size(data_frame)[1],
        :number_distinct => length(frequencies),
        :ratio => Rational(length(frequencies), (size(data_frame)[1] - number_nothing)),
    )
end # column_frequency_stats

function column_ratio(data_frame::DataFrame, column_subpath::String)
    frequencies = freqtable(data_frame, column_subpath)
    number_nothing = if in(nothing, frequencies)
        frequencies[nothing]
    else
        0
    end
    Rational(length(frequencies), (size(data_frame)[1] - number_nothing))
end

function column_type(data_frame::DataFrame, column_subpath::String)
    ratio = column_ratio(data_frame, column_subpath)
    if ratio == 1 // 1
        :unique
    elseif ratio.num == 1 && ratio.den == size(data_frame)[1]
        :constant
    else
        ratio
    end
end

function column_types(data_frame::DataFrame, subpaths::Vector{String})
    map(subpaths) do subpath
        (subpath, column_type(data_frame, subpath))
    end
end

function column_ratios(data_frame::DataFrame, subpaths::Vector{String})
    map(subpaths) do subpath
        (subpath, column_ratio(data_frame, subpath))
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
end # classify_columns

classify_columns(data_frame) = classify_columns(data_frame, names(data_frame))

function unique(data_frame::DataFrame, subpaths::Vector{String})
    unique_columns = classify_columns(data_frame, subpaths)[:unique]
    data_frame[:, unique_columns]
end

unique(data_frame) = unique(data_frame, names(data_frame))

function constant(data_frame::DataFrame, subpaths::Vector{String})
    constant_columns = classify_columns(data_frame, subpaths)[:constant]
    data_frame[:, constant_columns]
end

function discriminant(data_frame::DataFrame, subpaths::Vector{String})
    constant_columns = classify_columns(data_frame, subpaths)[:discriminant]
    data_frame[:, constant_columns]
end

discriminant(data_frame) = discriminant(data_frame, names(data_frame))

function unique_column_subpaths(data_frame::DataFrame, subpaths::Vector{String})
    classify_columns(data_frame, subpaths)[:unique]
end
unique_column_subpaths(data_frame) = unique_column_subpaths(data_frame, names(data_frame))

function variable_column_subpaths(data_frame::DataFrame, subpaths::Vector{String})
    append!(classify_columns(data_frame, subpaths)[:unique], classify_columns(data_frame, subpaths)[:discriminant])
end
variable_column_subpaths(data_frame) = variable_column_subpaths(data_frame, default_columns(data_frame))

function sort_columns(data_frame::DataFrame)
    sort(map(names(data_frame)) do column_name
        (TableDirectories.column_frequency_stats(data_frame, column_name)[:number_distinct], column_name)
    end)
end

function default_columns(data_frame::DataFrame)
    number_display_columns = min(5, size(data_frame)[1])
    map(sort_columns(data_frame)[end-number_display_columns:end]) do pair
        pair[2]
    end
end
end # TableDirectories
