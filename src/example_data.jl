using DataFrames
using DataFramesMeta

include(joinpath(@__DIR__, "lib.jl"))

partition = TableDirectories.RowRoot(TableDirectories.block_devices, "8:1")
file_value = TableDirectories.Column(partition, "power")
#TableDirectories.column_value(file_value)
TableDirectories.path(file_value)
TableDirectories.path(partition)
columns_dir = joinpath(TableDirectories.path(partition), "")
value_names = TableDirectories.column_names(partition)
TableDirectories.dict(partition, value_names)
data_frame = TableDirectories.data_frame(TableDirectories.block_devices, value_names)
TableDirectories.column_types(data_frame, value_names)
classification = TableDirectories.classify_columns(data_frame, value_names)
#getindex.(classification[:constant], 1)
@show TableDirectories.discriminant(data_frame, value_names)
