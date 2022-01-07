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

function attribute_names(file_tree_root::SysDisk)
    attribute_names(file_tree_root.path, "")
end

function attribute_name_sets()
    unique(attribute_names.(disks()))
end

function all_attribute_names()
    unique(vcat(attribute_name_sets()...))
end


function classify(file_tree_root::SysDisk)
    bdi = SysDisk.attribute_value(Attribute(file_tree_root, "bdi"))
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
        :partition => SysDisk.attribute_value.(Attribute.(disks(), "partition")),
        :dev => SysDisk.attribute_value.(Attribute.(disks(), "dev")),
        :bdi => SysDisk.attribute_value.(Attribute.(disks(), "bdi")),
        :capability => SysDisk.attribute_value.(Attribute.(disks(), "capability")),
        :diskseq => SysDisk.attribute_value.(Attribute.(disks(), "diskseq")),
        :events => SysDisk.attribute_value.(Attribute.(disks(), "events")),
        :events_async => SysDisk.attribute_value.(Attribute.(disks(), "events_async")),
        :events_poll_msecs => SysDisk.attribute_value.(Attribute.(disks(), "events_poll_msecs")),
        :ext_range => SysDisk.attribute_value.(Attribute.(disks(), "ext_range")),
        :hidden => SysDisk.attribute_value.(Attribute.(disks(), "hidden")),
        :integrity => SysDisk.attribute_value.(Attribute.(disks(), "integrity")),
        :mq => SysDisk.attribute_value.(Attribute.(disks(), "mq")),
        :queue => SysDisk.attribute_value.(Attribute.(disks(), "queue")),
        :range => SysDisk.attribute_value.(Attribute.(disks(), "range")),
        :removable => SysDisk.attribute_value.(Attribute.(disks(), "removable")),
        :slaves => SysDisk.attribute_value.(Attribute.(disks(), "slaves")),
        :device_state => SysDisk.attribute_value.(Attribute.(disks(), "device/state")),
        :device_blacklist => SysDisk.attribute_value.(Attribute.(disks(), "device/blacklist")),
        :device_device_blocked => SysDisk.attribute_value.(Attribute.(disks(), "device/device_blocked")),
        :device_device_busy => SysDisk.attribute_value.(Attribute.(disks(), "device/device_busy")),
        :device_dh_state => SysDisk.attribute_value.(Attribute.(disks(), "device/dh_state")),
        :device_eh_timeout => SysDisk.attribute_value.(Attribute.(disks(), "device/eh_timeout")),
        :device_iocounterbits => SysDisk.attribute_value.(Attribute.(disks(), "device/iocounterbits")),
        :device_max_sectors => SysDisk.attribute_value.(Attribute.(disks(), "device/max_sectors")),
        :device_modalias => SysDisk.attribute_value.(Attribute.(disks(), "device/modalias")),
        :device_model => SysDisk.attribute_value.(Attribute.(disks(), "device/model")),
        :device_queue_depth => SysDisk.attribute_value.(Attribute.(disks(), "device/queue_depth")),
        :device_queue_type => SysDisk.attribute_value.(Attribute.(disks(), "device/queue_type")),
        :device_rev => SysDisk.attribute_value.(Attribute.(disks(), "device/rev")),
        :device_scsi_level => SysDisk.attribute_value.(Attribute.(disks(), "device/scsi_level")),
        :device_timeout => SysDisk.attribute_value.(Attribute.(disks(), "device/timeout")),
        :device_type => SysDisk.attribute_value.(Attribute.(disks(), "device/type")),
        :device_uevent => SysDisk.attribute_value.(Attribute.(disks(), "device/uevent")),
        :device_vendor => SysDisk.attribute_value.(Attribute.(disks(), "device/vendor")),
        :device_wwid => SysDisk.attribute_value.(Attribute.(disks(), "device/wwid")),
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
    insertcols!(data_frame, :partition => SysDisk.attribute_value.(data_frame.sys_device, "partition"))
    insertcols!(data_frame, :device => SysDisk.attribute_value.(data_frame.sys_device, "device"))
    insertcols!(data_frame, :dev => SysDisk.attribute_value.(data_frame.sys_device, "dev"))
    data_frame
end

partition = SysDevices.DeviceRoot(SysDevices.block_devices, "8:1")
file_value = SysDevices.Attribute(partition, "power")
#SysDevices.attribute_value(file_value)
SysDevices.path(file_value)
SysDevices.path(partition)
attributes_dir = joinpath(SysDevices.path(partition), "")
value_names = SysDevices.attribute_names(partition)
SysDevices.dict(partition, value_names)
data_frame = SysDevices.data_frame(SysDevices.block_devices, value_names)
SysDevices.column_types(data_frame, value_names)
classification = SysDevices.classify_columns(data_frame, value_names)
#getindex.(classification[:constant], 1)
@show SysDevices.discriminant(data_frame, value_names)
