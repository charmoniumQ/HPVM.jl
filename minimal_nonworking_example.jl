function llvm_hpvm_createNode(func)::Node
    # TODO: pass this type in properly
    llvm_func = @cfunction($func, Int, (Int, Int))
    GC.@preserve llvm_func begin
        Node(
            ccall("llvm.hpvm.createNode", llvmcall, Ref{Int8}, (Ptr{Int8},), Base.unsafe_convert(Ptr{Cvoid}, llvm_func))
        )
    end
end

llvm_hpvm_createNode(+)
