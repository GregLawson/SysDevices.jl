using DataFrames
using DataFramesMeta

include(joinpath(@__DIR__, "lib.jl"))

partition = TableDirectories.RowRoot(TableDirectories.block_devices, "8:1")
file_value = TableDirectories.Column(partition, "power")
sparse_row = TableDirectories.RowRoot(TableDirectories.block_devices, "11:0")
sparse_column = TableDirectories.Column(sparse_row, "partition")
#TableDirectories.column_value(file_value)

columns_dir = joinpath(TableDirectories.path(partition), "")
all_column_names = TableDirectories.column_names(partition)
TableDirectories.dict(partition, all_column_names)
data_frame = TableDirectories.data_frame(TableDirectories.block_devices, all_column_names)
TableDirectories.column_types(data_frame, all_column_names)
classification = TableDirectories.classify_columns(data_frame, all_column_names)
#getindex.(classification[:constant], 1)
@show TableDirectories.discriminant(data_frame, all_column_names)
@show TableDirectories.column_frequency_stats(data_frame, "partition")
