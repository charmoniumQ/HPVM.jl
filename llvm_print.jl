using Libdl
using Base
import Base.CodegenParams

function get_function_llvm_obj(@nospecialize(f), @nospecialize(t=Tuple);
    native::Bool=false, wrapper::Bool=false, optimize::Bool=true,
    params::CodegenParams=CodegenParams()
)::Ptr{Cvoid}

    # TODO: this is based on InteractiveUtils.code_llvm
    # clean up the extraneously copied parts

    ccall(:jl_is_in_pure_context, Bool, ()) && error("code reflection cannot be used from generated functions")
    if isa(f, Core.Builtin)
        throw(ArgumentError("argument is not a generic function"))
    end
    # get the MethodInstance for the method match
    world = typemax(UInt)
    meth = which(f, t)
    t = Base.to_tuple_type(t)
    tt = Base.signature_type(f, t)
    (ti, env) = ccall(:jl_type_intersection_with_env, Any, (Any, Any), tt, meth.sig)::Core.SimpleVector
    meth = Base.func_for_method_checked(meth, ti, env)
    linfo = ccall(:jl_specializations_get_linfo, Ref{Core.MethodInstance}, (Any, Any, Any, UInt), meth, ti, env, world)

    # get the code for it
    if native
        llvmf = ccall(:jl_get_llvmf_decl, Ptr{Cvoid}, (Any, UInt, Bool, CodegenParams), linfo, world, wrapper, params)
    else
        llvmf = ccall(:jl_get_llvmf_defn, Ptr{Cvoid}, (Any, UInt, Bool, Bool, CodegenParams), linfo, world, wrapper, optimize, params)
    end
    if llvmf == C_NULL
        error("could not compile the specified method")
    end

    return llvmf
end

libllvm_support = Libdl.dlopen("_build/libllvm_support.so")
value__get_name = Libdl.dlsym(libllvm_support, "value__get_name")

function get_function_llvm_name(@nospecialize(f), @nospecialize(t=Tuple);
    native::Bool=false, wrapper::Bool=false, optimize::Bool=true,
    params::CodegenParams=CodegenParams()
)::String
    llvmf = get_function_llvm_obj(
        f, t;
        native=native, wrapper=wrapper, optimize=optimize, params=params
    )
    return unsafe_string(ccall(value__get_name, Cstring, (Ptr{Cvoid},), llvmf))
end

function thunk()
    println("hello world")
    return 0
end

println(get_function_llvm_name(thunk, ()))
