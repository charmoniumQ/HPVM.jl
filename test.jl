struct Node
    data::Ref{Int8}
end

struct Blob
    data::Ref{Int8}
end

struct LiveGraph
    data::Ref{Int8}
end

function llvm_hpvm_createNode(func)::Node
    # TODO: pass this type in properly
    llvm_func = @cfunction($func, Int, (Int, Int))
    # GC.@preserve llvm_func begin
        Node(
            ccall("llvm.hpvm.createNode", llvmcall, Ref{Int8}, (Ptr{Int8},), Base.unsafe_convert(Ptr{Cvoid}, llvm_func))
        )
    # end
end

function llvm_hpvm_bind_input(
    src::Node, dst::Node, broadcast::Bool, src_port::Int32,
    dst_port::Int32, streaming::Bool)::Void
    ccall(
        "llvm.hpvm.bind.input",
        llvmcall,
        Cvoid,
        (Ref{Int8}, Ref{Int8}, Bool, Int32, Int32, Bool),
        src.data, dst.data, broadcast, src_port, dst_port, streaming
    )
end

function llvm_hpvm_init()::Void
    ccall("llvm.hpvm.init", llvmcall, Cvoid, ())
end

function llvm_hpvm_cleanup()::Void
    ccall("llvm.hpvm.cleanup", llvmcall, Cvoid, ())
end

using InteractiveUtils

function comp_graph()
    node_abc = llvm_hpvm_createNode(*)
    llvm_hpvm_bind_input(node_abc, 0, 0)
    llvm_hpvm_bind_input(node_abc, 1, 1)
    # llvm_hpvm_bind_output(node_abc, 0, 0)

    # node_def = llvm_hpvm_createNode(*)
    # llvm_hpvm_bind_input(node_def, 0, 0)
    # llvm_hpvm_bind_input(node_def, 1, 1)
    # llvm_hpvm_bind_output(node_def, 0, 0)

    # node_cfg = llvm_hpvm_createNode(+)
    # llvm_hpvm_bind_input(node_cfg, 0, 0)
    # llvm_hpvm_bind_input(node_cfg, 1, 1)
    # llvm_hpvm_bind_output(node_cfg, 0, 0)
end

function main()
    # TODO: use a block here
    llvm_hpvm_init()

    # TODO: do argument passing without copies

    # llvm_hpvm_launch(comp_graph, (2, 3, 4, 5), )

    llvm_hpvm_cleanup()
end

# InteractiveUtils.@code_llvm optimize=false dump_module=true debuginfo=:source llvm_hpvm_createNode(*, Int, Int, Int)
InteractiveUtils.@code_llvm optimize=false dump_module=true debuginfo=:source main()
InteractiveUtils.@code_llvm optimize=false dump_module=true debuginfo=:source llvm_hpvm_init()
InteractiveUtils.@code_llvm optimize=false dump_module=true debuginfo=:source llvm_hpvm_cleanup()
InteractiveUtils.@code_llvm optimize=false dump_module=true debuginfo=:source llvm_hpvm_createNode(*)
node = llvm_hpvm_createNode(*)
InteractiveUtils.@code_llvm optimize=false dump_module=true debuginfo=:source llvm_hpvm_bind_input(node, 0, 0)
