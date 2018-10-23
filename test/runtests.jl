module TestViVa

using ViVa

using DataFrames
using GeneticVariation
using Base.Test


all_tests = [
    ("new_vcf_utils.jl",   "           Testing: New VCF Utils"),
#    ("plot_utils.jl",     "       Testing: Plot Utils")
    ]

println("Running tests:")

for (t, test_string) in all_tests
    println("-----------------------------------------")
    println("-----------------------------------------")
    println(test_string)
    println("-----------------------------------------")
    println("-----------------------------------------")
    include(t)
end

end