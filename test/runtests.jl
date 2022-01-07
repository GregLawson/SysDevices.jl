#using SysDevices
#using PathTrees
using Test

include(joinpath(@__DIR__, "../src/example_data.jl"))


@testset "devices" begin
    @test SysDevices.devices(SysDevices.usb_devices) !== []
end # devices


@testset "path" begin
    @test SysDevices.path(partition) == "/sys/dev/block/8:1"
end # path

@testset "Attribute.path" begin
    @test SysDevices.path(file_value) == "/sys/dev/block/8:1/power"
end # Attribute.path

@testset "subpath" begin
    #@test subpath(attribute, basename(attribute_path)) == "power/async"
end # subpath

@testset "attribute_name_from_path" begin
    #@test attribute_name_from_path(attribute_path).subpath == "power"
end # attribute_name_from_path

@testset "find_all" begin
    subsystems = filter(SysDevices.find_all("/sys/devices", "subsystem")) do attribute
        !isnothing(attribute)
    end
    @test subsystems == []
end # attribute_name_from_path


@testset "file_tree_roots()" begin
    #@test @subset(file_tree_roots(), :partition .!== nothing) == @subset(file_tree_roots(), :bdi .== nothing)
    @test SysDevices.attribute_names(partition, "holders") == []
end

@testset "attribute_names" begin
    subpath = "power"
    attribute_path = SysDevices.path(file_value)
    #@test Main.attribute.file_tree_root == Main.partition
    #@test attribute.subpath == subpath
    @test !islink(attribute_path)
    @test !isfile(attribute_path)
    @test isdir(attribute_path)
    @test basename(attribute_path) == "power"
    #@test attribute_name_from_path(sub_attribute_path, parent_attribute.file_tree_root).subpath == "power/async"
    #@test attribute_names(partition, sub_attribute_name(attribute, basename(attribute_path)))

    path = joinpath(SysDevices.path(partition), subpath)
    @test path == "/sys/dev/block/8:1/power"
    attribute_paths = readdir(path; join = true)
    #@test attribute_paths == ["/sys/dev/block/8:18/power/async", "/sys/dev/block/8:18/power/autosuspend_delay_ms", "/sys/dev/block/8:18/power/control", "/sys/dev/block/8:18/power/runtime_active_kids", "/sys/dev/block/8:18/power/runtime_active_time", "/sys/dev/block/8:18/power/runtime_enabled", "/sys/dev/block/8:18/power/runtime_status", "/sys/dev/block/8:18/power/runtime_suspended_time", "/sys/dev/block/8:18/power/runtime_usage"]
    #paths = paths(attribute)
    #@test paths == ["/sys/dev/block/8:18/power/async", "/sys/dev/block/8:18/power/autosuspend_delay_ms", "/sys/dev/block/8:18/power/control", "/sys/dev/block/8:18/power/runtime_active_kids", "/sys/dev/block/8:18/power/runtime_active_time", "/sys/dev/block/8:18/power/runtime_enabled", "/sys/dev/block/8:18/power/runtime_status", "/sys/dev/block/8:18/power/runtime_suspended_time", "/sys/dev/block/8:18/power/runtime_usage"]
    #subpath * "/" .* basename.(attribute_path)
    @test SysDevices.attribute_names(partition, "power") == ["power/async", "power/autosuspend_delay_ms", "power/control", "power/runtime_active_kids", "power/runtime_active_time", "power/runtime_enabled", "power/runtime_status", "power/runtime_suspended_time", "power/runtime_usage"]
    #SysDevices.attribute_names(partition, "")
    SysDevices.attribute_names(partition)
end # attribute_names
