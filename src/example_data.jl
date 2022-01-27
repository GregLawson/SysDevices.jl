using DataFrames
#using DataFramesMeta

include(joinpath(@__DIR__, "lib.jl"))
block_devices = TableDirectories.TableRoot("/sys/dev/block/")
partition = TableDirectories.RowRoot(block_devices, "8:1")
file_value = TableDirectories.Cell(partition, "power")
sparse_row = TableDirectories.RowRoot(block_devices, "11:0")
sparse_column = TableDirectories.Cell(sparse_row, "partition")
#TableDirectories.cell_value(file_value)

columns_dir = joinpath(TableDirectories.path(partition), "")
all_column_names = TableDirectories.column_names(partition)
TableDirectories.dict(partition, all_column_names)
data_frame = TableDirectories.data_frame(block_devices, all_column_names)

top_regex = r"^[-0-9]+$"
bus_regex = r"usb([1-9]+)"
endpoint_regex = r"^[-0-9.]+:.+$"
live_usb_devices = TableDirectories.data_frame(TableDirectories.TableRoot("/sys/bus/usb/devices", top_regex))
endpoint_data_frame = TableDirectories.data_frame(TableDirectories.TableRoot("/sys/bus/usb/devices", endpoint_regex))
#@show TableDirectories.discriminant(endpoint_data_frame)
#@show live_usb_devices[!, TableDirectories.unique_column_subpaths(live_usb_devices)]
live_usb_devices.port = getindex.(splitpath.(live_usb_devices.port), 8)
live_usb_devices[!, ["devnum", "devpath", "dev", "port"]]
#TableDirectories.default_columns(live_usb_devices)
eth0_dataframe = TableDirectories.data_frame(TableDirectories.TableRoot("/sys/class/net", r".+"))
