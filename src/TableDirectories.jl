module TableDirectories
using Glob
using DataFrames

PatternElement = Union{Glob.GlobMatch,Glob.FilenameMatch,Regex,Base.String}
PatternArray = Array{PatternElement}
PatternType = Union{Glob.GlobMatch,Glob.FilenameMatch,Regex,Base.String,Array{PatternElement,1}}

"""
TableRoot(path, ::PatternType)

Defines the top directory and the file filter that will contain the rows of the table.
Example: TableRoot("/sys/bus/usb/devices", r"^[-0-9.]+") on a Linux system will generate a large table of USB device attributes.
The default regex is r".+" (i.e. all files in top directory) which for usb devices will also include end points, which have quite different attributes.
"""
struct TableRoot
    path::String
    filter::PatternType # make more general?
end

TableRoot(path) = TableRoot(path, r".+")


"""
rows(table_root)

Returns the rows of the table.
Example: rows(TableRoot("/sys/bus/usb/devices", r"^[-0-9.]+")) on a Linux system will return a Vector of RowRoot objects one for each USB device.
"""
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

struct Cell
    row_root::RowRoot
    subpath::String
end

function path(cell::Cell)::String
    joinpath(path(cell.row_root), cell.subpath)
end # Cell.path

function paths(cell::Cell)::Vector{String}
    readdir(path(cell); join = true)
end

"""
cell_value(cell)

Given a cell object returns its value
If file is a normal data file the value is the contents of the file.
If the file is not readable, the value is the string "not readable".
If the file is a link the value is the absolute path linked to.
If the file does not exist nothing is returned. This was perferred over missing which implies the value could theoretically be returned but circumstance prevented it.
Generally the file does not exist because it is not meaningful or not available such as the power consumption of a virtual device.
"""
function cell_value(cell::Cell)
    cell_path = path(cell)
    if islink(cell_path)
        realpath(cell_path)
    else
        if isfile(cell_path)
            try
                chomp(read(cell_path, String))
            catch error
                "not readable"
            end
        else
            if isdir(cell_path)
                sub_directory_files = readdir(cell_path)
                if sub_directory_files == []
                    missing
                else
                    cell_path * " is a directory containing: " * join(sub_directory_files, ", ")
                end
            else
                missing
            end
        end
    end
end # cell_value


function subpath(parent_cell::Cell, added_filename::String)::String
    parent_column.subpath * "/" * added_filename
end # subpath

function column_name_from_path(cell_path::String, row_root::RowRoot)::Cell
    sub_path = cell_path[length(path(row_root))+1:end]
    Cell(row_root, sub_path)
end # column_name_from_path

function find_all(root::String, filename::String)::Vector{Union{Missing,String}}
    map(readdir(root)) do path
        if filename == basename(path)
            path
        elseif isdir(path)
            find_all(path, filename)
        end
    end
end

"""
column_names(::RowRoot, column_path)

Returns Vector of column names of row.
Example: column_names(TableRoot("/sys/bus/usb/devices", r"^[-0-9.]+")) on a Linux system will return a Vector of column names one for each USB device.
If you want the union of all row's column_names use: names(data_frame())
"""

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
                    missing
                end
            end
        end
    end
    vcat(ret...)
end # column_names

function dict(row_root::RowRoot, subpaths::Vector{String})
    ret = Dict()
    for column_subpath in subpaths
        cell = Cell(row_root, column_subpath)
        ret[column_subpath] = cell_value(cell)
    end
    ret
end # dict
"""
data_frame(table_root, [subpaths])

Return a DataFrame
"""
function data_frame(table_root::TableRoot, subpaths::Vector{String})
    data_frame = DataFrame()
    for row_filename in rows(table_root)
        append!(data_frame, dict(row_filename, subpaths), cols = :union)
    end
    data_frame
end # data_frame

data_frame(table_root) = data_frame(table_root, column_names(rows(table_root)[1], ""))

end # TableDirectories
