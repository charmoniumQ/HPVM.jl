struct Node
    data::Int64
end

struct Blob
    data::Int64
end

struct LiveGraph
    data::Int64
end

function llvm_hpvm_createNode(func)::Node
    # TODO: pass this type in properly
    llvm_func = @cfunction($func, Int, (Int, Int))
    GC.@preserve llvm_func begin
        Node(
            Base.llvmcall(
                (
                    """declare i8* @llvm.hpvm.createNode(i8*)""",
                    """
                        %2 = inttoptr i64 %0 to i8*
                        %ret_ptr = call i8* @llvm.hpvm.createNode(i8* %2)
                        %ret = ptrtoint i8* %ret_ptr to i64
                        ret i64 %ret
                    """,
                ),
                Int64,
                Tuple{Int64},
                Int64(Base.unsafe_convert(Ptr{Cvoid}, llvm_func)),
            )
        )
    end
end

function llvm_hpvm_createEdge(
    src::Node, dst::Node, broadcast::Bool, src_port::Int32,
    dst_port::Int32, streaming::Bool
)::Edge
    Edge(
        Base.llvmcall(
            (
                """declare i8* @llvm.hpvm.createEdge(i8*, i8*, i1, i32, i32, i1)""",
                """
                    %ptr0 = inttoptr i64 %0 to i8*
                    %ptr1 = inttoptr i64 %1 to i8*
                    %bit2 = icmp eq i8 %2, 1
                    %bit5 = icmp eq i8 %5, 1
                    %ret_ptr = call i8* @llvm.hpvm.createEdge(i8* %ptr0, i8* %ptr1, i1 %bit2, i32 %3, i32 %4, i1 %bit5)
                    %ret = ptrtoint i8* %ret_ptr to i64
                    ret i64 %ret
                """,
            ),
            Int64,
            Tuple{Int64, Int64, Bool, Int32, Int32, Bool},
            src.data, src.data, broadcast, src_port.data, dst_port.data, streaming,
        )
    )
end

function llvm_hpvm_bind_input(
    node::Node, parent_port::Int32, child_port::Int32, streaming::Bool
)::Void
    Base.llvmcall(
        (
            """declare i8* @llvm.hpvm.bind.input(i8*, i32, i32, i1)""",
            """
                %ptr0 = inttoptr i64 %0 to i8*
                %bit3 = icmp eq i8 %5, 1
                call void @llvm.hpvm.createEdge(i8* %ptr0, i32 %1, i32 %2, i1 %bit3)
                ret void
            """,
        ),
        Cvoid,
        Tuple{Int64, Int32, Int32, Bool},
        node.data, parent_port.data, child_port.data, streaming,
    )
end

function llvm_hpvm_bind_input(
    node::Node, child_port::Int32, parent_port::Int32, streaming::Bool
)::Void
    Base.llvmcall(
        (
            """declare i8* @llvm.hpvm.bind.output(i8*, i32, i32, i1)""",
            """
                %ptr0 = inttoptr i64 %0 to i8*
                %bit3 = icmp eq i8 %5, 1
                call void @llvm.hpvm.createEdge(i8* %ptr0, i32 %1, i32 %2, i1 %bit3)
                ret void
            """,
        ),
        Cvoid,
        Tuple{Int64, Int32, Int32, Bool},
        node.data, child_port.data, parent_port.data, streaming,
    )
end

function llvm_hpvm_malloc(n_bytes:: Int64)::Blob
    Blob(
        Base.llvmcall(
            (
                """declare i8* @llvm.hpvm.malloc(i64)""",
                """
                    %ret_ptr = call i8* @llvm.hpvm.malloc(i64 %0)
                    %ret = ptrtoint i8* %ret_ptr to i64
                    ret i64 %ret
                """,
            ),
            Int64,
            Tuple{Int64},
            n_bytes,
        )
    )
end

function llvm_hpvm_init()::Void
    Base.llvmcall(
        (
            """declare i8* @llvm.hpvm.init()""",
            """
                call void @llvm.hpvm.init()
                ret void
            """,
        ),
        Cvoid,
        Tuple{},
    )
end

function llvm_hpvm_cleanup()::Void
    Base.llvmcall(
        (
            """declare i8* @llvm.hpvm.cleanup()""",
            """
                call void @llvm.hpvm.cleanup()
                ret void
            """,
        ),
        Cvoid,
        Tuple{},
    )
end

function llvm_hpvm_launch(func, args, streaming::Bool)
    llvm_func = @cfunction($func, Int, (Int, Int, Int, Int))
    
    GC.@preserve llvm_func begin
        LiveGraph(
            Base.llvmcall(
                (
                    """declare i8* @llvm.hpvm.launch(i8*, i8*, i1)""",
                    """
                        %ptr0 = inttoptr i64 %0 to i8*
                        %ptr1 = inttoptr i64 %1 to i8*
                        %bit2 = icmp eq i8 %2, 1
                        %ret_ptr = call i8* @llvm.hpvm.createEdge(i8* %ptr0, i8* %ptr1, i1 %bit2)
                        %ret = ptrtoint i8* %ret_ptr to i64
                        ret i64 %ret
                    """,
                ),
                Int64,
                Tuple{Int64, Int64, Bool},
                Int64(Base.unsafe_convert(Ptr{Cvoid}, llvm_func)), args, streaming,
            )
        )
    end
end

function llvm_hpvm_wait(graph::LiveGraph)::Void
    Base.llvmcall(
        (
            """declare i8* @llvm.hpvm.wait(i8*)""",
            """
                %ptr0 = inttoptr i64 %0 to i8*
                call void @llvm.hpvm.wait(i8* %ptr0)
                ret void
            """,
        ),
        Cvoid,
        Tuple{Int64},
        graph.data,
    )
end

using InteractiveUtils

function comp_graph()
    node_abc = llvm_hpvm_createNode(*)
    llvm_hpvm_bind_input(node_abc, 0, 0)
    llvm_hpvm_bind_input(node_abc, 1, 1)
    llvm_hpvm_bind_output(node_abc, 0, 0)

    node_def = llvm_hpvm_createNode(*)
    llvm_hpvm_bind_input(node_def, 0, 0)
    llvm_hpvm_bind_input(node_def, 1, 1)
    llvm_hpvm_bind_output(node_def, 0, 0)

    node_cfg = llvm_hpvm_createNode(+)
    llvm_hpvm_bind_input(node_cfg, 0, 0)
    llvm_hpvm_bind_input(node_cfg, 1, 1)
    llvm_hpvm_bind_output(node_cfg, 0, 0)
end

function main()
    # TODO: use a block here
    llvm_hpvm_init()

    # TODO: do argument passing without copies

    llvm_hpvm_launch(comp_graph, (2, 3, 4, 5), )

    llvm_hpvm_cleanup()
end

# InteractiveUtils.@code_llvm optimize=false dump_module=true debuginfo=:source llvm_hpvm_createNode(*, Int, Int, Int)
