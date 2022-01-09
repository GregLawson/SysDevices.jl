using DataFrames
using DataFramesMeta

include(joinpath(@__DIR__, "lib.jl"))


struct SysDisk
    major::Int32
    minor::Int32
end

function disks()
    map(readdir("/sys/dev/block/")) do filename
        SysDisk(parse.(Int16, split(filename, ':'))...)
    end
end

function column_names(file_tree_root::SysDisk)
    column_names(file_tree_root.path, "")
end

function column_name_sets()
    unique(column_names.(disks()))
end

function all_column_names()
    unique(vcat(column_name_sets()...))
end


function classify(file_tree_root::SysDisk)
    bdi = SysDisk.column_value(Column(file_tree_root, "bdi"))
    if isnothing(bdi)
        :mountable_partition
    elseif bdi[1:3] == "vir"
        :virtual_bdi
    else
        :normal_drive
    end
end

function file_tree_roots()::DataFrame
    DataFrame(
        :disk => disks(),
        :classify => classify.(disks()),
        :partition => SysDisk.column_value.(Column.(disks(), "partition")),
        :dev => SysDisk.column_value.(Column.(disks(), "dev")),
        :bdi => SysDisk.column_value.(Column.(disks(), "bdi")),
        :capability => SysDisk.column_value.(Column.(disks(), "capability")),
        :diskseq => SysDisk.column_value.(Column.(disks(), "diskseq")),
        :events => SysDisk.column_value.(Column.(disks(), "events")),
        :events_async => SysDisk.column_value.(Column.(disks(), "events_async")),
        :events_poll_msecs => SysDisk.column_value.(Column.(disks(), "events_poll_msecs")),
        :ext_range => SysDisk.column_value.(Column.(disks(), "ext_range")),
        :hidden => SysDisk.column_value.(Column.(disks(), "hidden")),
        :integrity => SysDisk.column_value.(Column.(disks(), "integrity")),
        :mq => SysDisk.column_value.(Column.(disks(), "mq")),
        :queue => SysDisk.column_value.(Column.(disks(), "queue")),
        :range => SysDisk.column_value.(Column.(disks(), "range")),
        :removable => SysDisk.column_value.(Column.(disks(), "removable")),
        :slaves => SysDisk.column_value.(Column.(disks(), "slaves")),
        :device_state => SysDisk.column_value.(Column.(disks(), "device/state")),
        :device_blacklist => SysDisk.column_value.(Column.(disks(), "device/blacklist")),
        :device_device_blocked => SysDisk.column_value.(Column.(disks(), "device/device_blocked")),
        :device_device_busy => SysDisk.column_value.(Column.(disks(), "device/device_busy")),
        :device_dh_state => SysDisk.column_value.(Column.(disks(), "device/dh_state")),
        :device_eh_timeout => SysDisk.column_value.(Column.(disks(), "device/eh_timeout")),
        :device_iocounterbits => SysDisk.column_value.(Column.(disks(), "device/iocounterbits")),
        :device_max_sectors => SysDisk.column_value.(Column.(disks(), "device/max_sectors")),
        :device_modalias => SysDisk.column_value.(Column.(disks(), "device/modalias")),
        :device_model => SysDisk.column_value.(Column.(disks(), "device/model")),
        :device_queue_depth => SysDisk.column_value.(Column.(disks(), "device/queue_depth")),
        :device_queue_type => SysDisk.column_value.(Column.(disks(), "device/queue_type")),
        :device_rev => SysDisk.column_value.(Column.(disks(), "device/rev")),
        :device_scsi_level => SysDisk.column_value.(Column.(disks(), "device/scsi_level")),
        :device_timeout => SysDisk.column_value.(Column.(disks(), "device/timeout")),
        :device_type => SysDisk.column_value.(Column.(disks(), "device/type")),
        :device_uevent => SysDisk.column_value.(Column.(disks(), "device/uevent")),
        :device_vendor => SysDisk.column_value.(Column.(disks(), "device/vendor")),
        :device_wwid => SysDisk.column_value.(Column.(disks(), "device/wwid")),
    )
end

function mountable_partitions()
    @subset(file_tree_roots(), :partition .!== nothing)
end

function proc_partitions()
    file_string = read("/proc/partitions")
    data_frame = CSV.read(file_string, DataFrame; delim = ' ', ignorerepeated = true, skipto = 2, header = [:major, :minor, :blocks, :name],
        types = [Int32, Int32, Int64, String])
    data_frame.sys_device = SysDisk.(data_frame.major, data_frame.minor)
    select!(data_frame, :name, :sys_device, :blocks)
    insertcols!(data_frame, :partition => SysDisk.column_value.(data_frame.sys_device, "partition"))
    insertcols!(data_frame, :device => SysDisk.column_value.(data_frame.sys_device, "device"))
    insertcols!(data_frame, :dev => SysDisk.column_value.(data_frame.sys_device, "dev"))
    data_frame
end

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
