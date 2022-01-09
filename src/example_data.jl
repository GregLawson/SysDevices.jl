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

TableDirectories.classify_columns(TableDirectories.data_frame(TableDirectories.block_devices))
TableDirectories.classify_columns(TableDirectories.data_frame(TableDirectories.loops))
TableDirectories.classify_columns(TableDirectories.data_frame(TableDirectories.char_devices))
TableDirectories.classify_columns(TableDirectories.data_frame(TableDirectories.devices))
TableDirectories.classify_columns(TableDirectories.data_frame(TableDirectories.drivers))
TableDirectories.classify_columns(TableDirectories.data_frame(TableDirectories.TableRoot("/sys/bus/usb/devices")))

# all_regex = r"^.+$"
# full_regex = r"^[-0-9.:]+$"
# device_regex = r"^[-0-9.]+$"
top_regex = r"^[-0-9]+$"
bus_regex = r"usb([1-9]+)"
endpoint_regex = r"^[-0-9.]+:.+$"
live_usb_devices = TableDirectories.data_frame(TableDirectories.TableRoot("/sys/bus/usb/devices", top_regex))
top_usb = TableDirectories.classify_columns(live_usb_devices)
bus_usb = TableDirectories.classify_columns(TableDirectories.data_frame(TableDirectories.TableRoot("/sys/bus/usb/devices", bus_regex)))
endpoint_usb = TableDirectories.classify_columns(TableDirectories.data_frame(TableDirectories.TableRoot("/sys/bus/usb/devices", endpoint_regex)))
endpoint_data_frame = TableDirectories.data_frame(TableDirectories.TableRoot("/sys/bus/usb/devices", endpoint_regex))
@show TableDirectories.discriminant(endpoint_data_frame)
#@show live_usb_devices[!, TableDirectories.unique_column_subpaths(live_usb_devices)]
live_usb_devices.port = getindex.(splitpath.(live_usb_devices.port), 8)
@show live_usb_devices[!, ["devnum", "devpath", "dev", "port"]]
