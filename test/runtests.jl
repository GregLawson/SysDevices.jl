#using TableDirectories
#using PathTrees
using Test

include(joinpath(@__DIR__, "../src/example_data.jl"))


@testset "rows" begin
    @test TableDirectories.rows(TableDirectories.usb_devices) !== []
end # rows


@testset "path" begin
    @test TableDirectories.path(partition) == "/sys/dev/block/8:1"
end # path

@testset "Column.path" begin
    @test TableDirectories.path(file_value) == "/sys/dev/block/8:1/power"
end # Column.path

@testset "column_value" begin
    @test sum(isnothing.(data_frame[!, "partition"])) > 0
end # column_value

@testset "subpath" begin
    #@test subpath(column, basename(column_path)) == "power/async"
end # subpath

@testset "column_name_from_path" begin
    #@test column_name_from_path(column_path).subpath == "power"
end # column_name_from_path

@testset "find_all" begin
    subsystems = filter(TableDirectories.find_all("/sys/devices", "subsystem")) do column
        !isnothing(column)
    end
    @test subsystems == []
end # column_name_from_path


@testset "file_tree_roots()" begin
    #@test @subset(file_tree_roots(), :partition .!== nothing) == @subset(file_tree_roots(), :bdi .== nothing)
    @test TableDirectories.column_names(partition, "holders") == []
end

@testset "column_names" begin
    subpath = "power"
    column_path = TableDirectories.path(file_value)
    #@test Main.column.file_tree_root == Main.partition
    #@test column.subpath == subpath
    @test !islink(column_path)
    @test !isfile(column_path)
    @test isdir(column_path)
    @test basename(column_path) == "power"
    #@test column_name_from_path(sub_column_path, parent_column.file_tree_root).subpath == "power/async"
    #@test column_names(partition, sub_column_name(column, basename(column_path)))

    path = joinpath(TableDirectories.path(partition), subpath)
    @test path == "/sys/dev/block/8:1/power"
    column_paths = readdir(path; join = true)
    #@test column_paths == ["/sys/dev/block/8:18/power/async", "/sys/dev/block/8:18/power/autosuspend_delay_ms", "/sys/dev/block/8:18/power/control", "/sys/dev/block/8:18/power/runtime_active_kids", "/sys/dev/block/8:18/power/runtime_active_time", "/sys/dev/block/8:18/power/runtime_enabled", "/sys/dev/block/8:18/power/runtime_status", "/sys/dev/block/8:18/power/runtime_suspended_time", "/sys/dev/block/8:18/power/runtime_usage"]
    #paths = paths(column)
    #@test paths == ["/sys/dev/block/8:18/power/async", "/sys/dev/block/8:18/power/autosuspend_delay_ms", "/sys/dev/block/8:18/power/control", "/sys/dev/block/8:18/power/runtime_active_kids", "/sys/dev/block/8:18/power/runtime_active_time", "/sys/dev/block/8:18/power/runtime_enabled", "/sys/dev/block/8:18/power/runtime_status", "/sys/dev/block/8:18/power/runtime_suspended_time", "/sys/dev/block/8:18/power/runtime_usage"]
    #subpath * "/" .* basename.(column_path)
    @test TableDirectories.column_names(partition, "power") == ["power/async", "power/autosuspend_delay_ms", "power/control", "power/runtime_active_kids", "power/runtime_active_time", "power/runtime_enabled", "power/runtime_status", "power/runtime_suspended_time", "power/runtime_usage"]
    #TableDirectories.column_names(partition, "")
    TableDirectories.column_names(partition)
end # column_names

@testset "dict" begin
end # dict

@testset "data_frame" begin
			#TableDirectories.data_frame()
end # data_frame

@testset "column_frequency_stats" begin
end # column_frequency_stats

@testset "classify_columns" begin
    @test TableDirectories.classify_columns(data_frame)[:unique] == ["dev", "uevent"]
end # classify_columns
