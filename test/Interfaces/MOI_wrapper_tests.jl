# ============================ /test/MOI_wrapper.jl ============================
# Test structure taken from https://jump.dev/JuMP.jl/stable/moi/submodules/Test/overview/

module TestClarabel

import Clarabel
using MathOptInterface
using Test

const MOI = MathOptInterface

T = Float64
optimizer = Clarabel.Optimizer{T}()
MOI.set(optimizer,MOI.Silent(),true)

BRIDGED = MOI.Bridges.full_bridge_optimizer(
    MOI.Utilities.CachingOptimizer(
        MOI.Utilities.UniversalFallback(MOI.Utilities.Model{T}()),
        optimizer,
    ),
    T,
)

# See the docstring of MOI.Test.Config for other arguments.
const CONFIG = MOI.Test.Config(
    # Modify tolerances as necessary.
    atol = 1e-4,
    rtol = 1e-4,
    # Use MOI.LOCALLY_SOLVED for local solvers.
    optimal_status = MOI.OPTIMAL,
    # Pass attributes or MOI functions to `exclude` to skip tests that
    # rely on this functionality.
    exclude = Any[MOI.VariableName,
                  MOI.delete,
                  MOI.ObjectiveBound],
)

"""
    runtests()

This function runs all functions in the this Module starting with `test_`.
"""
function runtests()
    @testset "MOI" begin
        for name in names(@__MODULE__; all = true)
            if startswith("$(name)", "test_")
                @testset "$(name)" begin
                    getfield(@__MODULE__, name)()
                end
            end
        end
    end
end

"""
    test_runtests()

This function runs all the tests in MathOptInterface.Test.

Pass arguments to `exclude` to skip tests for functionality that is not
implemented or that your solver doesn't support.
"""
function test_MOI_standard()

    MOI.Test.Config(
        exclude = Any[
            # MOI.VariableName
    ])

    MOI.Test.runtests(
        BRIDGED,
        CONFIG,
        exclude = String[
            "test_model_UpperBoundAlreadySet",   #fixed in https://github.com/jump-dev/MathOptInterface.jl/pull/1775,  waiting for it to be merged to next MOI release.
        ],
        # This argument is useful to prevent tests from failing on future
        # releases of MOI that add new tests.
        exclude_tests_after = VersionNumber(Clarabel.moi_version()),
    )
    return
end

"""
    test_SolverName()

You can also write new tests for solver-specific functionality. Write each new
test as a function with a name beginning with `test_`.
"""
function test_SolverName()
    @test MOI.get(Clarabel.Optimizer(), MOI.SolverName()) == "Clarabel"
    return
end

end # module TestClarabel

# This line at tne end of the file runs all the tests!
TestClarabel.runtests()
