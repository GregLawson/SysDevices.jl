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

@testset "Cell.path" begin
    @test TableDirectories.path(file_value) == "/sys/dev/block/8:1/power"
end # Cell.path

@testset "cell_value" begin
    @test sum(isnothing.(data_frame[!, "partition"])) > 0
end # cell_value

@testset "subpath" begin
    #@test subpath(cell, basename(cell_path)) == "power/async"
end # subpath

@testset "column_name_from_path" begin
    #@test column_name_from_path(cell_path).subpath == "power"
end # column_name_from_path

@testset "find_all" begin
    subsystems = filter(TableDirectories.find_all("/sys/devices", "subsystem")) do cell
        !isnothing(cell)
    end
    @test subsystems == []
end # column_name_from_path


@testset "file_tree_roots()" begin
    #@test @subset(file_tree_roots(), :partition .!== nothing) == @subset(file_tree_roots(), :bdi .== nothing)
    @test TableDirectories.column_names(partition, "holders") == []
end

@testset "column_names" begin
    subpath = "power"
    cell_path = TableDirectories.path(file_value)
    #@test Main.cell.file_tree_root == Main.partition
    #@test cell.subpath == subpath
    @test !islink(cell_path)
    @test !isfile(cell_path)
    @test isdir(cell_path)
    @test basename(cell_path) == "power"
    #@test column_name_from_path(sub_column_path, parent_column.file_tree_root).subpath == "power/async"
    #@test column_names(partition, sub_column_name(cell, basename(cell_path)))

    path = joinpath(TableDirectories.path(partition), subpath)
    @test path == "/sys/dev/block/8:1/power"
    column_paths = readdir(path; join = true)
    #@test column_paths == ["/sys/dev/block/8:18/power/async", "/sys/dev/block/8:18/power/autosuspend_delay_ms", "/sys/dev/block/8:18/power/control", "/sys/dev/block/8:18/power/runtime_active_kids", "/sys/dev/block/8:18/power/runtime_active_time", "/sys/dev/block/8:18/power/runtime_enabled", "/sys/dev/block/8:18/power/runtime_status", "/sys/dev/block/8:18/power/runtime_suspended_time", "/sys/dev/block/8:18/power/runtime_usage"]
    #paths = paths(cell)
    #@test paths == ["/sys/dev/block/8:18/power/async", "/sys/dev/block/8:18/power/autosuspend_delay_ms", "/sys/dev/block/8:18/power/control", "/sys/dev/block/8:18/power/runtime_active_kids", "/sys/dev/block/8:18/power/runtime_active_time", "/sys/dev/block/8:18/power/runtime_enabled", "/sys/dev/block/8:18/power/runtime_status", "/sys/dev/block/8:18/power/runtime_suspended_time", "/sys/dev/block/8:18/power/runtime_usage"]
    #subpath * "/" .* basename.(cell_path)
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
